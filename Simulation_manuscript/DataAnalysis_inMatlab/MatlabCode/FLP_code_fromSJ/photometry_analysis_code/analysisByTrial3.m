% analysis of raw neural and behavioral data
% analysis by trial type
% low pass filter signal at 100Hz

%clear all;
%close all;
%clear all;

dataname={'AD1_'};
ch_name={'dLight'};
filelist = [1 2 3 4 5 6 7 8];
mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};

n=length(filelist); %number of mice
duration=100; %analysis duration of 30s <-------------------100
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
Ethovision_delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=12; %number of days for all trials
output_dir=[''];

timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

baseline=[0.3104]; %fiber autofluorescence baseline

% global timebin
% global windowSize

timebin=10;
windowSize=200;
Ethovision_delay=198; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
delay=Ethovision_delay - windowSize;

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];
delay=Ethovision_delay - windowSize;

for i=1:1:n
    counter=0;
    clear TrialData;
    daily_intensity_baseline=[];
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for photometry data
        if (day==1)
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180731 AKAR + DA sensor mice - behavior day 1\'];
        elseif day==11
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180810 AKAR + DA sensor mice - behavior day 11\'];
        elseif day==12
            input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\Combined Data\20180811 AKAR + DA sensor mice - behavior day 12 - omission\'];
        else 
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\2018080',num2str(day-1),' AKAR + DA sensor mice - behavior day ',num2str(day),'\'];
        end
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180730 AKAR+DA sensor mice - behavior - summary\'];
        
        %estimate delay between SCAN IMAGE and ETHOVISION
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(i)),'.mat'];
        load(filename,'FLPdata_time');
        Ethovision_delay=(FLPdata_time(1)-0.85)*1000;
        delay=Ethovision_delay - windowSize;
        
        display(['Ethovision delay(ms): ',num2str(Ethovision_delay)]);
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2','latency3', 'entering_time3', 'occupancy', 'total_occupancy', 'trial_duration','latency4', 'entering_time4');
        
        %loop through each intensity channel
        data=[]; zdata=[];
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
            y=y(windowSize+1:end);
            
            %median filter
            %y=medfilt1(x.data,windowSize);
            
            %y=x.data;
            
            %detrending of bleaching effect
            %f=fit([1:1:length(y)]',y','exp1');
            %figure(100+2);plot([1:1:length(y)],f.a*exp(f.b*[1:1:length(y)]),'r'); hold off;
            coeff = polyfit([1:1:length(y)],y,1);
            if(coeff(1)<0)
                for k=1:length(y)
                    y(k)=y(k)-coeff(1)*k;
                end
            end     
            
            %putting raw traces into a user defined timebin
            for k=1:floor(length(y)/timebin)
                data(d,k) = sum(y(timebin*(k-1)+1:timebin*k));
            end
            
            figure(100+d); plot(data(d,:));
        end
        %autoArrangeFigures();
        
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
                
                %aligning data to the trigger zone entering_time
                if(cuetime(j)>0 && cuetime(j)-3+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(cuetime(j)-3+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_trigger(d,1:length(x))=x;
                    TrialData(counter).dff_trigger(d,1:length(y))=y;
                else
                    TrialData(counter).raw_trigger(d,:)=0;
                    TrialData(counter).dff_trigger(d,:)=0;
                end
                
                %aligning data to the LED on time
                if(cuetime(j)>0 && cuetime(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_LED(d,1:length(x))=x;
                    TrialData(counter).dff_LED(d,1:length(y))=y;
                else
                    TrialData(counter).raw_LED(d,:)=0;
                    TrialData(counter).dff_LED(d,:)=0;
                end
                
                %aligning data to the entering time
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
                elseif TrialData(counter).trialtype == 4 && entering_time(j)+3+delay/1000+duration <= datalim %omission trial analysis for expected dispensing time
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time(j)+3+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
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
                    TrialData(counter).raw_receptacle2(d,:)=0;
                    TrialData(counter).dff_receptacle2(d,:)=0;
                end
            end
        end
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    %save(outputfilename,'TrialData','-append');
    save(outputfilename,'TrialData');
end
% 
% % %delete(findall(0,'Type','figure'));
% % %plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
% % %confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
% % return;
            

%% analyze the lifetime signal using the behavioral event timestamps
global spc

timebin = 1;
num_days=12;
duration=100; %duration of analysis=ITI interval
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM board channel name

delay=Ethovision_delay;

session_baseline_duration=120; %session baseline tau calculation duration

for f=1:length(filelist)
    clear TrialData;
    session_baseline_tau=zeros(1,num_days);
    
    day=1;
    %directory for photometry data for day1
    input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180731 AKAR + DA sensor mice - behavior day 1\'];
    
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc.fit.range=[5.2 13.5];
    spc.fits{ch}.fitstart=5.2;
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
        if (day==1)
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180731 AKAR + DA sensor mice - behavior day 1\'];
        elseif day==11
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180810 AKAR + DA sensor mice - behavior day 11\'];
        elseif day==12
            input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\Combined Data\20180811 AKAR + DA sensor mice - behavior day 12 - omission\'];
        else
            input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\2018080',num2str(day-1)',' AKAR + DA sensor mice - behavior day ',num2str(day),'\'];
        end
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180730 AKAR+DA sensor mice - behavior - summary\'];
        
        %estimate delay between SCAN IMAGE and ETHOVISION
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        load(filename,'FLPdata_time');
        Ethovision_delay=(FLPdata_time(1)-0.85)*1000;
        delay=Ethovision_delay;
        display(['Ethovision delay(ms): ',num2str(Ethovision_delay)]);
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
        load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2','latency3', 'entering_time3', 'occupancy', 'total_occupancy', 'trial_duration');
        
        %caluclate the lifetime during the baseline period 120s before the
        %1st trial
        [tau,photoncount,time] = align_FLIM_signal_abs_tau(FLPdata_time, FLPdata_lifetimes,session_baseline_duration,session_baseline_duration,session_baseline_duration,timebin,ch);
        session_baseline_tau(day) = mean(tau);
        
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
            
            %caluclate the lifetime during the baseline period 20s before zone 1 entering
            [tau,photoncount,time] = align_FLIM_signal_abs_tau(FLPdata_time, FLPdata_lifetimes, cuetime(j)-3+delay/1000, baseline_duration ,baseline_duration,timebin,ch);            
            baseline_tau = mean(tau);
            
            %aligning data to the trigger zone entering
            if(cuetime(j)>0 && cuetime(j)-3+delay/1000+duration <= datalim) % if data exists
                eventtime=cuetime(j)-3+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
                TrialData(counter).dtau_trigger=dlifetime;
                TrialData(counter).pc_trigger=photoncount;
                TrialData(counter).dtautime_trigger=time;
            else
                TrialData(counter).dtau_trigger=0;
                TrialData(counter).pc_trigger=0;
                TrialData(counter).dtautime_trigger=0;
            end
            
            %aligning data to the LED on time
            if(cuetime(j)>0 && cuetime(j)+delay/1000+duration <= datalim) % if data exists
                eventtime=cuetime(j)+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
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
                eventtime=entering_time(j)+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
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
                eventtime=rewardtime(j)+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
                TrialData(counter).dtau_dispense=dlifetime;
                TrialData(counter).pc_dispense=photoncount;
                TrialData(counter).dtautime_dispense=time;
            elseif TrialData(counter).trialtype == 4 && entering_time(j)+3+delay/1000+duration <= datalim %omission trial analysis for expected dispensing time
                eventtime=entering_time(j)+3+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
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
                eventtime=entering_time2(j)+delay/1000;
                [dlifetime,photoncount,time] = align_FLIM_signal5(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau);
                
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
    
    figure(200); plot(session_baseline_tau); hold on;
    
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    save(outputfilename,'TrialData','session_baseline_tau','-append');
    %save(outputfilename,'TrialData','successrate','latency_combined','latency2_combined','occupancy_combined');
end
%return;

%% update behavior variables
timestamp=[0:timebin/1000:duration];

for i=1:length(filelist)
    clear 'successrate' 'latency_combined' 'latency2_combined' 'latency3_combined' 'occupancy_combined' 'cuetime_combined' ...
        'entering_time_combined' 'entering_time2_combined' 'entering_time3_combined' 'rewardtime_combined'...
        'total_occupancy_combined' 'trial_duration_combined'...
        'entering_time_trigger_combined' 'occupancy_trigger_combined'...
        'speed_combined' 'angular_vel_combined' 'accel_combined' 'distance_to_receptacle_combined'...
        'time_combined' 'distance_combined';
    
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180730 AKAR+DA sensor mice - behavior - summary2\'];       
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
        load(filename2, 'cuetime', 'rewardtime', 'num_reward', 'latency',...
            'entering_time', 'latency2', 'entering_time2', 'occupancy', ...
            'total_occupancy', 'trial_duration','latency3','entering_time3',...
            'latency4','entering_time4','entering_time_trigger','occupancy_trigger',...
            'time','distance','speed','angular_vel','accel','distance_to_receptacle');
        
        num_success=0;
        for j=1:length(occupancy)
            if(occupancy(j)>=3 || rewardtime(j)>0) %sometimes no dispensing when occupancy>=3, dispensing when occupancy<3
                num_success=num_success+1;
            end
        end
        successrate(day)=num_success/length(rewardtime);
        
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
        
        entering_time_trigger_combined(day).data=entering_time_trigger;
        occupancy_trigger_combined(day).data=occupancy_trigger;
        speed_combined(day).data=speed;
        angular_vel_combined(day).data=angular_vel;
        accel_combined(day).data=accel;
        distance_to_receptacle_combined(day).data=distance_to_receptacle;
        time_combined(day).data=time;
        distance_combined(day).data=distance;
        
        %display(rewardtime);
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    save(outputfilename,'successrate','latency_combined','latency2_combined','latency3_combined','occupancy_combined','cuetime_combined',...
        'entering_time_combined','entering_time2_combined','entering_time3_combined','rewardtime_combined',...
        'total_occupancy_combined','trial_duration_combined',...
        'entering_time_trigger_combined','occupancy_trigger_combined',...
        'speed_combined','angular_vel_combined','accel_combined','distance_to_receptacle_combined',...
        'time_combined','distance_combined','-append');
end

%delete(findall(0,'Type','figure'));
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;