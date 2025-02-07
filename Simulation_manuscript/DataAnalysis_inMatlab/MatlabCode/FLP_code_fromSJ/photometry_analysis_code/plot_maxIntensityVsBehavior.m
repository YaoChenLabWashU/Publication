function plot_maxIntensityVsBehavior(data,data_list,num_days,behavior,search_duration,eventtime,inputrate,timebin,plottitle)
%plot max intensity signal aligned to eventtime
%   Detailed explanation goes here
%data: intensity data 4-D array: # of days X data number X trial number X time
%d: AD channel number
%behavior: behavior time (latency, occupancy time, etc) in interest 2-D array: # of days X trial number
%search_duration: time duration for max-peak search (time after the event time)
%eventtime: event in interest
%inputrate: NIDAQ acquistion rate
%timebin: integration time for intensity data

%plot DA signal aligned to eventtime vs. latency
x=[];
y=[];
for d=data_list
    for i=2:num_days
        for j=1:size(data,3)
            idx1=eventtime*inputrate/timebin;
            idx2=(eventtime+search_duration)*1000/timebin;
            x=[x,max(data(i,d,j,idx1:idx2))];
            y=[y,behavior(i,j)];
        end
    end
end

figure(3);
plot(x,y,'.');
title(plottitle);
linear_fit=fitlm(x,y)
end