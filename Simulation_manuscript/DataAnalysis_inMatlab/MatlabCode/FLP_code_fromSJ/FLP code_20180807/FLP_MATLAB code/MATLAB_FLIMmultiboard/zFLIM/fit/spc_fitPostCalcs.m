function spc_fitPostCalcs(chan)
% multiFLIM: call this AFTER updating the global fits{}.range fits{}.betaN

global spc PeakGeneralization PostPeakChannels BackGroundCorrection backcorr PeakChannelSet % FixPeakChannel peak_point_define
nsPerPoint=spc.datainfo.psPerUnit/1000;

% scaled beta0 for display values (but no need to redisplay or reload global; 
% this was done by spc_betaIntoGlobal)
[beta0, range]=spc_fitParamsFromGlobal(chan);
if findstr('prf',spc.fits{chan}.lastFitFunction)
    % beta6 is scatter
    sbeta0=beta0(:).*[1 nsPerPoint 1 nsPerPoint nsPerPoint 1]';
else % beta6 is gauss width
    sbeta0=beta0(:).*[1 nsPerPoint 1 nsPerPoint nsPerPoint nsPerPoint]';
end
nsRange=range*nsPerPoint;

% Calculate and display population fractions
	tau=sbeta0(2);
    tau2=sbeta0(4);
    pop1 = sbeta0(1)/(sbeta0(3)+sbeta0(1));
	pop2 = sbeta0(3)/(sbeta0(3)+sbeta0(1));
    spc.fits{chan}.pop1=pop1;
    spc.fits{chan}.pop2=pop2;
    
% Calculate and display mean tau from fit
    mean_tau = (tau*tau*pop1+tau2*tau2*pop2)/(tau*pop1 + tau2*pop2);
	spc.fits{chan}.avgTau=mean_tau; % save this value
    
% Now estimate the truncation of the distribution between the 
%  peak of the lifetime distribution and the end
% Added by gy 20110307 for better estimation of Figure Offset
%  see modifications also to spc_adjustTauOffset
    tmax=(range(2)-range(1)-beta0(5))*nsPerPoint;
    % disp(['tmax =' num2str(tmax,3)]);  % for debugging
    % following formula from the definite integral from 0 to tmax
    %  of pop1*t*exp(-t/tau1) + pop1*t*exp(-t/tau2)
    % over the definite integral from 0 to tmax
    %  of pop1*exp(-t/tau1) + pop2*exp(-t/tau2)
    ff1=exp(-tmax/tau);
    ff2=exp(-tmax/tau2);
    spc.fits{chan}.avgTauTrunc = ...
       (pop1*(tau^2-(tau*(tau+tmax))*ff1) + pop2*(tau2^2-(tau2*(tau2+tmax))*ff2)) ...
        / (pop1*tau*(1-ff1) + pop2*tau2*(1-ff2));
    
    % Next I will calculate the empirical lifetime, starting from the peak
    % of the histogram to around 13.68 ns after peak (140 channels) 
    % Pingchuan added 06.28.21
    
%     
%     if FixPeakChannel==1
%         lft_points=[-4:1:149]*nsPerPoint;
%         peak_point=peak_point_define;
%         empirical_lifetimes=spc.lifetimes{chan}((peak_point-5):(peak_point+148));
%         spc.fits{chan}.EmpTauTrunc = sum(empirical_lifetimes.*lft_points')/sum(empirical_lifetimes);
%     else
%         The part above was added on 02.17.2022 by Pingchuan Ma. I was
%         trying to fix the peak channel and calculate the empirical
%         lifetime base on a few channels before the peak and lots of
%         channels after the peak. To call this part, before running the
%         FLP analysis, FixPeakChannel and peak_point_define needs to be
%         defined.
% add background correction term

    if BackGroundCorrection == 1
        spc.lifetimes{chan} = spc.lifetimes{chan} - backcorr;
    end



    if PeakGeneralization == 0
        fit_start = spc.fits{chan}.fitstart/nsPerPoint;
        fit_end = spc.fits{chan}.fitend/nsPerPoint;
        n_channels = fit_end - fit_start +1;
    
        lft_points=[0.5:1:n_channels-0.5]*nsPerPoint;
    %         peak_point=find(spc.lifetimes{chan}==max(spc.lifetimes{chan}));
        empirical_lifetimes=spc.lifetimes{chan}(fit_start:fit_end);
        spc.fits{chan}.EmpTauTrunc=sum(empirical_lifetimes.*lft_points')/sum(empirical_lifetimes); % calculation of empirical lifetime, Pingchuan added 06.28.21
    end
    
    if PeakGeneralization == 1
        peak_channel = floor(mean(find(spc.lifetimes{chan} == max(spc.lifetimes{chan}))));
        fit_start = peak_channel;
        fit_end = peak_channel + PostPeakChannels -1;
    
        lft_points=[0.5:1:PostPeakChannels-0.5]*nsPerPoint;
    %         peak_point=find(spc.lifetimes{chan}==max(spc.lifetimes{chan}));
        empirical_lifetimes=spc.lifetimes{chan}(fit_start:fit_end);
        spc.fits{chan}.EmpTauTrunc=sum(empirical_lifetimes.*lft_points')/sum(empirical_lifetimes); % calculation of empirical lifetime generalized by peak channels, Pingchuan added 04.12.23
    end

    if PeakGeneralization == 2
        fit_start = PeakChannelSet;
        fit_end = PeakChannelSet + PostPeakChannels -1;
    
        lft_points=[0.5:1:PostPeakChannels-0.5]*nsPerPoint;
    %         peak_point=find(spc.lifetimes{chan}==max(spc.lifetimes{chan}));
        empirical_lifetimes=spc.lifetimes{chan}(fit_start:fit_end);
        spc.fits{chan}.EmpTauTrunc=sum(empirical_lifetimes.*lft_points')/sum(empirical_lifetimes); % calculation of empirical lifetime generalized by peak channels, Pingchuan added 04.12.23
    end



        
    
%     empirical_lifetimes=spc.lifetimes{chan}(41:180); % This was trying to
%     fix the peak_channel.
    
%     empirical_lifetimes=spc.lifetimes{chan}(peak_point:(peak_point+179))-6500/256;
%     This was for background correction.
    
    

% gy 20110307 - following lines choose between 
%   average Tau (integrated 0 to inf) or avgTauTrunc
    spc.switches.truncateIntegral = 1;
    spc.switchess{chan}.truncateIntegral=1;
    if spc.switches.truncateIntegral
        spc.fits{chan}.average = spc.fits{chan}.avgTauTrunc;
    else
        spc.fits{chan}.average = spc.fits{chan}.avgTau;
    end
    
%if chan==spc_mainChannelChoice    
    spc_updateGUIbyGlobal('spc.fits',chan,'pop1');
    spc_updateGUIbyGlobal('spc.fits',chan,'pop2');
    spc_updateGUIbyGlobal('spc.fits',chan,'avgTau');
    spc_updateGUIbyGlobal('spc.fits',chan,'avgTauTrunc');
%end
  
    
    
