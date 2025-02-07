%plot by day group (beginner, intermediate, trained)

clear all;
%dataname={'AD1_','AD2_','AD3_'};
%ch_name={'dLight'};
%mousenamelist = {'SJ149','SJ150','SJ151'}; %mAKAR cohort
%mousenamelist = {'SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'}; %mAKAR + AKAR cohort
%mousenamelist = {'SJ191_mAKAR','SJ192_mAKAR','SJ193_mAKAR','SJ194_mAKAR'}; %mAKAR + AKAR cohort
%mousenamelist = {'SJ149','SJ150','SJ151','SJ191_mAKAR','SJ192_mAKAR','SJ193_mAKAR','SJ194_mAKAR'}; %D1 mAKAR combined
mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ130','SJ91','SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'}; %D1 AKAR combined

num_days=12;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group

inputrate=1000; %in Hz
timebin=500; %timebin in msec per data point

excel_filename='\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\20181027 data summary\excel files\D1 AKAR combined';

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
        
        %no analysis needed if there was no day that fits the criteria
        if(i>=2 && daylist(i)==daylist(i-1))
            continue;
        end
        
        %dtau aligned to LED
        output=selectTrialData(TrialData,'dtau_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
        if(size(output,1)>0)
            outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED zone entry
        output=selectTrialData(TrialData,'dtau_zone',d,[1 2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
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
        
        %dtau aligned to LED. split into successful entry vs. no-entry
        %trial
        output=selectTrialData(TrialData,'dtau_LED',d,[1 2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'dtau_LED',d,[3],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
        end
        
        %dtau aligned to zone entering. split into reward vs. no-reward
        %trials
        output=selectTrialData(TrialData,'dtau_zone',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'dtau_zone',d,[2],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED split into reward vs no reward trial
        output=selectTrialData(TrialData,'dtau_LED',d,[1],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
        end
        
        output=selectTrialData(TrialData,'dtau_LED',d,[2 3],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
        end
        
        idx_start=idx_end+1;
    end
    
    %omission trial analysis
    if strcmp(mousenamelist{mouse},'SJ191_mAKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ192_mAKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ193_mAKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ194_mAKAR')==1 
        idx_start=-1;
        for j=1:length(TrialData)
            if TrialData(j).day==13 && idx_start==-1
                idx_start=j;
            end
            if TrialData(j).day==14
                idx_end=j-1;
                break;
            end
        end
        if TrialData(j).day~=14
            idx_end=length(TrialData);
        end
    elseif strcmp(mousenamelist{mouse},'SJ191_AKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ192_AKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ193_AKAR')==1 || ...
        strcmp(mousenamelist{mouse},'SJ194_AKAR')==1 
        idx_start=-1;
        for j=1:length(TrialData)
            if TrialData(j).day==12 && idx_start==-1
                idx_start=j;
            end
            if TrialData(j).day==14
                idx_end=j-1;
                break;
            end
        end
        if TrialData(j).day~=14
            idx_end=length(TrialData);
        end
    else
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
        output=selectTrialData(TrialData,'dtau_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
        if(size(output,1)>0)
            outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
        end
        
        %dtau aligned to LED zone entry
        output=selectTrialData(TrialData,'dtau_zone',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
        end
        
        %dtau aligned to pellet dispensing
        output=selectTrialData(TrialData,'dtau_dispense',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
        end
        
        %dtau aligned to receptacle entry
        output=selectTrialData(TrialData,'dtau_receptacle',d,[4],idx_start,idx_end);
        if(size(output,1)>0)
            outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
            outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
        end
    end
end

    legend_mark=zeros(plot_num,length(daylist)+1);
    p_list=[1,4];
    for p=p_list
        cmap=hsv(length(daylist)+1);
        for i=1:length(daylist)+1            
            if outputdata(p,i).numtrials>0
                figure(p);
                temp=squeeze(mean(outputdata(p,i).data,1));               
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;

                legend_mark(p,i)=1;
                legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+2');
                
                out=timestamp';
                out=[out,squeeze(outputdata(p,i).data)'];
                filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
                xlswrite(filename,out,1);
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+2'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel('delta lifetime');
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