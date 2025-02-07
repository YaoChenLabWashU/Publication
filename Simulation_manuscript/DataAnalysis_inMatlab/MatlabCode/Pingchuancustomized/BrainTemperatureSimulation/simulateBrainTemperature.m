
function [simulatedT,asymptots] = simulateBrainTemperature(flagsWakeREM,initalT,circadian_time, num_day,SF,wind,shft,inputs)

% simulateBrainTemperature: Call this function when you want to simulate
% brain temperature based on scoring seqence and predefined parameters.
% Inputs:
%   flagsWakeREM : is a *column* binary vector where Wake and REM are marked as 1, and NREM as 0.
%   InitialT : (scalar) initial temperature at time t = 1. (if the value is -1, the initial temperature will be estimated automatically).
%   SF : a scalar indicate how many seconds are represented by one sample (Warning: The code was not tested with values different than 4).
%   PWP (Prior Wake Prevalence) parameters - 
%       hWindow: (vector of scalars) window size for PWP (in hours)
%       hShift: (vecotr of scalars) the shift of the window (in hours) forward or backward.
%       (in order to cancle use of PWP, define hWindow = 0).
%   inputs: a vector including the following scalars (in this specific order) - 
%         1) Lower temperature asymptote (degree C)
%         2) Upper temperature asymptote (degree C)
%         3) Wake time constant (in hours)
%         4) NREM time constant (in hours)
%         5) PWP muliplier factor (the wight for PWP effect
%         6) Circadian amplitude (put nan to ignore ciradian rhythm
%         7) chircadian phase (hours)
%
% Default parameters that can be used to run the code are (see Table1 in the reference below):
% initalT = -1; wind = 3; shft = -1.4; inputs = [34.26, 36.28, 0.21, 0.11, 1.01, 0.19, -0.71];
% ---> "flagsWakeREM" and "SF" are dereived directly from the sleep scoring data
% 
%
% Output:
%     simulatedT: a vector of the simulated temperautre for each sample of scoring vector
%     asymptots: The lower and upper asymptotes in every point (matrix of 2 vectors)
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


% These 3 lines are basically calling the function below which run the simulation
s = '[simulatedT, asymptots] = runSimulation(flagsWakeREM,initalT, circadian_time, num_day,SF,wind,shft,inputs(1)';
for iVar = 2:length(inputs), s = [s,',inputs(',num2str(iVar),')']; end
eval([s, ');']);    

%% Main Function - Generate simulated temperature
function [simulatedT, asymptots] = runSimulation(flagsWakeREM, initalT,circadian_time, num_day, SF, hWindow, hShift, ...
                                lowAsmp, upAsmp, TauW, TauN, scalePWP, circadianAmp, circadianPhase)

    if initalT <= 0 % If there is no Initial T, estimate it by first 7 minutes of sleep scoring (see Sela et al)
%         initalT = 0.92265*(mean(flagsWakeREM(2701:2700+floor(7*60/SF)))) + 34.3282;
        initalT = 0.092265*(mean(flagsWakeREM(2701:2700+floor(7*60/SF)))) + 4.14;
    end

    % 1) Defintions
    len = length(flagsWakeREM);                       
    hour = 3600/SF;
%     simulatedT = nan(len,1); % initizilize output
%     simulatedT(1) = initalT;  % Set intial T
    hWindow = floor(hWindow*hour); % Convert units: from value in hours to samples
    hShift = floor(hShift*hour); % Convert units: from value in hours to samples
    circadianPhase = circadianPhase / (24/2/pi); % Convert units: from value in hours to samples
    exponents = [exp(-1/hour/TauW),exp(-1/hour/TauN)]; % exponents in the formula are constant once TawW & TawN are defined. cacluate their values.


    % 2) Build temperature asymptote vectors
    
    
    % Estimate the effect of PWP on asymptotes
    asyPWP = zeros(length(flagsWakeREM)+hWindow,1);   
    if hWindow > 0 % If PWP is required
        % Create artifical prerecording scoring based on mean baseline days
%         asyPWP(1:hWindow) = ( flagsWakeREM(24*hour-(1:hWindow)) + flagsWakeREM(48*hour-(1:hWindow)) )/2;
        asyPWP(1:hWindow) = zeros (length(hWindow), 1) + 1;
        % Insert the real state data to vector rest of the vector
        asyPWP(hWindow+1:end) = double(flagsWakeREM);
        % Moving average of vigilance state
        asyPWP = movmean(asyPWP,[hWindow-1,0]);
        % Remove the artifical addition
        asyPWP(1:hWindow) = [];
%         global mean_asyPWP
        mean_asyPWP = mean(asyPWP);
        % Normalized across zero (subtraction of mean) and multiple

%         asyPWP = (asyPWP-mean(asyPWP))*scalePWP*2;
        asyPWP = (asyPWP-mean_asyPWP)*scalePWP*2;
        display(mean_asyPWP)

        % Shift window - add zero padding to either direction
        if hShift < 0
            asyPWP = [asyPWP((abs(hShift)+1):end) ; zeros(abs(hShift),1)];
        else, asyPWP = [zeros(hShift,1) ; asyPWP(1:(end-hShift))];
        end        
    end
    
    

    ignored_index = find(circadian_time >= 10800 & circadian_time< 10800+2700);
    flagsWakeREM(ignored_index) = [];
    circadian_time(ignored_index) = [];
    asyPWP(ignored_index) = [];
    len = length(flagsWakeREM);

%     global middle_inputs
% 
%     middle_inputs = {};
%     middle_inputs{1} = flagsWakeREM;
%     middle_inputs{2} = circadian_time;
%     middle_inputs{3} = asyPWP;

%     simulatedT = nan(len,1); % initizilize output

    % Estimate the effect of circadian ryhtem of asymptotes
    if any(isnan([circadianAmp ,circadianPhase])), circadianAmp = 0; circadianPhase = 0; end % If given nan for circadian, ignore it
    sine24H=-1*sin( 2*pi*(1/24)*(circadian_time*1/hour) +circadianPhase )*circadianAmp;

    simulatedT = nan(len,1); % initizilize output
    simulatedT(1) = initalT;  % Set intial T


    % Incorporate the two effects to base asymptotic values
    upperAsymptote = upAsmp + asyPWP + sine24H;
    lowerAsymptote = lowAsmp + asyPWP + sine24H;
    asymptots = [lowerAsymptote,upperAsymptote];

    % 3) Run simulation - estimate the temperature in each sample after t=1
    for i = 2:len
        if flagsWakeREM(i) == 1
            simulatedT(i) = upperAsymptote(i) - (upperAsymptote(i) - simulatedT(i-1))*exponents(1);
        elseif flagsWakeREM(i) == 0
            simulatedT(i) = lowerAsymptote(i) + (simulatedT(i-1) - lowerAsymptote(i))*exponents(2);
        else
            simulatedT(i)=simulatedT(i-1);
        end
    end
end

end