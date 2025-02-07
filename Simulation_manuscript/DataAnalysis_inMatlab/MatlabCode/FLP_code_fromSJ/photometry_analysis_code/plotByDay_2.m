%plot by each day
clear all;
mousenamelist = {'SJ243_AKAR','SJ244_AKAR','SJ245_AKAR','SJ246_AKAR','SJ247_AKAR','SJ248_AKAR'};
%mousenamelist = {'SJ243_mAKAR','SJ244_mAKAR','SJ245_mAKAR','SJ246_mAKAR','SJ247_mAKAR','SJ248_mAKAR'};

num_days=14;
timebin=500; %timebin in ms
duration=100; %analysis duration in s
inputrate=1000; %in 0Hz
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in


%% Plotting intensity data
% timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
% idx=length(timestamp);
% cmap=hsv(num_days);
% for mouse=1:length(mousenamelist)
%     filename = ['analysis_',mousenamelist{mouse},'.mat'];
%     load(filename,'TrialData');
%     legend_mark=zeros(8,num_days);
% 
%     for d=1:length(TrialData(1).ch_name);
%         display(mousenamelist{mouse});
%         display(TrialData(1).ch_name{d});
% 
%         idx_start=1;
%         for i=1:num_days
%             for j=idx_start:length(TrialData)
%                 if j==length(TrialData)
%                     idx_end=j;
%                     break;
%                 end
%                 if TrialData(j+1).day>i
%                     idx_end=j;
%                     break;
%                 end
%             end
%     
%             %df/f aligned to LED
%             output=selectTrialData(TrialData,'dff_LED',d,[1 2 3 4 5 6 7 8],idx_start,idx_end); %plot dff_LED for all trial types
%             figure(1);
%             title('df/f(%) vs. time(s): 0s = LED on');
%             plot(timestamp,mean(output,1),'color',cmap(i,:));
%             hold on;
%             legend_mark(1,i)=1;
% 
%             %df/f aligned to LED zone entry
%             output=selectTrialData(TrialData,'dff_zone',d,[1 2 4 5 6 8],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(2);
%                 title('df/f(%) vs. time(s): 0s = LED zone entering');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(2,i)=1;
%             end
% 
%             %df/f aligned to pellet dispensing
%             output=selectTrialData(TrialData,'dff_dispense',d,[1 5],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(3);
%                 title('df/f(%) vs. time(s): 0s = pellet dispensed');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(3,i)=1;
%             end
% 
%             %df/f aligned to receptacle entry
%             output=selectTrialData(TrialData,'dff_receptacle',d,[1 5],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(4);
%                 title('df/f(%) vs. time(s): 0s = receptacle entry');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
% 
%             %df/f aligned to LED. split into successful entry vs. no-entry
%             %trial
%             output=selectTrialData(TrialData,'dff_LED',d,[1 2 4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(5);
%                 title('df/f(%) vs. time(s): 0s = LED on (successful entry trials)');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(5,i)=1;
%             end
% 
%             output=selectTrialData(TrialData,'dff_LED',d,[3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(6);
%                 title('df/f(%) vs. time(s): 0s = LED on (no-entry trials)');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(6,i)=1;
%             end
% 
%             %df/f aligned to zone entering. split into reward vs. no-reward
%             %trials
%             output=selectTrialData(TrialData,'dff_zone',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(7);
%                 title('df/f(%) vs. time(s): 0s = zone entering (reward trials)');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(7,i)=1;
%             end
% 
%             output=selectTrialData(TrialData,'dff_zone',d,[2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(8);
%                 title('df/f(%) vs. time(s): 0s = zone entering (no reward trials)');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(8,i)=1;
%             end
%             idx_start=idx_end+1;
%         end
% 
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:),'day'));
%             xlabel('time(s)');
%             ylabel('df/f(%)');
%             hold off;
%         end
% 
%         autoArrangeFigures();
%         delete(findall(0,'Type','figure'));
% %         stderror=std(dfoverf1,0,1)/sqrt(n);
% %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
%     end
% end
% 
% return;

%% Plotting lifetime data
timebin=1;
timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);
cmap=hsv(num_days);

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData');
    legend_mark=zeros(9,num_days);
    
    d=1;
    idx_start=1;
    %for i=1:num_days
    for i=1:num_days                
        for j=idx_start:length(TrialData)
            if j==length(TrialData)
                idx_end=j;
                break;
            end
            if TrialData(j+1).day>i
                idx_end=j;
                break;
            end
        end
        
        if(idx_start >= idx_end) %no trial for this day
            continue;
        end
        
        %delta lifetime aligned to LED
        output=selectTrialData(TrialData,'dtau_LED',d,[1 2 3 4 5 6 7 8],idx_start,idx_end); %plot dff_LED for all trial types
        if(size(output,1)>0)
            figure(1);
            title('delta lifetime(ns) vs. time(s): 0s = LED on');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(1,i)=1;
        end
        
        %delta lifetime aligned to LED zone entry
        output=selectTrialData(TrialData,'dtau_zone',d,[1 2 4 5 6 8],idx_start,idx_end);
        if(size(output,1)>0)
            figure(2);
            title('delta lifetime(ns) vs. time(s): 0s = LED zone entering');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(2,i)=1;
        end
        
        %delta lifetime aligned to pellet dispensing
        output=selectTrialData(TrialData,'dtau_dispense',d,[1 5],idx_start,idx_end);
        if(size(output,1)>0)
            figure(3);
            title('delta lifetime(ns) vs. time(s): 0s = pellet dispensed');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(3,i)=1;
        end
        
        %delta lifetime aligned to receptacle entry
        output=selectTrialData(TrialData,'dtau_receptacle',d,[1 5],idx_start,idx_end);
        if(size(output,1)>0)
            figure(4);
            title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(4,i)=1;
        end
        
        %delta lifetime aligned to LED. split into successful entry vs. no-entry
        %trial
        output=selectTrialData(TrialData,'dtau_LED',d,[1 2 4],idx_start,idx_end);
        if(size(output,1)>0)
            figure(5);
            title('delta lifetime(ns) vs. time(s): 0s = LED on (successful entry trials)');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(5,i)=1;
        end
        
        output=selectTrialData(TrialData,'dtau_LED',d,[3],idx_start,idx_end);
        if(size(output,1)>0)
            figure(6);
            title('delta lifetime(ns) vs. time(s): 0s = LED on (no-entry trials)');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(6,i)=1;
        end
        
        %delta lifetime aligned to zone entering. split into reward vs. no success
        %trials
        output=selectTrialData(TrialData,'dtau_zone',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            figure(7);
            title('delta lifetime(ns) vs. time(s): 0s = zone entering (reward trials)');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(7,i)=1;
        end
        
        output=selectTrialData(TrialData,'dtau_zone',d,[2],idx_start,idx_end);
        if(size(output,1)>0)
            figure(8);
            title('delta lifetime(ns) vs. time(s): 0s = zone entering (no reward trials)');
            plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
            hold on;
            legend_mark(8,i)=1;
        end
        
        if (i==13 && strcmp(mousenamelist{1},'SJ243_mAKAR')==1) || (i==12 && strcmp(mousenamelist{1},'SJ243_AKAR')==1)
%             for j=idx_start:idx_end
%                 display(TrialData(j).trialtype);
%                 display(TrialData(j).rewardtime);
%             end
            
            %delta lifetime alinged to pellet dispesning separated for
            %reward omission trial
            output=selectTrialData(TrialData,'dtau_zone',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(9);
                plot(timestamp,mean(output(:,1:length(timestamp)),1),'color',cmap(i,:));
                title('delta lifetime(ns) vs. time(s): 3s = reward omission');
                hold on;
                legend_mark(9,i)=1;
            end
        end
        
        idx_start=idx_end+1;
    end
    
    for i=1:9
        figure(i);
        legend(legend_maker(legend_mark(i,:),'day'));
        hold off;
    end
    
    autoArrangeFigures();
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

