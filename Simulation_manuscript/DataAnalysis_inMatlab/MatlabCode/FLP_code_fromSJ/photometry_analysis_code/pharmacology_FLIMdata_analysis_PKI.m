%analyze delta lifetime for pharmacology experiment
global spc
cell=0;
filelist = [1 2 3];
mousenamelist={'SJ274','SJ275','SJ276'};
output_dir='';

%% D1R agonist response analysis
% eventtime(1,:) = [627 629 632]; %time when the injection ended
% eventtime(2,:) = [642 636 655];
% eventtime(3,:) = [1953 1950 1973];
% 
% eventtime(4,:) = [1946 1945 1960];
% eventtime(5,:) = [1946 1944 1949];
% eventtime(6,:) = [1966 1946 1950];
% eventtime(7,:) = [1945 1942 1950];
% 
% baseline_duration = 400; %200s
% baseline_tau_duration=50;
% duration = 2000; % 1800s
% timebin = 1;
% ch = 1;
% daylist=[1 2 4 6 8 10 12];
% cmap=hsv(length(daylist));
% 
% timestamp=[-baseline_duration:timebin:duration-baseline_duration];
% 
% for f=1:length(filelist)
%     for i=1:length(daylist)
%         
%         if(daylist(i)<=8)
%             input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_2019020',num2str(daylist(i)+1),' AKAR-PKI D1R agonist day',num2str(daylist(i)),'\'];
%         else
%             input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_201902',num2str(daylist(i)+1),' AKAR-PKI D1R agonist day',num2str(daylist(i)),'\'];
%         end
%         
%         if(daylist(i)<=2)
%             filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)+1)];
%         else
%             filename=[input_dir,'continuous aquistion data_',num2str(filelist(f))];
%         end
%         
%         load(filename,'FLPdata_time','FLPdata_counter','FLPdata_lifetimes');
%         spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
%         spc_drawAll(ch, 1, 1);
%         spc_fitexpgaussGY(ch);
%         spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
%         baseline=cal_baseline(ch);
%         
%         dtau=[];    photoncount=[]; time=[];
%         if cell==1 % old data file in cells
%             [dtau,photoncount,time] = align_FLIM_signal2(FLPdata_time, FLPdata_lifetimes, eventtime(i,f),duration,baseline_duration,timebin,ch,baseline_tau_duration,baseline);
%         else % new data file in regular arrays
%             [dtau,photoncount,time] = align_FLIM_signal4(FLPdata_time, FLPdata_lifetimes, eventtime(i,f),duration,baseline_duration,timebin,ch,baseline_tau_duration);
%         end
%         
%         [tau,photoncount,time]=align_FLIM_signal_abs_tau(FLPdata_time, FLPdata_lifetimes, eventtime(i,f),duration,baseline_duration,timebin,ch);
%         
%         outputfilename = ['analysis_',mousenamelist{f},'day',num2str(daylist(i))];
%         save(outputfilename,'dtau','photoncount','time','tau');
%         
%         if length(timestamp) > dtau
%             timestamp=timestamp(1:end-1);
%         end
%         
%         figure(100);
%         plot(timestamp,dtau(1:length(timestamp)),'color',cmap(i,:));
%         title('delta lifetime (ns) vs. time (s): injection ended at 0s');
%         hold on;
%         
%         figure(101);
%         plot(timestamp,photoncount(1:length(timestamp)),'color',cmap(i,:));
%         title('photoncount vs. time (s): injection ended at 0s');
%         hold on;
%         
%         figure(102);
%         plot(timestamp,tau(1:length(timestamp)),'color',cmap(i,:));
%         title('lifetime (ns) vs. time (s): injection ended at 0s');
%         hold on;
%     end
%     
%     legendlabel={};
%     for i=1:length(daylist)
%         legendlabel{i}=['day ',num2str(daylist(i))];
%     end
%     
%     for i=0:1:2
%         figure(100+i);
%         if(i==0)
%             ylim([-0.2, +0.05]);
%         end
%         legend(legendlabel);
%         hold off;
%     end
% end
% 
% return;

%% pellet response analysis
global spc

timebin = 1;
num_days=1;
duration=100; %duration of analysis=ITI interval
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM board channel name
ch_name='AKAR';
inputrate=1;
delay=50; %50ms NIDAQ external trigger delay

daylist=[4 6 8 10 12];

for f=1:length(filelist)
    clear TrialData;
    %directory for lifetime data
    input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20190205 AKAR-PKI D1R agonist day4\'];
    
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    counter=0;
    
    %add data to the pre-existing TrialData file
%     outputfilename = [output_dir,'analysis_',mousenamelist{f}];
%     load(outputfilename,'TrialData');
    
    for day=daylist
        display(['analyzing mouse ',num2str(f),' day ',num2str(day),'.....']);
        
        if(day<=8)
            %directory for lifetime data
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_2019020',num2str(1+day),' AKAR-PKI D1R agonist day',num2str(day),'\'];
        else
            %directory for lifetime data
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_201902',num2str(1+day),' AKAR-PKI D1R agonist day',num2str(day),'\'];
        end
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
        spc_fitexpgaussGY(ch);
        spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation        
        
        %directory for behavior data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20190202 AKAR-PKI D1R agonist summary\'];
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
        load(filename2,'rewardtime', 'entering_time2', 'latency2');
        
        datalim=max(max(FLPdata_time()));
        cmap=hsv(length(rewardtime));
        %processing data by each trial
        for j=1:length(rewardtime)
            if f==3
                if day==4 && (j>=4 && j<=6)
                    continue;
                end
                
                if day==6 && (j>=2 && j<=7)
                    continue;
                end
            end
            
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
            
            %aligning data to the pellet dispensing time
            if(entering_time2(j)>0 && latency2(j)<120 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,rewardtime(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_dispense=dlifetime;
                TrialData(counter).pc_dispense=photoncount;
                TrialData(counter).dtautime_dispense=time;
           
                figure(100);
                plot(dlifetime,'color',cmap(j,:));
                hold on;
                
                figure(101);
                plot(photoncount,'color',cmap(j,:));
                hold on;
            else
                TrialData(counter).dtau_dispense=0;
                TrialData(counter).pc_dispense=0;
                TrialData(counter).dtautime_dispense=0; 
            end
            
            %aligning data to the pellet receptacle entering
            if(entering_time2(j)>0 && latency2(j)<120 && entering_time2(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,entering_time2(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_receptacle=dlifetime;
                TrialData(counter).pc_receptacle=photoncount;
                TrialData(counter).dtautime_receptacle=time;        
                
                figure(102);
                plot(dlifetime,'color',cmap(j,:));
                hold on;
                
                figure(103);
                plot(photoncount,'color',cmap(j,:));
                hold on;
            else
                TrialData(counter).dtau_receptacle=0;
                TrialData(counter).pc_receptacle=0;
                TrialData(counter).dtautime_receptacle=0;        
            end
        end       
        
        display(day);
        for j=0:1:3
            figure(100+j); hold off;
        end
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    %save(outputfilename,'TrialData','-append');
    save(outputfilename,'TrialData');
end
return;