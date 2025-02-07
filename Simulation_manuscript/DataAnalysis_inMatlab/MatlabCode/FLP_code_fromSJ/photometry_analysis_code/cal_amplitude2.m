function amplitude = cal_amplitude2(data,idx_peak,timebin,amplitude_interval)
% calculating the amplitude from the input peak location
     idx=idx_peak;
     amplitude=mean(data(idx-floor(amplitude_interval/2):idx+floor(amplitude_interval/2)));
end

