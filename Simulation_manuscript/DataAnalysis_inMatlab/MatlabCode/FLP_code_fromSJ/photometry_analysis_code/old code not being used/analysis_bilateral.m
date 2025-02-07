%peak analysis for bilateral DA signal
clear all;

dataname={'AD2_','AD3_'};
%dataname='AD2_';
filelist = [1 2 3 4];
n=length(filelist);
n_trial = 12;
timebin=50; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=120; %analysis duration of 30s
ITI=10; %intertrial interval of 200s
first_time=10; %first pellet dropped at 120s, analyze starting 10s before pellet dropping
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=9; %number of days for all trials
output_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\DA sensor photometry\20180430 DA sensor behavior - summary\'];

%% analyze the controlled stimulus evoked DA signal peak
mousenamelist = {'SJ141'};
event_time = baseline_duration;

for i=1:length(mousenamelist)
    amplitude1=[];  amplitude1_2=[];
    amplitude2=[];  amplitude2_2=[];
    amplitude3=[];
    x=[];
    y=[];
    data1=[];
    data2=[];
    
    for day=1:num_days
        outputfilename = [output_dir,mousenamelist{i},'-day',num2str(day)];
        load(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
        
        data1=squeeze(dff_LED(1,:,:));
        data2=squeeze(dff_LED(2,:,:));
        
%                 if(num_reward==0)
%                     continue
%                 end
%                 data1=squeeze(dff_dispense(1,:,:));
%                 data2=squeeze(dff_dispense(2,:,:));
        
        temp1=[];
        temp2=[];
        counter=0;
        for j=1:size(data1,1)
            if(mean(data1(j,:))~=0)
                counter=counter+1;
                temp1(counter,:)=data1(j,:);
                temp2(counter,:)=data2(j,:);
            end
        end
        data1=temp1;
        data2=temp2;
        
        %amplitude calculation
        for j=1:counter
            %preliminary half width calculation using the whole trial duration
            halfwidth1(j)=cal_halfwidth(data1(j,:),timebin);
            halfwidth2(j)=cal_halfwidth(data2(j,:),timebin);
            amplitude_interval = max([halfwidth1(j),halfwidth2(j)]); %halfwidth for amplitude averaging duration
            
            %locating the peak of one side near the event time (range of 2*max halfwidth)
            idx=event_time*inputrate/timebin;
            %idx_start=max(idx-round(2*amplitude_interval*inputrate/timebin),1);
            idx_start=idx;
            idx_end=min(idx+round(2*amplitude_interval*inputrate/timebin),length(data1)-1);
            
            %updating halfwidth with restricted time window (range of 2*max halfwidth near the event time)
            halfwidth1(j)=cal_halfwidth(data1(j,idx_start:idx_end),timebin);
            halfwidth2(j)=cal_halfwidth(data2(j,idx_start:idx_end),timebin);
            amplitude_interval=halfwidth1(j);
            
            amplitude1(day,j)=cal_amplitude(data1(j,idx_start:idx_end),timebin,amplitude_interval);
            
            %locating the peak of the other side near the peak of the side 1
            %more lenient search for the peak in the other side
            %where find any peak in the range of t,peak,side1 +/- halfwidth(k)
            %idx=find(data1(j,:)==max(data1(j,event_time*inputrate/timebin:end)),1);
            idx=idx_start-1+find(data1(j,idx_start:idx_end) == max(data1(j,idx_start:idx_end)));
            idx_start=max(max(idx-round(amplitude_interval*inputrate/timebin),1),event_time*inputrate/timebin);
            idx_end=min(idx+round(amplitude_interval*inputrate/timebin),length(data1)-1);
            amplitude2(day,j)=cal_amplitude(data2(j,idx_start-1:idx_end+1),timebin,amplitude_interval);
            
            %using the idx,peak of the one side to calculate the amplitude of the other side
            amplitude1_2(day,j)=cal_amplitude2(data1(j,:),idx,timebin,amplitude_interval);
            amplitude2_2(day,j)=cal_amplitude2(data2(j,:),idx,timebin,amplitude_interval);
            
            %average amplitude of the other trials at the same time point
            temp=zeros(1,19);
            temp_counter=0;
            for l=1:size(data1,1)
                if(l~=j)
                    temp_counter=temp_counter+1;
                    temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,amplitude_interval);
                end
            end
            amplitude3(day,j)=mean(temp);
            
            x=[x,amplitude1(day,j)*ones(1,length(temp))];
            y=[y,temp];
            
            %             figure(1);
            %             plot(data1(j,:),'b');
            %             hold on;
            %             plot(idx,data1(j,idx),'.r');
            %             hold off;
            %
            %             figure(2);
            %             plot(data2(j,:),'b');
            %             hold on;
            %             plot(idx,data2(j,idx),'.r');
            %             hold off;
            %             display(idx);
        end
        
        %display(halfwidth1);
    end
    amplitude1=reshape(amplitude1,1,size(amplitude1,1)*size(amplitude1,2));
    amplitude2=reshape(amplitude2,1,size(amplitude2,1)*size(amplitude2,2));
    amplitude3=reshape(amplitude3,1,size(amplitude3,1)*size(amplitude3,2));
    amplitude1_2=reshape(amplitude1_2,1,size(amplitude1_2,1)*size(amplitude1_2,2));
    amplitude2_2=reshape(amplitude2_2,1,size(amplitude2_2,1)*size(amplitude2_2,2));
    
    amplitude1=amplitude1(find(amplitude1~=0));
    amplitude2=amplitude2(find(amplitude2~=0));
    amplitude3=amplitude3(find(amplitude3~=0));
    amplitude1_2=amplitude1_2(find(amplitude1_2~=0));
    amplitude2_2=amplitude2_2(find(amplitude2_2~=0));
    
    figure(3);
    plot(amplitude1,amplitude2,'.');
    title('Evoked DA signal peak amplitude of two sides (df/f %)');
    
    %linear_fit=fitlm(amplitude1,amplitude2,'Intercept',false)
    linear_fit=fitlm(amplitude1,amplitude2)
    
    %     figure(4);
    %     plot(amplitude1,amplitude3,'.');
    %     title('peak amplitude of side 1 vs. side2 in the different trials');
    %     linear_fit=fitlm(amplitude1,amplitude3)
    
    figure(4);
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
    
    figure(5);
    plot(amplitude1_2,amplitude2_2,'.');
    title('Evoked DA signal peak amplitude of two sides (df/f %)');
    linear_fit=fitlm(amplitude1,amplitude2_2)
