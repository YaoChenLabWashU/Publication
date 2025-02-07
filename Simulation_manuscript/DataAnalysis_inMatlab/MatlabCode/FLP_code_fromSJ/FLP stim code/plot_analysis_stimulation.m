clear all;

mousenamelist = {'SJ471_1', 'SJ471_2', 'SJ471_3', 'SJ471_4', 'SJ471_5', 'SJ471_6',...
     'SJ471_7', 'SJ471_8', 'SJ471_9', 'SJ471_10', 'SJ471_11'};
 
num_days=1;
timebin=20; %timebin of 50ms per data point
duration=100; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=50; %baseline_duration: duration of the baseline used for the df/f calculation in

cmap = colormap(hsv(num_days));
timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];
idx=length(timestamp);

%% Plotting lifetime data
timebin = 1; %1s
duration=100; %duration of analysis
ITI=120;
baseline_duration=20;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data

timestamp=[-baseline_duration:timebin:duration-baseline_duration];
idx=length(timestamp);

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'dtau_dispense','pc_dispense','rewardtime_combined');
    legend_mark=zeros(4,num_days);
    
    for i=1:num_days
        legend_mark2=ones(1,size(dtau_dispense,2));
        cmap2=hsv(size(dtau_dispense,2));
        for j=1:size(dtau_dispense,2)
            figure(100+1);            
            plot(timestamp,squeeze(dtau_dispense(i,j,1:idx)),'color',cmap2(j,:));
            hold on;
        end
        figure(100+1);
        title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
        legend(legend_maker(legend_mark2,'trial'));
        hold off;
        
        for j=1:size(dtau_dispense,2)
            figure(100+2);
            plot(timestamp,squeeze(pc_dispense(i,j,1:idx)),'color',cmap2(j,:));
            hold on;
        end
        figure(100+2);
        title('photoncounts vs. time(s): 0s = stimulation started');
        legend(legend_maker(legend_mark2,'trial'));
        hold off;
        
        %delta lifetime aligned to stimulation
        counter=0; temp=[]; temp2=[];
        %for j=1:length(rewardtime_combined(i,:))
        for j=1:size(pc_dispense,2)
            if(rewardtime_combined(i,j)>0 && pc_dispense(i,j,1)~=0) %if j th trial is a rewarded trial
                counter=counter+1;
                temp(counter,:)=dtau_dispense(i,j,1:idx);
                temp2(counter,:)=pc_dispense(i,j,1:idx);
            end
        end
        if counter>0
            stderror=std(temp,0,1)/sqrt(size(temp,1));
            figure(100+3);
            confplot(timestamp,mean(temp,1),stderror,stderror,'color',cmap(i,:),'LineWidth',2);
            title('delta lifetime(ns) vs. time(s): 0s = stimulation started');
            
            stderror=std(temp2,0,1)/sqrt(size(temp,1));
            figure(100+4);
            plot(timestamp,squeeze(mean(temp2,1)),'color',cmap(i,:));
            title('photoncount vs. time(s): 0s = stimulation started');
            hold on;
            
            out=timestamp';
            out=[out,temp'];
            filename=['analysis_',mousenamelist{mouse},'.xlsx'];
            xlswrite(filename,out,1);
        end

    end
    
    autoArrangeFigures();
    delete(findall(0,'Type','figure'));
end