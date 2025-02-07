%Comapre the amplitudes of each channel (dLight, JRCaMP, or AKAR)

clear;

mousenamelist = {'SJ164'};
var_name='normalized_dff_LED';
%ch_name={'VTA jRCaMP','dLight'};
ch_name={'VTA jRCaMP','NAc jRCaMP'};
ch(1)=3;
ch(2)=2;
alignment='LED on';
unit='normalized df/f';

timebin=100; %timebin of 50ms per data point
duration=40; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\'];

num_days=11;
group_criteria=[0 0.3 0.7];

%% analyze the controlled stimulus evoked signal peak
event_time = baseline_duration;

for mouse=1:length(mousenamelist)
    amplitude1=[];  amplitude1_2=[];
    amplitude2=[];  amplitude2_2=[];
    amplitude3=[];
    amplitude4=[];
    amplitude5=[];
    
    data1=[];
    data2=[];
    
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
        
    %all trials included for analysis
    %idx_list{1}=[1:1:length(TrialData)];
    
    %categorize trials by 3 groups: beginner, intermediate, and expert days
%     idx_list={};
%     counter=1;
%     for j=1:length(TrialData)
%         if(counter < length(group_criteria) && TrialData(j).day>2) %%intermediate group cannot include first 2 days
%             if(successrate(TrialData(j).day) > group_criteria(counter+1))
%                 counter=counter+1;
%             end
%         end
%         
%         if counter>length(idx_list)
%             idx_list{counter}=j;
%         else
%             idx_list{counter}=[idx_list{counter},j];
%         end
%     end
    
    %categorize trials by 2 groups: success entry vs. no entry trial
    day_list=idx_list;
    idx_list={};

    idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],day_list{1}(1),day_list{1}(end)); %entry trial
    idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],day_list{1}(1),day_list{1}(end)); %no-entry trial
    
    idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],1,length(TrialData)); %entry trial
    idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],1,length(TrialData)); %no-entry trial

    %calculate the average halfwidth across trials
    for j=1:length(TrialData)
        read_data=eval(['TrialData(j).',var_name]);
        
        if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
            continue;
        end
        
        data1=squeeze(read_data(ch(1),:));
        data2=squeeze(read_data(ch(2),:));
        halfwidth1(j)=cal_halfwidth(data1(:),timebin);
        halfwidth2(j)=cal_halfwidth(data2(:),timebin);
    end
    mean_halfwidth1=mean(halfwidth1)
    mean_halfwidth2=mean(halfwidth2)
    
    for i=1:length(idx_list) 
        for j=1:length(idx_list{i})
            read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
            
            if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
                continue;
            end
            
            data1=squeeze(read_data(ch(1),:));
            data2=squeeze(read_data(ch(2),:));
            
            %locating the peak of channel 1 near the event time (range of 2*max halfwidth)
            idx=event_time*inputrate/timebin;
            idx_start=idx;
            idx_end=min(idx+round(2*mean_halfwidth1*inputrate/timebin),length(data1)-1);
            
            %updating halfwidth with restricted time window (range of 2*max halfwidth near the event time)
            halfwidth1(j)=cal_halfwidth(data1(idx_start:idx_end),timebin);
            halfwidth2(j)=cal_halfwidth(data2(idx_start:idx_end),timebin);
            
            amplitude_interval=min(halfwidth1(j),3-halfwidth1(j)); %3s minimum delay b/w cue and food reward dispense
            amplitude1(i,j)=cal_amplitude(data1(idx_start:idx_end),timebin,amplitude_interval);
            
            %locating the peak of the other side near the peak of the side 1
            %more lenient search for the peak in the other side
            %where find any peak in the range of t,peak,side1 +/- halfwidth(k)
            %idx=find(data1(:)==max(data1(event_time*inputrate/timebin:end)),1);
            %                 idx=idx_start-1+find(data1(idx_start:idx_end) == max(data1(idx_start:idx_end)));
            %                 idx_start=max(max(idx-round(halfwidth1(j)*inputrate/timebin),1),event_time*inputrate/timebin);
            %                 idx_end=min(idx+round(halfwidth1(j)*inputrate/timebin),length(data1)-1);
            %                 amplitude2(i,j)=cal_amplitude(data2(idx_start-1:idx_end+1),timebin,halfwidth1(j));
            
            %using the idx,peak of the one side to calculate the amplitude of the other side
            amplitude_interval=min(halfwidth2(j),3-halfwidth2(j)); %3s minimum delay b/w cue and food reward dispense
            idx=idx_start-1+find(data1(idx_start:idx_end) == max(data1(idx_start:idx_end)));
            amplitude2(i,j)=cal_amplitude2(data2(:),idx,timebin,amplitude_interval);
            
            %average amplitude of the other trials at the same time point
            temp=[];
            temp_counter=0;
            for l=1:length(TrialData)
                if(l~=j)
                    read_data=eval(['TrialData(l).',var_name]);
                    temp_counter=temp_counter+1;
                    temp(temp_counter)=cal_amplitude2(read_data(ch(2),:),idx,timebin,amplitude_interval);
                end
            end
            amplitude3(i,j)=mean(temp);
            amplitude4=[amplitude4,amplitude1(i,j)*ones(1,length(temp))];
            amplitude5=[amplitude5,temp];
            
            %             figure(1);
            %             plot(data1(:),'b');
            %             hold on;
            %             plot(idx,data1(idx),'.r');
            %             hold off;
            %
            %             figure(2);
            %             plot(data2(:),'b');
            %             hold on;
            %             plot(idx,data2(idx),'.r');
            %             hold off;
            %             display(idx);
            
        end
        %     amplitude1=reshape(amplitude1,1,size(amplitude1,1)*size(amplitude1,2));
        %     amplitude2=reshape(amplitude2,1,size(amplitude2,1)*size(amplitude2,2));
        %     amplitude3=reshape(amplitude3,1,size(amplitude3,1)*size(amplitude3,2));
        figure(3);
        plot(amplitude1(i,:),amplitude2(i,:),'.');
        title([alignment,' peak amplitude of ',ch_name{2},' vs. ',ch_name{1}]);
        xlabel(unit);
        ylabel(unit);
        %legend({'successful entry trial','no entry trial'});
        legend({'beginner','intermediate','trained'});
        hold on;
        
        linear_fit=fitlm(amplitude1(i,:),amplitude2(i,:))
        display('');
        %linear_fit.Rsquared.Adjusted
        %linear_fit.Coefficients.Estimate
        
        %     figure(4);
        %     plot(amplitude4,amplitude5,'.');
        %     title('peak amplitude of side 1 vs. side2 in the different trials');
        %     linear_fit=fitlm(amplitude4,amplitude5)
        
        figure(5);
        plot(i,linear_fit.Rsquared.Adjusted,'.');
        legend({'beginner','intermediate','trained'});
        hold on;
    end
end

return