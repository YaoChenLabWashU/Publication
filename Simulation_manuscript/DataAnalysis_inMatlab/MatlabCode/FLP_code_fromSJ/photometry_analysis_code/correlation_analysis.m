%Comapre the amplitudes of each chan9nel (dLight, JRCaMP, or AKAR)

%mousenamelist = {'SJ164','SJ165','SJ195','SJ197','SJ198'};
%mousenamelist = {'SJ164','SJ165','SJ197','SJ198'};
mousenamelist = {'SJ163','SJ164','SJ165'};
var_name='normalized_dff_LED';
%ch_name={'jRCaMP VTA','dLight'};
ch_name={'jRCaMP NAc','dLight'};
%ch_name={'jRCaMP VTA','jRCaMP NAc'};
alignment='LED on';
unit='normalized df/f';

%timebin=20; %timebin of 50ms per data point
duration=100; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
output_dir=[''];

timestamp=[-baseline_duration:timebin/1000:duration-baseline_duration];

%windowSize=10; %linear regrssion time window, number of timebins

global timebin
global windowSize

%% analyze the controlled stimulus evoked signal peak
event_time = baseline_duration;

for mouse=1:length(mousenamelist)
    mousenamelist = {'SJ163-pellet-day0','SJ164-pellet-day0','SJ165-pellet-day0'};
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');

    for i=1:length(TrialData(1).ch_name)
        if(strcmp(TrialData(1).ch_name{i},ch_name{1})==1)
            ch(1)=i;
        end
        if(strcmp(TrialData(1).ch_name{i},ch_name{2})==1)
            ch(2)=i;
        end
    end
    
    %all trials included for analysis
    idx_list{1}=[1:1:length(TrialData)];

    data1=[];
    data2=[];
    for i=1:length(idx_list) 
        for j=1:length(idx_list{i})
            read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
            
            if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
                continue;
            end
            
            data1=[data1,squeeze(read_data(ch(1),:))];
            data2=[data2,squeeze(read_data(ch(2),:))];
        end
    end
    
    mousenamelist = {'SJ163','SJ164','SJ165'};
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData','successrate');

    for i=1:length(TrialData(1).ch_name)
        if(strcmp(TrialData(1).ch_name{i},ch_name{1})==1)
            ch(1)=i;
        end
        if(strcmp(TrialData(1).ch_name{i},ch_name{2})==1)
            ch(2)=i;
        end
    end
    
    %all trials included for analysis
    idx_list{1}=[1:1:length(TrialData)];

    for i=1:length(idx_list) 
        for j=1:length(idx_list{i})
            read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
            
            if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
                continue;
            end
            
            data1=[data1,squeeze(read_data(ch(1),:))];
            data2=[data2,squeeze(read_data(ch(2),:))];
        end
    end
    
    display(mousenamelist{mouse});
    linear_fit=fitlm(data1,data2)
    
    figure(1);
    plot(data1,data2,'.');
    title(['Normalized df/f ',ch_name{2},' vs. ',ch_name{1}]);
    xlabel(['Normalized df/f ', ch_name{1}]);
    ylabel(['Normalized df/f ', ch_name{2}]);
    legend(mousenamelist);
    hold on;

    %multivariable regression
%     for i=1:windowSize
%         X(:,i)=data1(windowSize-i+1:end-i+1);
%     end
%     X(:,windowSize+1)=ones(length(data1)-windowSize+1,1);
%     
%     coeff = mvregress(X,data2(windowSize:end)');
%     
%     res=[];expected=[];
%     for i=windowSize:length(data1)
%         expected(i)=0;
%         for j=1:length(coeff)-1
%             expected(i)=expected(i)+coeff(j)*data1(i-j+1);
%         end
%         expected(i)=expected(i)+coeff(end);
%         
%         res(i)=data2(i)-expected(i);
%     end
%     
%     figure(1); plot(data1,data2,'.');
%     figure(2); plot(data1,res,'.');
%     title('residual for dLight signal prediction vs. jRCaMP VTA signal');
% 
%     res=[]; expected=[]; actual=[];
%     for i=1:length(idx_list)
%         for j=1:length(idx_list{i})
%             read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
%             
%             if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
%                 continue;
%             end
%             
%             data1=squeeze(read_data(ch(1),:));
%             data2=squeeze(read_data(ch(2),:));
%             
%             %res(i,j,:)=data2-(c(1)+c(2)*data1);
%             %res(i,j,:)=data2-(c(1)+c(2)*data1+c(3)*data1(i).^2);
%             %pred(i,j,:)=(c(1)+c(2)*data1);
%             
%             for k=windowSize:length(data1)
%                 expected(k)=0;
%                 for l=1:length(coeff)-1
%                     expected(k)=expected(k)+coeff(l)*data1(k-l+1);
%                 end
%                 expected(k)=expected(k)+coeff(end);
%                 res(k)=data2(k)-expected(k);
%             end
%             actual(i,j,:)=data2;
%         end
%     end
%     
%     figure(3);
%     temp=mean(squeeze(expected(1,:,:)),1);
%     plot(timestamp,temp(1:length(timestamp)));
%     hold on;
%     
%     temp=mean(squeeze(actual(1,:,:)),1);
%     figure(3);
%     plot(timestamp,temp(1:length(timestamp)));
%     legend('predicted','actual');
%     title('normalized df/f(%) vs. time(s): 0s=LED on');
%     hold off;
%     
%     return;
    
    %simple linear relatioship analysis
%     linear_fit=fitlm(data1,data2,'purequadratic')
%     c=linear_fit.Coefficients.Estimate;
%     
%     res=[];
%     for i=1:length(data2)
%        res(i)=data2(i)-(c(1)+c(2)*data1(i));
%        %res(i)=data2(i)-(c(1)+c(2)*data1(i)+c(3)*data1(i).^2);
%     end
%     
%     figure(1); plot(data1,data2,'.');
%     figure(2); plot(data1,res,'.');
%     title('residual for dLight signal prediction vs. jRCaMP VTA signal');    
%     
%     res=[];
%     for i=1:length(idx_list) 
%         for j=1:length(idx_list{i})
%             read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
%             
%             if(read_data(ch(1),1)==0 || read_data(ch(2),1)==0) %if no data exists in this trial skip this trial for analysis
%                 continue;
%             end
%             
%             data1=squeeze(read_data(ch(1),:));
%             data2=squeeze(read_data(ch(2),:));
%             
%             %res(i,j,:)=data2-(c(1)+c(2)*data1);
%             res(i,j,:)=data2-(c(1)+c(2)*data1+c(3)*data1(i).^2);
%             
%             %pred(i,j,:)=(c(1)+c(2)*data1);
%             pred(i,j,:)=c(1)+c(2)*data1+c(3)*data1.^2;
%             actual(i,j,:)=data2;
%         end
%     end
%     
%     figure(3);
%     temp=mean(squeeze(pred(1,:,:)),1);
%     plot(timestamp,temp(1:length(timestamp)));
%     hold on;
% 
%     temp=mean(squeeze(actual(1,:,:)),1);
%     figure(3);
%     plot(timestamp,temp(1:length(timestamp)));
%     legend('predicted','actual');
%     title('normalized df/f(%) vs. time(s): 0s=LED on');
%     hold off;
end
