 dataname={'AD1_'}; 
filelist = [5 6 7 8];
mousenamelist = {'SJ185_2','SJ186_2','SJ187_2','SJ188_2'};

eattime=zeros(4,10); %manually recorded time of pellet eating
eattime(1,1:2)=[1957 2195];
eattime(2,1)=[2292];
eattime(3,1:4)=[1200 1335 1440 2463];
eattime(4,1:3)=[1220 1400 2166];

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
% for f=1:length(filelist)
%     dff_LED=[];     raw_LED=[];
%     dff_zone=[];    raw_zone=[];
%     dff_dispense=[];    raw_dispense=[];
%     dff_receptacle=[];  raw_receptacle=[];
%     for day=1:num_days
%         %directory for photometry data
%         input_dir=[''];
%         %directory for behavioral data
%         input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180819 D1 Cre AKAR+ DA mice - pellet + D1R antagonist\Export Files\'];
% 
%         for d=1:length(dataname)
%             filename=[input_dir,dataname{d},num2str(filelist(f)),'.mat'];
%             load(filename,[dataname{d},num2str(filelist(f))]);
%             x=eval([dataname{d},num2str(filelist(f))]);
%             data=[];
%             for k=1:floor(length(x.data)/timebin)
%                 data(k) = sum(x.data(timebin*(k-1)+1:timebin*k));
%             end
% 
%             filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)-4),'.mat'];
%             load(filename2,'rewardtime', 'num_reward', 'latency2', 'entering_time2');
% 
%             entering_time2=zeros(1,length(entering_time2));
%             eattime_idx=find(eattime(f,:)>0);
%             for i=eattime_idx %replacing the entering_time2 with manually recorded pellet eating time
%                 for j=1:length(rewardtime)
%                     if(eattime(f,i)>=rewardtime(j) && eattime(f,i)<rewardtime(j)+ITI)
%                         entering_time2(j)=eattime(f,i);
%                     end
%                 end
%             end
%             
%             figure(100);
%             plot(rewardtime,entering_time2,'.');
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
%             for j=1:length(entering_time2)
%                 if(entering_time2(j)>0)
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
%             figure(65);
%             %plot(timestamp,squeeze(mean(dff_dispense(day,d,:,:),3)),'color',cmap(j,:));
%             temp=[]; counter=0;
%             for j=1:length(entering_time2)
%                 if(dff_receptacle(day,d,j,1)~=0)
%                     counter=counter+1;
%                     temp(counter,:)=dff_receptacle(day,d,j,:);
%                 end
%             end
%             
%             m=squeeze(mean(temp,1));
%             ste=squeeze(std(temp,0,1));
%             confplot(timestamp,m,ste,ste,'color',[1 0 0],'LineWidth',2);
%             title('dLight df/f(%) vs. time(s): aligned to receptacle entry');       
%             
%             figure(61);hold off;
%             figure(62);hold off;
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
    
    for day=1:num_days
        display(day);
        display(filelist(f));
        
        %directory for photometry data
        input_dir=[''];
        %directory for behavioral data
        input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Behavior\20180819 D1 Cre AKAR+ DA mice - pellet + D1R antagonist\Export Files\'];
        
        filename=[input_dir,'continuous aquistion data_',num2str(filelist(f)),'.mat'];
        load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
        
        filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(f)-4),'.mat'];
        load(filename2,'rewardtime', 'num_reward', 'latency2', 'entering_time2');
        
        entering_time2=zeros(1,length(entering_time2));
        eattime_idx=find(eattime(f,:)>0);
        for i=eattime_idx %replacing the entering_time2 with manually recorded pellet eating time
            for j=1:length(rewardtime)
                if(eattime(f,i)>=rewardtime(j) && eattime(f,i)<rewardtime(j)+ITI)
                    entering_time2(j)=eattime(f,i);
                end
            end
        end
        
        figure(100);
        plot(rewardtime,entering_time2,'.');
        
        cmap=hsv(length(rewardtime));
        for i=1:length(rewardtime)
            if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal_new(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,baseline_duration);
                %[dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch);
                %[dlifetime,photoncount,time] = align_FLIM_signal_downsample(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,2);
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
            
            if(entering_time2(i)>0) %rewardtime==-1 when the mouse was not rewarded
                [dlifetime,photoncount,time] = align_FLIM_signal_new(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch,baseline_duration);
                %[dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch);
                %[dlifetime,photoncount,time] = align_FLIM_signal_downsample(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch,2);
                
                dtau_receptacle(day,i,1:length(dlifetime))=dlifetime;
                time_receptacle(day,i,1:length(time))=time;
                figure(72);
                plot(timestamp,squeeze(dtau_receptacle(day,i,1:idx)),'color',cmap(i,:));
                title('delta lifetime(ns) vs. time(s): aligned to receptacle entry');
                hold on;
            else
                dtau_receptacle(day,i,1:length(timestamp))=zeros(1,length(timestamp));
                time_receptacle(day,i,1:length(timestamp))=zeros(1,length(timestamp));
            end
        end
        
        rewardtime_combined(day,1:length(rewardtime))=rewardtime;
        latency2_combined(day,1:length(latency2))=latency2;
        
        m=squeeze(mean(dtau_dispense(day,:,:),2));
        ste=squeeze(std(dtau_dispense(day,:,:),0,2));
        
        if length(m)>length(timestamp)
            m=m(1:length(timestamp));
            ste=ste(1:length(timestamp));
        end
        
        figure(73);
        confplot(timestamp,m,ste,ste,'color',[1 0 0],'LineWidth',2);
        title('delta lifetime(ns) vs. time(s): aligned to pellet dispensing');

        temp=[]; counter=0;
        for j=1:length(entering_time2)
            if(dtau_receptacle(day,j,1)~=0)
                counter=counter+1;
                temp(counter,:)=dtau_receptacle(day,j,:);
            end
        end
        
        m=squeeze(mean(temp,1));
        ste=squeeze(std(temp,0,1));

        if length(m)>length(timestamp)
            m=m(1:length(timestamp));
            ste=ste(1:length(timestamp));
        end
        
        figure(74);
        confplot(timestamp,m,ste,ste,'color',[1 0 0],'LineWidth',2);
        title('delta lifetime(ns) vs. time(s): aligned to pellet eating');
        
        figure(71);hold off;
        figure(72);hold off;
    end
    outputfilename = [output_dir,'analysis_',mousenamelist{f}];
    save(outputfilename,'dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency2_combined','rewardtime_combined','-append');
    %save(outputfilename,'dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency2_combined','rewardtime_combined');
    
    %export to excel sheet
    filename=[mousenamelist{f},'.xlsx'];
    xlswrite(filename,outdata);
end
return;