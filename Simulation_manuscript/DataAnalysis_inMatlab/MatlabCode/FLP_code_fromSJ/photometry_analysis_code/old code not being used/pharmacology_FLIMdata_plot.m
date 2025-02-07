%plotting delta lifetime for pharmacology experiment for multple mice
baseline_duration = 400; %200s
duration = 2000; % 1800s
timebin = 2;
ch = 1;
mousenamelist = {'SJ63','SJ64','SJ90','SJ91','SJ185','SJ186','SJ187','SJ188'};

timestamp=[-baseline_duration:timebin:duration-baseline_duration];

temp=[];
cmap=hsv(length(mousenamelist));
idx_end=length(timestamp);
for f=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{f}];
    load(filename,'dtau','photoncount','time');
    
    idx_end=min(idx_end,length(dtau));
    dtau=dtau(1:idx_end);
    temp(f,1:length(dtau))=dtau;
    
    figure(1);
    plot(timestamp(1:idx_end),dtau(1:idx_end),'color',cmap(f,:));
    title('delta lifetime (ns) vs. time (s): injection ended at 0s');
    hold on;
    
    figure(2);
    plot(timestamp(1:idx_end),photoncount(1:idx_end),'color',cmap(f,:));
    title('photoncount vs. time (s): injection ended at 0s');
    hold on;
    
    legendlabel{f}=['mouse',num2str(f)];
end

figure(1);legend(legendlabel);hold off;

timestamp=timestamp(1:idx_end);
for f=1:length(mousenamelist)
    temp2(f,:)=temp(f,1:idx_end);
end
temp=temp2;

stderror=std(temp,0,1)/sqrt(size(temp,1));
figure(3);
confplot(timestamp,mean(temp,1),stderror,stderror,'Color',[1 0 0],'LineWidth',2);
title('delta lifetime(ns) vs. time(s): 0s = injection ended');
