global spc

filenumber=[1 2 3 4 5 6];
mousenamelist={'SJ130','SJ91','SJ110','SJ136','SJ137','SJ138'};
%filenumber=[6];
%mousenamelist={'SJ138'};

timebin = 1;
num_days=11;
duration=120; %duration of analysis=ITI interval
baseline_duration=50;%50s duration for baseline lifetime calculation
timebin=1; %1s timebin for FLIM data
ch=1; %FLIM channel

for f=1:length(filenumber)
    day=1;
    input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\FLP data\FLP_201805',num2str(14+day),' (AKAR mice- behavior day ',num2str(day),')\'];
    input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20180514 (AKAR mice- behavior - summary)\'];
    filename=[input_dir,'continuous aquistion data_',num2str(filenumber(f)),'.mat'];
    load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    
    for day=1:num_days
        if(day~=5)
            input_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\FLP data\FLP_201805',num2str(14+day),' (AKAR mice- behavior day ',num2str(day),')\'];
            input_dir2=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\FLP data\FLP_20180514 (AKAR mice- behavior - summary)\'];
            
            filename=[input_dir,'continuous aquistion data_',num2str(filenumber(f)),'.mat'];
            load(filename,'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits', 'FLPdata_counter');
            
            filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filenumber(f)),'.mat'];
            load(filename2,'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
            
            display(day);
            display(f);
            
            dtau_LED=[];    time_LED=[];
            dtau_zone=[];   time_zone=[];
            dtau_dispense=[];   time_dispense=[];
            dtau_receptacle=[]; time_receptacle=[];
            for i=1:length(cuetime)
                [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,cuetime(i),duration,baseline_duration,timebin,ch);
                if(length(dlifetime)==0) %%if the recording stopped before the behavior, the returned matrix is an empty matrix
                    display(i);
                    display('');
                else
                    dtau_LED(i,1:length(dlifetime))=dlifetime;
                    time_LED(i,1:length(time))=time;
                    
                    [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time(i),duration,baseline_duration,timebin,ch);
                    dtau_zone(i,1:length(dlifetime))=dlifetime;
                    time_zone(i,1:length(time))=time;
                    
                    if(rewardtime(i)>0) %rewardtime==-1 when the mouse was not rewarded
                        [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,rewardtime(i),duration,baseline_duration,timebin,ch);
                        dtau_dispense(i,1:length(dlifetime))=dlifetime;
                        time_dispense(i,1:length(time))=time;
                    end
                    
                    if(entering_time2(i)>0) %entering_time2==-1 when the mouse was not rewarded
                        [dlifetime,photoncount,time] = align_FLIM_signal(FLPdata_time,FLPdata_lifetimes,entering_time2(i),duration,baseline_duration,timebin,ch);
                        dtau_receptacle(i,1:length(dlifetime))=dlifetime;
                        time_receptacle(i,1:length(time))=time;
                    end
                end
            end
            
            savefilename=['analysis_',mousenamelist{f},'_day',num2str(day)];
            save(savefilename,'dtau_LED','time_LED','dtau_zone','time_zone','dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
        end
    end
end

return;

for i=0:7
    figure(70+i); hax{i+1}=axes;
end

cmap=hsv(num_days);
for f=1:length(filenumber)        
    legendlabel={}; label_counter=0;
    legendlabel2={}; label_counter2=0;
    legendlabel3={}; label_counter3=0;
    legendlabel4={}; label_counter4=0;
    
    for day=1:num_days
        if(day~=5)
            label_counter=label_counter+1;
            legendlabel{label_counter}=['day',num2str(day)];
            time=[-baseline_duration:timebin:duration-1];
            filename=['analysis_',mousenamelist{f},'_day',num2str(day)];
            load(filename,'dtau_LED','time_LED','dtau_zone','time_zone','dtau_dispense','time_dispense','dtau_receptacle','time_receptacle','cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
            
            for i=1:size(dtau_LED,1)
                figure(80);
                plot(time,dtau_LED(i,1:length(time)));
                hold on;
            end
            
            figure(70);
            plot(time,mean(dtau_LED(:,1:length(time)),1),'color',cmap(day,:));
            hold on;
            
            figure(71);
            plot(time,mean(dtau_zone(:,1:length(time)),1),'color',cmap(day,:));
            hold on;
            
            counter=0;
            temp_dispense=[];
            for i=1:size(dtau_dispense,1)
                if(rewardtime(i)>0)
                    counter=counter+1;
                    temp_dispense(counter,:)=dtau_dispense(i,:);
                end
            end
            if counter>0
                figure(72);
                plot(time,mean(temp_dispense(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
                label_counter2=label_counter2+1;                
                legendlabel2{label_counter2}=['day',num2str(day)];
            end
            
            counter=0;
            temp_receptacle=[];
            for i=1:size(dtau_receptacle,1)
                if(rewardtime(i)>0)
                    counter=counter+1;
                    temp_receptacle(counter,:)=dtau_receptacle(i,:);
                end
            end
            if counter>0
                figure(73);
                plot(time,mean(temp_receptacle(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
            end
            
            counter=0;  dtau_LED_enter=[];
            counter2=0; dtau_LED_noenter=[];
            for i=1:size(dtau_LED,1)
                if(latency(i)<5)
                    counter=counter+1;
                    dtau_LED_enter(counter,:)=dtau_LED(i,:);
                else
                    counter2=counter2+1;
                    dtau_LED_noenter(counter2,:)=dtau_LED(i,:);
                end
            end
            if counter>0
                figure(74);
                plot(time,mean(dtau_LED_enter(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
            end
            if counter2>0
                figure(75);
                plot(time,mean(dtau_LED_noenter(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
                
                label_counter3=label_counter3+1;
                legendlabel3{label_counter3}=['day',num2str(day)];
            end
            
            counter=0;  dtau_zone_reward=[];
            counter2=0; dtau_zone_noreward=[];
            for i=1:size(dtau_zone,1)
                if(rewardtime(i)>0)
                    counter=counter+1;
                    dtau_zone_reward(counter,:)=dtau_zone(i,:);
                else
                    counter2=counter2+1;
                    dtau_zone_noreward(counter2,:)=dtau_zone(i,:);
                end
            end
            if counter>0
                figure(76);
                plot(time,mean(dtau_zone_reward(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
            end
            if counter2>0
                figure(77);
                plot(time,mean(dtau_zone_noreward(:,1:length(time)),1),'color',cmap(day,:));
                hold on;
                
                label_counter4=label_counter4+1;
                legendlabel4{label_counter4}=['day',num2str(day)];
            end
        end
    end
    
    figure(70);
    title('delta lifetime (ns) vs. time (s): aligned to LED on');
    legend(legendlabel);
    hold off;
    
    figure(71);
    title('delta lifetime (ns) vs. time (s): aligned to entering the LED zone');
    legend(legendlabel);
    hold off;
    
    figure(72);
    title('delta lifetime (ns) vs. time (s): aligned to pellet dispensing');
    legend(legendlabel2);
    hold off;
    
    figure(73);
    title('delta lifetime (ns) vs. time (s): aligned to entering the receptacle');
    legend(legendlabel2);
    hold off;
    
    figure(74);
    title('delta lifetime (ns) vs. time (s): aligned to LED on, entering');
    legend(legendlabel);
    hold off;
    
    figure(75);
    title('delta lifetime (ns) vs. time (s): aligned to LED on, noentering');
    legend(legendlabel3);
    hold off;
    
    figure(76);
    title('delta lifetime (ns) vs. time (s): aligned to entering the LED zone, rewarded');
    legend(legendlabel2);
    hold off;
    
    figure(77);
    title('delta lifetime (ns) vs. time (s): aligned to entering the LED zone, non-rewarded');
    legend(legendlabel4);
    hold off;
    
    for i=0:7
        figure(70+i);
        xlabel('time (s)');
        ylabel('delta lifetime (ns)');
        line([0 0],get(hax{i+1},'YLim'),'color','k');
        hold off;
    end
    
    display(filenumber(f));
end