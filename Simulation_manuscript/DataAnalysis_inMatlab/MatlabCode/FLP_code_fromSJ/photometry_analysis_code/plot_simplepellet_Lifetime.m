%plot by day group (beginner, intermediate, trained)

clear all;

%mousenamelist = {'SJ243_LED','SJ244_LED','SJ245_LED','SJ246_LED','SJ247_LED','SJ248_LED'};
%mousenamelist = {'SJ243_pellet','SJ244_pellet','SJ245_pellet','SJ246_pellet','SJ247_pellet','SJ248_pellet'};
%mousenamelist = {'SJ243_LED_D2Rant','SJ244_LED_D2Rant','SJ245_LED_D2Rant','SJ246_LED_D2Rant','SJ247_LED_D2Rant','SJ248_LED_D2Rant'};
%mousenamelist = {'SJ243_pellet_D2Rant','SJ244_pellet_D2Rant','SJ245_pellet_D2Rant','SJ246_pellet_D2Rant','SJ247_pellet_D2Rant','SJ248_pellet_D2Rant'};

%mousenamelist = {'SJ245_LED','SJ246_LED','SJ247_LED','SJ248_LED'};
%mousenamelist = {'SJ245_pellet','SJ246_pellet','SJ247_pellet','SJ248_pellet'};
%mousenamelist = {'SJ245_LED_D2Rant','SJ246_LED_D2Rant','SJ247_LED_D2Rant','SJ248_LED_D2Rant'};
%mousenamelist = {'SJ245_pellet_D2Rant','SJ246_pellet_D2Rant','SJ247_pellet_D2Rant','SJ248_pellet_D2Rant'};

%filelist = [1 3 2 4 5 6];
%mousenamelist = {'SJ91','SJ110','SJ130','SJ136','SJ137','SJ138'};

%filelist = [1 2];
%mousenamelist = {'SJ91','SJ110'};

%filelist = [3 4 5 6];
%mousenamelist = {'SJ110','SJ136','SJ137','SJ138'};

% filelist = [1 2 3 4];
% mousenamelist = {'SJ191','SJ192','SJ193','SJ194'};

% filelist = [1 2 3 4];
% mousenamelist = {'SJ181','SJ182','SJ183','SJ184'};

filelist = [5 6 7 8];
mousenamelist = {'SJ185','SJ186','SJ187','SJ188'};

num_days=1;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group

inputrate=1000; %in Hz
timebin=500; %timebin in msec per data point

%excel_filename='A2A AKAR_LED_D2Rant';
%excel_filename='A2A AKAR_pellet_D2Rant';
%excel_filename='A2A AKAR_pellet';
excel_filename='D1 AKAR_pellet';

%% Plotting lifetime data by each mouse
timebin=1;
timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);
cmap=hsv(length(group_criteria)+1);

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    legend_mark=zeros(8,num_days);

    daylist=[0];
    for d=1:size(TrialData(1).ch_name,1)
        display(mousenamelist{mouse});
        
        idx_start=1; idx_end=10;
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
            
            %no analysis needed if there was no day that fits the criteria
            if(i>=2 && daylist(i)==daylist(i-1))
                continue;
            end
            
            %dtau aligned to pellet dispensing
            output=selectTrialData(TrialData,'dtau_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                temp=mean(output,1);             
                figure(3);
                plot(timestamp,temp(1:idx),'color',cmap(i,:));
                title('delta lifetime(ns) vs. time(s): 0s = pellet dispensed');
                hold on;
                legend_mark(3,i)=1;
                
                cmap2=hsv(size(output,1));
                for j=1:size(output,1)
                    figure(13);
                    plot(timestamp,output(j,1:idx),'color',cmap2(j,:));
                    hold on;
                end
                figure(13);
                title('delta lifetime(ns) vs. time(s): 0s = pellet dispensed');
            end
            
            %dtau aligned to receptacle entry
            output=selectTrialData(TrialData,'dtau_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                temp=mean(output,1);             
                figure(4);
                plot(timestamp,temp(1:idx),'color',cmap(i,:));
                title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
                hold on;
                legend_mark(4,i)=1;
                
                cmap2=hsv(size(output,1));
                for j=1:size(output,1)
                    figure(14);
                    plot(timestamp,output(j,1:idx),'color',cmap2(j,:));
                    hold on;
                end
                figure(14);
                title('delta lifetime(ns) vs. time(s): 0s = receptacle entry');
            end
            
            idx_start=idx_end+1;
        end
        
        for i=15:20
            figure(i);
        end
        
        autoArrangeFigures();
        delete(findall(0,'Type','figure'));
    end
end

return;

%% Plotting lifetime across mice (group all mice's data): comparing omission trials
filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;
timebin=1;
num_days=12;

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

d=1;
for i=1:plot_num
    for j=1:length(group_criteria)+2
        outputdata(i,j).numtrials=0;
    end
end

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
        
    daylist=[0];
    
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
        
        %no analysis needed if there was no day that fits the criteria
        if(i>=2 && daylist(i)==daylist(i-1))
            continue;
        end
        
        %dtau aligned to pellet dispensing
        output=selectTrialData(TrialData,'dtau_dispense',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
        end
        
        %dtau aligned to receptacle entry
        output=selectTrialData(TrialData,'dtau_receptacle',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
        end
        
        idx_start=idx_end+1;
    end
end

legend_mark=zeros(plot_num,length(daylist)+1);
p_list=[3,4];
for p=p_list
    cmap=hsv(length(daylist)+1);
    for i=1:length(daylist)
        if outputdata(p,i).numtrials>0
            display(size(outputdata(p,i).data,1));
            
            figure(p);
            temp=squeeze(mean(outputdata(p,i).data,1));
            ste=std(outputdata(p,i).data,1)/sqrt(length(outputdata(p,i).data));
            confplot(timestamp,temp(1:length(timestamp)),ste(1:length(timestamp)),ste(1:length(timestamp)),'color',[1 0 0],'LineWidth',2);
            
            %plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
            hold on;
            
            %                 legend_mark(p,i)=1;
            %                 legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+2');
            
            out=timestamp';
            out=[out,squeeze(outputdata(p,i).data)'];
            filename=[excel_filename,'_',filetitle{p},'.xlsx'];
            xlswrite(filename,out,1);
        end
    end
    figure(p);
    %legend(legend_maker(legend_mark(p,:),'group_day+2'));
    title(figuretitle{p});
    xlabel('time(s)');
    ylabel('delta lifetime(ns)');
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
%delete(findall(0,'Type','figure'));
%         stderror=std(dfoverf1,0,1)/sqrt(n);
%         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);