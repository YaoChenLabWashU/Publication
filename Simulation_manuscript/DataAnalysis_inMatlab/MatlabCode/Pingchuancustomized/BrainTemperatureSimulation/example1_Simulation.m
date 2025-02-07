function example1_Simulation()
% An example for simulating brain temperature based on the wake/sleep state
% sequencing of a mouse. Experiment has 12:12 dark/light design, and 
% recording starts at light onset.
%
% The code is based on the article of Sela, Hoekstra & Franken, eLife 2021.
close all;

%% 1) Definitions and Loading
SF = 4; % Sampling frequency (how many seconds are represented by one sample). [Warning: The code was not tested with values different than 4].
data = load('exampleData'); % Load example data of mouse#617 (including 2 column vectors, of states and raw temperature)
states = data.states; % Sleep scoring [manually scored wake (as 4), NREM (as 5), or REM (as 6)]
rawT = data.temperatures; % Recorded temperature

%% 2) Initialization
flagsWakeREM = (states==4 | states==6); % Convert wake & REM to '1', and NREM to '0'

% Define initial input
initial_temperature = -1; % negative value produces an estimated initial temperature

% Use the median parameter values from Table 1:
p.sizePWP = 3;              % window size (in hours) of the prior wake prevelance (PWP)
p.shiftPWP = -1.4;          % window shift (in hours) of the prior wake prevelance (PWP)
p.lowerAsymptote = 34.26;   % Lower asymptote value (in C)
p.upperAsymptote =  36.28;  % Upper Asymptote value (in C)
p.wakeTimeConstant = 0.21;  % Time constant of wake and REM states
p.nremTimeConstant = 0.11;  % Time constant of NREM sleep
p.scalePWP = 1.01;          % The multiplier of PWP values
p.circadianAmplitude = 0.19;% The multiplier of the circadian values
p.circadianPhase = -0.71;   % Phase shift of circadian process (in hours)


%% 3) Run simulation
% Run simulation. Notice not to change the order of input sequence.
[simulatedT,asymptots] = simulateBrainTemperature (...
        flagsWakeREM, initial_temperature, SF, p.sizePWP, p.shiftPWP,...
        [p.lowerAsymptote, p.upperAsymptote, p.wakeTimeConstant, ...
         p.nremTimeConstant, p.scalePWP, p.circadianAmplitude, p.circadianPhase...
        ]);

% Shift the simulated dynamics on the Y axis, to best compare to raw data   
asymptots  = asymptots  - (mean(simulatedT) - mean(rawT));
simulatedT = simulatedT - (mean(simulatedT) - mean(rawT));     
    
% Calculate correlation and error of model output
correlation = corr(simulatedT,rawT)
mean_error = sqrt(nanmean( (simulatedT - rawT).^2))


%% 4) Plot results
% plot defitions
lenInHours = length(rawT)*SF/3600; 
timeAxis = (SF/3600):(SF/3600):lenInHours;

% Plot
figure; hold on;
p1=plot(timeAxis , rawT);
p2=plot(timeAxis , simulatedT);
p3=plot(timeAxis , asymptots(:,1)' , 'g');
plot(timeAxis , asymptots(:,2)' , 'g');

% Design of the plot
set(gca,'xtick',[0:12:lenInHours]); 
YLIM = get(gca,'ylim');
for i = 12:24:(lenInHours)
    p4=plotBackground([0, 12]+i, mean(YLIM), diff(get(gca,'ylim'))/2,'k');
end
p5=plotBackground([0, 6]+48, mean(YLIM), diff(YLIM)/2,'r');
xlim([0,lenInHours]); ylim(YLIM); 

% Add legend and axes title 
legend([p1,p2,p3,p4,p5],{'Recorded data','Simulation output','Asymptotes','Dark periods', 'Sleep Deprivation'},'Location','southeast');
ylabel('Temperature (C)'); xlabel('Time (Hours)');

%% 5) ~~~ Helper Functions ~~~~
% Used to plot the background for the dark periods and sleep deprivation
function ebars=plotBackground( X, Y, DEV, c)
    Y = ones(size(X))*Y;
    ebars=patch([X,fliplr(X)],[Y-DEV,fliplr(Y+DEV)],c);
    set(ebars,'EdgeColor','none');  alpha(0.25);
end

end
