clear all;

dataname={'AD1_','AD2_','AD3_'};
%dataname='AD2_';
mousenamelist = {'SJ165'};
num_days=11;
n_trial = 20;
timebin=50; %timebin of 50ms per data point
duration=40; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in

cmap = colormap(hsv(num_days));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

legendlabel={};
for i=1:num_days
    legendlabel{i}=['day',num2str(i)];
end

for mouse=1:length(mousenamelist)
    legend_mark=zeros(8,num_days);
    for d=1:length(dataname);
        for i=1:num_days    
            filename = [mousenamelist{mouse},'-day',num2str(i),'.mat'];
            load(filename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
            
            %df/f aligned to LED
            figure(1);
            plot(timestamp,squeeze(mean(dff_LED(d,:,1:idx),2))','color',cmap(i,:));
            title('df/f(%) vs. time: 0s = LED on');
            legend_mark(1,:)=ones(1,num_days);
            hold on;
            
            %df/f aligned to LED zone entering
            figure(2);
            plot(timestamp,squeeze(mean(dff_zone(d,:,1:idx),2))','color',cmap(i,:));
            title('df/f(%) vs. time: 0s = LED zone entering');
            legend_mark(2,:)=ones(1,num_days);
            hold on;
            
            %df/f aligned to pellet dispensing
            counter=0; temp=[];
            for j=1:length(rewardtime)
                if(rewardtime(j)>0) %if j th trial is a rewarded trial
                    counter=counter+1;
                    temp(counter,:)=dff_dispense(d,j,1:idx);
                end
            end
            if counter>0
                figure(3);
                plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = pellet dispensed');
                hold on;
                legend_mark(3,i)=1;
                
%                 if (i==11)
%                     cmap2=colormap(hsv(size(temp,1)));
%                     for j=1:size(temp,1)
%                         figure(10);
%                         plot(timestamp,temp(j,1:idx),'color',cmap2(j,:));
%                         hold on;
%                     end
%                     figure(10); hold off;
%                 end
            end
            
            %df/f alinged to receptacle entry
            counter=0;  temp=[];
            for j=1:length(rewardtime)
                if(rewardtime(j)>0) %if j th trial is a rewarded trial
                    counter=counter+1;
                    temp(counter,:)=dff_receptacle(d,j,1:idx);
                end
            end
            if(counter>0)
                figure(4);
                plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = receptacle entry');
                hold on;
                legend_mark(4,i)=1;
            end
            
            %df/f aligned to LED. split into successful entry vs. no-entry
            %trial
            counter=0;  temp=[];
            counter2=0; temp2=[];
            for j=1:length(rewardtime)
                if(occupancy(j)>0) %if j th trial is a successful entry trial
                    counter=counter+1;
                    temp(counter,:)=dff_LED(d,j,1:idx);
                else %if jth trial is a no-entry trial
                    counter2=counter2+1;
                    temp2(counter2,:)=dff_LED(d,j,1:idx);
                end
            end
            if(counter>0)
                figure(5);
                plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = LED on (successful entry trials)');
                hold on;
                legend_mark(5,i)=1;
            end
            if(counter2>0)
                figure(6);
                plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = LED on (no-entry trials)');
                hold on;
                legend_mark(6,i)=1;
            end
            
            %df/f aligned to zone entering. split into reward vs. no-reward
            %trials
            counter=0;  temp=[];
            counter2=0; temp2=[];
            for j=1:length(rewardtime)
                if(rewardtime(j)>0) %if j th trial is a reward trial
                    counter=counter+1;
                    temp(counter,:)=dff_zone(d,j,1:idx);
                else %if jth trial is a no-reward trial
                    counter2=counter2+1;
                    temp2(counter2,:)=dff_zone(d,j,1:idx);
                end
            end
            if(counter>0)
                figure(7);
                plot(timestamp,squeeze(mean(temp,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = zone entering (reward trials)');
                hold on;
                legend_mark(7,i)=1;
            end
            if(counter2>0)
                figure(8);
                plot(timestamp,squeeze(mean(temp2,1))','color',cmap(i,:));
                title('df/f(%) vs. time: 0s = zone entering (no reward trials)');
                hold on;
                legend_mark(8,i)=1;
            end
        end
        
        for i=1:8
            figure(i);
            legend(legend_maker(legend_mark(i,:)));
            hold off;
        end
        
        delete(findall(0,'Type','figure'));
%         stderror=std(dfoverf1,0,1)/sqrt(n);
%         confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
    end    
end