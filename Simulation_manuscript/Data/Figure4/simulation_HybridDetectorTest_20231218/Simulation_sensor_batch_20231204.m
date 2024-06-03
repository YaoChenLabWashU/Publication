

    p1=p1_samples(i); % define p1
    p2=1-p1;
    n_sensor_PMT_simulated = {};
    n_sensor_HBD_simulated = {};
    PopulationName=[PopulationName_prefix,'_FLP_population_',num2str(p1),'.mat']; % define double exponential population name
%     GenPop512_FLIM_v2(1000000, p1, p2, tau1, tau2, PopulationName);  % generate the double exponential population
    parfor j=1:length(SS_samples)
        rng('shuffle','twister') % added to shuffle the random number generator
        SS=SS_samples(j); % define the sensor sample size
        n_PMT_all = zeros(500, 256);
        n_HBD_all = zeros(500, 256);
        for k=1:500 % simulating 200 times
            [n1, n2, n_PMT] = FLIMsim512_FLIM_v2(SS,PrfName1, PopulationName); % simulation with afterpulse 0
            n_PMT_all(k, :) = n_PMT;

            [n1, n2, n_HBD] = FLIMsim512_FLIM_v2(SS,PrfName2, PopulationName);
            n_HBD_all(k, :) = n_HBD;
        end
        n_sensor_PMT_simulated{j} = n_PMT_all;
        n_sensor_HBD_simulated{j} = n_HBD_all;

    end

    simulated_name_PMT = ['Simulated_data/', num2str(p1), '_PMT_sensor.mat'];
    save(simulated_name_PMT, 'n_sensor_PMT_simulated')

    simulated_name_HBD = ['Simulated_data/', num2str(p1), '_HBD_sensor.mat'];
    save(simulated_name_HBD, 'n_sensor_HBD_simulated')