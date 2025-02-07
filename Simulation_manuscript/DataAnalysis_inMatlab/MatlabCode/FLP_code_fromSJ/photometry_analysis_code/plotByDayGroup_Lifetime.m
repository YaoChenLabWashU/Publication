%plot by day group (beginner, intermediate, trained)

clear all;

%mousenamelist = {'SJ185','SJ186','SJ187','SJ188'}; %D1 AKAR + dLight cohort
%mousenamelist = {'SJ184'}; %A2A AKAR + dLight cohort
%mousenamelist = {'SJ110','SJ136', 'SJ137', 'SJ138','SJ184'}; %A2A AKAR cohort
%mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ130','SJ91'}; %D1 AKAR
%mousenamelist = {'SJ184','SJ110','SJ136','SJ137','SJ138'}; %A2A AKAR
%mousenamelist = {'SJ149','SJ150','SJ151'}; %mAKAR cohort
%mousenamelist = {'SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'}; %mAKAR + AKAR cohort
%mousenamelist = {'SJ191_mAKAR','SJ192_mAKAR','SJ193_mAKAR','SJ194_mAKAR'}; %mAKAR + AKAR cohort
%mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ130','SJ91','SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'}; %D1 AKAR combined

%mousenamelist = {'SJ213','SJ214','SJ215','SJ216','SJ217','SJ218','SJ219','SJ220'};  
%mousenamelist = {'SJ213','SJ214','SJ215','SJ216'};  %D1 AKAR + dLight cohort
%mousenamelist = {'SJ217','SJ218','SJ219','SJ220'};  %A2A AKAR + dLight cohort

%mousenamelist = {'SJ243_AKAR','SJ244_AKAR','SJ245_AKAR','SJ246_AKAR','SJ247_AKAR','SJ248_AKAR'}; %A2A AKAR + mAKAr cohort
%mousenamelist = {'SJ243_mAKAR','SJ244_mAKAR','SJ245_mAKAR','SJ246_mAKAR','SJ247_mAKAR','SJ248_mAKAR'};
%weak AKAR signal: SJ243
%large AKAR signal: SJ244, SJ246, SJ248

%single trial usuable AKAR signal (D1): 213, 214, 215, 216 /214, 215
%single trial usable AKAR signal (A2A): 217?, 218, 219?,220  /217, 218

%mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'}; 
%mousenamelist = {'SJ185','SJ186','SJ187','SJ188'}; %D1 AKAR dLight
%mousenamelist = {'SJ181','SJ182','SJ183','SJ184'}; %A2A AKAR dLight

%mousenamelist = {'SJ213','SJ214','SJ215','SJ216','SJ217','SJ218','SJ219','SJ220'};
%mousenamelist = {'SJ213','SJ214','SJ215','SJ216'}; %D1 AKAR dLight
%mousenamelist = {'SJ217','SJ218','SJ219','SJ220'}; %A2A AKAR dLight

% mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ213','SJ214','SJ215','SJ216'}; %D1 Cre AKAR dLight
% group_name='D1';
% mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ217','SJ218','SJ219','SJ220'}; %A2A Cre AKAR dLight
% group_name='A2A';

% mousenamelist = {'SJ130','SJ91'}; %D1 Cre AKAR only
% group_name='D1';
% mousenamelist = {'SJ110','SJ136','SJ137','SJ138'}; %A2A Cre AKAR only
% group_name='A2A';

%D1 Cre AKAR dLight + D1 Cre AKAR only + D1 Cre AKAR/mAKAR
mousenamelist = {'SJ185','SJ186','SJ187','SJ188','SJ213','SJ214','SJ215','SJ216','SJ130','SJ91','SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'};
group_name='D1';

%A2A Cre AKAR dLight + A2A Cre AKAR only + A2A Cre AKAR/mAKAR
%mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ217','SJ218','SJ219','SJ220','SJ110','SJ136','SJ137','SJ138','SJ243_AKAR','SJ244_AKAR','SJ245_AKAR','SJ246_AKAR','SJ247_AKAR','SJ248_AKAR'}; %A2A Cre AKAR dLight
%group_name='A2A';

