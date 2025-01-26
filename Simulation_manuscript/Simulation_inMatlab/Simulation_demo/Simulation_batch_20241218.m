
% 5. This is the content of the script for batch processing.
% use batch function for parallel computing of simulation

    p1=p1_samples(i); % Define p1
    p2=1-p1;
    n_sensor_simulated = {}; % Simulated histogram vector will be saved in this cell variable; simulated data of each sample size condition will be saved as one cell
    PopulationName=[SimulationName,'_population_',num2str(p1),'.mat']; % Define double exponential population name
    GenPop512_FLIM_v2(1000000, p1, p2, tau1, tau2, PopulationName);  % Generate the double exponential population
    parfor j=1:length(SS_samples)
        rng('shuffle','twister') % Shuffle the random number generator
        SS=SS_samples(j); % Define the sensor sample size
        n_all = zeros(500, 256); % For each sensor sample size condition, simulated data will be saved as row vectors in 'n_all' varible 
        for k=1:500 % Simulating 500 times
            [n1, n2, n] = FLIMsim512_v2(SS,PrfName, PopulationName); % Simulation with corresponding sample size (SS), IRF (PrfName), and population (PopulationName)
            n_all(k, :) = n; % Save simulated data into n_all
        end
        n_sensor_simulated{j} = n_all; % Simulated data under each sample size condition is saved as one cell in 'n_sensor_simulated'
    end
    
    % Save the simulated data under each p1 condition as one file
    simulated_name = ['Simulated_data/', num2str(p1), '_sensor.mat'];
    save(simulated_name, 'n_sensor_simulated')