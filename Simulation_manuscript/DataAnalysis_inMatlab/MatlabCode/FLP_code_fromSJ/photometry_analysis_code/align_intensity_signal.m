function [raw,dff] = align_intensity_signal(data,eventtime,duration,baseline_duration,inputrate,timebin,fo)
%   aligning intensity_signal to eventtime
% data: intensity_signal in V
% eventtime: time of the event in interest in seconds
% duration: total duration of the analysis per trial in seconds
% baseline_duration: duration of the baseline used for the df/f calculation in
% seconds
% inputrate: rate of intensity signal (Hz)
% timebin: timebin (integration duration) of analysis in milisecs

raw=data(floor((eventtime-baseline_duration)*inputrate/timebin):floor((eventtime-baseline_duration+duration)*inputrate/timebin));
%fo=mean(data(floor((eventtime-baseline_duration)*inputrate/timebin):floor((eventtime)*inputrate/timebin)));
dff=(raw-fo)/fo*100;

end

