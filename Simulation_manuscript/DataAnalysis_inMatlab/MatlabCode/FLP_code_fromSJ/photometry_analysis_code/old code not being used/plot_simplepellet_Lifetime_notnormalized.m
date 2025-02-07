%plot by day group (beginner, intermediate, trained)

clear all;
filelist = [1 2 3];
mousenamelist = {'SJ274','SJ275','SJ276'};
num_trial=10;

num_days=1;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group

inputrate=1000; %in Hz
timebin=500; %timebin in msec per data point

excel_filename='';

%% Plotting lifetime across mice
filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;
timebin=1;
num_days=1;

timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);

figuretitle{1}='delta lifetime(ns) vs. time(s): 0s = LED on';
figuretitle{2}='delta lifetime(ns) vs. time(s): 0s = LED zone entering';
figuretitle{3}='delta lifetime(ns) vs. time(s): 0s = pellet dispensed';
figuretitle{4}='delta lifetime(ns) vs. time(s): 0s = receptacle entry';
figuretitle{5}='delta lifetime(ns) vs. time(s): 0s = LED on (successful entry trials)';
figuretitle{6}='delta lifetime(ns) vs. time(s): 0s = LED on (no-entry trials)';
figuretitle{7}='delta lifetime(ns) vs. time(s): 0s = zone entering (reward trials)';
figuretitle{8}='delta lifetime(ns) vs. time(s): 0s = zone entering (no reward trials)';
figuretitle{9}='delta lifetime(ns) vs. time(s): 0s = LED on, rewarded trial';
figuretitle{10}='delta lifetime(ns) vs. time(s): 0s = LED on, no-reward trial';

filetitle{1}='dtau LED on';
filetitle{2}='dtau LED zone entering';
filetitle{3}='dtau pellet dispensed';
filetitle{4}='dtau receptacle entry';
filetitle{5}='dtau LED on (successful entry trials)';
filetitle{6}='dtau LED on (no-entry trials)';
filetitle{7}='dtau zone entering (reward trials)';
filetitle{8}='dtau zone entering (no reward trials)';
filetitle{9}='dtau LED (reward tirals)';
filetitle{10}='dtau LED (no reward trials)';
daylist=[4 6 8 10 12];

for mouse=1:length(mousenamelist)
    for i=1:plot_num
        for j=1:length(daylist)
            outputdata(i,j).numtrials=0;
        end
    end
    
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    
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
        
        %dtau aligned to pellet dispensing
        output=selectTrialData(TrialData,'dtau_dispense',1,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
        end
        
        %dtau aligned to receptacle entry
        output=selectTrialData(TrialData,'dtau_receptacle',1,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
        end
        
        idx_start=idx_end+1;
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
    
    %plot average signal per day
    p_list=[3,4];
    for p=p_list
        cmap=hsv(length(daylist));
        for i=1:length(daylist)
            if outputdata(p,i).numtrials>0
                figure(p);
                temp=squeeze(mean(outputdata(p,i).data,1));
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legendlabel{i}=['day',num2str(daylist(i))];
    
                if(daylist(i)==10)
                    excel_filename=['simple pellet PKI_',filetitle{p},'_',mousenamelist{mouse},'.xlsx'];
    
                    out=timestamp';
                    out=[out,squeeze(outputdata(p,i).data)'];
                    filename=[excel_filename];
                    xlswrite(filename,out,1);
                end
            end
        end
        figure(p);
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel('delta lifetime');
        legend(legendlabel);
        hold off;
    end
    
    autoArrangeFigures();
end

% p_list=[3,4];
% for p=p_list
%     cmap=hsv(length(daylist));
%     for i=1:length(daylist)
%         if outputdata(p,i).numtrials>0
%             figure(p);
%             temp=squeeze(mean(outputdata(p,i).data,1));
%             plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%             hold on;
%             legendlabel{i}=['day',num2str(daylist(i))];
%             
%             if(daylist(i)==10)
%                 excel_filename='simple pellet PKI_avg.xlsx';
%                 
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename];
%                 xlswrite(filename,out,1);
%             end
%         end
%     end
%     figure(p);
%     title(figuretitle{p});
%     xlabel('time(s)');
%     ylabel('delta lifetime');
%     legend(legendlabel);
%     %hold off;
% end
%autoArrangeFigures();

%delete(findall(0,'Type','figure'));

%         stderror=std(dfoverf1,0,1)/sqrt(n);
%         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);