end

return
%
%% analyze the spontaneous DA signal peak
halfwidth=[];
halfwidth2=[];
M=0;
peak=[];
idx_peak=[];
baseline=[];

for i=1:length(mousenamelist)
    counter=0;
    amplitude_mini1=[]; amplitude_mini1_2=[];
    amplitude_mini2=[]; amplitude_mini2_2=[];
    amplitude_mini3=[];
    x=[];
    y=[];
    SD=[];
    
    data1=[];
    data2=[];
    for day=1:num_days
        outputfilename = [output_dir,mousenamelist{i},'-day',num2str(day)];
        load(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
        
        data1=squeeze(dff_LED(1,:,:));
        data2=squeeze(dff_LED(2,:,:));
        
        idx_end=baseline_duration*inputrate/timebin;
        baseline=[];
        for j=1:size(data1,1)
            baseline(i,(j-1)*idx_end+1:j*idx_end)=data1(j,1:idx_end);
        end
        SD(i) = std(baseline(i,:));
        
        %finding spontaneous peaks during the baseline before the food reward stimulus
        
        for j=1:size(data1,1)
            %only look at +1s ~ baseline duration -1s time duration for mini peaks
            r=0.5;
            range=[0,0];
            range(1)=r*2*inputrate/timebin;
            range(2)=(baseline_duration-r*2)*inputrate/timebin;
            idx_peak=[];
            halfwidth=[];
            
            %preliminary peaks with the range of 0.5
            idx_peak=find_peaks(data1(j,:),SD(i),range,r,r*2,timebin,inputrate);
            
            if(length(idx_peak)>0)
                for k=1:length(idx_peak)
                    halfwidth(k)=cal_halfwidth(data1(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data1))),timebin);
                end
                
                %updated peaks with the range of preliminary halfwidths
                r=2;
                idx_peak=find_peaks(data1(j,:),SD(i),range,max(halfwidth),r,timebin,inputrate)
                
                for k=1:length(idx_peak)
                    halfwidth(k)=cal_halfwidth(data1(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data1))),timebin);
                    idx_start=max(idx_peak(k)-round(halfwidth(k)*inputrate/timebin),1);
                    idx_end=min(idx_peak(k)+round(halfwidth(k)*inputrate/timebin),length(data1));
                    
                    %more lenient search for the peak in the other side
                    %where find any peak in the range of t,peak,side1 +/-
                    %halfwidth(k)
                    counter=counter+1;
                    amplitude_mini1(day,counter)=cal_amplitude(data1(j,idx_start:idx_end),timebin,halfwidth(k));
                    amplitude_mini2(day,counter)=cal_amplitude(data2(j,idx_start:idx_end),timebin,halfwidth(k));
                    
                    %using the idx,peak of the side 1
                    amplitude_mini1_2(day,counter)=cal_amplitude2(data1(j,:),idx_peak(k),timebin,halfwidth(k));
                    amplitude_mini2_2(day,counter)=cal_amplitude2(data2(j,:),idx_peak(k),timebin,halfwidth(k));
                    
                    %average amplitude of the other trials at the same time point
                    temp=zeros(1,19);
                    temp_counter=0;
                    for l=1:size(data1,1)
                        if(l~=j)
                            temp_counter=temp_counter+1;
                            temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,halfwidth(k));
                        end
                    end
                    amplitude_mini3(day,counter)=mean(temp);
                    
                    x=[x,amplitude_mini1(day,counter)*ones(1,length(temp))];
                    y=[y,temp];
                end
                
