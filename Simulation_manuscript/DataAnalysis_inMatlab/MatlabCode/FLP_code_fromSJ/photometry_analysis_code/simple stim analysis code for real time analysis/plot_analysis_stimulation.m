clear all;

%dataname={'AD1_','AD2_','AD3_'};
%mousenamelist = {'SJ179_1','SJ179_2','SJ179_3','SJ179_4','SJ179_5','SJ179_6','SJ179_7','SJ179_8','SJ179_9'};
%mousenamelist = {'SJ180_1','SJ180_2','SJ180_3','SJ180_4','SJ180_5','SJ180_6','SJ180_7','SJ180_8'};
mousenamelist={'SJ272_8'};

num_days=1;
timebin=20; %timebin of 50ms per data point
duration=100; %analysis duration of 30s
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

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    %load(filename,'dtau_LED','time_LED','dtau_zone','time_zone','dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
    %load(filename,'dtau_LED','time_LED','pc_LED','dtau_zone','time_zone','pc_zone','dtau_dispense','time_dispense','pc_dispense','dtau_receptacle','time_receptacle','pc_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
    load(filename,'dtau_dispense','pc_dispense','rewardtime_combined');
    legend_mark=zeros(4,num_days);
    
    for i=1:num_days
        legend_mark2=ones(1,size(dtau_dispense,2));
        cmap2=hsv(size(dtau_dispense,2));
        for j=1:size(dtau_dispense,2)
            figure(1);
            if(mouse==8 || mouse==9) %NAc stimulation results in optogenetic light going into detection PMT            
                %omit 2s interval after stimulation (1s stimulation, but
                %let's be safe)
                x=[-baseline_duration:timebin:-1,2:timebin:duration-baseline_duration];
                y=[squeeze(dtau_dispense(i,j,1:baseline_duration))',squeeze(dtau_dispense(i,j,baseline_duration+3:duration+1))'];
                plot(x,y,'color',cmap2(j,:));
            else
                plot(timestamp,squeeze(dtau_dispense(i,j,1:idx)),'color',cmap2(j,:));
            end
            hold on;
        end
        figure(1);
        title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
        legend(legend_maker(legend_mark2,'trial'));
        hold off;
        
        for j=1:size(dtau_dispense,2)
            figure(2);
            if(mouse==8 || mouse==9) %NAc stimulation results in optogenetic light going into detection PMT
                %omit 2s interval after stimulation (1s stimulation, but
                %let's be safe)
                x=[-baseline_duration:timebin:-1,2:timebin:duration-baseline_duration];
                y=[squeeze(pc_dispense(i,j,1:baseline_duration))',squeeze(pc_dispense(i,j,baseline_duration+3:duration+1))'];
                plot(x,y,'color',cmap2(j,:));
            else
                plot(timestamp,squeeze(pc_dispense(i,j,1:idx)),'color',cmap2(j,:));
            end
            hold on;
        end
        figure(2);
        title('normalized photoncounts vs. time(s): 0s = stimulation started');
        legend(legend_maker(legend_mark2,'trial'));
        hold off;
        
        %delta lifetime aligned to pellet dispensing
        counter=0; temp=[]; temp2=[];
        %for j=1:length(rewardtime_combined(i,:))
        for j=1:size(pc_dispense,2)
            if(rewardtime_combined(i,j)>0 && pc_dispense(i,j,1)~=0) %if j th trial is a rewarded trial
                counter=counter+1;
                temp(counter,:)=dtau_dispense(i,j,1:idx);
                temp2(counter,:)=pc_dispense(i,j,1:idx);
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
            
            %             figure(1);
            %             plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
            %             title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
            %             hold on;
            %
            %             figure(2);
            %             plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
            %             title('normalized photoncount vs. time(s): 0s = stimulation started');
            %             hold on;
        end
        %
        %         %delta lifetime alinged to receptacle entry
        %         counter=0;  temp=[];    temp2=[];
        %         %for j=1:length(rewardtime_combined(i,:))
        %         for j=1:size(pc_receptacle,2)
        %             if(rewardtime_combined(i,j)>0 && pc_receptacle(i,j,1)~=0) %if j th trial is a rewarded trial
        %                 counter=counter+1;
        %                 temp(counter,:)=dtau_receptacle(i,j,1:idx);
        %                 temp2(counter,:)=pc_receptacle(i,j,1:idx);
        %             end
        %         end
        %         if(counter>0)
        %             figure(3);
        %             plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
        %             title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
        %             hold on;
        %             legend_mark(3,i)=1;
        %
        %             figure(4);
        %             plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
        %             title('normalized photoncount vs. time(s): 0s = receptacle entry');
        %             legend_mark(4,i)=1;
        %             hold on;
        %         end
    end
    %     for i=1:size(legend_mark,1)
    %         figure(i);
    %         legend(legend_maker(legend_mark(i,:)),'day');
    %         hold off;
    %     end
    
    f=figure(1); movegui(f,'northwest');
    f=figure(2); movegui(f,'northeast');
    f=figure(3); movegui(f,'southwest');
    f=figure(4); movegui(f,'southeast');
    
    %delete(findall(0,'Type','figure'));
end