% var_name='z';
% figure_var_name='z score';
% var_name='dff';
% figure_var_name='dff(%)';
%var_name='norm_dff';
%figure_var_name='normalized dff';
var_name='dtau';
figure_var_name='delta lifetime';

ch_name={'dtau'};

num_days=13;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.5, 0.9]; %success rate criteria cutoff for intermediate and trained group
timebin=1;
timestamp=[-baseline_duration:timebin:duration-baseline_duration];

excel_filename='';

return;

%% Plotting average baseline period lifetime by each mouse
temp=zeros(length(mousenamelist),num_days);
for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'session_baseline_tau');
    
    session_baseline_tau=session_baseline_tau-session_baseline_tau(1);
    
    figure(1); plot(session_baseline_tau); hold on;
    
    temp(mouse,1:length(session_baseline_tau))=session_baseline_tau;
end

for i=1:num_days
    temp2=temp(:,i);
    temp2=temp2(temp2~=0);
    
    m(i)=mean(temp2);
    ste(i)=std(temp2)/sqrt(length(temp2));
end

figure(2); plot(1:num_days,m); hold on; errorbar(1:num_days,m,ste,ste);

return;

%% Plotting lifetime data by each mouse
close all;

cmap = colormap(hsv(length(group_criteria)+3));
idx=length(timestamp);
for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    legend_mark=zeros(9,num_days);

    %grouping days by success rate
    daylist=[];
    
    num_days=11;
    
    for i=1:length(group_criteria)
        if(i==1)
            idx_list=find(successrate>=max(successrate(1:num_days)*0.5));
            daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
        elseif i==2
            idx_list=find(successrate>=max(successrate(1:num_days)*0.9));
            daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
        end
    end
    
    daylist(end+1)=num_days;
    
    display(mousenamelist{mouse});
    display(daylist);
    display(['successrate criteria: ',num2str(max(successrate(1:num_days))*0.5),' ',num2str(max(successrate(1:num_days))*0.9)]);
    
%     daylist=[];
%     for i=1:length(group_criteria)
%         idx_list=find(successrate>=group_criteria(i));
%         daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
%     end
%     daylist(end+1)=num_days;

    for d=1:length(TrialData(1).ch_name)
        display(mousenamelist{mouse});
        display(TrialData(1).ch_name);

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

            display([num2str(idx_start),' ',num2str(idx_end)]);
            
            %no analysis needed if there was no day that fits the criteria
            if(i>=2 && daylist(i)==daylist(i-1))
                continue;
            end
            
            %skip these trials if dff
