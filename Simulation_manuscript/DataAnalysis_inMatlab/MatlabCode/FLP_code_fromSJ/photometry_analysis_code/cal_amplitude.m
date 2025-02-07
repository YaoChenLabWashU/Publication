function amplitude = cal_amplitude(data,timebin,amplitude_interval)
% calculating the amplitude of the max peak
     idx=find(data==max(data),1);
     
     start_idx=max(round(idx-amplitude_interval/2),1);
     end_idx=min(round(idx+amplitude_interval/2),length(data));   
     
     amplitude=mean(data(round(start_idx:end_idx)));
end

