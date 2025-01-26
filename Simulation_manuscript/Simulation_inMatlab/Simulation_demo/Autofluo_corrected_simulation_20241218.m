% 9. the script for batch processing of simulation of autofluorescence

    SS=SS_samples(j); % Generate a set of simulated autofluorescence for each sensor sample size condition
    n_auto_all = zeros(500, 256); % Simulated data will be saved as a row vector in 'n_auto_all'
    rng('shuffle','twister') % Shuffle the random number generator
    for i=1:500 % Simulating 500 times
        AF=(randi(round(AF_mean_corrected*0.1)))+round(AF_mean_corrected*0.95); % Introduce 10% of fluctuation of the autofluorescence photon number
        [n_auto] = AutoFluo_sim_v2(autofluo_corrected, AF); % Simulation of autofluorescence based on autofluorescence distribution 'autofluo_corrected' and autofluorescence photon number 'AF'
        n_auto_all(i, :) = n_auto; % Save simulated data as a row vector in 'n_auto_all'
    end
    % Save the simulated data under each photon number condition as one file
    autoF_save_name = ['Simulated_data/autoF_', num2str(SS), '.mat'];
    save(autoF_save_name, 'n_auto_all')
