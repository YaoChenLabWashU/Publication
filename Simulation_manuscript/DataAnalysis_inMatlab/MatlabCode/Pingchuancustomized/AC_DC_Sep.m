

% This script is to separate the DC/AC component of FLP data using
% Butterworth filtering.

%For digital filters, the cutoff frequencies must lie between 0 and 1, where 1 corresponds to the Nyquist rate?half the sample rate or ? rad/sample.
%For analog filters, the cutoff frequencies must be expressed in radians per second and can take on any positive value.
% time=time_serial;
signal_to_filter=tau_empTrunc;
% signal_to_filter=intensity_serial;

order=6;
Nyquist=0.5*3489/3600;% Nyquist rate -- half the sample rate.
CutoffLow=0.005;
normalizedCutoffLow = CutoffLow / Nyquist;
[b1,a1]=butter(order,normalizedCutoffLow,'low');
tau_empTrun_DC=filtfilt(b1,a1,signal_to_filter);

figure
plot(time, signal_to_filter);
hold on
plot(time, tau_empTrun_DC);


CutoffHigh=0.01;
normalizedCutoffHigh = CutoffHigh / Nyquist;
[b2,a2]=butter(order,normalizedCutoffHigh,'high');
tau_empTrunc_AC=filtfilt(b2,a2,signal_to_filter);

figure
yyaxis left
plot(time, signal_to_filter);
yyaxis right
hold on
plot(time, tau_empTrunc_AC);

