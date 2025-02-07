%Comapre the amplitudes of each chan9nel (dLight, JRCaMP, or AKAR)

clear;

%mousenamelist = {'SJ164','SJ165','SJ195','SJ197','SJ198'};
%mousenamelist = {'SJ164','SJ165','SJ197','SJ198'};
%mousenamelist = {'SJ164'};
mousenamelist = {'SJ164-pellet-day0','SJ165-pellet-day0'};
var_name='normalized_dff_dispense_max';
ch_name={'jRCaMP VTA','jRCaMP NAc','dLight'};
%ch_name={'jRCaMP VTA','dLight'};
%ch_name={'jRCaMP NAc','dLight'};
%ch_name={'jRCaMP VTA','jRCaMP NAc'};
alignment='LED on';
unit='normalized df/f';

timebin=40; %timebin of 50ms per data point
duration=100; %analysis duration of 30s
inputrate=1000; %1000Hz
baseline_duration=20; %baseline_duration: duration of the baseline used for the df/f calculation in
output_dir=[''];

group_criteria=[0.3 0.7];
num_days=11;

range=20; %acf range in s
%% calculate autocorrelation of a signal
event_time = baseline_duration;

for c=1:length(ch_name)
    display(ch_name{c});
    
    filename = ['analysis_',mousenamelist{1},'.mat'];
    load(filename,'TrialData','successrate');
    for i=1:length(TrialData(1).ch_name)
        if(strcmp(TrialData(1).ch_name{i},ch_name{c})==1)
            ch(1)=i;
        end
    end
    
    TrialData(1).ch_name{ch(1)}
    
    data1=[]; 
    for mouse=1:length(mousenamelist)
        filename = ['analysis_',mousenamelist{mouse},'.mat'];
        load(filename,'TrialData','successrate');        
        
        %all trials included for autocorrelation analysis
        idx_list{1}=[1:1:length(TrialData)];
        
        for i=1:length(idx_list)
            for j=1:length(idx_list{i})
                read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
                
                if(read_data(ch(1),1)==0) %if no data exists in this trial skip this trial for analysis
                    continue;
                end
                
                data1=[data1,squeeze(read_data(ch(1),:))];
            end
        end
    end
    
    %average LED response in trained animals
    data2=[]; counter2=0;  time_lim=length([-range:timebin/inputrate:range]);
    for mouse=1:length(mousenamelist)
        filename = ['analysis_',mousenamelist{mouse},'.mat'];
        load(filename,'TrialData','successrate');        
        
        %categorize trials by 3 groups: beginner, intermediate, and expert days
        idx_list={};
        counter=1;
        for j=1:length(TrialData)
            if(TrialData(j).day>11)
                break;
            end
            
            if(counter <= length(group_criteria) && TrialData(j).day>2) %%intermediate group cannot include first 2 days
                if(successrate(TrialData(j).day) > group_criteria(counter))
                    counter=counter+1;
                    
                    display(TrialData(j).day);
                end
            end
            
            if counter>length(idx_list)
                idx_list{counter}=j;
            else
                idx_list{counter}=[idx_list{counter},j];
            end
        end
        
        for i=1:length(idx_list) %only trained animals
            for j=1:length(idx_list{i})               
                read_data=eval(['TrialData(idx_list{i}(j)).',var_name]);
                
                if(read_data(ch(1),1)==0) %if no data exists in this trial skip this trial for analysis
                    continue;
                end
                
                counter2=counter2+1;
                data2(counter2,1:time_lim)=read_data(ch(1),1:time_lim);
                
                figure(10+c);
                time=[-range:timebin/inputrate:range];
                plot(time,data2(counter2,1:time_lim));
                title(['normalized df/f of ',ch_name{c}]);
                hold on;
            end
        end
    end    
    
    acf=[];
    for i=1:round(range*inputrate/timebin)
        acf(i)=acf_k(data1,i,mean(data1),var(data1));
    end
    figure(c);
    idx_lim=length([0:timebin/inputrate:range])-1;
    time=[-range:timebin/inputrate:range];
    plot(time,[fliplr(acf(1:idx_lim)),acf_k(data1,0,mean(data1),var(data1)),acf(1:idx_lim)]);
    title(['autocorrelation vs. normalized df/f of ',ch_name{c}]);
    hold on;
    temp=mean(data2,1);
    plot(time,temp(1,1:length(time))/max(temp));
    legend('autocorrleation','actual data');
    
    x=time;
    y=[fliplr(acf(1:idx_lim)),acf_k(data1,0,mean(data1),var(data1)),acf(1:idx_lim)];
    f{c} = fit(x',y','gauss2')
    figure(length(ch_name)+c);
    plot(f{c},x,y);
    title(['autocorrelation of ',ch_name{c}]);
    
%     model_impulse{c}=f(x');
%     figure(length(ch_name)*2+c);
%     plot(x,model_impulse{c});
%     title(['autocorrelation of ',ch_name{c}]);
    
    autoArrangeFigures();
end

% ---------------
% SUB FUNCTION
% ---------------
function autocorr = acf_k(y,k,avg,variance)
% ACF_K - Autocorrelation at Lag k
% acf(y,k)
%
% Inputs:
% y - series to compute acf for
% k - which lag to compute acf
% 

cross_sum=0;
for i=k+1:length(y)
    cross_sum=cross_sum + (y(i)-avg)*(y(i-k)-avg);
end
autocorr = cross_sum / (length(y)-k) / variance;
end