%                 figure(1);
%                 plot([1:length(data1)]*timebin/inputrate,data1(j,:),'b');
%                 hold on;
%                 plot(idx_peak(:)*timebin/inputrate,data1(j,idx_peak(:)),'.r');
%                 hold off;
%                 display(idx_peak);
%                 
%                 figure(2);
%                 plot([1:length(data1)]*timebin/inputrate,data2(j,:),'b');
%                 hold on;
%                 plot(idx_peak(:)*timebin/inputrate,data2(j,idx_peak(:)),'.r');
%                 hold off;
%                 display(idx_peak);
            end
        end
    end
    
    amplitude_mini1=reshape(amplitude_mini1,1,size(amplitude_mini1,1)*size(amplitude_mini1,2));
    amplitude_mini2=reshape(amplitude_mini2,1,size(amplitude_mini2,1)*size(amplitude_mini2,2));
    amplitude_mini3=reshape(amplitude_mini3,1,size(amplitude_mini3,1)*size(amplitude_mini3,2));
    amplitude_mini1_2=reshape(amplitude_mini1_2,1,size(amplitude_mini1_2,1)*size(amplitude_mini1_2,2));
    amplitude_mini2_2=reshape(amplitude_mini2_2,1,size(amplitude_mini2_2,1)*size(amplitude_mini2_2,2));
    
    amplitude_mini1=amplitude_mini1(find(amplitude_mini1~=0));
    amplitude_mini2=amplitude_mini2(find(amplitude_mini2~=0));
    amplitude_mini3=amplitude_mini3(find(amplitude_mini3~=0));
    amplitude_mini1_2=amplitude_mini1_2(find(amplitude_mini1_2~=0));
    amplitude_mini2_2=amplitude_mini2_2(find(amplitude_mini2_2~=0));
    
    figure(3);
    plot(amplitude_mini1,amplitude_mini2,'.');
    title('spontaneous peak amplitude of side 1 vs. side2');
    linear_fit=fitlm(amplitude_mini1,amplitude_mini2)
    
    figure(4);
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
    
    %     figure(4);
    %     plot(amplitude_mini1,amplitude_mini3,'.');
    %     title('peak amplitude of side 1 vs. side2 in the different trials');
    %     linear_fit=fitlm(amplitude_mini1,amplitude_mini3)
    
    figure(5);
    plot(amplitude_mini1_2,amplitude_mini2_2,'.');
    title('spontaneous peak amplitude of side 1 vs. side2');
    linear_fit=fitlm(amplitude_mini1_2,amplitude_mini2_2)
end

return;

%% analyze all peaks above 2SD of the baseline (10s before food) including the food evoked and the spontaneous DA signal peaks
halfwidth=[];
halfwidth2=[];
M=0;
peak=[];
idx_peak=[];
baseline=[];

