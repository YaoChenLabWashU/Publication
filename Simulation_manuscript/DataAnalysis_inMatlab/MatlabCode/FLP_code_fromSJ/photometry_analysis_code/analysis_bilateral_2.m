% analysis of raw neural and behavioral data
% analysis by trial type
clear;

dataname={'AD1_','AD2_'};
ch_name={'dLight_1','dLight_2'};
filelist = [1 2 3 4];
mousenamelist = {'SJ207','SJ208','SJ209','SJ210'};

%var_name='normalized_dff_LED';
var_name='normalized_dff_receptacle';
ch_name={'dLight_1','dLight_2'};
%ch_name={'jRCaMP NAc','dLight'};
%ch_name={'jRCaMP VTA','jRCaMP NAc'};
%alignment='LED on';
alignment='receptacle entry';
unit='normalized df/f';
ch(1)=1;ch(2)=2;

n=length(filelist); %number of mice
timebin=40; %timebin in ms
duration=100; %analysis duration in sec
inputrate=1000; %in Hz
cc_range=1;
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
delay=50; %delay in ms between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=13; %number of days for all trials
output_dir=['\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\SJ\DA sensor photometry\20180924 Bilateral dLight - summary\']; %output file directory
windowSize=500; %moving average window_size in ms

num_days=11;
group_criteria=[0 0.3 0.7];


%% analyze the controlled stimulus evoked DA signal peak
event_time = baseline_duration;

temp1=[];
temp2=[];
for mouse=1:length(mousenamelist)
    amplitude1=[];
    amplitude2=[];
    amplitude3=[];
    amplitude4=[];
    amplitude5=[];

    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');

    %all trials included for analysis
    idx_list{1}=[1:1:length(TrialData)];

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
    %     day_list=idx_list;
    %     idx_list={};
    %
    %     idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],day_list{1}(1),day_list{1}(end)); %entry trial
    %     idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],day_list{1}(1),day_list{1}(end)); %no-entry trial
    %
    %     idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],1,length(TrialData)); %entry trial
    %     idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],1,length(TrialData)); %no-entry trial

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

            %locating the peak of channel 1 near the event time (range of 2*average halfwidth)
            idx=event_time*inputrate/timebin;
            idx_start=idx;
            idx_end=min(idx+round(2*mean_halfwidth1*inputrate/timebin),length(data1)-1);

            %updating halfwidth with restricted time window (range of 2*average halfwidth near the event time)
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
        %         legend({'beginner','intermediate','trained'});
        legend(mousenamelist);
        hold on;

        linear_fit=fitlm(amplitude1(i,:),amplitude2(i,:))
        display('');
        %linear_fit.Rsquared.Adjusted
        %linear_fit.Coefficients.Estimate

        %     figure(4);
        %     plot(amplitude4,amplitude5,'.');
        %     title('peak amplitude of side 1 vs. side2 in the different trials');
        %     linear_fit=fitlm(amplitude4,amplitude5)

        %         figure(5);
        %         plot(i,linear_fit.Rsquared.Adjusted,'.');
        %         legend({'beginner','intermediate','trained'});
        %         hold on;
    end

    amplitude1=reshape(amplitude1,1,size(amplitude1,1)*size(amplitude1,2));
    amplitude2=reshape(amplitude2,1,size(amplitude2,1)*size(amplitude2,2));
    amplitude3=reshape(amplitude3,1,size(amplitude3,1)*size(amplitude3,2));

    temp1=[temp1,amplitude1];
    temp2=[temp2,amplitude2];
end
figure(6);
plot(temp1,temp2,'.');
title([alignment,' peak amplitude of ',ch_name{2},' vs. ',ch_name{1}]);
xlabel(unit);
ylabel(unit);

linear_fit=fitlm(temp1,temp2)

return
%
%% analyze the spontaneous DA signal peak
halfwidth=[];
halfwidth2=[];
M=0;
peak=[];
idx_peak=[];
baseline=[];

combinedx=[];
combinedy=[];
total_num_trial=0;

for mouse=1:length(mousenamelist)
    counter=0;
    amplitude_mini1=[]; amplitude_mini1_2=[];
    amplitude_mini2=[]; amplitude_mini2_2=[];
    amplitude_mini3=[];
    x=[];
    y=[];
    
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');
    
