

SS=SS_samples(j);
n_bkgrd_all = zeros(500, 256);
for i=1:500
    rng('shuffle','twister')
    Bkgrd_AP=(randi(round(bkgrd_AP_sum*bkgrd_ratio*0.1)))+round(bkgrd_AP_sum*bkgrd_ratio*0.95); % 10% of fluctuation
    Bkgrd_SensorAP = Bkgrd_AP + round(SS*afterpulse_ratio);
    [n_bkgrd] = AutoFluo_sim_v2(bkgrd_AP_distribution, Bkgrd_SensorAP);
    n_bkgrd_all(i, :) = n_bkgrd;
end

bkgrd_save_name = ['Simulated_data_NoAutoF_LowBg/bkgrd50_AP_', num2str(SS), '.mat'];
save(bkgrd_save_name, 'n_bkgrd_all')