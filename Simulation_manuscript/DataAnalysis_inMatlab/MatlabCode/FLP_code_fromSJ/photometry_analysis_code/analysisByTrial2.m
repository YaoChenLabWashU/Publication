% analysis of raw neural and behavioral data
% analysis by trial type
% low pass filter signal at 100Hz

%clear all;

dataname={'AD1_','AD2_'};
ch_name={'dLight','dLight'};
filelist = [1 2 3];
mousenamelist = {'SJ261','SJ262','SJ263'};


n=length(filelist); %number of mice
duration=100; %analysis duration of 30s
inputrate=1000; %1000Hz
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=11; %number of days for all trials
%output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\']; %output file directory
output_dir=[''];

timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

baseline=[0.228 0.4298]; %fiber autofluorescence baseline

% global timebin
% global windowSize

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for i=1:1:n
    counter=0;
    clear TrialData;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for photometry data
        if(day<=2)
            input_dir= ['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\DA sensor photometry\2019010',num2str(day+7),' dLight titer test - day ',num2str(day),'\'];
        elseif(day>=3)
            input_dir= ['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\DA sensor photometry\201901',num2str(day+7),' dLight titer test - day ',num2str(day),'\'];
        end
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20190107 dLight titer cohort - summary\'];
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2','latency3', 'entering_time3', 'occupancy', 'total_occupancy', 'trial_duration','latency4', 'entering_time4');
        
        %loop through each intensity channel
        data=[];
        for d=1:length(dataname)
            %reading raw photometry data
            filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
            load(filename,[dataname{d},num2str(filelist(i))]);
            x=eval([dataname{d},num2str(filelist(i))]);
            
            %baseline fiber autofluorescence subtraction
            x.data=x.data-baseline(d);
            
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
                else
                    TrialData(counter).raw_LED(d,:)=0;
                    TrialData(counter).dff_LED(d,:)=0;
                end
                
                %aligning data to the LED zone entering time
                if(entering_time(j)>0 && entering_time(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_zone(d,1:length(x))=x;
                    TrialData(counter).dff_zone(d,1:length(y))=y;
                else
                    TrialData(counter).raw_zone(d,:)=0;
                    TrialData(counter).dff_zone(d,:)=0;
                end
                
                %aligning data to the pellet dispensing time
                if(rewardtime(j)>0 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_dispense(d,1:length(x))=x;
                    TrialData(counter).dff_dispense(d,1:length(y))=y;
                else
                    TrialData(counter).raw_dispense(d,:)=0;
                    TrialData(counter).dff_dispense(d,:)=0;
                end
                
                %aligning data to the pellet receptacle entering
                cmap=hsv(length(entering_time2));
                if(entering_time2(j)>0 && entering_time2(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_receptacle(d,1:length(x))=x;
                    TrialData(counter).dff_receptacle(d,1:length(y))=y;
                else
                    TrialData(counter).raw_receptacle(d,:)=0;
                    TrialData(counter).dff_receptacle(d,:)=0;
                end
                
                %aligning data to the pellet receptacle entering after LED
                if(entering_time4(j)>0 && entering_time4(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time4(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_receptacle2(d,1:length(x))=x;
                    TrialData(counter).dff_receptacle2(d,1:length(y))=y;
                else
                    TrialData(counter).raw_receptacle2(d,1:length(timestamp))=zeros(1,length(timestamp));
                    TrialData(counter).dff_receptacle2(d,1:length(timestamp))=zeros(1,length(timestamp));
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


%% update behavior variables
timestamp=[0:timebin/1000:duration];

for i=1:length(filelist)
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20190107 dLight titer cohort - summary\'];
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
        
        %display(rewardtime);
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