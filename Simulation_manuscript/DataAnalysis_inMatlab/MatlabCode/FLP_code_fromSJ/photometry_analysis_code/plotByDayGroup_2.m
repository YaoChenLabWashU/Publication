%plot by day group (beginner, intermediate, trained)

clear all;

%mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
mousenamelist = {'SJ185','SJ186','SJ187','SJ188'};
%mousenamelist = {'SJ181','SJ182','SJ183','SJ184'};
%mousenamelist = {'SJ181','SJ183','SJ184'};

num_days=12;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group

inputrate=1000; %in Hz
timebin=500; %timebin in msec per data point

%% Plotting intensity data by each mouse
% cmap = colormap(hsv(length(group_criteria)+1));
% timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
% idx=length(timestamp);
% for mouse=1:length(mousenamelist)
%     filename = ['analysis_',mousenamelist{mouse},'.mat'];
%     load(filename,'TrialData','successrate');
%     legend_mark=zeros(8,num_days);
%     
%     daylist=[];
%     for i=1:length(group_criteria)
%         idx_list=find(successrate>=group_criteria(i));
%         daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%     end
%     daylist(end+1)=num_days;
%     
%     for d=1:length(TrialData(1).ch_name);
%         display(mousenamelist{mouse});
%         display(TrialData(1).ch_name{d});
%         
%         idx_start=1;
%         for i=1:length(daylist)
%             for j=idx_start:length(TrialData)
%                 if j==length(TrialData)
%                     idx_end=j;
%                     break;
%                 end
%                 if TrialData(j+1).day>daylist(i)
%                     idx_end=j;
%                     break;
%                 end
%             end
%             
%             %df/f aligned to LED
%             output=selectTrialData(TrialData,'dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
%             figure(1);
%             title('df/f(%) vs. time(s): 0s = LED on');
%             plot(timestamp,mean(output,1),'color',cmap(i,:));
%             hold on;
%             legend_mark(1,i)=1;
%             
%             %df/f aligned to LED zone entry
%             output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
%             figure(2);
%             title('df/f(%) vs. time(s): 0s = LED zone entering');
%             plot(timestamp,mean(output,1),'color',cmap(i,:));
%             hold on;
%             legend_mark(2,i)=1;
%             
%             %df/f aligned to pellet dispensing
%             output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(3);
%                 title('df/f(%) vs. time(s): 0s = pellet dispensed');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(3,i)=1;
%             end
%             
%             %df/f aligned to receptacle entry
%             output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
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
%             output=selectTrialData(TrialData,'dff_LED',d,[1 2],idx_start,idx_end);
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
%             
%             idx_start=idx_end+1;
%         end
%         
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:),'group_day'));
%         end
%         
%         autoArrangeFigures();
%         %delete(findall(0,'Type','figure'));
%         %         stderror=std(dfoverf1,0,1)/sqrt(n);
%         %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
%         
%         %omission trial analysis
%         idx_start=-1;
%         for j=1:length(TrialData)
%             if TrialData(j).day==12 && idx_start==-1
%                 idx_start=j;
%             end
%             if TrialData(j).day==13
%                 idx_end=j-1;
%                 break;
%             end
%         end
%         
%         if TrialData(j).day~=13
%             idx_end=length(TrialData);
%         end
%         
%         display([num2str(idx_start),' ',num2str(idx_end)]);
% 
%         if(idx_start>0 && idx_end>0)
%             i=length(daylist)+1;
%             cmap=hsv(i);
%             
%             %dff aligned to LED
%             output=selectTrialData(TrialData,'dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
%             if(size(output,1)>0)
%                 figure(1);
%                 title('df/f(%) vs. time(s): 0s = LED on');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(1,i)=1;
%             end
%             
%             %dff aligned to LED zone entry
%             output=selectTrialData(TrialData,'dff_zone',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
%                 figure(2);
%                 title('df/f(%) vs. time(s): 0s = LED zone entering');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(2,i)=1;
%             end
%             
%             %dff aligned to receptacle entry
%             output=selectTrialData(TrialData,'dff_receptacle',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(4);
%                 title('df/f(%) vs. time(s): 0s = receptacle entry');
%                 plot(timestamp,mean(output,1),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
%         end
%         
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:),'group_day+2'));
%         end
%         
%         autoArrangeFigures();
%         delete(findall(0,'Type','figure'));
%     end
% end
% 
% return;

%% Plotting intensity across mice (group all mice's data)
%organize by cateogry: category X trial # X time series
% 
% cmap = colormap(hsv(length(group_criteria)+1));
% timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
% idx=length(timestamp);
% 
% filename = ['analysis_',mousenamelist{1},'.mat'];
% load(filename,'TrialData','successrate');
% plot_num=10;
% 
% figuretitle{1}='normalized df/f vs. time(s): 0s = LED on';
% figuretitle{2}='normalized df/f vs. time(s): 0s = LED zone entering';
% figuretitle{3}='normalized df/f vs. time(s): 0s = pellet dispensed';
% figuretitle{4}='normalized df/f vs. time(s): 0s = receptacle entry';
% figuretitle{5}='normalized df/f vs. time(s): 0s = LED on (successful entry trials)';
% figuretitle{6}='normalized df/f vs. time(s): 0s = LED on (no-entry trials)';
% figuretitle{7}='normalized df/f vs. time(s): 0s = zone entering (reward trials)';
% figuretitle{8}='normalized df/f vs. time(s): 0s = zone entering (no reward trials)';
% figuretitle{9}='normalized df/f vs. time(s): 0s = LED on, rewarded trial';
% figuretitle{10}='normalized df/f vs. time(s): 0s = LED on, no-reward trial';
% 
% for d=1:length(TrialData(1).ch_name)
%     for i=1:plot_num
%         for j=1:length(group_criteria)+1
%             outputdata(i,j).numtrials=0;
%         end
%     end   
%     
%     for mouse=1:length(mousenamelist)
%         
%         filename = ['analysis_',mousenamelist{mouse},'.mat'];
%         load(filename,'TrialData','successrate');
%         
%         %grouping days by success rate
%         daylist=[];
%         for i=1:length(group_criteria)
%             idx_list=find(successrate>=group_criteria(i));
%             daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%         end
%         daylist(end+1)=num_days;
%         
%         idx_start=1;
%         for i=1:length(daylist)
%             for j=idx_start:length(TrialData)
%                 if j==length(TrialData)
%                     idx_end=j;
%                     break;
%                 end
%                 if TrialData(j+1).day>daylist(i)
%                     idx_end=j;
%                     break;
%                 end
%             end
%             
%             %df/f aligned to LED
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
%             if(size(output,1)>0)    
%                 outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output;
%                 outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED zone entry
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[1 2 3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output;
%                 outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to pellet dispensing
%             output=selectTrialData(TrialData,'normalized_dff_dispense',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output;
%                 outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to receptacle entry
%             output=selectTrialData(TrialData,'normalized_dff_receptacle',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output;
%                 outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED. split into successful entry vs. no-entry
%             %trial
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output;
%                 outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output;
%                 outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to zone entering. split into reward vs. no-reward
%             %trials
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output;
%                 outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output;
%                 outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED split into reward vs no reward trial
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output;
%                 outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[2 3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output;
%                 outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
%             end
%             
%             idx_start=idx_end+1;
%         end
%     end
%     
%     legend_mark=zeros(plot_num,length(daylist));
%     p_list=[1:10];
%     for p=p_list
%         cmap=hsv(length(daylist));
%         for i=1:length(daylist)
%             figure(p);
%             plot(timestamp,squeeze(mean(outputdata(p,i).data,1)),'color',cmap(i,:));
%             hold on;
%             
%             if outputdata(p,i).numtrials>0
%                 legend_mark(p,i)=1;
%             end
%         end
%         figure(p);
%         legend(legend_maker(legend_mark(p,:),'group_day'));
%         title(figuretitle{p});
%         xlabel('time(s)');
%         ylabel('normalized df/f');
%         hold off;
%     end
% 
%     %plotting individual trials
% %     trial_num=10;
% %     legend_mark=zeros(plot_num,length(trial_num));
% %     p_list=[1];
% %     for p=p_list
% %         cmap=hsv(trial_num);
% %         for i=1:trial_num
% %             figure(p);
% %             plot(timestamp,outputdata(p,3).data(190+i,:),'color',cmap(i,:));
% %             hold on;
% %         end
% %         figure(p);
% %         %legend(legend_maker(legend_mark(p,:),'group_day'));
% %         title(figuretitle{p});
% %         hold off;
% %     end
%     
%     autoArrangeFigures();
%     delete(findall(0,'Type','figure'));
%     %         stderror=std(dfoverf1,0,1)/sqrt(n);
%     %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
% end
% 
% return;

%% intensity across many mice: comparing reward omission trials
% cmap = colormap(hsv(length(group_criteria)+2));
% timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
% idx=length(timestamp);
% num_days=11;
% 
% filename = ['analysis_',mousenamelist{1},'.mat'];
% load(filename,'TrialData','successrate');
% plot_num=10;
% 
% figuretitle{1}='normalized df/f vs. time(s): 0s = LED on';
% figuretitle{2}='normalized df/f vs. time(s): 0s = LED zone entering';
% figuretitle{3}='normalized df/f vs. time(s): 0s = pellet dispensed';
% figuretitle{4}='normalized df/f vs. time(s): 0s = receptacle entry';
% figuretitle{5}='normalized df/f vs. time(s): 0s = LED on (successful entry trials)';
% figuretitle{6}='normalized df/f vs. time(s): 0s = LED on (no-entry trials)';
% figuretitle{7}='normalized df/f vs. time(s): 0s = zone entering (reward trials)';
% figuretitle{8}='normalized df/f vs. time(s): 0s = zone entering (no reward trials)';
% figuretitle{9}='normalized df/f vs. time(s): 0s = LED on, rewarded trial';
% figuretitle{10}='normalized df/f vs. time(s): 0s = LED on, no-reward trial';
% 
% for d=1:length(TrialData(1).ch_name)
%     for i=1:plot_num
%         for j=1:length(group_criteria)+2
%             outputdata(i,j).numtrials=0;
%         end
%     end
%     
%     for mouse=1:length(mousenamelist)        
%         filename = ['analysis_',mousenamelist{mouse},'.mat'];
%         load(filename,'TrialData','successrate');
%         
%         %grouping days by success rate
%         daylist=[];
%         for i=1:length(group_criteria)
%             idx_list=find(successrate>=group_criteria(i));
%             daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%         end
%         daylist(end+1)=num_days;
%         
%         idx_start=1;
%         for i=1:length(daylist)
%             for j=idx_start:length(TrialData)
%                 if j==length(TrialData)
%                     idx_end=j;
%                     break;
%                 end
%                 if TrialData(j+1).day>daylist(i)
%                     idx_end=j;
%                     break;
%                 end
%             end
%             
%             %df/f aligned to LED
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
%             if(size(output,1)>0)    
%                 outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output;
%                 outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED zone entry
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[1 2 3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output;
%                 outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to pellet dispensing
%             output=selectTrialData(TrialData,'normalized_dff_dispense',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output;
%                 outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to receptacle entry
%             output=selectTrialData(TrialData,'normalized_dff_receptacle',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output;
%                 outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED. split into successful entry vs. no-entry
%             %trial
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output;
%                 outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output;
%                 outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to zone entering. split into reward vs. no-reward
%             %trials
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output;
%                 outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output;
%                 outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
%             end
%             
%             %df/f aligned to LED split into reward vs no reward trial
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output;
%                 outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
%             end
%             
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[2 3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output;
%                 outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
%             end
%             
%             idx_start=idx_end+1;
%         end
%         
%         %omission trial analysis
%         idx_start=-1;
%         for j=1:length(TrialData)
%             if TrialData(j).day==12 && idx_start==-1
%                 idx_start=j;
%             end
%             if TrialData(j).day==13
%                 idx_end=j-1;
%                 break;
%             end
%         end
%         
%         if TrialData(j).day~=13
%             idx_end=length(TrialData);
%         end
%         
%         display([num2str(idx_start),' ',num2str(idx_end)]);
%         
%         if(idx_start>0 && idx_end>0)
%             i=length(daylist)+1;
%             %dff aligned to LED
%             output=selectTrialData(TrialData,'normalized_dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
%             if(size(output,1)>0)
%                 outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
%                 outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
%             end
%             
%             %dff aligned to LED zone entry
%             output=selectTrialData(TrialData,'normalized_dff_zone',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
%                 outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
%             end
%             
%             %dff aligned to receptacle entry
%             output=selectTrialData(TrialData,'normalized_dff_receptacle',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
%                 outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
%             end
%         end
%     end
%     
%     legend_mark=zeros(plot_num,length(daylist));
%     p_list=[1:10];
%     for p=p_list
%         cmap=hsv(length(daylist)+1);
%         for i=1:length(daylist)+1            
%             if outputdata(p,i).numtrials>0
%                 figure(p);
%                 temp=squeeze(mean(outputdata(p,i).data,1));               
%                 plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%                 hold on;
% 
%                 legend_mark(p,i)=1;
%             end
%         end
%         figure(p);
%         legend(legend_maker(legend_mark(p,:),'group_day+2'));
%         title(figuretitle{p});
%         xlabel('time(s)');
%         ylabel('normalized df/f');
%         hold off;
%     end
% 
%     %plotting individual trials
% %     p_list=[1 2 3 4];
% %     for p=p_list
% %         cmap=hsv(size(outputdata(p,4).data,1));
% %         for i=1:size(outputdata(p,4).data,1)
% %             figure(p);
% %             plot(timestamp,outputdata(p,4).data(i,:),'color',cmap(i,:));
% %             hold on;
% %         end
% %         hold off;
% %     end
%     
%     autoArrangeFigures();
%     delete(findall(0,'Type','figure'));
%     %         stderror=std(dfoverf1,0,1)/sqrt(n);
%     %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
% end
% 
% return;

%% Plotting lifetime data by each mouse

% timebin=1;
% timestamp=[-baseline_duration:timebin:duration-baseline_duration];
% idx=length(timestamp);
% cmap=hsv(length(group_criteria)+1);
% 
% for mouse=1:length(mousenamelist)
%     filename = ['analysis_',mousenamelist{mouse},'.mat'];
%     load(filename,'TrialData','successrate');
%     legend_mark=zeros(8,num_days);
%     
%     daylist=[];
%     for i=1:length(group_criteria)
%         idx_list=find(successrate>=group_criteria(i));
%         daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%     end
%     daylist(end+1)=num_days;
% 
%     for d=1:length(TrialData(1).ch_name);
%         display(mousenamelist{mouse});
%         display(TrialData(1).ch_name{d});
%         
%         idx_start=1;
%         for i=1:length(daylist)
%             for j=idx_start:length(TrialData)
%                 if j==length(TrialData)
%                     idx_end=j;
%                     break;
%                 end
%                 if TrialData(j+1).day>daylist(i)
%                     idx_end=j;
%                     break;
%                 end
%             end
%             
%             %dtau aligned to LED
%             output=selectTrialData(TrialData,'dtau_LED',d,[1 2 3],idx_start,idx_end); %plot dtau_LED for all trial types
%             figure(1);
%             title('delta lifetime(ns) vs. time(s): 0s = LED on');
%             temp=mean(output,1);
%             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%             hold on;
%             legend_mark(1,i)=1;
%             
%             %dtau aligned to LED zone entry
%             output=selectTrialData(TrialData,'dtau_zone',d,[1 2 3],idx_start,idx_end);
%             figure(2);
%             title('delta lifetime(ns) vs. time(s): 0s = LED zone entering');
%             temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%             hold on;
%             legend_mark(2,i)=1;
%             
%             %dtau aligned to pellet dispensing
%             output=selectTrialData(TrialData,'dtau_dispense',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(3);
%                 title('delta lifetime(ns) vs. time(s): 0s = pellet dispensed');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(3,i)=1;
%             end
%             
%             %dtau aligned to receptacle entry
%             output=selectTrialData(TrialData,'dtau_receptacle',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(4);
%                 title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
%             
%             %dtau aligned to LED. split into successful entry vs. no-entry
%             %trial
%             output=selectTrialData(TrialData,'dtau_LED',d,[1 2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(5);
%                 title('delta lifetime(ns) vs. time(s): 0s = LED on (successful entry trials)');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(5,i)=1;
%             end
%             
%             output=selectTrialData(TrialData,'dtau_LED',d,[3],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(6);
%                 title('delta lifetime(ns) vs. time(s): 0s = LED on (no-entry trials)');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(6,i)=1;
%             end
%             
%             %dtau aligned to zone entering. split into reward vs. no-reward
%             %trials
%             output=selectTrialData(TrialData,'dtau_zone',d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(7);
%                 title('delta lifetime(ns) vs. time(s): 0s = zone entering (reward trials)');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(7,i)=1;
%             end
%             
%             output=selectTrialData(TrialData,'dtau_zone',d,[2],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(8);
%                 title('delta lifetime(ns) vs. time(s): 0s = zone entering (no reward trials)');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(8,i)=1;
%             end
%             
%             idx_start=idx_end+1;
%         end
%         
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:),'group_day'));
%         end
%         
%         autoArrangeFigures();
%         %delete(findall(0,'Type','figure'));
%         %         stderror=std(dfoverf1,0,1)/sqrt(n);
%         %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
%         
%         %omission trial analysis
%         idx_start=-1;
%         for j=1:length(TrialData)
%             if TrialData(j).day==12 && idx_start==-1
%                 idx_start=j;
%             end
%             if TrialData(j).day==13
%                 idx_end=j-1;
%                 break;
%             end
%         end
%         
%         if TrialData(j).day~=13
%             idx_end=length(TrialData);
%         end
%         
%         display([num2str(idx_start),' ',num2str(idx_end)]);
% 
%         if(idx_start>0 && idx_end>0)
%             i=length(daylist)+1;
%             cmap=hsv(i);
%             
%             %dtau aligned to LED
%             output=selectTrialData(TrialData,'dtau_LED',d,[4],idx_start,idx_end); %plot dtau_LED for all trial types
%             if(size(output,1)>0)
%                 figure(1);
%                 title('delta lifetime(ns) vs. time(s): 0s = LED on');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(1,i)=1;
%             end
%             
%             %dtau aligned to LED zone entry
%             output=selectTrialData(TrialData,'dtau_zone',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 output=selectTrialData(TrialData,'dtau_zone',d,[1 2 3],idx_start,idx_end);
%                 figure(2);
%                 title('delta lifetime(ns) vs. time(s): 0s = LED zone entering');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(2,i)=1;
%             end
%             
%             %dtau aligned to receptacle entry
%             output=selectTrialData(TrialData,'dtau_receptacle',d,[4],idx_start,idx_end);
%             if(size(output,1)>0)
%                 figure(4);
%                 title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
%                 temp=mean(output,1);             plot(timestamp,temp(1:idx),'color',cmap(i,:));
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
%         end
%         
%         for i=1:8
%             figure(i);
%             legend(legend_maker(legend_mark(i,:),'group_day+2'));
%         end
%         
%         autoArrangeFigures();
%         delete(findall(0,'Type','figure'));
%     end
% end
% 
% return;


%% Plotting lifetime across mice (group all mice's data)
%organize by cateogry: category X trial # X time series

% filename = ['analysis_',mousenamelist{1},'.mat'];
% load(filename,'TrialData','successrate');
% plot_num=10;
% timebin=1;
% 
% timestamp=[-baseline_duration:timebin:duration-baseline_duration];
% idx=length(timestamp);
% 
% figuretitle{1}='normalized delta lifetime vs. time(s): 0s = LED on';
% figuretitle{2}='normalized delta lifetime vs. time(s): 0s = LED zone entering';
% figuretitle{3}='normalized delta lifetime vs. time(s): 0s = pellet dispensed';
% figuretitle{4}='normalized delta lifetime vs. time(s): 0s = receptacle entry';
% figuretitle{5}='normalized delta lifetime vs. time(s): 0s = LED on (successful entry trials)';
% figuretitle{6}='normalized delta lifetime vs. time(s): 0s = LED on (no-entry trials)';
% figuretitle{7}='normalized delta lifetime vs. time(s): 0s = zone entering (reward trials)';
% figuretitle{8}='normalized delta lifetime vs. time(s): 0s = zone entering (no reward trials)';
% figuretitle{9}='normalized delta lifetime vs. time(s): 0s = LED on, rewarded trial';
% figuretitle{10}='normalized delta lifetime vs. time(s): 0s = LED on, no-reward trial';
% 
% d=0;
% for i=1:plot_num
%     for j=1:length(group_criteria)+2
%         outputdata(i,j).numtrials=0;
%     end
% end
% 
% for mouse=1:length(mousenamelist)
%     
%     filename = ['analysis_',mousenamelist{mouse},'.mat'];
%     load(filename,'TrialData','successrate');
%     
%     %grouping days by success rate
%     daylist=[];
%     for i=1:length(group_criteria)
%         idx_list=find(successrate>=group_criteria(i));
%         daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%     end
%     daylist(end+1)=num_days;
%     daylist(end+1)=14;
%     
%     idx_start=1;
%     for i=1:length(daylist)
%         if(i==4)
%             for j=idx_start:length(TrialData)
%                 if TrialData(j+1).day==daylist(i)
%                     idx_start=j;
%                     break;
%                 end
%             end
%             idx_end=length(TrialData);
%         end
%         
%         for j=idx_start:length(TrialData)
%             if j==length(TrialData)
%                 idx_end=j;
%                 break;
%             end
%             if TrialData(j+1).day>daylist(i)
%                 idx_end=j;
%                 break;
%             end
%         end
%         
%         if(idx_start>=idx_end)
%             continue;
%         end
%         
%         %dtau aligned to LED
%         output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1 2 3 5 6 7],idx_start,idx_end); %plot dff_LED for all trial types
%         if(size(output,1)>0)
%             outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to LED zone entry
%         output=selectTrialData(TrialData,'normalized_dtau_zone',d,[1 2 5 6],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to pellet dispensing
%         output=selectTrialData(TrialData,'normalized_dtau_dispense',d,[1 5],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to receptacle entry
%         output=selectTrialData(TrialData,'normalized_dtau_receptacle',d,[1 5],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to LED. split into successful entry vs. no-entry
%         %trial
%         output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1 2],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
%         end
%         
%         output=selectTrialData(TrialData,'normalized_dtau_LED',d,[3],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to zone entering. split into reward vs. no-reward
%         %trials
%         output=selectTrialData(TrialData,'normalized_dtau_zone',d,[1],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
%         end
%         
%         output=selectTrialData(TrialData,'normalized_dtau_zone',d,[2],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
%         end
%         
%         %dtau aligned to LED split into reward vs no reward trial
%         output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
%         end
%         
%         output=selectTrialData(TrialData,'normalized_dtau_LED',d,[2 3],idx_start,idx_end);
%         if(size(output,1)>0)
%             outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output(:,1:idx);
%             outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
%         end
%         
%         idx_start=idx_end+1;
%     end
% end
% 
% legend_mark=zeros(plot_num,length(daylist));
% p_list=[1:10];
% for p=p_list
%     cmap=hsv(length(daylist));
%     for i=1:length(daylist)
%         if outputdata(p,i).numtrials>0
%             legend_mark(p,i)=1;
%             figure(p);
%             plot(timestamp,squeeze(mean(outputdata(p,i).data,1)),'color',cmap(i,:));
%             hold on;
%         end
%     end
%     figure(p);
%     legend(legend_maker(legend_mark(p,:),'group_day+1'));
%     title(figuretitle{p});
%     xlabel('time(s)');
%     ylabel('normalized delta lifetime');
%     ylim([-0.5,0.15]);
%     hold off;
% end
% 
% %plotting individual trials
% %     trial_num=10;
% %     legend_mark=zeros(plot_num,length(trial_num));
% %     p_list=[1];
% %     for p=p_list
% %         cmap=hsv(trial_num);
% %         for i=1:trial_num
% %             figure(p);
% %             plot(timestamp,outputdata(p,3).data(190+i,:),'color',cmap(i,:));
% %             hold on;
% %         end
% %         figure(p);
% %         %legend(legend_maker(legend_mark(p,:),'group_day'));
% %         title(figuretitle{p});
% %         hold off;
% %     end
% 
% autoArrangeFigures();
% delete(findall(0,'Type','figure'));
% return;
% % %         stderror=std(dfoverf1,0,1)/sqrt(n);
% % %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);

%% Plotting lifetime across mice (group all mice's data): comparing omission trials
filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;
timebin=1;
num_days=12;

timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);

figuretitle{1}='normalized delta lifetime vs. time(s): 0s = LED on';
figuretitle{2}='normalized delta lifetime vs. time(s): 0s = LED zone entering';
figuretitle{3}='normalized delta lifetime vs. time(s): 0s = pellet dispensed';
figuretitle{4}='normalized delta lifetime vs. time(s): 0s = receptacle entry';
figuretitle{5}='normalized delta lifetime vs. time(s): 0s = LED on (successful entry trials)';
figuretitle{6}='normalized delta lifetime vs. time(s): 0s = LED on (no-entry trials)';
figuretitle{7}='normalized delta lifetime vs. time(s): 0s = zone entering (reward trials)';
figuretitle{8}='normalized delta lifetime vs. time(s): 0s = zone entering (no reward trials)';
figuretitle{9}='normalized delta lifetime vs. time(s): 0s = LED on, rewarded trial';
figuretitle{10}='normalized delta lifetime vs. time(s): 0s = LED on, no-reward trial';

d=0;
for i=1:plot_num
    for j=1:length(group_criteria)+2
        outputdata(i,j).numtrials=0;
    end
end

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    
    %grouping days by success rate
    daylist=[];
    for i=1:length(group_criteria)
        idx_list=find(successrate>=group_criteria(i));
        daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
    end
    daylist(end+1)=num_days;
    
    idx_start=1;
    for i=1:length(daylist)
        for j=idx_start:length(TrialData)
            if j==length(TrialData)
                idx_end=j;
                break;
            end
            if TrialData(j+1).day>daylist(i)
                idx_end=j;
                break;
            end
        end
        
        %dtau aligned to LED
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
        if(size(output,1)>0)
            outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED zone entry
        output=selectTrialData(TrialData,'normalized_dtau_zone',d,[1 2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
        end
        
        %dtau aligned to pellet dispensing
        output=selectTrialData(TrialData,'normalized_dtau_dispense',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
        end
        
        %dtau aligned to receptacle entry
        output=selectTrialData(TrialData,'normalized_dtau_receptacle',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED. split into successful entry vs. no-entry
        %trial
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1 2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[3],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
        end
        
        %dtau aligned to zone entering. split into reward vs. no-reward
        %trials
        output=selectTrialData(TrialData,'normalized_dtau_zone',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'normalized_dtau_zone',d,[2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED split into reward vs no reward trial
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[2 3],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
        end
        
        idx_start=idx_end+1;
    end
    
    %omission trial analysis
    idx_start=-1;
    for j=1:length(TrialData)
        if TrialData(j).day==12 && idx_start==-1
            idx_start=j;
        end
        if TrialData(j).day==13
            idx_end=j-1;
            break;
        end
    end
    if TrialData(j).day~=13
        idx_end=length(TrialData);
    end
    
    display([num2str(idx_start),' ',num2str(idx_end)]);
    
    counter=0;
    for i=idx_start:idx_end
        %display(TrialData(i).trialtype);
        if(TrialData(i).trialtype==1 ||TrialData(i).trialtype==4)
            counter=counter+1;
        end
    end
    display(counter);
    
    if(idx_start>0 && idx_end>0)
        i=length(daylist)+1;
        %dtau aligned to LED
        output=selectTrialData(TrialData,'normalized_dtau_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
        if(size(output,1)>0)
            outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED zone entry
        output=selectTrialData(TrialData,'normalized_dtau_zone',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
        end
        
        %dtau aligned to pellet dispensing
        output=selectTrialData(TrialData,'normalized_dtau_dispense',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
        end
        
        %dtau aligned to receptacle entry
        output=selectTrialData(TrialData,'normalized_dtau_receptacle',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
        end
    end
end

    legend_mark=zeros(plot_num,length(daylist));
    p_list=[1:10];
    for p=p_list
        cmap=hsv(length(daylist)+1);
        for i=1:length(daylist)+1            
            if outputdata(p,i).numtrials>0
                figure(p);
                temp=squeeze(mean(outputdata(p,i).data,1));               
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;

                legend_mark(p,i)=1;
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+2'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel('normalized delta lifetime');
        hold off;
    end

%plotting individual trials
%     trial_num=10;
%     legend_mark=zeros(plot_num,length(trial_num));
%     p_list=[1];
%     for p=p_list
%         cmap=hsv(trial_num);
%         for i=1:trial_num
%             figure(p);
%             plot(timestamp,outputdata(p,3).data(190+i,:),'color',cmap(i,:));
%             hold on;
%         end
%         figure(p);
%         %legend(legend_maker(legend_mark(p,:),'group_day'));
%         title(figuretitle{p});
%         hold off;
%     end

autoArrangeFigures();
delete(findall(0,'Type','figure'));
%         stderror=std(dfoverf1,0,1)/sqrt(n);
%         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);