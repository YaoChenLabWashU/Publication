function [tau,photoncount,time] = align_FLIM_signal_abs_tau2(FLPdata_time, FLPdata_lifetimes, eventtime,duration,baseline_duration,timebin,ch)
%calculate lifetime in a defined period by fitting
% new data file in regular arrays
global spc

tau=[];
photoncount=[];
time=[];

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
    %display(i);
    if counter2==0 || (FLPdata_time(i,ch) > ceil(bin_start) && FLPdata_time(i,ch) <= ceil(bin_start + timebin) && counter2<timebin)
        lifetimes = lifetimes + squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = counter2 + 1;
    else
        counter = counter + 1;
        spc.lifetimes{ch}=lifetimes;
        %tau(counter)=spc_calculateAvgTau_fit(ch);
        tau(counter)=spc_calculateAvgTau3(ch);
        %time(counter)=timebin*counter;
        time(counter)=FLPdata_time(i);
        photoncount(counter) = sum(lifetimes);
        bin_start = bin_start+timebin;
        lifetimes = squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = 1;
        
        %resolving time skipping problem by interpolating
        if FLPdata_time(i,ch)-FLPdata_time(i-1,ch) > 1.5*timebin
            time(counter)=FLPdata_time(i-1,ch)+timebin;
            while(1)
                if counter>1
                    y1=tau(counter-1);
                    y2=spc_calculateAvgTau3(ch);
                    x1=time(counter-1);
                    x2=FLPdata_time(i,ch);
                    tau(counter)=y1+(y2-y1)*(time(counter)-x1)/(x2-x1);
                else
                    tau(counter)=spc_calculateAvgTau3(ch);
                end
                photoncount(counter)=sum(lifetimes);
                               
                if(time(counter) + timebin > FLPdata_time(i))
                    bin_start=bin_start+timebin;
                    counter = counter + 1;
                    time(counter)=FLPdata_time(i,ch);
                    tau(counter)=spc_calculateAvgTau3(ch);
                    photoncount(counter)=sum(lifetimes);
                    break;
                end
                
                bin_start=bin_start+timebin;
                counter = counter + 1;
                time(counter)=time(counter-1)+timebin;
            end
        end
                
        %removing some artifact outliers
%         if(counter>2 && abs((photoncount(counter)-photoncount(counter-1))/photoncount(counter-1))>0.1)
%             tau(counter)=tau(counter-1);
%             photoncount(counter)=photoncount(counter-1);
%             %spc.lifetimes{ch}=lifetimes;
%             %spc_drawLifetime(ch);
%             display(i);
%             display('');
%         elseif(counter>2 && abs(tau(counter)-tau(counter-1))>0.015)
%             tau(counter)=tau(counter-1);
%             photoncount(counter)=photoncount(counter-1);
% %             spc.lifetimes{ch}=lifetimes;
% %             spc_drawLifetime(ch);
%             display(i);
%             display('');
%         end
    end
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

