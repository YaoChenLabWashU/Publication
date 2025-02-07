function [parameters, simulatedT, asymptots] = optimizeParametersForBrainTemperature(flagsWakeREM, T, circadian_time, num_day,minutesToInitialT, SF, optimzationInitialInputs, sHP)
    
% optimizeParametersForBrainTemperature: This function optimizes the
% parameters needed for simulation of brain temperature, by minimizing the 
% mean squared error (MSE) of the difference between the model and the 
% raw temperature recorded.
%
% Inputs:
%   flagsWakeREM : is a *column* biary vector where Wake and REM are marked as 1, and NREM as 0.
%   T : Temperature vector (numerical values), in the same size as 'flagsWakeREM'
%   minutesToInitialT : The number of minutes the code will average from 
%   vector 'T' to determine the initial temperaure (at t=1).
%   SF : how many seconds are in one sample (Warning: The code was not tested with values different than 4).
%   optimzationInitialInputs: a vectors of the initial values for the parameters to optimize (in this specific order):
%         1) Lower temperature asymptote (degree C)
%         2) Upper temperature asymptote (degree C)
%         3) Wake time constant (in hours)
%         4) NREM time constant (in hours)
%         5) PWP muliplier factor (the wight for Prior Wake Prevalence)
%         6) Circadian amplitude (put nan to ignore circadin modulation)
%         7) chircadian phase (hours)
%   sHP : is a 2x3 matrix, containing in the firs row the sequence of values to be tested for 'window size' , and in the second row 'window shift' 
%		Values are [X,Y,Z] indicate the code will iterate through X and Z (X&Z included), with stepsize of Y. e.g. [3,4,15] = 3,7,11,15.
%
%
% Output:
%   Parameters: a numerical vector containing the optimized variables required for
%   simulating brain temperature (including the 2 separate PWP parameters):
%     Parameters(1) = lower temperature asymptote (optimized)
%     Parameters(2) = upper temperature asymptote (optimized)
%     Parameters(3) = Wake time constant (optimized)
%     Parameters(4) = NREM time constant (optimized)
%     Parameters(5) = PWP muliplier (optimized)
%     Parameters(6) = Circadian amplitude (optimized)
%     Parameters(7) = chircadian phase (optimized)
%     Parameters(8) = Best window size (for PWP)
%     Parameters(9) = Best window shift (for PWP)
%
%   simulatedT: Simulated temperautre, for every sample of scoring vector
%   asymptots: The lower and upper asymptotes in every point (matrix of 2 vectors)
% 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The code is based on the article of Sela, Hoekstra & Franken, eLife 2021.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (C) 2021, Yaniv Sela, Marieke Hoekstra and Paul Franken.
% All rights reserved. Contact Info: YanivDoar@gmail.com, Paul.Franken@unil.ch
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Turn off optional warnings
    warning('off','optimlib:checkbounds:PadUbWithInf');
    warning('off','optimlib:checkbounds:PadLbWithMinusInf');
    
    % The code will 1) itereate through the PWP different values, 2)for
    % each combination optimize the parameter, and 3) keep the one
    % producing the smalles error
    ignored_index = find(circadian_time >= 10800 & circadian_time< 10800+2700);
    T(ignored_index) = [];
    initalT = mean(T(1:(minutesToInitialT*60/SF)));
    err=inf;
    wndValues = (sHP(1,1):sHP(1,2):sHP(1,3)); % Hourly values
    sftValues = (sHP(2,1):sHP(2,2):sHP(2,3)); % Hourly values
    % Loop through the PWP window & shift possibilitys
    bestWindow = nan;  bestShift = nan; bestErr = inf; bestOptimizations = nan;
    for wind_i = 1:length(wndValues)
        for shft_i =  1:length(sftValues)
            wind = wndValues(wind_i); shft = sftValues(shft_i);
            % display progress of optimization
            disp(num2str(round([shft_i + (wind_i-1)*length(sftValues),length(wndValues).*length(sftValues),wind, shft],4), 'iteration %d/%d: PWP values of size and shift are [%.2f , %.1f].'));
            % Run optimization
            optimzationOutputs = optimizeSimulation(flagsWakeREM, T,initalT,circadian_time,num_day,SF,wind,shft, [min(T), max(T), optimzationInitialInputs]);
            % Get error of simulation
            simulatedT = simulateBrainTemperature(flagsWakeREM,initalT,circadian_time,num_day,SF,wind,shft,optimzationOutputs);
            err = mean( (simulatedT - T).^2, 'omitnan');
            % If model is best so far, save the parameters
            if err < bestErr
                bestWindow = wind; bestShift = shft; bestErr = err;
                bestOptimizations = optimzationOutputs;
            end
        end
    end
    
    % Run again the simulation with best parameters
    [simulatedT, asymptots] = simulateBrainTemperature(flagsWakeREM,initalT,circadian_time, num_day,SF,bestWindow,bestShift,bestOptimizations);
    % Save final parameters
    parameters = [bestWindow,bestShift,bestOptimizations];
    
    % Turn back on optional warnings
    warning('on','optimlib:checkbounds:PadUbWithInf');
    warning('on','optimlib:checkbounds:PadLbWithMinusInf');

    %% Inner function - Actually do the optimization with 'fmincon' function
    function outputs = optimizeSimulation(states, T, initalT,circadian_time, num_day,SF,wind,shft, optimzationInputs)
        % Try to optimize the optimzation variables, by minimizing the mean squared error between simulation and raw data
        f = @(optimzationInputs)objective(optimzationInputs, states,T,initalT,circadian_time, num_day,SF,wind,shft);
        LB = [-2*[1,1]+min(T),    0,    0, -inf,    0, -inf];
        UB = [+2*[1,1]+max(T), +inf, +inf, +inf, +inf, +inf];
        if isnan(optimzationInputs(6)), LB(6) = -inf; end % if no Circadian (i.e. phase is NaN)- its LowerBound (LB) is not relevant. Since NaN cannot have LB, put -inf.

        outputs = fmincon(f, optimzationInputs,[],[],[],[],LB,UB,[],optimset('Display','off'));

        function err = objective(vars, states,T,initalT,circadian_time, num_day,SF,wind,shft)
            simulatedTemperature = simulateBrainTemperature(states,initalT,circadian_time, num_day,SF,wind,shft,vars);
            err = mean( (simulatedTemperature - T).^2, 'omitnan');
        end
    end
end