

    p1=p1_samples(i); % define p1
    p2=1-p1;
    n_sensor_simulated = {};
    PopulationName=[SimulationName,'_FLP_population_',num2str(p1),'.mat']; % define double exponential population name
%     GenPop512_FLIM_v2(1000000, p1, p2, tau1, tau2, PopulationName);  % generate the double exponential population
    for j=1:length(SS_samples)
        rng('shuffle','twister') % added to shuffle the random number generator
        SS=SS_samples(j); % define the sensor sample size
        n_all = zeros(500, 256);
        for k=1:500 % simulating 500 times
            [n1, n2, n] = FLIMsim512_v2(SS,PrfName, PopulationName); % simulation with afterpulse 0
            n_all(k, :) = n;
        end
        n_sensor_simulated{j} = n_all;
    end

    simulated_name = ['Simulated_data/', num2str(p1), '_sensor.mat'];
    save(simulated_name, 'n_sensor_simulated')