for i=1:length(mousenamelist)
    counter=0;
    amplitude1=[];  amplitude1_2=[];
    amplitude2=[];  amplitude2_2=[];
    amplitude3=[];
    x=[];
    y=[];
    
    data=[];
    data2=[];
    for day=1:num_days
        outputfilename = [output_dir,mousenamelist{i},'-day',num2str(day)];
        load(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle', 'cuetime', 'rewardtime', 'num_reward', 'latency', 'entering_time', 'latency2', 'entering_time2', 'occupancy', 'total_occupancy', 'trial_duration');
        
        data=squeeze(dff_LED(2,:,:));
        data2=squeeze(dff_LED(1,:,:));
        
        idx_end=baseline_duration*inputrate/timebin;
        %idx_end=60*inputrate/timebin;
        baseline=[];
        for k=1:size(data,1)
            baseline(i,(k-1)*idx_end+1:k*idx_end)=data(1:idx_end);
        end
        SD(i) = std(baseline(i,:));
        
        %finding spontaneous peaks during the baseline before the food reward stimulus
        for j=1:size(data,1)
            %only look at +1s ~ end ITI-1s time duration for mini peaks
            r=0.5;
            range=[0,0];
            range(1)=r*2*inputrate/timebin;
            range(2)=(duration-r*2)*inputrate/timebin;
            idx_peak=[];
            halfwidth=[];
            
            %preliminary peaks with the range r*2
            idx_peak=find_peaks(data(j,:),SD(i),range,r,r*2,timebin,inputrate)
            for k=1:length(idx_peak)
                halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
            end
            
            %updated peaks with the range of preliminary halfwidths
            r=2;
            range(1)=2*r*inputrate/timebin;
            range(2)=(duration-2*r)*inputrate/timebin;
            
            idx_peak=find_peaks(data(j,:),SD(i),range,max(halfwidth),r,timebin,inputrate)
            for k=1:length(idx_peak)
                halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
                idx_start=max(idx_peak(k)-round(halfwidth(k)*inputrate/timebin),1);
                idx_end=min(idx_peak(k)+round(halfwidth(k)*inputrate/timebin),length(data));
                
                counter=counter+1;
                amplitude1(j,counter)=cal_amplitude(data(j,idx_start:idx_end),timebin,halfwidth(k));
                amplitude2(j,counter)=cal_amplitude(data2(j,idx_start:idx_end),timebin,halfwidth(k));
                
                %using the idx,peak of the side 1
                amplitude1_2(day,counter)=cal_amplitude2(data(j,:),idx_peak(k),timebin,halfwidth(k));
                amplitude2_2(day,counter)=cal_amplitude2(data2(j,:),idx_peak(k),timebin,halfwidth(k));
                
                %average amplitude of the other trials at the same time point
                temp=zeros(1,19);
                temp_counter=0;
                for l=1:size(data,1)
                    if(l~=j)
                        temp_counter=temp_counter+1;
                        temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,halfwidth(k));
                    end
                end
                amplitude3(j,counter)=mean(temp);
                x=[x,amplitude1(j,counter)*ones(1,length(temp))];
                y=[y,temp];
            end
            
%             figure(1);
%             plot(data(j,:),'b');
%             hold on;
%             plot(idx_peak(:),data(j,idx_peak(:)),'.r');
%             hold off;
%             display(idx_peak);
%             
%             figure(2);
%             plot(data2(j,:),'b');
%             hold on;
%             plot(idx_peak(:),data2(j,idx_peak(:)),'.r');
%             hold off;
%             display(idx_peak);
        end
    end
    
    amplitude1=reshape(amplitude1,1,size(amplitude1,1)*size(amplitude1,2));
    amplitude2=reshape(amplitude2,1,size(amplitude2,1)*size(amplitude2,2));
    amplitude3=reshape(amplitude3,1,size(amplitude3,1)*size(amplitude3,2));
    amplitude1_2=reshape(amplitude1_2,1,size(amplitude1_2,1)*size(amplitude1_2,2));
    amplitude2_2=reshape(amplitude2_2,1,size(amplitude2_2,1)*size(amplitude2_2,2));
    
    amplitude1=amplitude1(find(amplitude1~=0));
    amplitude2=amplitude2(find(amplitude2~=0));
    amplitude3=amplitude3(find(amplitude3~=0));
    amplitude1_2=amplitude1_2(find(amplitude1_2~=0));
    amplitude2_2=amplitude2_2(find(amplitude2_2~=0));
    
    figure(3);
    plot(amplitude1,amplitude2,'.');
    title('peak amplitude of side 1 vs. side2 in the same trial');
    linear_fit=fitlm(amplitude1,amplitude2)
    
    figure(4);
    %     plot(amplitude1,amplitude3,'.');
    %     title('peak amplitude of side 1 vs. side2 in the different trials');
    %     linear_fit=fitlm(amplitude1,amplitude3)
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
    
    figure(5);
    plot(amplitude1_2,amplitude2_2,'.');
    title('Evoked DA signal peak amplitude of two sides (df/f %)');
    linear_fit=fitlm(amplitude1_2,amplitude2_2)
    
    c=0;
    for i=1:counter
        if(length(find(amplitude1(i)==amplitude1)) >1 || length(find(amplitude2(i)==amplitude2)) >1)
            list=find(amplitude1(i)==amplitude1);
            for j=1:length(list)-1
                if(list(j)==list(j+1))
                    c=c+1;
                    find(amplitude1(i)==amplitude1)
                    find(amplitude2(i)==amplitude2)
                end
            end
            
            list=find(amplitude2(i)==amplitude2);
            for j=1:length(list)-1
                if(list(j)==list(j+1))
                    c=c+1;
                    find(amplitude1(i)==amplitude1)
                    find(amplitude2(i)==amplitude2)
                end
            end
        end
    end
    display(c);
end