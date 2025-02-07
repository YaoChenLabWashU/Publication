%plot by day group (beginner, intermediate, trained)

%clear all;
mousenamelist = {'SJ418_2'};


timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

n=length(mousenamelist); %number of mice
duration=20; %analysis duration in sec
inputrate=1000; %in Hz
cc_range=1;
baseline_duration=10; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
delay=50; %delay in ms between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
output_dir=['']; %output file directory
ch_name={'dLight'};

timebin=20; %timebin of 50ms per data point
windowSize=400; %moving average window_size in ms

num_trial=10;

%excel_filename='\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\20181027 data summary\excel files\';

%% Plotting intensity data by each mouse
cmap = colormap(hsv(num_trial));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);
filetitle{1}='dff LED on';
filetitle{2}='dff LED zone entering';
filetitle{3}='dff pellet dispensed';
filetitle{4}='dff receptacle entry';
filetitle{5}='dff LED on (successful entry trials)';
filetitle{6}='dff LED on (no-entry trials)';
filetitle{7}='dff zone entering (reward trials)';
filetitle{8}='dff zone entering (no reward trials)';
filetitle{9}='dff LED (reward tirals)';
filetitle{10}='dff LED (no reward trials)';

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    legend_mark=zeros(8,num_days);

    daylist=[1];

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

            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
%                 temp=mean(output,1);
%                 figure(3);
%                 plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = pellet dispensed');
%                 hold on;
                
                temp=mean(output,1);
                ste=std(output,1)/sqrt(size(output,1));
                figure(3);
                confplot(timestamp,temp(1:length(timestamp)),ste(1:length(timestamp)),ste(1:length(timestamp)),'color',[1 0 0],'LineWidth',2);
                title('df/f(%) vs. time(s): 0s = stimulation started');

                cmap2=hsv(size(output,1));
                for k=1:size(output,1)
                    figure(10+3);
                    plot(timestamp,output(k,1:length(timestamp)),'color',cmap2(k,:));
                    title('df/f(%) vs. time(s): 0s = stimulation started');
                    hold on;
                end
                
                legend_mark(3,i)=1;
                
%                 output=output(:,1:length(timestamp));
%
%                 out=timestamp';
%                 out=[out,output'];
%                 filename=[excel_filename,mousenamelist{mouse},'_',filetitle{3},'.xlsx'];
%                 xlswrite(filename,out,1);
            end

            %df/f aligned to max df/f after pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense_max',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
%                 temp=mean(output,1);
%                 figure(6);
%                 plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = max amplitude after dispensing');
%                 hold on;
                
                temp=mean(output,1);
                ste=std(output,1)/sqrt(size(output,1));
                figure(6);
                confplot(timestamp,temp(1:length(timestamp)),ste(1:length(timestamp)),ste(1:length(timestamp)),'color',[1 0 0],'LineWidth',2);
                title('df/f(%) vs. time(s): 0s = max amplitude after dispensing');

                legend_mark(6,i)=1;

                cmap2=hsv(size(output,1));
                for k=1:size(output,1)
                    figure(10+6);
                    plot(timestamp,output(k,1:length(timestamp)),'color',cmap2(k,:));
                    title('df/f(%) vs. time(s): 0s = max amplitude after dispensing');
                    hold on;
                end
                
%                 output=output(:,1:length(timestamp));
%
%                 out=timestamp';
%                 out=[out,output'];
%                 filename=[excel_filename,mousenamelist{mouse},'_',filetitle{3},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
            idx_start=idx_end+1;
        end

        %autoArrangeFigures();
        %delete(findall(0,'Type','figure'));
    end
end

return;

%% intensity across many mice
cmap = colormap(hsv(num_trial));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData');
plot_num=10;

figuretitle{1}='df/f vs. time(s): 0s = pellet dispensed';
figuretitle{2}='df/f vs. time(s): 0s = receptacle entry';
figuretitle{3}='df/f vs. time(s): 0s = max peak)';

filetitle{1}='normalized dff LED on';
filetitle{2}='normalized dff LED zone entering';
filetitle{3}='normalized dff pellet dispensed';

for d=1:length(TrialData(1).ch_name)
    display(TrialData(1).ch_name{d});
    
    for i=1:plot_num
        for j=1:1
            outputdata(i,j).numtrials=0;
        end
    end
    
    for mouse=1:length(mousenamelist)
        filename = ['analysis_',mousenamelist{mouse},'.mat'];
        load(filename,'TrialData','successrate');
        
        %grouping days by success rate
%         daylist=[];
%         for i=1:length(group_criteria)
%             idx_list=find(successrate>=group_criteria(i));
%             daylist(i)=max(idx_list(1)-1,2); %the first category should include at least upto 2nd day
%         end
%         daylist(end+1)=num_days;
        
        daylist=1;
        
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
            
           
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(1,i).data(outputdata(1,i).numtrials+1:outputdata(1,i).numtrials+size(output,1),:)=output;
                outputdata(1,i).numtrials = outputdata(1,i).numtrials + size(output,1);
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(2,i).data(outputdata(2,i).numtrials+1:outputdata(2,i).numtrials+size(output,1),:)=output;
                outputdata(2,i).numtrials = outputdata(2,i).numtrials + size(output,1);
            end
            
                        
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_dispense_max',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                outputdata(3,i).data(outputdata(3,i).numtrials+1:outputdata(3,i).numtrials+size(output,1),:)=output;
                outputdata(3,i).numtrials = outputdata(3,i).numtrials + size(output,1);
            end
            
            idx_start=idx_end+1;
        end
    end
    
    legend_mark=zeros(plot_num,length(daylist)+1);
    p_list=[1:3];
    for p=p_list
        cmap=hsv(length(daylist));
        for i=1:length(daylist)
            if outputdata(p,i).numtrials>0
                temp=squeeze(mean(outputdata(p,i).data,1));
%                 figure(p);
%                 plot(timestamp,temp(1:length(timestamp)),'color',cmap(i,:));
%                 hold on;
                
                ste=std(outputdata(p,i).data,1)/sqrt(size(outputdata(p,i).data,1));
                figure(p);
                confplot(timestamp,temp,ste,ste,'color',[1 0 0],'LineWidth',2);
                
                legend_mark(p,i)=1;
                %legend_list=legend_maker(ones(1,size(legend_mark,2)),'group_day+2');
                
%                 out=timestamp';
%                 out=[out,squeeze(outputdata(p,i).data)'];
%                 filename=[excel_filename,'_',filetitle{p},'_',legend_list{i},'.xlsx'];
%                 xlswrite(filename,out,1);
            end
        end
        figure(p);
        %legend(legend_maker(legend_mark(p,:),'group_day+2'));
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
    
    %autoArrangeFigures();
    delete(findall(0,'Type','figure'));
    %         stderror=std(dfoverf1,0,1)/sqrt(n);
    %         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
end

return;