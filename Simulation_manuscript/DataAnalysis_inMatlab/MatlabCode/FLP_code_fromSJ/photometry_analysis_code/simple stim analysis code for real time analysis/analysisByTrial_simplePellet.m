% analysis of raw neural and behavioral data
% analysis by trial type


dataname={'AD1_'};
filelist = [1 2 3];
mousenamelist = {'SJ291','SJ292','SJ293'};

% filelist = [3];
% mousenamelist = {'SJ165-pellet-day0'};
trial_num=10;
num_days=1; %number of days for all trials

n=length(filelist); %number of mice
duration=20; %analysis duration in sec
inputrate=1000; %in Hz
cc_range=1;
baseline_duration=10; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
delay=50; %delay in ms between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
output_dir=['']; %output file directory
ch_name={'dLight'};

timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for i=1:1:n
    clear TrialData
    counter=0;
    for day=1:num_days
        display(['analyzing mouse ',num2str(i),' day ',num2str(day),'.....']);
        
        %directory for photometry data
        input_dir=[''];
        
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20190306 Chrimson dLight - simple pellet calibration\Export Files\'];
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(i)];
        load(filename2,'rewardtime', 'entering_time2');
        
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
                
                %aligning data to the LED on time
                if(cuetime(j)>0 && cuetime(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_LED(d,:)=x;
                    TrialData(counter).dff_LED(d,:)=y;
                else
                    TrialData(counter).raw_LED(d,:)=0;
                    TrialData(counter).dff_LED(d,:)=0;
                end
                
                %aligning data to the LED zone entering time
                if(entering_time(j)>0 && entering_time(j)+delay/1000+duration <= datalim) % if data exists
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_zone(d,:)=x;
                    TrialData(counter).dff_zone(d,:)=y;
                else
                    TrialData(counter).raw_zone(d,:)=0;
                    TrialData(counter).dff_zone(d,:)=0;
                end
                
                %aligning data to the pellet dispensing time
                if(entering_time2(j)>0 && rewardtime(j)+delay/1000+duration <= datalim) %rewardtime==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_dispense(d,:)=x;
                    TrialData(counter).dff_dispense(d,:)=y;
                    
                    %                     display(j);
                    %                     figure(100);
                    %                     plot(y,'color',cmap(j,:));
                    %                     hold on;
                    
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
                
                %aligning data to the pellet receptacle entering
                cmap=hsv(length(entering_time2));
                if(entering_time2(j)>0 && entering_time2(j)+delay/1000+duration <= datalim) %when the mouse entered the receptacle before the end of data acquisition
                    [x,y]=align_intensity_signal(squeeze(data(d,:)),(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo);
                    TrialData(counter).raw_receptacle(d,:)=x;
                    TrialData(counter).dff_receptacle(d,:)=y;
                    
%                     display(j);
%                     figure(100);
%                     plot(y,'color',cmap(j,:));
%                     hold on;
                else
                    TrialData(counter).raw_receptacle(d,:)=0;
                    TrialData(counter).dff_receptacle(d,:)=0;
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
ch=1; %FLIM board channel name
ch_name='AKAR';

for f=1:length(filelist)
    clear TrialData;
    day=1;
    %directory for lifetime data
    input_dir=[''];
    
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    counter=0;
    
    %add data to the pre-existing TrialData file
    %     outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    %     load(outputfilename,'TrialData');
    
    for day=1:num_days
        display(['analyzing mouse ',num2str(f),' day ',num2str(day),'.....']);
        
        %directory for lifetime data
        input_dir=[''];
        %directory for behavior data
        input_dir2=[''];
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        filename2=[input_dir2,'event_time_',num2str(filelist(f)),'.mat'];
        load(filename2,'rewardtime', 'entering_time2');
        
        datalim=max(max(FLPdata_time()));
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
                
                display(j);
                figure(100);
                plot(dlifetime,'color',cmap(j,:));
                hold on;
            else
                TrialData(counter).dtau_receptacle=0;
                TrialData(counter).pc_receptacle=0;
                TrialData(counter).dtautime_receptacle=0;
            end
        end
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    %save(outputfilename,'TrialData','-append');
    save(outputfilename,'TrialData');
end
return;