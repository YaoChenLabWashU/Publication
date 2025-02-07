function example2_Optimization(rawData, num_day, optResults)
% An example for optimizing the parameters required to simulate brain 
% temperature based on the wake/sleep state sequencing of a mouse. 
% Experiment has 12:12 dark/light design, recording starts at light onset.
%
% The code is based on the article of Sela, Hoekstra & Franken, eLife 2021.
close all;  

%% 1) Definition and Loading
SF = 4; % Sampling frequency- how many seconds are between each two samples. [Warning: The code was not tested with values different than 4].
minutesToInitialT = 5; % How many minutes of raw data to average as the initial temperature

data = load(rawData); % Load example data of mouse #617
flagsWakeREM = data.states_pooled; % Sleep scoring [manually scored wake (4), NREM (5), or REM (6)]
rawT = data.tau_pooled; % Recorded temperature
circadian_time = data.circadian_time;

% % Define initial parameter values
% Tau = 0.2; % initial value of time constants, based on Franken et al. 1992
% scalePWP = 0; % set PWP to have no effect
% circadianAmp = 1; % set circadian process to have no effect
% circadianPhase = 0; % set circadian process to have no phase
% sizePWP = [0.25,0.25,10]; % Possible Values. [X,Y,Z] translated to X:Y:Z
% shiftPWP = [-5,0.1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z

% % optimization 0921
% Tau = 0.06; % initial value of time constants, based on Franken et al. 1992
% scalePWP = -0.0108; % set PWP to have no effect
% circadianAmp = 0.0229; % set circadian process to have no effect
% circadianPhase = -1.4823; % set circadian process to have no phase
% sizePWP = [0,0.1,5]; % Possible Values. [X,Y,Z] translated to X:Y:Z
% shiftPWP = [-5,0.1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z

% % optimization 0922
% Tau = 0.08; % initial value of time constants, based on Franken et al. 1992
% scalePWP = 0.0848; % set PWP to have no effect
% circadianAmp = 0.0311; % set circadian process to have no effect
% circadianPhase = -2.1236; % set circadian process to have no phase
% sizePWP = [0,0.1,5]; % Possible Values. [X,Y,Z] translated to X:Y:Z
% shiftPWP = [-5,0.1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z

% % optimization 1004
% Tau = 0.08; % initial value of time constants, based on Franken et al. 1992
% scalePWP = 0.0848; % set PWP to have no effect
% circadianAmp = 0.0311; % set circadian process to have no effect
% circadianPhase = -2.1236; % set circadian process to have no phase
% sizePWP = [0.1,0.1,5]; % Possible Values. [X,Y,Z] translated to X:Y:Z
% shiftPWP = [-5,0.1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z

% optimization 1005
Tau = 0.0957; % initial value of time constants, based on Franken et al. 1992
scalePWP = 0.0469; % set PWP to have no effect
circadianAmp = 0.0065; % set circadian process to have no effect
circadianPhase = -2.1183; % set circadian process to have no phase
sizePWP = [0.1,0.1,5]; % Possible Values. [X,Y,Z] translated to X:Y:Z
shiftPWP = [-5,0.1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z

% sizePWP = [0.25,1,10.25]; % Possible Values. [X,Y,Z] translated to X:Y:Z
% shiftPWP = [-5,1,5];  % Possible Values. [X,Y,Z] translated to X:Y:Z
% PWP: First row defines windows size, and second row defines window shift.


%% 2) Initialization


% Pack initial values
possibleValuesPWP = [sizePWP; shiftPWP]; % First row for windows size, and second row for window shift
optimzationInitialInputs = [Tau, Tau, scalePWP , circadianAmp, circadianPhase]; 

%% 3) Run optimization

% Find best parameters
[parameters, simulatedT, asymptots] = optimizeParametersForBrainTemperature(flagsWakeREM, rawT, circadian_time, num_day,...
                                minutesToInitialT, SF, optimzationInitialInputs, possibleValuesPWP);
% Print optimized values                            
p.sizePWP = parameters(1);            % window size (in hours) of the prior wake prevelance (PWP)
p.shiftPWP = parameters(2);          % window shift (in hours) of the prior wake prevelance (PWP)
p.lowerAsymptote = parameters(3);    % Lower asymptote value (in C)
p.upperAsymptote = parameters(4);    % Upper Asymptote value (in C)
p.wakeTimeConstant = parameters(5);   % Time constant of wake and REM states
p.nremTimeConstant = parameters(6);   % Time constant of NREM sleep
p.scalePWP = parameters(7);          % The multiplier of PWP values
p.circadianAmplitude = parameters(8); % The multiplier of the circadian values
p.circadianPhase = parameters(9);    % Phase shift of circadian process (in hours)
OptimizedParameters = p

% Shift the simulated dynamics on the Y axis, to best compare to raw data   
asymptots  = asymptots  - (mean(simulatedT) - mean(rawT));
simulatedT = simulatedT - (mean(simulatedT) - mean(rawT)); 

ignored_index = find(circadian_time >= 10800 & circadian_time< 10800+2700);
rawT(ignored_index) = [];
    
% Calculate correlation and error of model output
correlation = corr(simulatedT,rawT)
mean_error = sqrt(mean( (simulatedT - rawT).^2, 'omitnan'))

save(optResults,"OptimizedParameters","mean_error","correlation","simulatedT","rawT","asymptots")

%% 4) Plot results
% plot defitions
lenInHours = length(rawT)*SF/3600; 
timeAxis = (SF/3600):(SF/3600):lenInHours;

% Plot
% figure; hold on;
% p1=plot(timeAxis , rawT);
% p2=plot(timeAxis , simulatedT);
% p3=plot(timeAxis , asymptots(:,1)' , 'g');
% plot(timeAxis , asymptots(:,2)' , 'g');
% 
% % Design
% set(gca,'xtick',[0:12:lenInHours]); 
% YLIM = get(gca,'ylim');
% for i = 12:24:(lenInHours)
%     p4=plotBackground([0, 12]+i, mean(YLIM), diff(get(gca,'ylim'))/2,'k');
% end
% p5=plotBackground([0, 6]+48, mean(YLIM), diff(YLIM)/2,'r');
% xlim([0,lenInHours]); ylim(YLIM); 
% 
% % Text
% legend([p1,p2,p3,p4,p5],{'Recorded data','Simulation output','Asymptotes','Dark periods', 'Sleep Deprivation'},'Location','southeast');
% ylabel('Temperature (C)'); xlabel('Time (Hours)');


%% 5) ~~~ Helper Function ~~~~
function ebars=plotBackground( X, Y, DEV, c)
    Y = ones(size(X))*Y;
    ebars=patch([X,fliplr(X)],[Y-DEV,fliplr(Y+DEV)],c);
    set(ebars,'EdgeColor','none');  alpha(0.25);
end

end
