% analysis of raw neural and behavioral data
% analysis by trial type

dataname={'AD1_'};
ch_name={'dLight'};
filelist = [1 2 3 4 5 6 7 8];
mousenamelist = {'SJ213','SJ214','SJ215','SJ216','SJ217','SJ218','SJ219','SJ220'};

n=length(filelist); %number of mice
timebin=40; %timebin in ms
duration=100; %analysis duration in sec
inputrate=1000; %in Hz
cc_range=1;
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
delay=50; %delay in ms between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=13; %number of days for all trials
output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20181015 dLight + AKAR mice - summary\']; %output file directory

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for i=1:1:n
    clear TrialData
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for photometry data
        input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\201810',num2str(15+day),' dLight + AKAR mice - behavior day ',num2str(day),'\'];
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20181015 dLight+AKAR mice - summary\'];
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2','latency3', 'entering_time3', 'occupancy', 'total_occupancy', 'trial_duration');
        
        %loop through each intensity channel
        data=[];
        for d=1:length(dataname)
            %reading raw photometry data
            filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
            load(filename,[dataname{d},num2str(filelist(i))]);
            x=eval([dataname{d},num2str(filelist(i))]);
            
            %putting raw traces into a user defined timebin
            for k=1:floor(length(x.data)/timebin)
                data(d,k) = sum(x.data(timebin*(k-1)+1:timebin*k));
            end
        end
        
        %processing data by each trial
        for j=1:length(cuetime)
            counter=counter+1;
            
            %saving data allocation variable
            TrialData(counter).timebin=timebin;
            TrialData(counter).duration=duration;
            TrialData(counter).inputrate=inputrate;
            TrialData(counter).baseline_duration=baseline_duration;
            
            %saving behavioral event time stamps
            TrialData(counter).day=day;
            TrialData(counter).trialnumber=j;
            TrialData(counter).cuetime=cuetime(j);
            TrialData(counter).rewardtime = rewardtime(j);
            TrialData(counter).latency=latency(j);
            TrialData(counter).entering_time=entering_time(j);
            TrialData(counter).latency2=latency2(j);
            TrialData(counter).entering_time2=entering_time2(j);
            TrialData(counter).occuapncy=occupancy(j);
            TrialData(counter).latency3=latency3(j);
            TrialData(counter).entering_time3=entering_time3(j);
            
            %saving channel names for each intensity channel
            TrialData(counter).ch_name = ch_name;
                       
            %figuring out a trial type
            if rewardtime(j)>0
                TrialData(counter).trialtype = 1; %reward received success trial
                %Do not include a trial as a success trial where the mouse did not enter the receptacle in
                %30s after dispensing of the pellet (either no pellet error or
                %IR sensor detection error)
                if(latency2(j)-latency3(j)>=10 || latency2(j)>=120)
                    TrialData(counter).trialtype = 9;
                end
            elseif occupancy(j)>0 && occupancy(j)<3
                TrialData(counter).trialtype = 2; %succesful entry, unsuccessful stay >= 3s
            elseif occupancy(j)>=3
                TrialData(counter).trialtype = 4; %reward omission trial (successful entry and stay + no reward)
            else
                TrialData(counter).trialtype = 3; %unsuccessful entry < 5s after LED onset
            end
            
            if day==13 %LED omission session (LED was omitted throughout this session)
                if rewardtime(j)>0
                    TrialData(counter).trialtype = 5; %reward received success trial
                    %Do not include a trial as a success trial where the mouse did not enter the receptacle in
                    %30s after dispensing of the pellet (either no pellet error or
                    %IR sensor detection error)
                    if(latency2(j)-latency3(j)>=10 || latency2(j)>=120)
                        TrialData(counter).trialtype = 10;
                    end
                elseif occupancy(j)>0 && occupancy(j)<3
                    TrialData(counter).trialtype = 6; %succesful entry, unsuccessful stay >= 3s
                elseif occupancy(j)>=3
                    TrialData(counter).trialtype = 8; %reward omission trial (successful entry and stay + no reward)
                else
                    TrialData(counter).trialtype = 7; %unsuccessful entry < 5s after LED onset
                end
            end
            
            for d=1:length(dataname)
                datalim = length(data(d,:))*timebin/1000;
                
                %calculating baseline before the trial onset (cue-3s):
                %animals has to stay in the zone 1 for 3s before LED on
                if cuetime(j)-3+delay/1000 + baseline_duration >= datalim
                    continue;
                end
                fo=calculate_reference(squeeze(data(d,:)),(cuetime(j)-3+delay/1000),baseline_duration,inputrate,timebin);
                TrialData(counter).intensity_baseline(d) = fo;
                
                %aligning data to the LED on time
                if(cuetime(j)>0 && cuetime(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_LED(d,1:length(x))=x;
                    TrialData(counter).dff_LED(d,1:length(y))=y;
                end
                
                %aligning data to the LED zone entering time
                if(entering_time(j)>0 && entering_time(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_zone(d,1:length(x))=x;
                    TrialData(counter).dff_zone(d,1:length(y))=y;
                end
                
                %aligning data to the pellet dispensing time
                if(rewardtime(j)>0 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_dispense(d,1:length(x))=x;
                    TrialData(counter).dff_dispense(d,1:length(y))=y;
                else
                    TrialData(counter).raw_dispense(d,1:length(timestamp))=zeros(1,length(timestamp));
                    TrialData(counter).dff_dispense(d,1:length(timestamp))=zeros(1,length(timestamp));
                end
                
                %aligning data to the pellet receptacle entering
                cmap=hsv(length(entering_time2));
                if(entering_time2(j)>0 && entering_time2(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_receptacle(d,1:length(x))=x;
                    TrialData(counter).dff_receptacle(d,1:length(y))=y;
                else
                    TrialData(counter).raw_receptacle(d,1:length(timestamp))=zeros(1,length(timestamp));
                    TrialData(counter).dff_receptacle(d,1:length(timestamp))=zeros(1,length(timestamp));
                end
            end
        end
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    save(outputfilename,'TrialData');
end

% %delete(findall(0,'Type','figure'));
% %plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
% %confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
% return;

%% analyze the lifetime signal using the behavioral event timestamps
global spc

timebin = 1;
num_days=13;
duration=100; %duration of analysis=ITI interval
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM board channel name

for f=1:length(filelist)
    clear TrialData;
    day=1;
    %directory for lifetime data
    input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\201810',num2str(15+day),' dLight + AKAR mice - behavior day ',num2str(day),'\'];
    
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc.fit.range=[5 13.5];
    spc.fits{ch}.fitstart=5;
    spc.fits{ch}.fitend=13.5;
    spc_drawAll(ch, 1, 1);
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    counter=0;
    
    %add data to the pre-existing TrialData file
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    load(outputfilename,'TrialData');
    
    for day=1:num_days
        display(['analyzing mouse ',num2str(f),' day ',num2str(day),'.....']);
        
        %directory for photometry data
        input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\201810',num2str(15+day),' dLight + AKAR mice - behavior day ',num2str(day),'\'];
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20181015 dLight+AKAR mice - summary\'];
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];        
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2','latency3', 'entering_time3', 'occupancy', 'total_occupancy', 'trial_duration');
        
        datalim=max(FLPdata_time);
        %processing data by each trial
        for j=1:length(cuetime)
            counter=counter+1;
            
            %saving data allocation variable
            TrialData(counter).timebin=timebin;
            TrialData(counter).duration=duration;
            TrialData(counter).inputrate=inputrate;
            TrialData(counter).baseline_duration=baseline_duration;
            
            %saving behavioral event time stamps
            TrialData(counter).day=day;
            TrialData(counter).trialnumber=j;
            TrialData(counter).cuetime=cuetime(j);
            TrialData(counter).rewardtime = rewardtime(j);
            TrialData(counter).latency=latency(j);
            TrialData(counter).entering_time=entering_time(j);
            TrialData(counter).latency2=latency2(j);
            TrialData(counter).entering_time2=entering_time2(j);
            TrialData(counter).occuapncy=occupancy(j);
            TrialData(counter).latency3=latency3(j);
            TrialData(counter).entering_time3=entering_time3(j);
            
            %saving channel names for each intensity channel
            TrialData(counter).ch_name = ch_name;
            
            %figuring out a trial type
            if rewardtime(j)>0
                TrialData(counter).trialtype = 1; %reward received success trial
                %Do not include a trial as a success trial where the mouse did not enter the receptacle in
                %30s after dispensing of the pellet (either no pellet error or
                %IR sensor detection error)
                if(latency2(j)-latency3(j)>=10 || latency2(j)>=120)
                    TrialData(counter).trialtype = 9;
                end
            elseif occupancy(j)>0 && occupancy(j)<3
                TrialData(counter).trialtype = 2; %succesful entry, unsuccessful stay >= 3s
            elseif occupancy(j)>=3
                TrialData(counter).trialtype = 4; %reward omission trial (successful entry and stay + no reward)
            else
                TrialData(counter).trialtype = 3; %unsuccessful entry < 5s after LED onset
            end
            
            if day==13 %LED omission session (LED was omitted throughout this session)
                if rewardtime(j)>0
                    TrialData(counter).trialtype = 5; %reward received success trial
                    %Do not include a trial as a success trial where the mouse did not enter the receptacle in
                    %30s after dispensing of the pellet (either no pellet error or
                    %IR sensor detection error)
                    if(latency2(j)-latency3(j)>=10 || latency2(j)>=120)
                        TrialData(counter).trialtype = 10;
                    end
                elseif occupancy(j)>0 && occupancy(j)<3
                    TrialData(counter).trialtype = 6; %succesful entry, unsuccessful stay >= 3s
                elseif occupancy(j)>=3
                    TrialData(counter).trialtype = 8; %reward omission trial (successful entry and stay + no reward)
                else
                    TrialData(counter).trialtype = 7; %unsuccessful entry < 5s after LED onset
                end
            end
            
            if(day==12)
                display('');
            end
            
            %aligning data to the LED on time
            if(cuetime(j)>0 && cuetime(j)+delay/1000+duration <= datalim) % if data exists
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,cuetime(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_LED=dlifetime;
                TrialData(counter).pc_LED=photoncount;
                TrialData(counter).dtautime_LED=time;                
            else
                TrialData(counter).dtau_LED=0;
                TrialData(counter).pc_LED=0;
                TrialData(counter).dtautime_LED=0;
            end
            
            %aligning data to the LED zone entering time
            if(entering_time(j)>0 && entering_time(j)+delay/1000+duration <= datalim) % if data exists
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,entering_time(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_zone=dlifetime;
                TrialData(counter).pc_zone=photoncount;
                TrialData(counter).dtautime_zone=time;     
            else
                TrialData(counter).dtau_zone=0;
                TrialData(counter).pc_zone=0;
                TrialData(counter).dtautime_zone=0;     
            end
            
            %aligning data to the pellet dispensing time
            if(rewardtime(j)>0 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,rewardtime(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_dispense=dlifetime;
                TrialData(counter).pc_dispense=photoncount;
                TrialData(counter).dtautime_dispense=time; 
            else
                TrialData(counter).dtau_dispense=0;
                TrialData(counter).pc_dispense=0;
                TrialData(counter).dtautime_dispense=0; 
            end
            
            %aligning data to the pellet receptacle entering
            if(entering_time2(j)>0 && entering_time2(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time,FLPdata_lifetimes,entering_time2(j)+delay/1000,duration,baseline_duration,timebin,ch,baseline_duration);
                TrialData(counter).dtau_receptacle=dlifetime;
                TrialData(counter).pc_receptacle=photoncount;
                TrialData(counter).dtautime_receptacle=time;        
            else
                TrialData(counter).dtau_receptacle=0;
                TrialData(counter).pc_receptacle=0;
                TrialData(counter).dtautime_receptacle=0;        
            end
        end    
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    save(outputfilename,'TrialData','-append');
    %save(outputfilename,'TrialData','successrate','latency_combined','latency2_combined','occupancy_combined');
end
%return;

%% update behavior variables
timestamp=[0:timebin/1000:duration];

for i=1:length(filelist)
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20181015 dLight+AKAR mice - summary\'];
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration' ,'latency3','entering_time3');
        
        %processing data by each trial
        successrate(day)=length(find(rewardtime>0))/length(rewardtime);
        latency_combined(day).data=latency;
        latency2_combined(day).data=latency2;
        latency3_combined(day).data=latency3;
        occupancy_combined(day).data=occupancy;
        
        cuetime_combined(day).data=cuetime;
        rewardtime_combined(day).data=rewardtime;
        entering_time_combined(day).data=entering_time;
        entering_time2_combined(day).data=entering_time2;
        entering_time3_combined(day).data=entering_time3;
        
        total_occupancy_combined(day).data=total_occupancy;
        trial_duration_combined(day)=trial_duration;
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    save(outputfilename,'successrate','latency_combined','latency2_combined','latency3_combined','occupancy_combined','cuetime_combined',...
        'entering_time_combined','entering_time2_combined','entering_time3_combined','rewardtime_combined',...
        'total_occupancy_combined','trial_duration_combined','-append');
end

%delete(findall(0,'Type','figure'));
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;