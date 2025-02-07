function baseline_tau = calculate_baseline_tau(FLPdata_time,FLPdata_lifetimes,eventtime,timebin,ch,baseline_tau_duration)
%   calculated delta lifetime in a defined period
% new data file in regular arrays
global spc

%baseline tau calculation
time_start= eventtime-baseline_tau_duration;
time_end=eventtime;
idx_start=find(FLPdata_time(:,ch)>time_start,1);
idx_end=find(FLPdata_time(:,ch)>time_end,1);

% display(['baseline time start ',num2str(time_start)]);
% display(['baseline time end ',num2str(time_end)]);

%average the baseline taus
bin_start = time_start;
counter = 0; counter2 = 0;
lifetimes = zeros(1024,1);
baseline_taus=[]; time=[]; photoncount=[];

for i=idx_start:1:idx_end
    if counter2==0 || (FLPdata_time(i,ch) > ceil(bin_start) && FLPdata_time(i,ch) <= ceil(bin_start + timebin) && counter2<timebin)
        lifetimes = lifetimes + squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = counter2 + 1;
    else
        counter = counter + 1;
        spc.lifetimes{ch}=lifetimes;
        baseline_taus(counter)=spc_calculateAvgTau3(ch);
        time(counter)=FLPdata_time(i);
        photoncount(counter) = sum(lifetimes);
        bin_start = bin_start+timebin;
        lifetimes = squeeze(FLPdata_lifetimes(i,ch,:));
        counter2 = 1;
        
        %resolving time skipping problem by interpolating the current data into
        %the missing timebin
        if FLPdata_time(i,ch)-FLPdata_time(i-1,ch) > 1.5*timebin
            time(counter)=FLPdata_time(i-1,ch)+timebin;
            while(1)
                if(counter>1)
                    y1=baseline_taus(counter-1);
                    y2=spc_calculateAvgTau3(ch);
                    x1=time(counter-1);
                    x2=FLPdata_time(i,ch);
                    baseline_taus(counter)=y1+(y2-y1)*(time(counter)-x1)/(x2-x1);
                else
                    baseline_taus(counter)=spc_calculateAvgTau3(ch);
                end
                photoncount(counter)=sum(lifetimes);
                
                if(time(counter) + timebin > FLPdata_time(i))
                    bin_start=bin_start+timebin;
                    counter = counter + 1;
                    time(counter)=FLPdata_time(i,ch);
                    baseline_taus(counter)=spc_calculateAvgTau3(ch);
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
%             baseline_taus(counter)=baseline_taus(counter-1);
%             photoncount(counter)=photoncount(counter-1);
%             %spc.lifetimes{ch}=lifetimes;
%             %spc_drawLifetime(ch);
%             display(i);
%             display('');
%         elseif(counter>2 && abs(baseline_taus(counter)-baseline_taus(counter-1))>0.015)
%             baseline_taus(counter)=baseline_taus(counter-1);
%             photoncount(counter)=photoncount(counter-1);
% %             spc.lifetimes{ch}=lifetimes;
% %             spc_drawLifetime(ch);
%             display(i);
%             display('');
%        end
    end
end

baseline_tau = mean(baseline_taus);

% display(baseline_tau);
% figure(57);
% plot(time,baseline_taus,'.');
% xlabel('time (s)');
% ylabel('lifetime (ns)');
% title('lifetime (ns) vs. time (s)');
end