%dataname={'AD1_','AD2_','AD3_'};
filelist=[1 2 3 4 5 6 7 8 9 10 11];
mousenamelist = {'SJ471_1', 'SJ471_2', 'SJ471_3', 'SJ471_4', 'SJ471_5', 'SJ471_6',...
     'SJ471_7', 'SJ471_8', 'SJ471_9', 'SJ471_10', 'SJ471_11'};

n=length(filelist);
timebin=20; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=100; %analysis duration of 30s
ITI=120; %intertrial interval of 200s
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=11; %number of days for all trials
output_dir=[''];


delay=0;

%% analyze the lifetime signal using the behavioral event timestamps
global spc

timebin = 1;
num_days=1;
duration=100; %duration of analysis=ITI interval
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM channel
trial_number=10;
baseline_tau_duration=baseline_duration;

for i=1:trial_number
    %rewardtime(i)=1500-120+120*i;
    rewardtime(i)=120*i;
    entering_time2(i)=1;
end

timestamp=[-baseline_duration:timebin:duration-baseline_duration];

for f=1:length(filelist)
    day=1;
    %directory for lifetime data
    %input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_201805',num2str(14+day),' (AKAR mice- behavior day ',num2str(day),')\'];
    input_dir=[''];
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    baseline=cal_baseline(ch);
    
    dtau_dispense=[];   time_dispense=[];   pc_dispense=[];
    dtau_receptacle=[]; time_receptacle=[]; pc_receptacle=[];
    
    for day=1:num_days
        %directory for lifetime data
        %input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\DA sensor photometry\20180808 DA sensor + Chrimson SJ 171 terminal\'];
        input_dir='';
        
        %directory for behavior data
        %input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20180514 (AKAR mice- behavior - summary)\'];
        
%         filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
%         load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
%         
%         filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
%         load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');

        %find laser control stim signal time
        stim_signal='AD3_';
        filename=[input_dir,stim_signal,num2str(filelist(f)),'.mat'];
        load(filename,[stim_signal,num2str(filelist(f))]);
        x=eval([stim_signal,num2str(filelist(f))]);        
        
        temp=[];
        for j=1:length(rewardtime)
            idx_start=inputrate*(rewardtime(j)-1);
            idx_end=inputrate*(rewardtime(j)+5);
            temp(j) = idx_start + find(x.data(idx_start:idx_end)>2.5,1) -1;
        end
        
        rewardtime=temp/inputrate;
        display('stim time: ');
        display(rewardtime);

        cmap=hsv(length(rewardtime));
        for i=1:length(rewardtime)
            %if(rewardtime(i)>0 && entering_time2(i)>0) %rewardtime==-1 when the mouse was not rewarded, throwing out a weird trial where reward happened despite LED turning off
                %[dlifetime,photoncount,time] = align_FLIM_signal_new(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,baseline_tau_duration,baseline);
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,baseline_tau_duration);
                if(length(dlifetime)>0)
                    dtau_dispense(day,i,1:length(dlifetime))=dlifetime;
                    time_dispense(day,i,1:length(time))=time;
                    pc_dispense(day,i,1:length(time))=photoncount(1:length(time));
                    
                    figure(100);
                    plot(timestamp, dlifetime(1:length(timestamp)),'color',cmap(i,:));
                    title('deltalifetime (ns) vs. time(s): pellet dispensed at 0s');
                    hold on;
                    
                    figure(101);
                    plot(timestamp, photoncount(1:length(timestamp)),'color',cmap(i,:));
                    title('normalized photon counts vs. time(s): pellet dispensed at 0s');
                    hold on;
                end
            %end
            
%             if(rewardtime(i)>0 && entering_time2(i)>0) %rewardtime==-1 when the mouse was not rewarded
%                 [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch,,baseline_tau_duration);
%                 if(length(dlifetime)>0)
%                     dtau_receptacle(day,i,1:length(dlifetime))=dlifetime;
%                     time_receptacle(day,i,1:length(time))=time;
%                     pc_receptacle(day,i,1:length(time))=photoncount(1:length(time));
%                 end
%             end
        end
        
         rewardtime_combined(day,1:length(rewardtime))=rewardtime;
%         latency2_combined(day,1:length(latency2))=latency2;
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    save(outputfilename,'dtau_dispense','pc_dispense','rewardtime_combined');
    %save(outputfilename,'dtau_LED','time_LED','pc_LED','dtau_zone','time_zone','pc_zone','dtau_dispense','time_dispense','pc_dispense','dtau_receptacle','time_receptacle','pc_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
    %save(outputfilename,'dtau_LED','time_LED','dtau_zone','time_zone','dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
    figure(100); hold off;
    figure(101); hold off;
end
return;