%analyze delta lifetime for pharmacology experiment
cell=0;

filelist = [1 2 3 4];
baseline_duration = 400; %200s
eventtime = [639 627 631 631]; %time when the injection ended
duration = 2000; % 1800s
timebin = 2;
ch = 1;
%mousenamelist = {'SJ63','SJ64','SJ90','SJ91'};
mousenamelist={'SJ185','SJ186','SJ187','SJ188'};

timestamp=[-baseline_duration:timebin:duration-baseline_duration];

cmap=hsv(length(filelist));
for f=1:length(filelist)
    filename=['continuous aquistion data_',num2str(filelist(f))];
    
    load(filename,'FLPdata_time','FLPdata_counter','FLPdata_lifetimes');
    
    dtau=[];    photoncount=[]; time=[];
    if cell==1 % old data file in cells
        [dtau,photoncount,time] = align_FLIM_signal2(FLPdata_time, FLPdata_lifetimes, eventtime(f),duration,baseline_duration,timebin,ch);
    else % new data file in regular arrays
        [dtau,photoncount,time] = align_FLIM_signal(FLPdata_time, FLPdata_lifetimes, eventtime(f),duration,baseline_duration,timebin,ch);
    end

    outputfilename = ['analysis_',mousenamelist{f}];
    save(outputfilename,'dtau','photoncount','time');
    
    if length(timestamp) > dtau
        timestamp=timestamp(1:end-1);
    end
    
    figure(100);
    plot(timestamp,dtau(1:length(timestamp)),'color',cmap(f,:));
    title('delta lifetime (ns) vs. time (s): injection ended at 0s');
    hold on;
    
    figure(101);
    plot(timestamp,photoncount(1:length(timestamp)),'color',cmap(f,:));
    title('photoncount vs. time (s): injection ended at 0s');
    hold on;
    display('');
end

legendlabel={};
for f=1:length(filelist)
    legendlabel{f}=['mouse ',num2str(f)];
end
figure(100);
legend(legendlabel);
hold off;

figure(101);
legend(legendlabel);
hold off;