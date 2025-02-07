function [dtau,photoncount,time] = align_FLIM_signal_new(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch,baseline_tau_duration,baseline)
%   calculated delta lifetime in a defined period
% new data file in regular arrays
global spc

dtau=[];
tau=[];
photoncount=[];
time=[];

%baseline tau calculation
time_start=eventtime-baseline_duration;
%time_end=eventtime-baseline_duration+baseline_tau_duration;
time_end=eventtime-baseline_duration+baseline_tau_duration;
idx_start=find(FLPdata_time(:,ch)>time_start,1);
idx_end=find(FLPdata_time(:,ch)>time_end,1);

%add up histogram first before baseline calculation
lifetimes = zeros(1024,1);
baseline_taus=[];
for i=idx_start:idx_end-1
    lifetimes = lifetimes + squeeze(FLPdata_lifetimes(i,ch,:));
    spc.lifetimes{ch}=squeeze(FLPdata_lifetimes(i,ch,:));
    %baseline_taus=[baseline_taus,spc_calculateAvgTau2(ch,baseline*timebin)];
end
%baseline_tau = mean(baseline_taus);
spc.lifetimes{ch}=lifetimes;
baseline_tau = spc_calculateAvgTau2(ch,baseline*(idx_end-1-idx_start+1));
% spc_fitexpgaussGY(ch);
% spc_fitexp2gaussGY(ch); %fit once to find out delta peak time using the baseline histogram

% sum up lifetime plots for the analysis time bin (regardless of how many
% acquisitions during the time bin) because there are some missing data
% points due to the FLIM data acquisition delay
time_start=eventtime-baseline_duration;
time_end=eventtime+duration-baseline_duration+1;
idx_start=find(FLPdata_time(:,ch)>time_start,1);
idx_end=find(FLPdata_time(:,ch)>time_end,1);

if( max(FLPdata_time(:,ch))<time_end )
    return;
end

bin_start = time_start;
counter = 0; counter2 = 0;
lifetimes = zeros(1024,1);

for i=idx_start:1:idx_end
    if counter2==0 || (FLPdata_time(i,ch) > ceil(bin_start) && FLPdata_time(i,ch) <= ceil(bin_start + timebin) && counter2<timebin)
        lifetimes = lifetimes + squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = counter2 + 1;
    else
        counter = counter + 1;
        spc.lifetimes{ch}=lifetimes;
        tau(counter)=spc_calculateAvgTau2(ch,baseline*counter2);
        %time(counter)=timebin*counter;
        time(counter)=FLPdata_time(i);
        photoncount(counter) = sum(lifetimes);
        bin_start = bin_start+timebin;
        lifetimes = squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = 1;
        
        %resolving time skipping problem by copying the current data into
        %the missing timebin
        if FLPdata_time(i,ch)-FLPdata_time(i-1,ch) > 1.5*timebin
            while(1)
                counter = counter + 1;
                time(counter)=timebin*counter;
                tau(counter)=tau(counter-1);
                photoncount(counter)=photoncount(counter-1);
                bin_start=bin_start+timebin;
                               
                if(time_start+time(counter) + timebin > FLPdata_time(i,ch))
                    break;
                end
            end
        end
                
        %removing some artifact outliers
%         if(counter>2 && abs((photoncount(counter)-photoncount(counter-1))/photoncount(counter-1))>0.1)
%             tau(counter)=tau(counter-1);
%             photoncount(counter)=photoncount(counter-1);
%             spc.lifetimes{ch}=lifetimes;
%             %spc_drawLifetime(ch);
%             display(i);
%             display('');
%         elseif(counter>2 && abs(tau(counter)-tau(counter-1))>0.015)
%             tau(counter)=tau(counter-1);
%             photoncount(counter)=photoncount(counter-1);
%             spc.lifetimes{ch}=lifetimes;
%             spc_drawLifetime(ch);
%             display(i);
%             display('');
%         end
    end
end

counter=min(counter,baseline_duration+duration);
time=time(1:counter);
% Calculating delta lifetime
for i=1:counter
    dtau(i) = tau(i)-baseline_tau;
end

if(counter<duration/timebin)
    display('binning error for align_FLIM_signal code');
    display(counter);
   for i=2:counter
       if(time(i)-time(i-1)>1.5)
           display(time(i));
           display('');
       end
   end
end

% figure(56);
% plot(time,photoncount,'.');
% xlabel('time (s)');
% ylabel('photoncount');
% title('photoncount vs. time (s)');
% 
% figure(57);
% plot(time,tau,'.');
% xlabel('time (s)');
% ylabel('lifetime (ns)');
% title('lifetime (ns) vs. time (s)');
% 
% figure(58);
% plot(time,dtau,'.');
% xlabel('time (s)');
% ylabel('delta lifetime (ns)');
% title('delta lifetime (ns) vs. time (s)');

end

