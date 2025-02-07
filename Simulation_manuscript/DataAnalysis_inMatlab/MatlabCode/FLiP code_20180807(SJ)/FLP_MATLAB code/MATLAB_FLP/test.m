function [ output_args ] = test( input_args )
global testTimer;
global state;
global tauplot;
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
state.timer.abort=0;

try
    close('Real time lifetime plot');
catch
end
tauplot=figure('Name','Real time lifetime plot','NumberTitle','off');
figure(tauplot);
xlabel('time(s)');
ylabel('tau(s)');
hold on;

timerCallPackageFunctions('FirstSetup');
timerCallPackageFunctions('Setup');
timerCallPackageFunctions('Start');

testTimer=timer('TimerFcn', @(~,~)ZFLP_timerFunction, 'Period', 0.05); %The Timerfcn is automatically passed two inputs, a handle to the timer and some event data. The '~' just ignores the input.
set(testTimer, 'ExecutionMode', 'fixedRate');
start(testTimer);

end