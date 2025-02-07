function fo=calculate_reference(data,time,baseline_duration,inputrate,timebin)
    fo=mean(data(floor((time-baseline_duration)*inputrate/timebin):floor(time*inputrate/timebin)));
end

