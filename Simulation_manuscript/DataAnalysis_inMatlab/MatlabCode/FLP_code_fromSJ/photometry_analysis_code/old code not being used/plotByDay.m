%plot by each day

clear all;

%mousenamelist = {'SJ163','SJ164','SJ165'};
mousenamelist = {'SJ164','SJ165'};

num_days=11;
timebin=40; %timebin of 50ms per data point
duration=40; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in

cmap = colormap(hsv(num_days));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

%% Plotting intensity data
cmap=hsv(num_days);
for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData');
    legend_mark=zeros(8,num_days);
    
    for d=1:length(TrialData(1).ch_name);
        idx_start=1;
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
            
            %df/f aligned to LED
            output=selectTrialData(TrialData,'dff_LED',d,[1 2 3],idx_start,idx_end); %plot dff_LED for all trial types
            figure(1);
            title('df/f(%) vs. time(s): 0s = LED on');
            plot(timestamp,mean(output,1),'color',cmap(i,:));
            hold on;
            legend_mark(1,i)=1;
            
            if(i==11)
                cmap2=hsv(size(output,1));
                for k=1:size(output,1)
                    figure(9);
                    title('df/f(%) vs. time(s): 0s = LED on, individual trials on day 11');
                    plot(timestamp,output(k,:),'color',cmap2(k,:));
                    hold on;
                end
                display('');
            end
            
            %df/f aligned to LED zone entry
            output=selectTrialData(TrialData,'dff_zone',d,[1 2 3],idx_start,idx_end);
            figure(2);
            title('df/f(%) vs. time(s): 0s = LED zone entering');
            plot(timestamp,mean(output,1),'color',cmap(i,:));
            hold on;
            legend_mark(2,i)=1;
            
            %df/f aligned to pellet dispensing
            output=selectTrialData(TrialData,'dff_dispense',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(3);
                title('df/f(%) vs. time(s): 0s = pellet dispensed');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(3,i)=1;
            end
            
            %df/f aligned to receptacle entry
            output=selectTrialData(TrialData,'dff_receptacle',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(4);
                title('df/f(%) vs. time(s): 0s = receptacle entry');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(4,i)=1;
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %trial
            output=selectTrialData(TrialData,'dff_LED',d,[1 2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(5);
                title('df/f(%) vs. time(s): 0s = LED on (successful entry trials)');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(5,i)=1;
            end
            
            output=selectTrialData(TrialData,'dff_LED',d,[3],idx_start,idx_end);
            if(size(output,1)>0)
                figure(6);
                title('df/f(%) vs. time(s): 0s = LED on (no-entry trials)');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(6,i)=1;
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            output=selectTrialData(TrialData,'dff_zone',d,[1],idx_start,idx_end);
            if(size(output,1)>0)
                figure(7);
                title('df/f(%) vs. time(s): 0s = zone entering (reward trials)');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(7,i)=1;
            end
            
            output=selectTrialData(TrialData,'dff_zone',d,[2],idx_start,idx_end);
            if(size(output,1)>0)
                figure(8);
                title('df/f(%) vs. time(s): 0s = zone entering (no reward trials)');
                plot(timestamp,mean(output,1),'color',cmap(i,:));
                hold on;
                legend_mark(8,i)=1;
            end
            
%             %df/f aligned to LED
%             counter=0; temp=[];
%             for j=idx_start:idx_end
%                 if(TrialData(j).dff_LED(d,1)>0) %if data exists
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_LED(d,:);
%                 end
%             end
%             if counter>0
%                 figure(1);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = LED on');
%                 hold on;
%                 legend_mark(1,i)=1;
%             end
%             
%             %df/f aligned to LED zone entry
%             counter=0; temp=[];
%             for j=idx_start:idx_end
%                 if(TrialData(j).dff_zone(d,1)>0) %if data exists
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_zone(d,:);
%                 end
%             end
%             if counter>0
%                 figure(2);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = LED zone entering');
%                 hold on;
%                 legend_mark(2,i)=1;
%             end
%             
%             %df/f aligned to pellet dispensing
%             counter=0; temp=[];
%             for j=idx_start:idx_end
%                 if(TrialData(j).dff_dispense(d,1)>0) %if data exists
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_dispense(d,:);
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
%             %df/f aligned to receptacle entry
%             counter=0; temp=[];
%             for j=idx_start:idx_end
%                 if(TrialData(j).dff_receptacle(d,1)>0) %if data exists
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_receptacle(d,:);
%                 end
%             end
%             if counter>0
%                 figure(4);
%                 plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
%                 title('df/f(%) vs. time(s): 0s = pellet dispensed');
%                 hold on;
%                 legend_mark(4,i)=1;
%             end
%             
%             %df/f aligned to LED. split into successful entry vs. no-entry
%             %trial
%             counter=0;  temp=[];
%             counter2=0; temp2=[];
%             for j=idx_start:idx_end
%                 if(TrialData(j).trialtype==1 || TrialData(j).trialtype==2) %if j th trial is a successful entry trial
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_LED(d,:);
%                 else %if jth trial is a no-entry trial
%                     counter2=counter2+1;
%                     temp2(counter2,:)=TrialData(j).dff_LED(d,:);
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
%             for j=idx_start:idx_end
%                 if TrialData(j).trialtype==1 %if j th trial is a rewarded trial
%                     counter=counter+1;
%                     temp(counter,:)=TrialData(j).dff_zone(d,:);
%                 elseif  TrialData(j).trialtype==2 %if jth trial is a no-reward trial + succesful entry
%                     counter2=counter2+1;
%                     temp2(counter2,:)=TrialData(j).dff_zone(d,:);
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
            
            idx_start=idx_end+1;
        end

        for i=1:8
            figure(i);
            legend(legend_maker(legend_mark(i,:),'day'));
            hold off;
        end

        delete(findall(0,'Type','figure'));
%         stderror=std(dfoverf1,0,1)/sqrt(n);
%         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
    end
end

return;