%             if strcmp(var_name,'dff')==1
%                 if(strcmp(mousenamelist{mouse},'SJ281')==1 && daylist(i)>=10 && d==3)
%                     for j=idx_start:length(TrialData)
%                         if TrialData(j+1).day>=10
%                             idx_end=j;
%                             break;
%                         end
%                     end
%                     
%                     display([num2str(idx_start),' : ',num2str(idx_end)]);
%                 end
%             end
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if size(output,1)>0
                figure(1);
                title([figure_var_name,' vs. time(s): 0s = LED on']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(1,i)=1;
                
                %plot 10 example individual trials for trained animals
                if(i==3)
                    cmap2=hsv(10);
                    for k=1:10
                        mag_time=[-baseline_duration:timebin:baseline_duration];
                        l=length(mag_time);
                        
                        figure(20);
                        plot(mag_time,output(size(output,1)-k+1,1:l),'color',cmap2(k,:));
                        title(['0s=LED on, 10 example individual trials (',mousenamelist{mouse},')']);
                        xlabel('time(s)');
                        ylabel(figure_var_name);
                        hold on;
                    end
                end
            end

            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1 2],idx_start,idx_end);
            if size(output,1)>0
                figure(2);
                title([figure_var_name,' vs. time(s): 0s = LED zone entering']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(2,i)=1;
            end

            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title([figure_var_name,' vs. time(s): 0s = pellet dispensed']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
                
                %plotting individual trials
%                 if (i==1)
%                     num_lines=5;
%                     cmap2=cbrewer('div','RdYlBu',num_lines);
%                     %cmap2=hsv(size(output,1));
%                     %for j=1:size(output,1)
%                     for j=1:num_lines
%                         figure(21);
%                         plot(timestamp,output(j,1:length(timestamp)),'color',cmap2(j,:));
%                         title(['reward response: ',TrialData(1).ch_name{d}]);
%                         ylabel(figure_var_name);
%                         xlabel('time(s)');
%                         xlim([-10 10]);
%                         set(gca,'FontSize',14);
%                         hold on;
%                     end
%                     hold off;
%                 end
            end

            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title([figure_var_name,' vs. time(s): 0s = receptacle entry']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;
% 
%                 %plotting individual trials
                if (i==3)
                    num_lines=min(10,size(output,1));
                    cmap2=cbrewer('div','RdYlBu',num_lines);
                    %cmap2=hsv(size(output,1));
                    %for j=1:size(output,1)
                    for j=1:num_lines
                        figure(21);
                        plot(timestamp,output(j,1:length(timestamp)),'color',cmap2(j,:));
                        %title(['reward response: ',TrialData(1).ch_name{d}]);
                        ylabel(figure_var_name);
                        xlabel('time(s)');
                        xlim([-20 20]);
                        set(gca,'FontSize',14);
                        hold on;
                    end
                    hold off;
                end
            end

            %df/f aligned to LED. split into successful entry vs. no-entry trial
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(5);
                title([figure_var_name,' vs. time(s): 0s = LED on (successful entry trials)']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(5,i)=1;
            end

            output=selectTrialData(TrialData,[var_name,'_LED'],d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                figure(6);
                title([figure_var_name,' vs. time(s): 0s = LED on (no-entry trials)']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(6,i)=1;
            end

            %df/f aligned to zone entering. split into reward vs. no-reward trials
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(7);
                title([figure_var_name,' vs. time(s): 0s = zone entering (reward trials)']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(7,i)=1;
            end

            output=selectTrialData(TrialData,[var_name,'_zone'],d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(8);
                title([figure_var_name,' vs. time(s): 0s = zone entering (no reward trials)']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(8,i)=1;
            end
            
%             %df/f aligned to receptacle entry subtract value at 0 to look
%             %at delta peak
%             output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[1],idx_start,idx_end);
%             if(size(output,1)>0)
%                 for k=1:size(output,1)
%                     output(k,:)=output(k,:)-output(k,round(baseline_duration*1000/timebin));
%                 end
%                 temp=mean(output,1);
%                 figure(9); plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%                 title([figure_var_name,' vs. time(s): 0s = receptacle entry (subtraction)']);
%                 hold on;
%                 legend_mark(9,i)=1;
%             end

            idx_start=idx_end+1;
        end

        for i=1:8
            figure(i);
            legend(legend_maker(legend_mark(i,:),'group_day'));
        end

        autoArrangeFigures();
        %delete(findall(0,'Type','figure'));

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

        if(idx_start>0 && idx_end>0)
            i=length(daylist)+1;

            %dff aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                figure(1);
                title([figure_var_name,' vs. time(s): 0s = LED on']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(1,i)=1;
            end

            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(2);
                title([figure_var_name,' vs. time(s): 0s = LED zone entering']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(2,i)=1;
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title([figure_var_name,' vs. time(s): 0s = pellet dispensed']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title([figure_var_name,' vs. time(s): 0s = receptacle entry']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;
            end
        end
        
        %LED omission trial analysis
        idx_start=-1;
        for j=1:length(TrialData)
            if TrialData(j).day==13 && idx_start==-1
                idx_start=j;
                break;
            end
        end
        idx_end=length(TrialData);

        display([num2str(idx_start),' ',num2str(idx_end)]);

        if(idx_start>0 && idx_end>0)
            i=length(daylist)+2;

            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[5 6 7],idx_start,idx_end); %plot dff_LED for all trial types
            figure(1);
            title([figure_var_name,' vs. time(s): 0s = LED on']);
            temp=mean(output,1);
            plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
            hold on;
            legend_mark(1,i)=1;

            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[5 6],idx_start,idx_end);
            figure(2);
            title([figure_var_name,' vs. time(s): 0s = LED zone entering']);
            temp=mean(output,1);
            plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
            hold on;
            legend_mark(2,i)=1;

            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[5],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title([figure_var_name,' vs. time(s): 0s = pellet dispensed']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
            end

            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[5],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title([figure_var_name,' vs. time(s): 0s = receptacle entry']);
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;
            end
        end        

        for i=1:9
            figure(i);
            legend(legend_maker(legend_mark(i,:),'group_day+3'));
            xlabel('time(s)');
            ylabel(figure_var_name);
        end

        autoArrangeFigures();
        %xls = fig2excel2(xls,figurelist,mousenamelist(mouse), TrialData(1).ch_name(d), TrialData, 'individual mice figure.xlsx');

        delete(findall(0,'Type','figure'));
    end
end

return;

 %% lifetime across many mice: comparing reward omission trials, no normalization, 
 % CI from bootstrapping using the sample size of the lowest trial number
 % condition

cmap = colormap(hsv(length(group_criteria)+3));

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;

figuretitle{1}=[var_name,' vs. time(s): 0s = LED on'];
figuretitle{2}=[var_name,' vs. time(s): 0s = LED zone entering'];
figuretitle{3}=[var_name,' vs. time(s): 0s = pellet dispensed'];
figuretitle{4}=[var_name,' vs. time(s): 0s = receptacle entry'];
figuretitle{5}=[var_name,' vs. time(s): 0s = LED on (successful entry trials)'];
figuretitle{6}=[var_name,' vs. time(s): 0s = LED on (no-entry trials)'];
figuretitle{7}=[var_name,' vs. time(s): 0s = zone entering (reward trials)'];
figuretitle{8}=[var_name,' vs. time(s): 0s = zone entering (no reward trials)'];
figuretitle{9}=[var_name,' vs. time(s): 0s = LED on, rewarded trial'];
figuretitle{10}=[var_name,' vs. time(s): 0s = LED on, no-reward trial'];

filetitle{1}=[var_name,' LED on'];
filetitle{2}=[var_name,' LED zone entering'];
filetitle{3}=[var_name,' pellet dispensed'];
filetitle{4}=[var_name,' receptacle entry'];
filetitle{5}=[var_name,' LED on (successful entry trials)'];
filetitle{6}=[var_name,' LED on (no-entry trials)'];
filetitle{7}=[var_name,' zone entering (reward trials)'];
filetitle{8}=[var_name,' zone entering (no reward trials)'];
filetitle{9}=[var_name,' LED (reward tirals)'];
filetitle{10}=[var_name,' LED (no reward trials)'];

% for i=1:plot_num
%     for j=1:length(group_criteria)+2
%         outputdata(i,j).numtrials=0;
%     end
% end

for d=1:length(TrialData(1).ch_name)
    for i=1:plot_num
        for j=1:length(group_criteria)+3
            outputdata(i,j).numtrials=0;
            outputdata(i,j).data=[];
        end
    end
    
    for mouse=1:length(mousenamelist) 
        display(mousenamelist{mouse});
        
        filename = ['analysis_',mousenamelist{mouse},'.mat'];
        load(filename,'TrialData','successrate');
        
        %grouping days by success rate
        daylist=[];
        num_days=11;
        
        for i=1:length(group_criteria)
            if(i==1)
                idx_list=find(successrate>=max(successrate(1:num_days)*0.5));
                daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
            elseif i==2
                idx_list=find(successrate>=max(successrate(1:num_days)*0.9));
                daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
            end
        end
        
        daylist(end+1)=num_days;
        
        display(mousenamelist{mouse});
        display(daylist);
        display(['successrate criteria: ',num2str(max(successrate(1:num_days))*0.5),' ',num2str(max(successrate(1:num_days))*0.9)]);
        
        %grouping days by success rate
%         daylist=[];
%         for i=1:length(group_criteria)
%             idx_list=find(successrate>=group_criteria(i));
%             daylist(i)=max(idx_list(1)-1,1); %the first category should include at least upto 1st day
%         end
%         daylist(end+1)=num_days;
        
        %daylist=[2 4 11]; %using simple day number instead of criteria, proxy for 40%, 70%
        %daylist=[2 5 11]; %using simple day number instead of criteria, proxy for 40%, 80%
        
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
            
            display([num2str(idx_start),' : ',num2str(idx_end)]);
            
            %no analysis needed if there was no day that fits the criteria
            if(i>=2 && daylist(i)==daylist(i-1))
                continue;
            end
            
            %skip these trials if dff
%             if strcmp(var_name,'dff')==1
%                 if(strcmp(mousenamelist{mouse},'SJ281')==1 && daylist(i)>=10 && d==3)
%                     for j=idx_start:length(TrialData)
%                         if TrialData(j+1).day>=10
%                             idx_end=j;
%                             break;
%                         end
%                     end
%                     
%                     display([num2str(idx_start),' : ',num2str(idx_end)]);
%                 end
%             end
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %trial
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED split into reward vs no reward trial
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[2 3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
            end
            
            idx_start=idx_end+1;
        end
        
        %Reward omission trial analysis
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
        
        if(idx_start>0 && idx_end>0)
            i=length(daylist)+1;
            %dff aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);;
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);;
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);;
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
        end
        
        %LED omission trial analysis
        idx_start=-1;
        for j=1:length(TrialData)
            if TrialData(j).day==13 && idx_start==-1
                idx_start=j;
                break;
            end
        end
        idx_end=length(TrialData);

        display([num2str(idx_start),' ',num2str(idx_end)]);
        
        if(idx_start>0 && idx_end>0)
            i=length(daylist)+2;
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[5 6 7],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[5 6],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[5],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[5],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
        end
    end

    legend_mark=zeros(plot_num,length(daylist)+2);
    p_list=[1:10];
    for p=p_list
%         temp=[];
%         for i=1:length(daylist)+2
%             if( outputdata(p,i).numtrials > 0)
%                 temp(i)=outputdata(p,i).numtrials;
%             end
%         end
%         sample_size=min(temp);
        
        cmap=hsv(length(daylist)+2);
        out=timestamp';        
        
        for i=1:length(daylist)+2         
            display(outputdata(p,i).numtrials);
            if outputdata(p,i).numtrials>0
                
                %bootstrapping from entire trial from all mice
%                 m=squeeze(mean(outputdata(p,i).data,1));
%                 n_boot=1000;
%                 bootstat = bootstrp(n_boot,@mean,outputdata(p,i).data);
%                 for j=1:size(outputdata(p,i).data,2)
%                     delta_mean=m(j)-bootstat(:,j);
%                     delta_mean=sort(delta_mean);
%                     CI(j,1)=abs(delta_mean(round(n_boot*0.025)));
%                     CI(j,2)=delta_mean(round(n_boot*0.975));
%                 end
%                 figure(p);
%                 l=length(timestamp);
%                 plot(timestamp,m(1:length(timestamp)),'color',cmap(i,:));
%                 %confplot(timestamp,m(1:l),CI(1:l,1)',CI(1:l,2)','color',cmap(i,:));
%                 hold on;                
%                 out=[out,m',CI];
                
                figure(p);
                temp=squeeze(mean(outputdata(p,i).data,1));               
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
%                 ste=std(outputdata(p,i).data,0,1)/sqrt(outputdata(p,i).numtrials);
%                 N=ones(size(outputdata(p,i).data,2),1) * outputdata(p,i).numtrials;
%                 out=[out,mean(outputdata(p,i).data,1)',ste',N];

                legend_mark(p,i)=1;
                legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+3');
                
%                 figure(20+p);
%                 l=length(timestamp);
%                 confplot(timestamp,temp(1:l),ste(1:l),ste(1:l),'color',[1 0 0]);
                
%                 if(p==1 && i==3)
%                     %plotting standard deviation for LED on plot
%                     figure(11);
%                     mag_time=[-baseline_duration:timebin/1000:baseline_duration];
%                     dev=std(outputdata(p,i).data,1);
%                     l=length(mag_time);
%                     confplot(mag_time,temp(1:l),dev(1:l),dev(1:l),'color',[1 0 0]);
%                     title([figuretitle{1},': trained animals']);
%                     xlabel('time(s)');
%                     ylabel('df/f');
%                 end
                
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+3'));
        %legend(legend_maker(legend_mark(p,:),'group_day'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel(figure_var_name);
        hold off;
        
        %autoArrangeFigures();
        
%         filename=[filetitle{p},'_bootstrap_',TrialData(1).ch_name{d},'.xlsx'];
%         xlswrite(filename,out,1);
    end

    %plotting individual trials
%     p_list=[1 2 3 4];
%     for p=p_list
%         cmap=hsv(size(outputdata(p,4).data,1));
%         for i=1:size(outputdata(p,4).data,1)
%             figure(p);
%             plot(timestamp,outputdata(p,4).data(i,:),'color',cmap(i,:));
%             hold on;
%         end
%         hold off;
%     end
    
    autoArrangeFigures();
    %xls = fig2excel2(xls,figurelist,mousenamelist(mouse), TrialData(1).ch_name(d), TrialData, 'averged figure.xlsx');
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

return;

%% lifetime across many mice: comparing reward omission trials, no normalization, SEM across mouse average
close all;

cmap = colormap(hsv(length(group_criteria)+3));
idx = length(timestamp);

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=11;

figuretitle{1}=[var_name,' vs. time(s): 0s = LED on'];
figuretitle{2}=[var_name,' vs. time(s): 0s = LED zone entering'];
figuretitle{3}=[var_name,' vs. time(s): 0s = pellet dispensed'];
figuretitle{4}=[var_name,' vs. time(s): 0s = receptacle entry'];
figuretitle{5}=[var_name,' vs. time(s): 0s = LED on (successful entry trials)'];
figuretitle{6}=[var_name,' vs. time(s): 0s = LED on (no-entry trials)'];
figuretitle{7}=[var_name,' vs. time(s): 0s = zone entering (reward trials)'];
figuretitle{8}=[var_name,' vs. time(s): 0s = zone entering (no reward trials)'];
figuretitle{9}=[var_name,' vs. time(s): 0s = LED on, rewarded trial'];
figuretitle{10}=[var_name,' vs. time(s): 0s = LED on, no-reward trial'];
figuretitle{11}=[var_name,' vs. time(s): 0s = LED on (premature exit)'];

filetitle{1}=[var_name,' LED on'];
filetitle{2}=[var_name,' LED zone entering'];
filetitle{3}=[var_name,' pellet dispensed'];
filetitle{4}=[var_name,' receptacle entry'];
filetitle{5}=[var_name,' LED on (successful entry trials)'];
filetitle{6}=[var_name,' LED on (no-entry trials)'];
filetitle{7}=[var_name,' zone entering (reward trials)'];
filetitle{8}=[var_name,' zone entering (no reward trials)'];
filetitle{9}=[var_name,' LED (reward tirals)'];
filetitle{10}=[var_name,' LED (no reward trials)'];
filetitle{11}=[var_name,' LED (premature exit trials)'];


% for i=1:plot_num
%     for j=1:length(group_criteria)+2
%         outputdata(i,j).numtrials=0;
%     end
% end

for d=1:length(TrialData(1).ch_name)
    for i=1:plot_num
        for j=1:length(group_criteria)+3
            outputdata(i,j).numtrials=0;
            outputdata(i,j).data=[];
        end
    end
    
    for mouse=1:length(mousenamelist) 
        display(mousenamelist{mouse});
        
        filename = ['analysis_',mousenamelist{mouse},'.mat'];
        load(filename,'TrialData','successrate');

        %grouping days by success rate
        daylist=[];
        
        num_days=11;
        
        for i=1:length(group_criteria)
            if(i==1)
                idx_list=find(successrate>=max(successrate(1:num_days)*0.5));
                daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
            elseif i==2
                idx_list=find(successrate>=max(successrate(1:num_days)*0.9));
                daylist(i)=max(idx_list(1)-1,1); %the first category should include at least 1st day
            end
        end
        
        daylist(end+1)=num_days;
        if length(successrate)<11
            daylist(end+1)=9;
            display('error');
        end
        
        display(mousenamelist{mouse});
        display(daylist);
        display(['successrate criteria: ',num2str(max(successrate(1:num_days))*0.5),' ',num2str(max(successrate(1:num_days))*0.9)]);
        
        %grouping days by success rate
%         daylist=[];
%         for i=1:length(group_criteria)
%             idx_list=find(successrate>=group_criteria(i));
%             daylist(i)=max(idx_list(1)-1,1); %the first category should include at least upto 1st day
%         end
%         daylist(end+1)=num_days;
        
        %daylist=[2 4 11]; %using simple day number instead of criteria, proxy for 40%, 70%
        %daylist=[2 5 11]; %using simple day number instead of criteria, proxy for 40%, 80%
        
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
            
            display([num2str(idx_start),' : ',num2str(idx_end)]);
            
            %no analysis needed if there was no day that fits the criteria
            if(i>=2 && daylist(i)==daylist(i-1))
                continue;
            end
            
            %skip these trials if dff
%             if strcmp(var_name,'dff')==1
%                 if(strcmp(mousenamelist{mouse},'SJ281')==1 && daylist(i)>=10 && d==3)
%                     for j=idx_start:length(TrialData)
%                         if TrialData(j+1).day>=10
%                             idx_end=j;
%                             break;
%                         end
%                     end
%                     
%                     display([num2str(idx_start),' : ',num2str(idx_end)]);
%                 end
%             end
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>1)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + 1;
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1 2],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(2,i).data(outputdata(2,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + 1;
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[1],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(3,i).data(outputdata(3,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + 1;
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[1],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(4,i).data(outputdata(4,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + 1;
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %vs. premature exit trial
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1 2],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(5,i).data(outputdata(5,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(5,i).numtrials = outputdata(5,i).numtrials + 1;
            end
            
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[3],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(6,i).data(outputdata(6,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(6,i).numtrials = outputdata(6,i).numtrials + 1;
            end
            
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[2],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(11,i).data(outputdata(11,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(11,i).numtrials = outputdata(11,i).numtrials + 1;
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[1],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(7,i).data(outputdata(7,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(7,i).numtrials = outputdata(7,i).numtrials + 1;
            end
            
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[2],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(8,i).data(outputdata(8,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(8,i).numtrials = outputdata(8,i).numtrials + 1;
            end
            
            %df/f aligned to LED split into reward vs no reward trial
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[1],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(9,i).data(outputdata(9,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(9,i).numtrials = outputdata(9,i).numtrials + 1;
            end
            
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[2 3],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(10,i).data(outputdata(10,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(10,i).numtrials = outputdata(10,i).numtrials + 1;
            end
            
            idx_start=idx_end+1;
        end
        
        %skip these trials
        if length(successrate)<11
            continue;
        end

        %Reward omission trial analysis
        idx_start=-1;
        if strcmp(mousenamelist{mouse},'SJ191_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ192_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ193_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ194_AKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==12 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==14
                    idx_end=j-1;
                    break;
                end
            end
        elseif strcmp(mousenamelist{mouse},'SJ191_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ192_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ193_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ194_mAKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==13 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==14
                    idx_end=j-1;
                    break;
                end
            end
        elseif strcmp(mousenamelist{mouse},'SJ243_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ244_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ245_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ246_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ247_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ248_AKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==12 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==14
                    idx_end=j-1;
                    break;
                end
            end
        elseif strcmp(mousenamelist{mouse},'SJ243_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ244_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ245_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ246_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ247_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ248_mAKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==13 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==14
                    idx_end=j-1;
                    break;
                end
            end
        else
            for j=1:length(TrialData)
                if TrialData(j).day==12 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==13
                    idx_end=j-1;
                    break;
                end
            end
            if(TrialData(j).day~=13)
                idx_end=length(TrialData);
            end
        end
        display([num2str(idx_start),' ',num2str(idx_end)]);
        
        if(idx_start>0 && idx_end>0)
            i=length(daylist)+1;
            %dff aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>1)
                outputdata(1,i).data(outputdata(1,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + 1;
            end
            
            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[4],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(2,i).data(outputdata(2,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + 1;
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[4],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(3,i).data(outputdata(3,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + 1;
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[4],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(4,i).data(outputdata(4,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + 1;
            end
        end
        
        %LED omission trial analysis
        idx_start=-1;
        if strcmp(mousenamelist{mouse},'SJ191_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ192_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ193_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ194_AKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==14 && idx_start==-1
                    idx_start=j;
                    break;
                end
            end
            idx_end=length(TrialData);
        elseif strcmp(mousenamelist{mouse},'SJ191_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ192_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ193_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ194_mAKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==14 && idx_start==-1
                    idx_start=j;
                    break;
                end
            end
            idx_end=length(TrialData);
        elseif strcmp(mousenamelist{mouse},'SJ243_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ244_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ245_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ246_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ247_AKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ248_AKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==14 && idx_start==-1
                    idx_start=j;
                    break;
                end
            end
            idx_end=length(TrialData);
        elseif strcmp(mousenamelist{mouse},'SJ243_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ244_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ245_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ246_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ247_mAKAR')==1 || ...
                strcmp(mousenamelist{mouse},'SJ248_mAKAR')==1
            for j=1:length(TrialData)
                if TrialData(j).day==14 && idx_start==-1
                    idx_start=j;
                    break;
                end
            end
            idx_end=length(TrialData);
        else
            for j=1:length(TrialData)
                if TrialData(j).day==13 && idx_start==-1
                    idx_start=j;
                    break;
                end
            end
            idx_end=length(TrialData);
        end
        display([num2str(idx_start),' ',num2str(idx_end)]);
        
        if(idx_start>0 && idx_end>0)
            i=length(daylist)+2;
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,[var_name,'_LED'],d,[5 6 7],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>1)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + 1;
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,[var_name,'_zone'],d,[5 6],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(2,i).data(outputdata(2,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + 1;
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,[var_name,'_dispense'],d,[5],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(3,i).data(outputdata(3,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + 1;
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,[var_name,'_receptacle'],d,[5],idx_start,idx_end);
            if(size(output,1)>1)
                outputdata(4,i).data(outputdata(4,i).numtrials+1,:)=mean(output(:,1:idx),1); %record mouse average
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + 1;
                
                if(mouse==3)
                    cmap2=hsv(size(output,1));
                    for j=1:size(output,1)
                        figure(100);
                        plot(timestamp,output(j,:),'color',cmap2(j,:)); hold on;
                    end
                end
            end
        end
    end
    
    legend_mark=zeros(plot_num,length(daylist)+2);
    p_list=[1:11];
    for p=p_list
        cmap=hsv(length(daylist)+2);
        out=timestamp';        
        for i=1:length(daylist)+2            
            if outputdata(p,i).numtrials>0
                figure(p);
                temp=squeeze(mean(outputdata(p,i).data,1));               
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                
                legend_mark(p,i)=1;
                legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+3');
                
                ste=std(outputdata(p,i).data,0,1)/sqrt(outputdata(p,i).numtrials);
                N=ones(size(outputdata(p,i).data,2),1) * outputdata(p,i).numtrials;
                out=[out,mean(outputdata(p,i).data,1)',ste',N];
                
                if (p==4 && i==5)
                    figure(20+p);
                    l=length(timestamp);
                    confplot(timestamp,temp(1:l),ste(1:l),ste(1:l),'color',[1 0 0]);
                    
                    cmap2=hsv(outputdata(p,i).numtrials);
                    for j=1:outputdata(p,i).numtrials
                        figure(100);
                        plot(timestamp,outputdata(p,i).data(j,:),'color',cmap2(j,:)); hold on;
                    end
                end
                
%                 if(p==1 && i==6)
%                     %plotting standard deviation for LED on plot
%                     figure(11);
%                     mag_time=[-baseline_duration:timebin/1000:baseline_duration];
%                     dev=std(outputdata(p,i).data,1);
%                     l=length(mag_time);
%                     confplot(mag_time,temp(1:l),dev(1:l),dev(1:l),'color',[1 0 0]);
%                     title([figuretitle{1},': trained animals']);
%                     xlabel('time(s)');
%                     ylabel('df/f');
%                 end
                
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+3'));
        %legend(legend_maker(legend_mark(p,:),'group_day'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel(figure_var_name);
        hold off;
        
        %autoArrangeFigures();
        
        filename=[group_name,'_',filetitle{p},'_AKAR.xlsx'];
        xlswrite(filename,out,1);
    end

    %plotting individual trials
%     p_list=[1 2 3 4];
%     for p=p_list
%         cmap=hsv(size(outputdata(p,4).data,1));
%         for i=1:size(outputdata(p,4).data,1)
%             figure(p);
%             plot(timestamp,outputdata(p,4).data(i,:),'color',cmap(i,:));
%             hold on;
%         end
%         hold off;
%     end
    
    autoArrangeFigures();
    %xls = fig2excel2(xls,figurelist,mousenamelist(mouse), TrialData(1).ch_name(d), TrialData, 'averged figure.xlsx');
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

return;

