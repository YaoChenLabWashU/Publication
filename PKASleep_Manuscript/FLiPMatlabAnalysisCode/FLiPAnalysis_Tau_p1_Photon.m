function [tau_fit_G, tau_emp,photoncount,p1, time] = FLiPAnalysis_Tau_p1_Photon(FLPdata_time, FLPdata_lifetimes, timebin, ch, filename,reset_val) %timebin should be the same as slice time (e.g. ~0.85ns)
%calculate lifetime, photoncount, and p1 from FliP data.
% new data file in regular arrays
global spc tau_emp tau_fit_G photoncount p1 time lock_status first_flag

if ~exist('reset_val','var') %this avoids local minimums at p=0, input reset_val =1000 for better fits ZBR/LT 5/16/25
    reset_val = 0;
end
idx_start=1;
idx_end=length(find(FLPdata_time(:,ch) ~= 0));
channels  = size(FLPdata_lifetimes);
tau_fit_G = [];
tau_emp = [];
photoncount = [];
p1 = [];
time = [];
shift = [];
chi_sq_G = [];
GWidth = [];
dpeak_time = [];
histograms = [];
fits = [];
pc_trunc = [];
% chi_sq_prf = [];

% sum up lifetime plots for the analysis time bin (regardless of how many
% acquisitions during the time bin) because there are some missing data
% points due to the FLIM data acquisition delay

% bin_start = time_start;
% counter = 0; counter2 = 0;
lifetimes = zeros(256,timebin);

%read off initial fitting values to have a good starting point
Initial=[];
% load('Z:\Active\Lizzie\FLP_data\fit_parameters.mat')
Initial(1)=spc.fits{ch}.beta1;
Initial(2)=spc.fits{ch}.beta2;
Initial(3)=spc.fits{ch}.beta3;
Initial(4)=spc.fits{ch}.beta4;
Initial(5)=spc.fits{ch}.beta5;
% Initial(5)=DeltaPeakTime;
Initial(6)=spc.fits{ch}.beta6;
% Initial(6)=GaussianWidth;
count = 0;
for i=idx_start:timebin:idx_end
%     disp(i)
    lock_status = 1;
    if timebin > 1 && i == idx_start && first_flag == 1
        lock_status = 0;
    end
%     lock_status = 0;
    count = count+1;
    these_bins = i:(i+timebin-1);
    if any(these_bins > idx_end)
        these_bins = i:idx_end;
    end
    lifetimes = squeeze(FLPdata_lifetimes(these_bins,ch,:)); %lifetime data of all 256 channels.
    if size(lifetimes,1) > size(lifetimes,2)
        lifetimes = lifetimes';
    end
    if size(lifetimes,1) > 1
        lifetimes = sum(lifetimes);
    end
    spc.lifetimes{ch} = lifetimes;
    if sum(lifetimes)== 0 || FLPdata_time(i)== 0
        tau(i)=NaN;
        p1(i)=NaN;
        time(i)=NaN;
        photoncount(i)=NaN;
        chi_sq_G(i)=NaN;
    else
        time(count) = FLPdata_time(these_bins(end));
        photoncount(count) = sum(lifetimes);
        
        nsPerPoint=spc.datainfo.psPerUnit/1000;
        nsRange=[spc.fits{ch}.fitstart spc.fits{ch}.fitend];
        range=round(nsRange/nsPerPoint);
        pc_trunc(count) = sum(lifetimes(range(1):range(2)));
%         reset_val = (spc.fits{ch}.beta1+spc.fits{ch}.beta3)/2;
        spc.fits{ch}.beta1=reset_val;
        spc.fits{ch}.beta3=reset_val;
%         spc.fits{ch}.beta5 = Initial(5);
%         spc.fits{ch}.beta6 = Initial(6);
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
            if count > 1
                while spc.fits{ch}.redchisq > chi_sq_G(count-1)*5
                    spc.fits{ch}.beta1=Initial(1);
                    spc.fits{ch}.beta3=Initial(3);
                    spc_fitexp2gaussGY(ch);
                    spc_adjustTauOffset(1); % update TauOffset
                end
            end

            GWidth(count)=spc.fits{ch}.beta6;
            dpeak_time(count)=spc.fits{ch}.beta5;
            p1(count)=spc.fits{ch}.beta1/(spc.fits{ch}.beta1+spc.fits{ch}.beta3); %p1
            tau_emp(count)=spc.switchess{ch}.EmpLife;
            shift(count)=spc.switchess{ch}.Shift;
            chi_sq_G(count)=spc.fits{ch}.redchisq;
            tau_fit_G(count)=spc.fits{ch}.avgTau; % mean Tau calculated from fit
            histograms(count,:) = spc.lifetimes{ch};
            fits(count,:) = spc.fits{ch}.curve;
%             spc.fits{ch}.beta1 = 0;
%             spc.fits{ch}.beta2 = Initial(2);
%             spc.fits{ch}.beta3 = 0;
%             spc.fits{ch}.beta4 = Initial(4);
%             spc.fits{ch}.beta5 = Initial(5);
%             spc.fits{ch}.beta6 = Initial(6);
%             spc_fitexp2prfGY(ch);
%             tau_fit_prf(i)=spc.fits{ch}.avgTau;
%             chi_sq_prf(i)=spc.fits{ch}.redchisq;
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
% plot(time,tau_emp,'.');
% xlabel('time (s)');
% ylabel('lifetime (ns)');
% title('lifetime (ns) vs. time (s)');
% 
% figure(58);
% plot(time,p1,'.');
% xlabel('time (s)');
% ylabel('p1');
% title('free fraction vs. time (s)');
% 
% % figure(58);
% % plot(time,dtau,'.');
% % xlabel('time (s)');
% % ylabel('delta lifetime (ns)');
% % title('delta lifetime (ns) vs. time (s)');
GWidth = GWidth(~isnan(GWidth));
GWidth = GWidth(find(GWidth ~= 0));

dpeak_time = dpeak_time(~isnan(dpeak_time));
dpeak_time = dpeak_time(find(dpeak_time ~= 0));

p1 = p1(~isnan(p1));
p1 = p1(find(p1 ~= 0));

time = time(~isnan(time));
time = time(find(time ~= 0));

pc_trunc = pc_trunc(~isnan(pc_trunc));
pc_trunc = pc_trunc(find(pc_trunc ~= 0));

photoncount = photoncount(~isnan(photoncount));
photoncount = photoncount(find(photoncount ~= 0));

tau_fit_G = tau_fit_G(~isnan(tau_fit_G));
tau_fit_G = tau_fit_G(find(tau_fit_G ~= 0));

chi_sq_G = chi_sq_G(~isnan(chi_sq_G));
chi_sq_G = chi_sq_G(find(chi_sq_G ~= 0));

tau_emp = tau_emp(~isnan(tau_emp));
tau_emp = tau_emp(find(tau_emp ~= 0));

% cd('testing')
save(filename, 'time', 'photoncount', 'tau_fit_G','p1', 'chi_sq_G', 'GWidth', 'dpeak_time', 'histograms', 'fits', 'tau_emp', 'pc_trunc');

end

