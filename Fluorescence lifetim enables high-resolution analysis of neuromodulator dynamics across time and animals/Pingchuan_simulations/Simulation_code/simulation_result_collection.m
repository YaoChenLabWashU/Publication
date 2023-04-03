
% filepath='/Users/pingchuanma/Documents/MATLAB/simulation/HEKcell_simulation_0710_1/';
cd(filepath);

p_all=[];
TauTrunc_all=[];
chi2_all=[];
avgTau_all=[];
emp_lft_all=[];
emp_lftTrunc_all=[];

% load([filepath,'Simulation_parameters_0710.mat']);
% photons_for_plot=[];
% for i=1:285
%     photons_for_plot(((i-1)*50+1):(i*50))= photons(i);
% end

for i=1:285
    result_file=[filepath,'/',num2str(i),'_simulation_result_121421'];
    load(result_file);
    p_all=[p_all p];
    TauTrunc_all=[TauTrunc_all TauTrunc];
    chi2_all=[chi2_all chi2];
    avgTau_all=[avgTau_all avgTau];
    emp_lft_all=[emp_lft_all emp_lft];
    emp_lftTrunc_all=[emp_lftTrunc_all emp_lftTrunc];
    
end
    
% photons_plot_baseline=[];
% 
% for i=94:163
%     photons_plot_baseline(50*(i-94)+1:50*(i-93))=ceil(photon_size(i)/3);
% end