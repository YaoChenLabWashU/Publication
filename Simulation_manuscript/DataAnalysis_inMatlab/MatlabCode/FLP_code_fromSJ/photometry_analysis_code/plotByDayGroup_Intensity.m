%plot by day group (beginner, intermediate, trained)

clear all;
mousenamelist = {'SJ207','SJ208','SJ209','SJ210'};

num_days=12;
duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group

inputrate=1000; %in Hz
timebin=40; %timebin in msec per data point

excel_filename='\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\20181027 data summary\excel files\bilateral dLight cohort';

timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

%% Plotting intensity data by each mouse
cmap = colormap(hsv(length(group_criteria)+2));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);
for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    legend_mark=zeros(8,num_days);

    daylist=[];
    for i=1:length(group_criteria)
        idx_list=find(successrate>=group_criteria(i));
        daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
    end
    daylist(end+1)=num_days;

    for d=1:length(TrialData(1).ch_name);
        display(mousenamelist{mouse});
        display(TrialData(1).ch_name{d});

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

            %df/f aligned to LED
            output=selectTrialData(TrialData,'dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            figure(1);
            title('df/f(%) vs. time(s): 0s = LED on');
            temp=mean(output,1);
            plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
            hold on;
            legend_mark(1,i)=1;
            
            %plot 10 example individual trials for trained animals
            if(i==3)
                cmap2=hsv(10);
                for k=1:10
                    mag_time=[-baseline_duration:timebin/1000:baseline_duration];
                    l=length(mag_time);
                    
                    figure(12);
                    plot(mag_time,output(size(output,1)-k+1,1:l),'color',cmap2(k,:));
                    title(['0s=LED on, 10 example individual trials (',mousenamelist{mouse},')']);
                    xlabel('time(s)');
                    ylabel('df/f(%)');
                    hold on;
                end
            end
            

            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
            figure(2);
            title('df/f(%) vs. time(s): 0s = LED zone entering');
            temp=mean(output,1);
            plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
            hold on;
            legend_mark(2,i)=1;

            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title('df/f(%) vs. time(s): 0s = pellet dispensed');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
            end

            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title('df/f(%) vs. time(s): 0s = receptacle entry');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;

%                 %plotting individual trials
%                 if (i==1 || i==2)
%                     cmap2=hsv(size(output,1));
%                     for j=1:size(output,1)
%                         figure(9);
%                         plot(timestamp,output(j,:),'color',cmap2(j,:));
%                         hold on;
%                     end
%                     hold off;
%                 end
            end

            %df/f aligned to LED. split into successful entry vs. no-entry trial
            output=selectTrialData(TrialData,'dff_LED',d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(5);
                title('df/f(%) vs. time(s): 0s = LED on (successful entry trials)');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(5,i)=1;
            end

            output=selectTrialData(TrialData,'dff_LED',d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                figure(6);
                title('df/f(%) vs. time(s): 0s = LED on (no-entry trials)');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(6,i)=1;
            end

            %df/f aligned to zone entering. split into reward vs. no-reward trials
            output=selectTrialData(TrialData,'dff_zone',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(7);
                title('df/f(%) vs. time(s): 0s = zone entering (reward trials)');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(7,i)=1;
            end

            %output=selectTrialData(TrialData,'dff_zone',d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(8);
                title('df/f(%) vs. time(s): 0s = zone entering (no reward trials)');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(8,i)=1;
            end

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
            output=selectTrialData(TrialData,'dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                figure(1);
                title('df/f(%) vs. time(s): 0s = LED on');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(1,i)=1;
            end

            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
                figure(2);
                title('df/f(%) vs. time(s): 0s = LED zone entering');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(2,i)=1;
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title('df/f(%) vs. time(s): 0s = receptacle entry');
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

            %dff aligned to LED
            output=selectTrialData(TrialData,'dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                figure(1);
                title('df/f(%) vs. time(s): 0s = LED on');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(1,i)=1;
            end

            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
                figure(2);
                title('df/f(%) vs. time(s): 0s = LED zone entering');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(2,i)=1;
            end

            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title('df/f(%) vs. time(s): 0s = pellet dispensed');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title('df/f(%) vs. time(s): 0s = receptacle entry');
                temp=mean(output,1);
                plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;
            end
        end        

        for i=1:8
            figure(i);
            legend(legend_maker(legend_mark(i,:),'group_day+3'));
            xlabel('time(s)');
            ylabel('df/f(%)');
        end

        autoArrangeFigures();
        delete(findall(0,'Type','figure'));
    end
end

 return;

 %% intensity across many mice: comparing reward omission trials, no normalization
cmap = colormap(hsv(length(group_criteria)+2));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
num_days=11;

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;

figuretitle{1}='df/f vs. time(s): 0s = LED on';
figuretitle{2}='df/f vs. time(s): 0s = LED zone entering';
figuretitle{3}='df/f vs. time(s): 0s = pellet dispensed';
figuretitle{4}='df/f vs. time(s): 0s = receptacle entry';
figuretitle{5}='df/f vs. time(s): 0s = LED on (successful entry trials)';
figuretitle{6}='df/f vs. time(s): 0s = LED on (no-entry trials)';
figuretitle{7}='df/f vs. time(s): 0s = zone entering (reward trials)';
figuretitle{8}='df/f vs. time(s): 0s = zone entering (no reward trials)';
figuretitle{9}='df/f vs. time(s): 0s = LED on, rewarded trial';
figuretitle{10}='df/f vs. time(s): 0s = LED on, no-reward trial';

filetitle{1}='df/f LED on';
filetitle{2}='df/f LED zone entering';
filetitle{3}='df/f pellet dispensed';
filetitle{4}='df/f receptacle entry';
filetitle{5}='df/f LED on (successful entry trials)';
filetitle{6}='df/f LED on (no-entry trials)';
filetitle{7}='df/f zone entering (reward trials)';
filetitle{8}='df/f zone entering (no reward trials)';
filetitle{9}='df/f LED (reward tirals)';
filetitle{10}='df/f LED (no reward trials)';

% for i=1:plot_num
%     for j=1:length(group_criteria)+2
%         outputdata(i,j).numtrials=0;
%     end
% end

for d=1:length(TrialData(1).ch_name)
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
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,'dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %trial
            output=selectTrialData(TrialData,'dff_LED',d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'dff_LED',d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            output=selectTrialData(TrialData,'dff_zone',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'dff_zone',d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED split into reward vs no reward trial
            output=selectTrialData(TrialData,'dff_LED',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'dff_LED',d,[2 3],idx_start,idx_end);
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
            output=selectTrialData(TrialData,'dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);;
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);;
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[4],idx_start,idx_end);
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
            output=selectTrialData(TrialData,'dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
        end
    end
    
    legend_mark=zeros(plot_num,length(daylist)+1);
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
                legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+3');
                
                if(p==1 && i==3)
                    %plotting standard deviation for LED on plot
                    figure(11);
                    mag_time=[-baseline_duration:timebin/1000:baseline_duration];
                    dev=std(outputdata(p,i).data,1);
                    l=length(mag_time);
                    confplot(mag_time,temp(1:l),dev(1:l),dev(1:l),'color',[1 0 0]);
                    title([figuretitle{1},': trained animals']);
                    xlabel('time(s)');
                    ylabel('df/f');
                end
                
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+2'));
        %legend(legend_maker(legend_mark(p,:),'group_day'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel('df/f');
        hold off;
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
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

return;
 
%% intensity across many mice: comparing reward omission trials
cmap = colormap(hsv(length(group_criteria)+2));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);
num_days=11;

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;

figuretitle{1}='normalized df/f vs. time(s): 0s = LED on';
figuretitle{2}='normalized df/f vs. time(s): 0s = LED zone entering';
figuretitle{3}='normalized df/f vs. time(s): 0s = pellet dispensed';
figuretitle{4}='normalized df/f vs. time(s): 0s = receptacle entry';
figuretitle{5}='normalized df/f vs. time(s): 0s = LED on (successful entry trials)';
figuretitle{6}='normalized df/f vs. time(s): 0s = LED on (no-entry trials)';
figuretitle{7}='normalized df/f vs. time(s): 0s = zone entering (reward trials)';
figuretitle{8}='normalized df/f vs. time(s): 0s = zone entering (no reward trials)';
figuretitle{9}='normalized df/f vs. time(s): 0s = LED on, rewarded trial';
figuretitle{10}='normalized df/f vs. time(s): 0s = LED on, no-reward trial';

filetitle{1}='normalized dff LED on';
filetitle{2}='normalized dff LED zone entering';
filetitle{3}='normalized dff pellet dispensed';
filetitle{4}='normalized dff receptacle entry';
filetitle{5}='normalized dff LED on (successful entry trials)';
filetitle{6}='normalized dff LED on (no-entry trials)';
filetitle{7}='normalized dff zone entering (reward trials)';
filetitle{8}='normalized dff zone entering (no reward trials)';
filetitle{9}='normalized dff LED (reward tirals)';
filetitle{10}='normalized dff LED (no reward trials)';

for d=1:length(TrialData(1).ch_name)
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
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)    
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,'normalized_dff_zone',d,[1 2 3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'normalized_dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'normalized_dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %trial
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(5,i).data(outputdata(5,i).numtrials+1:outputdata(5,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(5,i).numtrials = outputdata(5,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(6,i).data(outputdata(6,i).numtrials+1:outputdata(6,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(6,i).numtrials = outputdata(6,i).numtrials + size(output,1);
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            output=selectTrialData(TrialData,'normalized_dff_zone',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(7,i).data(outputdata(7,i).numtrials+1:outputdata(7,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(7,i).numtrials = outputdata(7,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'normalized_dff_zone',d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(8,i).data(outputdata(8,i).numtrials+1:outputdata(8,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(8,i).numtrials = outputdata(8,i).numtrials + size(output,1);
            end
            
            %df/f aligned to LED split into reward vs no reward trial
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(9,i).data(outputdata(9,i).numtrials+1:outputdata(9,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(9,i).numtrials = outputdata(9,i).numtrials + size(output,1);
            end
            
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[2 3],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(10,i).data(outputdata(10,i).numtrials+1:outputdata(10,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(10,i).numtrials = outputdata(10,i).numtrials + size(output,1);
            end
            
            idx_start=idx_end+1;
        end
        
        %omission trial analysis
        if(mouse==6 || mouse==7)
            idx_start=-1;
            for j=1:length(TrialData)
                if TrialData(j).day==10 && idx_start==-1
                    idx_start=j;
                end
                if TrialData(j).day==11
                    idx_end=j-1;
                    break;
                end
            end
            if TrialData(j).day~=11
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
        
        if(idx_start>0 && idx_end>0)
            i=length(daylist)+1;
            %dff aligned to LED
            output=selectTrialData(TrialData,'normalized_dff_LED',d,[4],idx_start,idx_end); %plot dff_LED for all trial types
            if(size(output,1)>0)
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %dff aligned to LED zone entry
            output=selectTrialData(TrialData,'normalized_dff_zone',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
            %dff aligned to receptacle entry
            output=selectTrialData(TrialData,'normalized_dff_receptacle',d,[4],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(4,i).data(outputdata(4,i).numtrials+1:outputdata(4,i).numtrials+size(output,1),:)=output(:,1:idx);
                outputdata(4,i).numtrials = outputdata(4,i).numtrials + size(output,1);
            end
        end
    end
    
    legend_mark=zeros(plot_num,length(daylist)+1);
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
                legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+2');
                
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
        end
        figure(p);
        legend(legend_maker(legend_mark(p,:),'group_day+2'));
        %legend(legend_maker(legend_mark(p,:),'group_day'));
        title(figuretitle{p});
        xlabel('time(s)');
        ylabel('normalized df/f');
        hold off;
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
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

return;