%plotting delta lifetime for pharmacology experiment for multple mice
clear all;close all;

baseline_duration = 500; %500s
duration = 2000; % 2000s
timebin = 1;
ch = 1;
mousenamelist = {'SJ274','SJ275','SJ276'};
amplitude_cal_duration = 50;

timestamp=[-baseline_duration:timebin:duration-baseline_duration];

temp=[];
idx_end=length(timestamp);
for f=1:length(mousenamelist)
    daylist=[1 2 4 6 8 10 12];
    cmap=hsv(length(daylist));
    
    excel_output=timestamp';
    for i=1:length(daylist)
        filename = ['analysis_',mousenamelist{f},' d',num2str(daylist(i))];
        load(filename,'dtau','photoncount','time');
        
        idx_end=min(idx_end,length(dtau));
        dtau=dtau(1:idx_end);
        temp(f,1:length(dtau))=dtau;
        
        idx_peak=find(dtau==min(dtau(baseline_duration:baseline_duration+300)));
        amplitude(i)=mean(dtau(idx_peak-amplitude_cal_duration/2:idx_peak+amplitude_cal_duration/2));
        
        figure(1);
        plot(timestamp(1:idx_end),dtau(1:idx_end),'color',cmap(i,:));
        title('delta lifetime(ns) vs. time(s): injection ended at 0s');
        hold on;
        
        figure(2);
        plot(timestamp(1:idx_end),photoncount(1:idx_end),'color',cmap(i,:));
        title('photoncount vs. time (s): injection ended at 0s');
        hold on;
        legendlabel{i}=['day',num2str(daylist(i))];
        excel_output=[excel_output,dtau'];
    end
    figure(1);legend(legendlabel);hold off;
    figure(2);legend(legendlabel);hold off;
    
    norm_amplitude=amplitude/amplitude(1);
    figure(3);
    plot(daylist,amplitude);
    
    figure(4);
    plot(daylist,norm_amplitude);
    
    autoArrangeFigures();
    
    %export to excel sheet
    output=[excel_output];
    filename=['dtau_timeseries_',mousenamelist{f},'.xlsx'];
    xlswrite(filename,output);
    
    output=[daylist',norm_amplitude'];
    filename=['normalized_amplitude_',mousenamelist{f},'.xlsx'];
    xlswrite(filename,output);
end