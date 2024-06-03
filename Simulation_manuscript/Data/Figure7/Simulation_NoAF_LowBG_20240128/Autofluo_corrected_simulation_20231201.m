
SS=SS_samples(j);
n_auto_all = zeros(500, 256);
for i=1:500
    rng('shuffle','twister')
    AF=(randi(round(AF_mean_corrected*0.1)))+round(AF_mean_corrected*0.95); % 10% of fluctuatio
    [n_auto] = AutoFluo_sim_v2(autofluo_corrected, AF);
    n_auto_all(i, :) = n_auto;
end
autoF_save_name = ['Simulated_data/autoF_', num2str(SS), '.mat'];
save(autoF_save_name, 'n_auto_all')