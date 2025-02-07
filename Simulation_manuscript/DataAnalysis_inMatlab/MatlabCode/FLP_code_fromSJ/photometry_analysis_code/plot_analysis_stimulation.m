clear all;

mousenamelist = {'SJ270_1','SJ270_2','SJ270_3','SJ270_4','SJ270_5','SJ270_6','SJ271_7','SJ271_8','SJ271_9','SJ271_10','SJ271_11','SJ271_13'};
%mousenamelist = {'SJ278_8','SJ278_9','SJ278_10','SJ278_11','SJ278_13'};

num_days=1;
timebin=50; %timebin of 50ms per data point
duration=150; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=50; %baseline_duration: duration of the baseline used for the df/f calculation in

cmap = colormap(hsv(num_days));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

%% Plotting intensity data
% for mouse=1:length(mousenamelist)
%     filename = ['analysis_',mousenamelist{mouse},'.mat'];
%     load(filename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
%     legend_mark=zeros(8,num_days);
%     for d=1:length(dataname);
%         for i=1:num_days
%             %df/f aligned to LED
%             figure(1);
%             plot(timestamp,squeeze(mean(dff_LED(i,d,:,1:idx),3))','color',cmap(i,:));
%             title('df/f(%) vs. time(s): 0s = LED on');
%             legend_mark(1,:)=ones(1,num_days);
%             hold on;
%
%             %df/f aligned to LED zone entering
%             figure(2);
%             plot(timestamp,squeeze(mean(dff_zone(i,d,:,1:idx),3))','color',cmap(i,:));
%             title('df/f(%) vs. time(s): 0s = LED zone entering');
%             legend_mark(2,:)=ones(1,num_days);
%             hold on;
%
%             %df/f aligned to pellet dispensing
%             counter=0; temp=[];
%             for j=1:length(rewardtime_combined(i,:))
%                 if(rewardtime_combined(i,j)>0) %if j th trial is a rewarded trial
%                     counter=counter+1;
%                     temp(counter,:)=dff_dispense(i,d,j,1:idx);
%                 end
%             end
%             if counter>0
%                 figure(3);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = pellet dispensed');
%                 hold on;
%                 legend_mark(3,i)=1;
%             end
%
%             %df/f alinged to receptacle entry
%             counter=0;  temp=[];
%             for j=1:length(rewardtime_combined(i,:))
%                 if(rewardtime_combined(i,j)>0) %if j th trial is a rewarded trial
%                     counter=counter+1;
%                     temp(counter,:)=dff_receptacle(i,d,j,1:idx);
%                 end
%             end
%             if(counter>0)
%                 figure(4);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = receptacle entry');
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
%
%             %df/f aligned to LED. split into successful entry vs. no-entry
%             %trial
%             counter=0;  temp=[];
%             counter2=0; temp2=[];
%             for j=1:length(rewardtime_combined(i,:))
%                 if(occupancy_combined(i,j)>0) %if j th trial is a successful entry trial
%                     counter=counter+1;
%                     temp(counter,:)=dff_LED(i,d,j,1:idx);
%                 else %if jth trial is a no-entry trial
%                     counter2=counter2+1;
%                     temp2(counter2,:)=dff_LED(i,d,j,1:idx);
%                 end
%             end
%             if(counter>0)
%                 figure(5);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = LED on (successful entry trials)');
%                 hold on;
%                 legend_mark(5,i)=1;
%             end
%             if(counter2>0)
%                 figure(6);
%                 plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = LED on (no-entry trials)');
%                 hold on;
%                 legend_mark(6,i)=1;
%             end
%
%             %df/f aligned to zone entering. split into reward vs. no-reward
%             %trials
%             counter=0;  temp=[];
%             counter2=0; temp2=[];
%             for j=1:length(rewardtime_combined(i,:))
%                 if(rewardtime_combined(i,j)>0) %if j th trial is a reward trial
%                     counter=counter+1;
%                     temp(counter,:)=dff_zone(i,d,j,1:idx);
%                 else %if jth trial is a no-reward trial
%                     counter2=counter2+1;
%                     temp2(counter2,:)=dff_zone(i,d,j,1:idx);
%                 end
%             end
%             if(counter>0)
%                 figure(7);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = zone entering (reward trials)');
%                 hold on;
%                 legend_mark(7,i)=1;
%             end
%             if(counter2>0)
%                 figure(8);
%                 plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = zone entering (no reward trials)');
%                 hold on;
%                 legend_mark(8,i)=1;
%             end
%         end
%
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:)));
%             hold off;
%         end
%
%         delete(findall(0,'Type','figure'));
% %         stderror=std(dfoverf1,0,1)/sqrt(n);
% %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
%     end
% end

