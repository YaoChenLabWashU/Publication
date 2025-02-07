function [tau,photoncount,p1, time] = FLiPAnalysis_Tau_p1_Photon(FLPdata_time, FLPdata_lifetimes, timebin,ch, filename) %timebin should be the same as slice time (i.e. ~0.85ns)
%calculate lifetime, photoncount, and p1 from FliP data.
% new data file in regular arrays
global spc tau photoncount p1 time

tau=[];
photoncount=[];
p1=[];
time=[];

% sum up lifetime plots for the analysis time bin (regardless of how many
% acquisitions during the time bin) because there are some missing data
% points due to the FLIM data acquisition delay
idx_start=1;
idx_end=length(FLPdata_time(:,ch));

% bin_start = time_start;
% counter = 0; counter2 = 0;
lifetimes = zeros(256,1);

%read off initial fitting values to have a good starting point
Initial=[];
Initial(1)=spc.fits{ch}.beta1;
Initial(2)=spc.fits{ch}.beta2;
Initial(3)=spc.fits{ch}.beta3;
Initial(4)=spc.fits{ch}.beta4;
Initial(5)=spc.fits{ch}.beta5;
Initial(6)=spc.fits{ch}.beta6;

for i=idx_start:1:idx_end
    %display(i);
    %     if counter2==0 || (FLPdata_time(i,ch) > ceil(bin_start) && FLPdata_time(i,ch) <= ceil(bin_start + timebin) && counter2<timebin)
    lifetimes = squeeze(FLPdata_lifetimes(i,ch,:)); %lifetime data of all 256 channels.
    %         counter2 = counter2 + 1;
    %     else
    % counter = counter + 1;
    spc.lifetimes{ch}=lifetimes;
    %tau(counter)=spc_calculateAvgTau_fit(ch);
    %tau(counter)=spc_calculateAvgTau3(ch);
    
    if sum(lifetimes)== 0 || FLPdata_time(i)== 0
        tau(i)=NaN;
        p1(i)=NaN;
        time(i)=NaN;
        photoncount(i)=NaN;        
    else
        time(i)=FLPdata_time(i);
        photoncount(i) = sum(lifetimes);
        spc_fitexp2gaussGY(ch);
        spc_adjustTauOffset(1); % update TauOffset
        if ~isfield(spc.fits{ch},'failedFit') || spc.fits{ch}.failedFit || ...
                (isfield(spc.fits{ch},'redchisq') && spc.fits{ch}.redchisq) > 1000
            % bad news - FIT FAILED - don't rewrite the fit parameters
            tau(i)=NaN; %failed fit
            p1(i)=NaN;
            spc.fits{ch}.beta1=Initial(1);
            spc.fits{ch}.beta3=Initial(3);
            spc.fits{ch}.beta5=Initial(5);
            spc.fits{ch}.beta6=Initial(6);
        else
            % fit did not fail, so write the parameters
            % Now output values.
            p1(i)=spc.fits{ch}.beta1/(spc.fits{ch}.beta1+spc.fits{ch}.beta3); %p1
            tau(i)=spc.fits{ch}.avgTau; % mean Tau calculated from fit
        end
        
    end
    
    
    %time(counter)=timebin*counter;
    
    %         bin_start = bin_start+timebin;
    % lifetimes = squeeze(FLPdata_lifetimes(i,ch,:));
    %         counter2 = 1;
    
    %resolving time skipping problem by interpolating
    %         if FLPdata_time(i,ch)-FLPdata_time(i-1,ch) > 1.5*timebin
    %             time(counter)=FLPdata_time(i-1,ch)+timebin;
    %             while(1)
    %                 if counter>1
    %                     y1=tau(counter-1);
    %                     y2=spc_calculateAvgTau3(ch);
    %                     x1=time(counter-1);
    %                     x2=FLPdata_time(i,ch);
    %                     tau(counter)=y1+(y2-y1)*(time(counter)-x1)/(x2-x1);
    %                 else
    %                     tau(counter)=spc_calculateAvgTau3(ch);
    %                 end
    %                 photoncount(counter)=sum(lifetimes);
    %
    %                 if(time(counter) + timebin > FLPdata_time(i))
    %                     bin_start=bin_start+timebin;
    %                     counter = counter + 1;
    %                     time(counter)=FLPdata_time(i,ch);
    %                     tau(counter)=spc_calculateAvgTau3(ch);
    %                     photoncount(counter)=sum(lifetimes);
    %                     break;
    %                 end
    %
    %                 bin_start=bin_start+timebin;
    %                 counter = counter + 1;
    %                 time(counter)=time(counter-1)+timebin;
    %             end
    %         end
    
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
    %     end
end

% if(counter<duration/timebin)
%     display('binning error for align_FLIM_signal code');
%     display(counter);
%    for i=2:counter
%        if(time(i)-time(i-1)>1.5)
%            display(time(i));
%            display('');
%        end
%    end
% end

figure(56);
plot(time,photoncount,'.');
xlabel('time (s)');
ylabel('photoncount');
title('photoncount vs. time (s)');

figure(57);
plot(time,tau,'.');
xlabel('time (s)');
ylabel('lifetime (ns)');
title('lifetime (ns) vs. time (s)');

figure(58);
plot(time,p1,'.');
xlabel('time (s)');
ylabel('p1');
title('free fraction vs. time (s)');

% figure(58);
% plot(time,dtau,'.');
% xlabel('time (s)');
% ylabel('delta lifetime (ns)');
% title('delta lifetime (ns) vs. time (s)');

save(filename, 'time', 'photoncount', 'tau', 'p1');

end

