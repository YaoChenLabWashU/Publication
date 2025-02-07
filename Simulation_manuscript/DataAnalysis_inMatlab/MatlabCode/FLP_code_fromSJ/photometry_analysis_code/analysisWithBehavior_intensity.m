clear all;

dataname={'AD2_','AD3_'};
%dataname='AD2_';
filelist = [1 2 3 4];
mousenamelist = {'SJ139','SJ141','SJ117','SJ118'};
n=length(filelist);
n_trial = 12;
timebin=50; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=120; %analysis duration of 30s
ITI=10; %intertrial interval of 200s
first_time=10; %first pellet dropped at 120s, analyze starting 10s before pellet dropping
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=9; %number of days for all trials
output_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\DA sensor photometry\20180430 DA sensor behavior - summary\'];

%% analyze the intensity signal using the behavioral event timestamps
cmap = colormap(hsv(n_trial));
timestamp=[0:timebin/1000:duration];

for day=1:num_days
    input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\DA sensor photometry\2018050',num2str(day),' DA sensor behavior - day ',num2str(day),'\'];
    
    for i=1:1:n
        dff_LED=[];     raw_LED=[];
        dff_zone=[];    raw_zone=[];
        dff_dispense=[];    raw_dispense=[];
        dff_receptacle=[];  raw_receptacle=[];
        
        for d=1:length(dataname)
            if(d==2 && i>=3)
            else
                filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
                load(filename,[dataname{d},num2str(filelist(i))]);
                x=eval([dataname{d},num2str(filelist(i))]);
                data=[];
                for k=1:floor(length(x.data)/timebin)
                    data(k) = sum(x.data(timebin*(k-1)+1:timebin*k));
                end
                
                filename2=[input_dir,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
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
                    
                    %             figure(1);
                    %             plot(timestamp,squeeze(raw_LED(d,j,:)),'color',cmap(j,:));
                    %             hold on;
                    %             figure(2);
                    %             plot(timestamp,squeeze(dff_LED(d,j,:)),'color',cmap(j,:));
                    %             hold on;
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
                        
                        figure(1);
                        plot(timestamp,squeeze(raw_dispense(d,j,:)),'color',cmap(j,:));
                        hold on;
                        figure(2);
                        plot(timestamp,squeeze(dff_dispense(d,j,:)),'color',cmap(j,:));
                        hold on;
                    end
                end
                
                %aligning data to the pellet receptacle entering
                cmap=hsv(length(entering_time2));
                for j=1:length(entering_time2)
                    if(entering_time2(j)>0) %entering_time2==-1 when the mouse was not rewarded
                        [x,y]=align_intensity_signal(data,(entering_time2(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                        raw_receptacle(d,j,:)=x;
                        dff_receptacle(d,j,:)=y;
                        
                        %                 figure(1);
                        %                 plot(timestamp,squeeze(raw_receptacle(d,j,:)),'color',cmap(j,:));
                        %                 hold on;
                        %                 figure(2);
                        %                 plot(timestamp,squeeze(dff_receptacle(d,j,:)),'color',cmap(j,:));
                        %                 hold on;
                    else
                        raw_receptacle(d,j,:)=zeros(1,size(raw_LED,3));
                        dff_receptacle(d,j,:)=zeros(1,size(raw_LED,3));
                    end
                end
                display('');
                %delete(findall(0,'Type','figure'));
            end
        end
        
        outputfilename = [output_dir,mousenamelist{i},'-day',num2str(day)];
        save(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
    end
end

legendlabel={};
for i=1:n_trial
    legendlabel{i}=['trial ',num2str(i)];
end

%delete(findall(0,'Type','figure'));
clear all;
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;