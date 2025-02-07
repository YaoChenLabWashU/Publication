dataname={'AD1_'};
filelist = [1 2 3 4];
%mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ185_2','SJ186_2','SJ187_2','SJ188_2'};
mousenamelist = {'SJ166','SJ167','SJ158','SJ160'};


n=length(filelist);
timebin=50; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=100; %analysis duration of 30s
ITI=120; %intertrial interval of 200s
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=1; %number of days for all trials
output_dir='';

%% analyze the intensity signal using the behavioral event timestamps
% timestamp=[0:timebin/1000:duration];
% datalist=[1:1:length(dataname)];
% 
% for i=1:1:n
%     dff_LED=[];     raw_LED=[];
%     dff_zone=[];    raw_zone=[];
%     dff_dispense=[];    raw_dispense=[];
%     dff_receptacle=[];  raw_receptacle=[];
%     for day=1:num_days
%         %directory for photometry data
%         input_dir=[''];
%         %directory for behavioral data
%         input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180819 D1 Cre AKAR+ DA mice - pellet\Export Files\'];
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
%             load(filename2,'rewardtime', 'num_reward', 'latency2', 'entering_time2');
% 
%             %calculate the reference intensity value
%             for j=1:length(rewardtime)
%                 fo(j)=calculate_reference(data,(rewardtime(j)+delay/1000),baseline_duration,inputrate,timebin);
%             end
% 
%             %aligning data to the pellet dispensing time
%             cmap=hsv(length(rewardtime));
%             for j=1:length(rewardtime)-1
%                 if(rewardtime(j)>0) %rewardtime==-1 when the mouse was not rewarded
%                     [x,y]=align_intensity_signal(data,(rewardtime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                     raw_dispense(day,d,j,1:length(timestamp))=x(1:length(timestamp));
%                     dff_dispense(day,d,j,1:length(timestamp))=y(1:length(timestamp));
% 
% %                     figure(60);
% %                     plot(timestamp,squeeze(raw_dispense(day,d,j,:)),'color',cmap(j,:));
% %                     hold on;
%                     figure(61);
%                     plot(timestamp,squeeze(dff_dispense(day,d,j,:)),'color',cmap(j,:));
%                     title('dLight df/f(%) vs. time(s): aligned to pellet dispensing');
%                     hold on;
%                 else
%                     raw_dispense(day,d,j,:)=zeros(1,size(raw_dispense,4));
%                     dff_dispense(day,d,j,:)=zeros(1,size(raw_dispense,4));
%                 end
%             end
% 
%             %aligning data to the pellet receptacle entering
%             cmap=hsv(length(entering_time2));
%             for j=1:length(entering_time2)-1
%                 if(rewardtime(j)>0)
%                     [x,y]=align_intensity_signal(data,(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
%                     raw_receptacle(day,d,j,1:length(timestamp))=x(1:length(timestamp));
%                     dff_receptacle(day,d,j,1:length(timestamp))=y(1:length(timestamp));
% 
% %                     figure(62);
% %                     plot(timestamp,squeeze(raw_receptacle(day,d,j,:)),'color',cmap(j,:));
% %                     hold on;
%                     figure(63);
%                     plot(timestamp,squeeze(dff_receptacle(day,d,j,:)),'color',cmap(j,:));
%                     title('dLight df/f(%) vs. time(s): aligned to receptacle entry');
%                     hold on;
%                 else
%                     raw_receptacle(day,d,j,:)=zeros(1,size(raw_receptacle,4));
%                     dff_receptacle(day,d,j,:)=zeros(1,size(raw_receptacle,4));
%                 end
%             end
%             display(day);
%             display(i);
%             display(d);
%             
%             figure(64);
%             %plot(timestamp,squeeze(mean(dff_dispense(day,d,:,:),3)),'color',cmap(j,:));
%             m=squeeze(mean(dff_dispense(day,d,:,:),3));
%             ste=squeeze(std(dff_dispense(day,d,:,:),0,3));
%             confplot(timestamp,m,ste,ste,'color',[1 0 0],'LineWidth',2);
%             title('dLight df/f(%) vs. time(s): aligned to pellet dispensing');            
%             
%             figure(61);hold off;
%             figure(63);hold off;
% 
%             rewardtime_combined(day,1:length(rewardtime))=rewardtime;
%             latency2_combined(day,1:length(latency2))=latency2;
%         end
%     end
% 
%     %normalization of df/f data array
%     dff_dispense_normalized = Normalize(dff_dispense,datalist,num_days);
%     dff_receptacle_normalized = Normalize(dff_receptacle,datalist,num_days);
% 
%     outputfilename = [output_dir,'analysis_',mousenamelist{i}];
%     save(outputfilename,'raw_dispense','dff_dispense','raw_receptacle','dff_receptacle','latency2_combined','rewardtime_combined');
%     %save(outputfilename,'dff_dispense_normalized','dff_receptacle_normalized','-append');
% end
% 
% %delete(findall(0,'Type','figure'));
% %plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
% %confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
% return;

%% analyze the lifetime signal using the behavioral event timestamps
global spc

timebin = 1;
duration=100; %duration of analysis=ITI interval
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM channel
timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);

for f=1:length(filelist)
    outdata=timestamp';
    
    day=1;
    input_dir=[''];
    filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    %spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    dtau_LED=[];    time_LED=[];
    dtau_zone=[];   time_zone=[];
    dtau_dispense=[];   time_dispense=[];
    dtau_receptacle=[]; time_receptacle=[];
    
    for day=3:3
        display(day);
        display(filelist(f));
        
        %directory for photometry data
        input_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180629 AKAR + DA sensor mice - pellet day 3\'];
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180629 AKAR + DA sensor mice - pellet day 3\'];
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)),'.mat'];
        load(filename2,'rewardtime', 'num_reward', 'latency2', 'entering_time2');
        
        cmap=hsv(length(rewardtime));
        for i=1:length(rewardtime)
            if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time, FLPdata_lifetimes, rewardtime(i),duration,baseline_duration,timebin,ch,baseline_tau_duration);
                %[dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,baseline_duration);
                dtau_dispense(day,i,1:length(dlifetime))=dlifetime;
                time_dispense(day,i,1:length(time))=time;
                figure(71);
                plot(timestamp,squeeze(dtau_dispense(day,i,1:idx)),'color',cmap(i,:));
                title('delta lifetime(ns) vs. time(s): aligned to pellet dispensing');
                hold on;
                
                if(length(timestamp)==length(dlifetime))
                    outdata=[outdata,dlifetime'];
                elseif length(timestamp)>length(dlifetime)
                    dlifetime=[dlifetime,0];
                    outdata=[outdata,dtau_disepnse'];
                else
                    outdata=[outdata,dlifetime(1:length(timestamp))'];
                end
            end
            
            if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal4(FLPdata_time, FLPdata_lifetimes, entering_time2(i),duration,baseline_duration,timebin,ch,baseline_tau_duration);
                %[dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch,baseline_duration);
                if length(dlifetime>0)
                    dtau_receptacle(day,i,1:length(dlifetime))=dlifetime;
                    time_receptacle(day,i,1:length(time))=time;
                    figure(72);
                    plot(timestamp,squeeze(dtau_receptacle(day,i,1:idx)),'color',cmap(i,:));
                    title('delta lifetime(ns) vs. time(s): aligned to receptacle entry');
                    hold on;
                end
            end
        end
        
        rewardtime_combined(day,1:length(rewardtime))=rewardtime;
        latency2_combined(day,1:length(latency2))=latency2;
        
        figure(73);
        m=squeeze(mean(dtau_dispense(day,:,:),2));
        stdev=squeeze(std(dtau_dispense(day,:,:),0,2));
        
        if length(m)>length(timestamp)
            m=m(1:length(timestamp));
            stdev=stdev(1:length(timestamp));
        end
        
        confplot(timestamp,m,stdev,stdev,'color',[1 0 0],'LineWidth',2);
        title('delta lifetime(ns) vs. time(s): aligned to pellet dispensing');
        
        figure(71);hold off;
        figure(72);hold off;
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    %save(outputfilename,'dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency2_combined','rewardtime_combined','-append');
    save(outputfilename,'dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency2_combined','rewardtime_combined');
    
    %export to excel sheet
    filename=[mousenamelist{f},'.xlsx'];
    xlswrite(filename,outdata);
end
return;