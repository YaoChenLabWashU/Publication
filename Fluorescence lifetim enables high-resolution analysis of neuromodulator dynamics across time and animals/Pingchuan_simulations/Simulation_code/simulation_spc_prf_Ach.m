
% filepath='/Users/pingchuanma/Documents/MATLAB/simulation/HEKcell_simulation_0710_1/';
chan=1;
lft_steps=(1:1:256)*12.5/256;

for i=1:285
    cd([filepath,'/',num2str(i)]);
%     delete FLIMSimulation_pm.mat
    matfiles = dir('*.mat');
    
    p=[];
    TauTrunc=[];
    chi2=[];
    avgTau=[];
    emp_lft=[];
    emp_lftTrunc=[];
    
    
    for j=1:1
        filename = matfiles(j).name;
        load(filename);
        spc.lifetimes{1,1} = n;
        spc_fitexp2prfGY(1);
        spc_adjustTauOffset(1);
        
        weight_n_lft=lft_steps.*n;
        empirical_lft=sum(weight_n_lft)/sum(n)-2.4471;
        
        p(j)=spc.fits{chan}.beta1/(spc.fits{chan}.beta1+spc.fits{chan}.beta3); %p1
        TauTrunc(j)=spc.fits{chan}.avgTauTrunc;%empirical lifetime; ; did not use spc_calcEmpiricalMean(chan) because the offset is not calculated every single time.
        chi2(j)=spc.fits{chan}.redchisq; %chi2
        avgTau(j)=spc.fits{chan}.avgTau; % mean Tau calculated from fit
        emp_lft(j)=empirical_lft; % empirical lft
        emp_lftTrunc(j)=spc.fits{chan}.EmpTauTrunc; %empTau truncated
    end
    
    savename=[filepath,'/',num2str(i),'_simulation_result_121421'];
    save(savename,'p','TauTrunc','chi2','avgTau','emp_lft','emp_lftTrunc');
end
        

% condition='sample only, fiexed tau, fixed delta peak time,prf fitting from 0.1 to 12.5'

% for j=0.4:0.02:0.6
% cd('HEKcell_simulation_0331AchsensorHEK001')
% lft_steps=(1:1:256)*12.5/256;
% % 
% chan=1;
% matfiles = dir('*.mat');
% 
%   for i = 1:163;
%       filename = matfiles(i).name;
%       load(filename)
%       spc_fitexp2prfGY(1);
%       spc_adjustTauOffset(1); % update TauOffset
%       spc.lifetimes{1,1} = n;
%       
%       weight_n_lft=lft_steps.*n;
%       empirical_lft=sum(weight_n_lft)/sum(n)-1.89;
%       if ~isfield(spc.fits{chan},'failedFit') || spc.fits{chan}.failedFit || ...
%             (isfield(spc.fits{chan},'redchisq') && spc.fits{chan}.redchisq > 1000)
%         % bad news - FIT FAILED - don't rewrite the fit parameters
%         Results(i)='failedFit';
%       else
%         % fit did not fail, so write the parameters
%         % Now output values.
%             p(i)=spc.fits{chan}.beta1/(spc.fits{chan}.beta1+spc.fits{chan}.beta3); %p1
%             TauTrunc(i)=spc.fits{chan}.avgTauTrunc;%empirical lifetime; ; did not use spc_calcEmpiricalMean(chan) because the offset is not calculated every single time.
%             chi2(i)=spc.fits{chan}.redchisq; %chi2
%             avgTau(i)=spc.fits{chan}.avgTau; % mean Tau calculated from fit
%             emp_lft(i)=empirical_lft; % empirical lft
%             
%       end
%       
%   
%   end
% simulationresult=['simulationfitting_Ach_0331001_prf','.mat'];
%       save (simulationresult,'p','TauTrunc','chi2','avgTau','emp_lft')
%  
% 
% % end