%     for i=1:length(TrialData(1).ch_name)
%         if(strcmp(TrialData(1).ch_name{i},ch_name{1})==1)
%             ch(1)=i;
%         end
%         if(strcmp(TrialData(1).ch_name{i},ch_name{2})==1)
%             ch(2)=i;
%         end
%     end

    ch(1)=1;ch(2)=2;

    %all trials included for analysis
    idx_list{1}=[1:1:length(TrialData)];
    total_num_trial=total_num_trial+length(TrialData);
    
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
    %     day_list=idx_list;
    %     idx_list={};
    %
    %     idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],day_list{1}(1),day_list{1}(end)); %entry trial
    %     idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],day_list{1}(1),day_list{1}(end)); %no-entry trial
    %
    %     idx_list{1}=selectTrialIdx(TrialData,var_name,ch(1),[1],1,length(TrialData)); %entry trial
    %     idx_list{2}=selectTrialIdx(TrialData,var_name,ch(2),[2],1,length(TrialData)); %no-entry trial
    
    %calculate the baseline standard deviation across trials
    combined1=[];
    combined2=[];
    analysis_range=baseline_duration*inputrate/timebin;
    for j=1:length(TrialData)
        read_data=eval(['TrialData(j).',var_name]);
        
        if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
            continue;
        end
        
%         data1=squeeze(read_data(ch(1),:));
%         data2=squeeze(read_data(ch(2),:));
        
        data1=squeeze(read_data(ch(1),1:analysis_range));
        data2=squeeze(read_data(ch(2),1:analysis_range));
        
        combined1=[combined1,data1];
        combined2=[combined2,data2];
    end
    SD1=std(combined1)
    SD2=std(combined2)
    
    for i=1:length(idx_list)
        for j=1:length(idx_list{i})
            read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
            
            if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
                continue;
            end
            
            data1=squeeze(read_data(ch(1),1:analysis_range));
            data2=squeeze(read_data(ch(2),1:analysis_range));
            
            if(length(data1)<analysis_range)
                continue;
            end
            
            r=0.5;
            range=[0,0];
            range(1)=r*2*inputrate/timebin;
            range(2)=(baseline_duration-r*2)*inputrate/timebin;
            idx_peak=[];
            halfwidth=[];
            
            %preliminary peaks with the range of 0.5 that rise above 2 SD
            idx_peak=find_peaks(data1,SD1*2,range,r,r*2,timebin,inputrate);
            
            display(idx_peak);
            
            if(length(idx_peak)>0)
                amplitude1_mini{j}=[];
                amplitude2_mini{j}=[];
                
                for k=1:length(idx_peak)
                    halfwidth(k)=cal_halfwidth(data1(max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data1))),timebin);
                end
                
                %updated peaks with the range of preliminary halfwidths
                r=2*halfwidth;
                idx_peak=find_peaks(data1,SD1*2,range,min(halfwidth),2*min(halfwidth),timebin,inputrate)
                
                if(length(idx_peak)>0)
                    
                    for k=1:length(idx_peak)
                        halfwidth(k)=cal_halfwidth(data1(max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data1))),timebin);
                        idx_start=max(idx_peak(k)-round(halfwidth(k)*inputrate/timebin),1);
                        idx_end=min(idx_peak(k)+round(halfwidth(k)*inputrate/timebin),length(data1));
                        
                        %using the idx,peak of the side 1
                        amplitude_mini1{j}(k)=cal_amplitude2(data1,idx_peak(k),timebin,halfwidth(k));
                        amplitude_mini2{j}(k)=cal_amplitude2(data2,idx_peak(k),timebin,halfwidth(k));
                    end
                    
%                     display(idx_peak);
%                     figure(1);
%                     plot([1:length(data1)]*timebin/inputrate,data1(:),'b');
%                     hold on;
%                     plot(idx_peak(:)*timebin/inputrate,data1(idx_peak(:)),'.r');
%                     hold off;
%                     
%                     figure(2);
%                     plot([1:length(data1)]*timebin/inputrate,data2(:),'b');
%                     hold on;
%                     plot(idx_peak(:)*timebin/inputrate,data2(idx_peak(:)),'.r');
%                     autoArrangeFigures();
%                     hold off;
                    
                end
            end
        end
        
        x=[];y=[];
        for j=1:length(amplitude_mini1)
            x=[x,amplitude_mini1{j}(find(amplitude_mini1{j}~=0))];
            y=[y,amplitude_mini2{j}(find(amplitude_mini2{j}~=0))];
            
%             figure(10);
%             plot(j,length(find(amplitude_mini1{j}(:)~=0)),'.');
%             hold on;
        end
        
        figure(3);
        plot(x,y,'.');
        title('spontaneous peak amplitude of side 1 vs. side2');
        ylabel('normalized dff');
        xlabel('normalized dff');
        legend(mousenamelist);
        hold on;
        
        autoArrangeFigures();
        
        combinedx=[combinedx,x];
        combinedy=[combinedy,y];
        
    end
end

linear_fit=fitlm(combinedx,combinedy)
length(combinedx)/total_num_trial

return;