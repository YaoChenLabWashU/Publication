%dataname={'AD1_','AD2_','AD3_'};
filelist=[1 2 3 4 5 6 7 8 9 10 11 13];
mousenamelist = {'SJ270_1','SJ270_2','SJ270_3','SJ270_4','SJ270_5','SJ270_6','SJ271_7','SJ271_8','SJ271_9','SJ271_10','SJ271_11','SJ271_13'};

n=length(filelist);
timebin=20; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=101; %analysis duration of 30s
ITI=120; %intertrial interval of 200s
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=21; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=11; %number of days for all trials
output_dir=[''];

%% analyze the intensity signal using the behavioral event timestamps
%timestamp=[0:timebin/1000:duration];

% for i=1:1:n
%     dff_LED=[];     raw_LED=[];
%     dff_zone=[];    raw_zone=[];
%     dff_dispense=[];    raw_dispense=[];
%     dff_receptacle=[];  raw_receptacle=[];
%     for day=1:num_days
%         %directory for photometry data
%         input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\201806',num2str(18+day),' JRCaMP + DA sensor mice - behavior day ',num2str(day),'\'];
%         %directory for behavioral data
%         input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180618 JRCaMP+DA sensor mice - summary\'];
%         
%         for d=1:length(dataname)
%             filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
%             load(filename,[dataname{d},num2str(filelist(i))]);
%             x=eval([dataname{d},num2str(filelist(i))]);
%             data=[];
%             for k=1:floor(length(x.data)/timebin)
%                 data(k) = sum(x.data(timebin*(k-1)+1:timebin*k));
%             end
%             
%             filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
%             load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
%             
%             %calculate the reference intensity value
%             for j=1:length(cuetime)
%                 fo(j)=calculate_reference(data,(cuetime(j)+delay/1000),baseline_duration,inputrate,timebin);
%             end
%             
%             %aligning data to the LED on time
%             cmap=hsv(length(cuetime));
%             for j=1:length(cuetime)
%                 [x,y]=align_intensity_signal(data,(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                 raw_LED(day,d,j,:)=x;
%                 dff_LED(day,d,j,:)=y;
%                 
%                 %                 figure(1);
%                 %                 plot(timestamp,squeeze(raw_LED(d,j,:)),'color',cmap(j,:));
%                 %                 hold on;
%                 %                 figure(2);
%                 %                 plot(timestamp,squeeze(dff_LED(d,j,:)),'color',cmap(j,:));
%                 %                 hold on;
%             end
%             
%             %aligning data to the LED zone entering time
%             cmap=hsv(length(entering_time));
%             for j=1:length(entering_time)
%                 [x,y]=align_intensity_signal(data,(entering_time(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                 raw_zone(day,d,j,:)=x;
%                 dff_zone(day,d,j,:)=y;
%                 
%                 %             figure(1);
%                 %             plot(timestamp,squeeze(raw_zone(d,j,:)),'color',cmap(j,:));
%                 %             hold on;
%                 %             figure(2);
%                 %             plot(timestamp,squeeze(dff_zone(d,j,:)),'color',cmap(j,:));
%                 %             hold on;
%             end
%             
%             %aligning data to the pellet dispensing time
%             cmap=hsv(length(rewardtime));
%             for j=1:length(rewardtime)
%                 if(rewardtime(j)>0) %rewardtime==-1 when the mouse was not rewarded
%                     [x,y]=align_intensity_signal(data,(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                     raw_dispense(day,d,j,:)=x;
%                     dff_dispense(day,d,j,:)=y;
%                     
%                     %                         figure(1);
%                     %                         plot(timestamp,squeeze(raw_dispense(d,j,:)),'color',cmap(j,:));
%                     %                         hold on;
%                     %                         figure(2);
%                     %                         plot(timestamp,squeeze(dff_dispense(d,j,:)),'color',cmap(j,:));
%                     %                         hold on;
%                 else
%                     raw_dispense(day,d,j,:)=zeros(1,size(raw_LED,4));
%                     dff_dispense(day,d,j,:)=zeros(1,size(raw_LED,4));
%                 end
%             end
%             
%             %aligning data to the pellet receptacle entering
%             cmap=hsv(length(entering_time2));
%             for j=1:length(entering_time2)
%                 if(rewardtime(j)>0) %rewardtime==-1 when the mouse was not rewarded
%                     [x,y]=align_intensity_signal(data,(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                     raw_receptacle(day,d,j,:)=x;
%                     dff_receptacle(day,d,j,:)=y;
%                     
%                     %                     figure(1);
%                     %                     plot(timestamp,squeeze(raw_receptacle(d,j,:)),'color',cmap(j,:));
%                     %                     hold on;
%                     %                     figure(2);
%                     %                     plot(timestamp,squeeze(dff_receptacle(d,j,:)),'color',cmap(j,:));
%                     %                     hold on;
%                 else
%                     raw_receptacle(day,d,j,:)=zeros(1,size(raw_LED,4));
%                     dff_receptacle(day,d,j,:)=zeros(1,size(raw_LED,4));
%                 end
%             end
%             display(day);
%             display(i);
%             display(d);
%             delete(findall(0,'Type','figure'));
%             
%             rewardtime_combined(day,1:length(rewardtime))=rewardtime;
%             latency_combined(day,1:length(latency))=latency;
%             latency2_combined(day,1:length(latency2))=latency2;
%             occupancy_combined(day,1:length(occupancy))=occupancy;
%         end
%     end
%     
%     outputfilename = [output_dir,'analysis_',mousenamelist{i}];
%     save(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
% end
% 
% clear all;
% %delete(findall(0,'Type','figure'));
% %plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
% %confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
% return;

%% analyze the lifetime signal using the behavioral event timestamps
global spc

timebin = 1;
num_days=1;
duration=100+1; %duration of analysis=ITI interval
baseline_duration=20+1;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM channel
trial_number=10;
baseline_tau_duration=baseline_duration;

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

        rewardtime=[];
        for i=1:10
            rewardtime(i)=120*i;
        end
        if f==6
            rewardtime=[1200:120:1200+120*9];
        end

        cmap=hsv(length(rewardtime));
        for i=1:length(rewardtime)
            %if(rewardtime(i)>0 && entering_time2(i)>0) %rewardtime==-1 when the mouse was not rewarded, throwing out a weird trial where reward happened despite LED turning off
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
                    title('photon counts vs. time(s): pellet dispensed at 0s');
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