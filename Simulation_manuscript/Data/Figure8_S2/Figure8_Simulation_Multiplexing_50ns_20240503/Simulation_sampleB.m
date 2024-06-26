
% Simulation_sampleB.m
rng('shuffle','twister') % Shuffle the random number generator
n_sensor_all = zeros(500, 256); % For each sensor sample size condition, simulated data will be saved as row vectors in 'n_all' varible 
for k=1:500 % Simulating 500 times
    [n1, n2, n] = FLIMsim512_v3(50, SS,PrfName, PopulationName); % Simulation with corresponding sample size (SS), IRF (PrfName), and population (PopulationName)
    n_sensor_all(k, :) = n; % Save simulated data into n_all
end
% Save the simulated data under each p1 condition as one file
simulated_name = ['Simulated_data/SampleB_',num2str(tau2), '_', num2str(SS), '_sensor.mat'];
save(simulated_name, 'n_sensor_all')