function idx_peak = find_peaks(data,threshold,range,halfwidth,ISI,timebin,timebinconversion)
%   find peaks in the defined range
%   reward stimulus

counter=0;
i=0;
idx_peak=[];

while i<length(data)
    i=i+1;    
    if data(i)>threshold && i>=range(1) && i<=range(2) && round(i+halfwidth*timebinconversion*2/timebin)<=length(data) && i-halfwidth*timebinconversion/timebin>=1
        counter=counter+1;
        idx_peak(counter)=round(i-halfwidth*timebinconversion/timebin) + find( data(round(i-halfwidth*timebinconversion/timebin):round(i+halfwidth*timebinconversion/timebin)) == max(data(round(i-halfwidth*timebinconversion/timebin):round(i+halfwidth*timebinconversion/timebin))) , 1) -1;
        i=idx_peak(counter)+round(ISI*timebinconversion/timebin); %jump at least ISI to find a new peak
    end
    
    if i>range(2)
        break;
    end
end

