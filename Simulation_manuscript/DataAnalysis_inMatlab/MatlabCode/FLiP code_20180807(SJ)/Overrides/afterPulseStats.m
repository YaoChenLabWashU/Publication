% DarkCount was calculated with no laser light and sum(lifetimes)
% See function PhotonCount.

function afterPulseStats(DarkCount)
global spc
global state

disp('base  tot   fraction_afterpulse fraction_darkcount peak2/peak1');
for k=1:1;
    lifetimes = double(spc.lifetimes{k});
    numPts= length(find(lifetimes)>=0);
    %base(k)=mean(lifetimes(200:400))-DarkCount/numPts; 
    %baseline(k)=mean(lifetimes(200:400)); %minimum (including dark count and after pulse)
    base(k)=mean(lifetimes(900:1000))-DarkCount/numPts; 
    baseline(k)=mean(lifetimes(900:1000));
    tot(k)=sum(lifetimes)-numPts*baseline(k); 
    
    peak1=max(lifetimes)-baseline(k);   
    Halfway=double(peak1/2)+baseline(k); %50% peak for IRF
    
    indexpeak =double(find(lifetimes == max(lifetimes)));
    index = find(lifetimes >= Halfway);
    index_start=index(1);
    index_end=index(length(index))+1;
    
    %linear approximation of time t1 and t2 that corresopnds to the peak/2 value
    index_start_real=(Halfway-lifetimes(index_start-1))/(lifetimes(index_start)- lifetimes(index_start-1))+index_start-1;
    index_end_real=(Halfway-lifetimes(index_end-1))/(lifetimes(index_end)- lifetimes(index_end-1))+index_end-1;
    time=((index_end_real-index_start_real))* spc.datainfo.psPerUnit/1000;
    
    %peak2=max(lifetimes(200:300))-baseline(k);
    peak2=max(lifetimes(1:100))-baseline(k);
    
    disp([num2str(base(k),'%5.1f') '  ' num2str(tot(k),'%8.0f') '  ' num2str(numPts*base(k)/tot(k),'%8.5f') '  ' num2str(DarkCount/tot(k), '%8.5f')...
        '  ' num2str(double(peak2)/double(peak1),'%8.5f')]);
    stats(k,1)=base(k);
    stats(k,2)=tot(k); 
    stats(k,3)=numPts*base(k)/tot(k);
    stats(k,4)=DarkCount/tot(k);
    
    display(['peak: ', num2str(peak1), ' base: ', num2str(base(k)) ] );
    disp(['raw photon count (including darkcount and afterpulse): ',num2str(sum(lifetimes)/state.spc.acq.SPCdata{1}.collect_time),'/s']);
    disp(['time of peak: ', num2str(max(indexpeak)*spc.datainfo.psPerUnit/1000),'ns']);
    disp(['halfwidthIRF: ', num2str(time)])
    
    try
        load('afterpulsedata.mat');
        temp=data;
        %data=[temp;state.files.lastAcquisition,double(state.spc.acq.SPCdata{1}.cfd_limit_low), double(state.spc.acq.SPCdata{1}.cfd_zc_level), tot(1),double(numPts)*double(base(k)/tot(k)),double(peak2)/double(peak1),DarkCount,sum(lifetimes)/state.spc.acq.SPCdata{1}.collect_time,tot(k)/state.spc.acq.SPCdata{1}.collect_time];
        data=[temp;state.files.lastAcquisition,double(state.spc.acq.SPCdata{1}.cfd_limit_low), double(state.spc.acq.SPCdata{1}.cfd_zc_level), sum(spc.lifetimes{1}), time, peak2/peak1, numPts*base(k)/tot(k) ];
    catch
        %data=[state.files.lastAcquisition,double(state.spc.acq.SPCdata{1}.cfd_limit_low), double(state.spc.acq.SPCdata{1}.cfd_zc_level), tot(1),double(numPts)*double(base(k)/tot(k)),double(peak2)/double(peak1),DarkCount,sum(lifetimes)/state.spc.acq.SPCdata{1}.collect_time,tot(k)/state.spc.acq.SPCdata{1}.collect_time];
       data=[state.files.lastAcquisition,double(state.spc.acq.SPCdata{1}.cfd_limit_low), double(state.spc.acq.SPCdata{1}.cfd_zc_level), sum(spc.lifetimes{1}), time, peak2/peak1, numPts*base(k)/tot(k) ];
    end
    
    save afterpulsedata.mat data;
end    