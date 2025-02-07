clear all;

dataname={'AD1_','AD2_','AD3_'};
filelist = [1 2 3];
mousenamelist = {'SJ163','SJ164','SJ165'};

n=length(filelist);
timebin=50; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=120; %analysis duration of 30s
ITI=10; %intertrial interval of 200s
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=9; %number of days for all trials
output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\'];

%% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for day=1:num_days
    %directory for photometry data
    input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\201806',num2str(18+day),' JRCaMP + DA sensor mice - behavior day ',num2str(day),'\'];
    %directory for behavioral data
    input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180618 JRCaMP+DA sensor mice - summary\'];
    
    for i=1:1:n
        dff_LED=[];     raw_LED=[];
        dff_zone=[];    raw_zone=[];
        dff_dispense=[];    raw_dispense=[];
        dff_receptacle=[];  raw_receptacle=[];
        
        for d=1:length(dataname)
            filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
            load(filename,[dataname{d},num2str(filelist(i))]);
            x=eval([dataname{d},num2str(filelist(i))]);
            data=[];
            for k=1:floor(length(x.data)/timebin)
                data(k) = sum(x.data(timebin*(k-1)+1:timebin*k));
            end
            
            filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
            load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
            
            %calculate the reference intensity value
            for j=1:length(cuetime)
                fo(j)=calculate_reference(data,(cuetime(j)+delay/1000),baseline_duration,inputrate,timebin);
            end
            
            %aligning data to the LED on time
            cmap=hsv(length(cuetime));
            for j=1:length(cuetime)
                [x,y]=align_intensity_signal(data,(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                raw_LED(d,j,:)=x;
                dff_LED(d,j,:)=y;
                
%                 figure(1);
%                 plot(timestamp,squeeze(raw_LED(d,j,:)),'color',cmap(j,:));
%                 hold on;
%                 figure(2);
%                 plot(timestamp,squeeze(dff_LED(d,j,:)),'color',cmap(j,:));
%                 hold on;
            end
            
            %aligning data to the LED zone entering time
            cmap=hsv(length(entering_time));
            for j=1:length(entering_time)
                [x,y]=align_intensity_signal(data,(entering_time(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                raw_zone(d,j,:)=x;
                dff_zone(d,j,:)=y;
                
                %             figure(1);
                %             plot(timestamp,squeeze(raw_zone(d,j,:)),'color',cmap(j,:));
                %             hold on;
                %             figure(2);
                %             plot(timestamp,squeeze(dff_zone(d,j,:)),'color',cmap(j,:));
                %             hold on;
            end
            
            %aligning data to the pellet dispensing time
            cmap=hsv(length(rewardtime));
            for j=1:length(rewardtime)
                if(rewardtime(j)>0) %rewardtime==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(data,(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                    raw_dispense(d,j,:)=x;
                    dff_dispense(d,j,:)=y;
                    
                    %                         figure(1);
                    %                         plot(timestamp,squeeze(raw_dispense(d,j,:)),'color',cmap(j,:));
                    %                         hold on;
                    %                         figure(2);
                    %                         plot(timestamp,squeeze(dff_dispense(d,j,:)),'color',cmap(j,:));
                    %                         hold on;
                end
            end
            
            %aligning data to the pellet receptacle entering
            cmap=hsv(length(entering_time2));
            for j=1:length(entering_time2)
                if(entering_time2(j)>0) %entering_time2==-1 when the mouse was not rewarded
                    [x,y]=align_intensity_signal(data,(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                    raw_receptacle(d,j,:)=x;
                    dff_receptacle(d,j,:)=y;
                    
%                     figure(1);
%                     plot(timestamp,squeeze(raw_receptacle(d,j,:)),'color',cmap(j,:));
%                     hold on;
%                     figure(2);
%                     plot(timestamp,squeeze(dff_receptacle(d,j,:)),'color',cmap(j,:));
%                     hold on;
                else
                    raw_receptacle(d,j,:)=zeros(1,size(raw_LED,3));
                    dff_receptacle(d,j,:)=zeros(1,size(raw_LED,3));
                end
            end
            display(day);
            display(i);
            display(d);
            delete(findall(0,'Type','figure'));
        end
        
        outputfilename = [output_dir,mousenamelist{i},'-day',num2str(day)];
        save(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
    end
end

%delete(findall(0,'Type','figure'));
clear all;
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;

%% analyze the intensity signal using the behavioral event timestamps
global spc

timebin = 1;
num_days=11;
duration=120; %duration of analysis=ITI interval
baseline_duration=50;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM channel

for f=1:length(filelist)
    day=1;
    input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\FLP data\FLP_201805',num2str(14+day),' (AKAR mice- behavior day ',num2str(day),')\'];
    input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20180514 (AKAR mice- behavior - summary)\'];
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    for day=1:num_days
        if(day~=5)
            input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\FLP data\FLP_201805',num2str(14+day),' (AKAR mice- behavior day ',num2str(day),')\'];
            input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20180514 (AKAR mice- behavior - summary)\'];
            
            filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
            load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
            
            filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
            load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
            
            display(day);
            display(f);
            
            dtau_LED=[];    time_LED=[];
            dtau_zone=[];   time_zone=[];
            dtau_dispense=[];   time_dispense=[];
            dtau_receptacle=[]; time_receptacle=[];
            for i=1:length(cuetime)
                [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,cuetime(i),duration,baseline_duration,timebin,ch);
                if(length(dlifetime)==0) %%if the recording stopped before the behavior, the returned matrix is an empty matrix
                    display(i);
                    display('');
                else
                    dtau_LED(i,1:length(dlifetime))=dlifetime;
                    time_LED(i,1:length(time))=time;
                    
                    [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time(i),duration,baseline_duration,timebin,ch);
                    dtau_zone(i,1:length(dlifetime))=dlifetime;
                    time_zone(i,1:length(time))=time;
                    
                    if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                        [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch);
                        dtau_dispense(i,1:length(dlifetime))=dlifetime;
                        time_dispense(i,1:length(time))=time;
                    end
                    
                    if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                        [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch);
                        dtau_receptacle(i,1:length(dlifetime))=dlifetime;
                        time_receptacle(i,1:length(time))=time;
                    end
                end
            end
            
            savefilename=['analysis_',mousenamelist{f},'_day',num2str(day)];
            save(savefilename,'dtau_LED','time_LED','dtau_zone','time_zone','dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
        end
    end
end

return;