dataname={'AD1_'};
filelist=[2];
mousenamelist = {'SJ418_2'};

n=length(filelist); %number of mice
duration=20; %analysis duration in sec
inputrate=1000; %in Hz
baseline_duration=10; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
delay=50; %delay in ms between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
output_dir=['']; %output file directory
ch_name={'dLight'};
num_days=1;
trial_number=6;

timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

input_dir='';
input_dir2='';
output_dir=[''];

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for i=1:trial_number
    %rewardtime(i)=1500-120+120*i;
    rewardtime(i)=120*(i-1)+60;
    entering_time2(i)=1;
end

for i=1:1:n
    clear TrialData
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %load('eatingtime.mat','eatingtime');
        %         for j=1:trial_num
        %             rewardtime(j)=120+200*(j-1);
        %             entering_time2(j)=eatingtime(j,i);
        %             latency2(j)=entering_time2(j)-rewardtime(j);
        %         end
        
        %loop through each intensity channel
        data=[];
        for d=1:length(dataname)
            %reading raw photometry data
            filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
            load(filename,[dataname{d},num2str(filelist(i))]);
            x=eval([dataname{d},num2str(filelist(i))]);
                        
            %low pass filter the raw intensity data with 100 Hz
            %y=lowpass(x.data,1,inputrate);
            
            %moving average filter
            b = (1/windowSize)*ones(1,windowSize);
            a = 1;
            y=filter(b,a,x.data);
            
            %median filter
            %y=medfilt1(x.data,windowSize);
            
            %y=x.data;
            
            %putting raw traces into a user defined timebin
            for k=1:floor(length(y)/timebin)
                data(d,k) = sum(y(timebin*(k-1)+1:timebin*k));
            end
        end
        
        cmap=hsv(length(rewardtime));
        %processing data by each trial
        for j=1:length(rewardtime)
            counter=counter+1;
            
            %saving data allocation variable
            TrialData(counter).timebin=timebin;
            TrialData(counter).duration=duration;
            TrialData(counter).inputrate=inputrate;
            TrialData(counter).baseline_duration=baseline_duration;
            
            %saving behavioral event time stamps
            TrialData(counter).day=day;
            TrialData(counter).trialnumber=j;
            TrialData(counter).cuetime=0;
            cuetime(j)=0;
            TrialData(counter).rewardtime = rewardtime(j);
            TrialData(counter).latency=0;
            TrialData(counter).entering_time=0;
            entering_time(j)=0;
            TrialData(counter).entering_time2=entering_time2(j);
            TrialData(counter).latency2=entering_time2(j)-rewardtime(j);
            TrialData(counter).occupancy=0;
            
            %saving channel names for each intensity channel
            TrialData(counter).ch_name = ch_name;
            
            %figuring out a trial type
            TrialData(counter).trialtype = 1; %reward received success trial
            
            for d=1:length(dataname)
                datalim = length(data(d,:))*timebin/1000;
                
                %calculating baseline before the trial onset (cue-3s):
                %animals has to stay in the zone 1 for 3s before LED on
                if rewardtime(j)-3+delay/1000 + baseline_duration >= datalim
                    continue;
                end
                fo=calculate_reference(squeeze(data(d,:)),(rewardtime(j)-3+delay/1000),baseline_duration,inputrate,timebin);
                TrialData(counter).intensity_baseline(d) = fo;
                
                %aligning data to the pellet dispensing time
                if(entering_time2(j)>0 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_dispense(d,:)=x;
                    TrialData(counter).dff_dispense(d,:)=y;
                    
                    display(j);
                    figure(100);
                    plot(timestamp,y(1:length(timestamp)),'color',cmap(j,:));
                    hold on;
                    
                    %find the time point of max peak after dispensing
                    %to receptacle entry time + 10s
                    idx_start=round((rewardtime(j)+delay/1000)*inputrate/timebin);
                    idx_end=round((entering_time2(j)+delay/1000+10)*inputrate/timebin);
                    m=max(data(d,idx_start:idx_end));
                    idx=idx_start-1+find(data(d,idx_start:idx_end)==m,1);
                    
                    %align to max peak
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),idx*timebin/inputrate,duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_dispense_max(d,1:length(x))=x;
                    TrialData(counter).dff_dispense_max(d,1:length(y))=y;
                    
%                     display(j);
%                     figure(100);
%                     plot(y,'color',cmap(j,:));
%                     hold on;
                else
                    TrialData(counter).raw_zone(d,:)=0;
                    TrialData(counter).dff_zone(d,:)=0;
                end
            end
        end
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    save(outputfilename,'TrialData');
end

%clear all;
%delete(findall(0,'Type','figure'));
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;

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