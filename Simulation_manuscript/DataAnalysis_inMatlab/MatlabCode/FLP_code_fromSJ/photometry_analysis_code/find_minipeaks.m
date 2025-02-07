function idx_peak = find_minipeaks(data,SD,range,halfwidth,timebin)
%   find peaks in the defined range
%   reward stimulus

counter=0;
i=0;
idx_peak=[];

while i<length(data)
    i=i+1;
    if data(i)>SD*2 && i>=range(1) && i<=range(2)
        counter=counter+1;
        idx_peak(counter)=i+find(data(i:i+halfwidth*2/timebin)==max(data(i:i+halfwidth*2/timebin)))-1;
        i=idx_peak(counter)+halfwidth*2/timebin; %jump at least 2 * average halfwidth to find a new peak
    end
end

end