%% Plotting lifetime data
timebin = 1; %1s
duration=100; %duration of analysis
ITI=120;
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
timestamp=[-baseline_duration:timebin:duration-baseline_duration];

idx=length(timestamp);

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'dtau_dispense');

%marker array for mouse X trial, 0=start at -1s, 1=start at 0
idx_array=zeros(length(mousenamelist),size(dtau_dispense,2));
for i=1:length(mousenamelist)
    if i==3 || i==8
        idx_array(i,1:3)=1;
    elseif i==6
    elseif i==9 || i==12
        idx_array(i,1)=1;
    else
        idx_array(i,1:2)=1;
    end
end

i=1;
for mouse=1:length(mousenamelist)
    display(mousenamelist{mouse});
    
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'dtau_dispense','pc_dispense','rewardtime_combined');
    legend_mark=zeros(4,num_days);
    legend_mark2=ones(1,size(dtau_dispense,2));
    cmap2=hsv(size(dtau_dispense,2));
    
    output=[];
    output(1,:)=timestamp;
    
    output2=[];
    output2(1,:)=timestamp;
    
    for j=1:size(dtau_dispense,2)
        figure(1);
        if idx_array(mouse,j)==1
            plot(timestamp,squeeze(dtau_dispense(i,j,2:idx+1)),'color',cmap2(j,:));
            output(j+1,:)=dtau_dispense(i,j,2:idx+1);
        else
            plot(timestamp,squeeze(dtau_dispense(i,j,1:idx)),'color',cmap2(j,:));
            output(j+1,:)=dtau_dispense(i,j,1:idx);
        end
        hold on;
    end
    figure(1);
    title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
    legend(legend_maker(legend_mark2,'trial'));
    hold off;
    
    for j=1:size(dtau_dispense,2)        
        figure(2);
        if idx_array(mouse,j)==1
            plot(timestamp,squeeze(pc_dispense(i,j,2:idx+1)),'color',cmap2(j,:));
            output2(j+1,:)=pc_dispense(i,j,2:idx+1);
        else
            plot(timestamp,squeeze(pc_dispense(i,j,1:idx)),'color',cmap2(j,:));
            output2(j+1,:)=pc_dispense(i,j,1:idx);
        end
        hold on;
    end
    figure(2);
    title('photoncounts vs. time(s): 0s = stimulation started');
    legend(legend_maker(legend_mark2,'trial'));
    hold off;
    
    %delta lifetime aligned to pellet dispensing
    counter=0; temp=[]; temp2=[];
    for j=1:size(pc_dispense,2)
        if(rewardtime_combined(i,j)>0 && pc_dispense(i,j,1)~=0) %if j th trial is a rewarded trial
            counter=counter+1;
            
            if idx_array(mouse,j)==1
                temp(counter,:)=dtau_dispense(i,j,2:idx+1);
                temp2(counter,:)=pc_dispense(i,j,2:idx+1);
            else
                temp(counter,:)=dtau_dispense(i,j,1:idx);
                temp2(counter,:)=pc_dispense(i,j,1:idx);
            end
        end
    end
    if counter>0
        stderror=std(temp,0,1)/sqrt(size(temp,1));
        figure(3);
        confplot(timestamp,mean(temp,1),stderror,stderror,'color',cmap(i,:),'LineWidth',2);
        title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
        
        stderror=std(temp2,0,1)/sqrt(size(temp,1));
        figure(4);
        plot(timestamp,squeeze(mean(temp2,1)),'color',cmap(i,:));
        title('normalized photoncount vs. time(s): 0s = stimulation started');
        hold on;
    end
    
    %export to excel sheet
    filename=['analysis_',mousenamelist{mouse},'.xlsx'];
    xlswrite(filename,output',1);
    xlswrite(filename,output2',2);
    
    %autoArrangeFigures();
    delete(findall(0,'Type','figure'));
end