%analyze delta lifetime for pharmacology experiment
cell=0;

filelist = [1 2];
baseline_duration = 400; %200s
eventtime = [600 600]; %time when the injection started
duration = 2000; % 1800s
timebin = 1;
ch = 1;
mousenamelist={'SJ211','SJ212'};
baseline_tau_duration=50;

timestamp=[-baseline_duration:timebin:duration-baseline_duration];

cmap=hsv(length(filelist));
for f=1:length(filelist)
    filename=['continuous aquistion data_',num2str(filelist(f))];
    
    load(filename,'FLPdata_time','FLPdata_counter','FLPdata_lifetimes');
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(1,ch,:));
    spc_fitexpgaussGY(ch);
    spc_fitexp2gaussGY(ch); %fit once to find out delta peak time for lifetime calculation
    baseline=cal_baseline(ch);
    
    
    dtau=[];    photoncount=[]; time=[];
    if cell==1 % old data file in cells
        [dtau,photoncount,time] = align_FLIM_signal2(FLPdata_time, FLPdata_lifetimes, eventtime(f),duration,baseline_duration,timebin,ch);
    else % new data file in regular arrays
        %[dtau,photoncount,time] = align_FLIM_signal_new(FLPdata_time, FLPdata_lifetimes, eventtime(f),duration,baseline_duration,timebin,ch,baseline_tau_duration,baseline);
        [dtau,photoncount,time] = align_FLIM_signal4(FLPdata_time, FLPdata_lifetimes, eventtime(f),duration,baseline_duration,timebin,ch,baseline_tau_duration);
    end
    
    outputfilename = ['analysis_',mousenamelist{f}];
    save(outputfilename,'dtau','photoncount','time');
    
    figure(100);
    plot(timestamp,dtau(1:length(timestamp)),'color',cmap(f,:));
    title('delta lifetime (ns) vs. time (s): injection ended at 0s');
    hold on;
    
    figure(101);
    plot(timestamp,photoncount(1:length(timestamp)),'color',cmap(f,:));
    title('photoncount vs. time (s): injection ended at 0s');
    hold on;
    
                display(length(dtau));
    display(time(end)-time(1));
    %     for i=1:length(time)-1
    %         temp(i)=time(i+1)-time(i);
    %     end
    %     figure(102);plot(temp);
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