

% 14. The script for batch processing of simulation of background

    n_bkgrd_all = zeros(500, 256) % Simulated data will be saved as a row vector in 'n_bkgrd_all'
    for i=1:500
        rng('shuffle','twister')
        Bkgrd_AP=(randi(round(bkgrd_sum*0.1)))+round(bkgrd_sum*0.95); % Introduce 10% of fluctuation of the background photon number
        Bkgrd_SensorAP = Bkgrd_AP + round(SS*afterpulse_ratio); % Adding afterpulse to the background based on the sample size (SS) and the afterpulse ratio (afterpulse_ratio)
        [n_bkgrd] = AutoFluo_sim_v2(bkgrd_AP_distribution, Bkgrd_SensorAP); % Simulation of background and afterpulse based on background distribution 'bkgrd_AP_distribution' and background and afterpulse photon number 'Bkgrd_SensorAP'
        n_bkgrd_all(i, :) = n_bkgrd; % Save simulated data as a row vector in 'n_bkgrd_all'
    end
 % Save the simulated data under each photon number condition as one file
    bkgrd_save_name = ['Simulated_data/bkgrd_AP_', num2str(SS), '.mat'];
    save(bkgrd_save_name, 'n_bkgrd_all')
    
%     Subject = 'Simulation done';
%     TextMessage = [SimulationName, ': Simulation task background ', num2str(SS), ' is done.'];
%     send_text_message('314-xxx-xxxx','verizon',Subject,TextMessage)