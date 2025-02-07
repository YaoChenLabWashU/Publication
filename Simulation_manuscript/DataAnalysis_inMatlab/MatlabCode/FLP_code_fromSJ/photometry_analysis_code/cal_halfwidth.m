function half_width = cal_halfwidth(data,timebin)
% calculating the halfwidth the max peak of the data array
    idx=find(data==max(data),1);
    
    k=idx;
    while(1)
        if(data(k)<0.5*data(idx) || k<=1)
            idx_start=k;
            break;
        end
        k=k-1;
    end

    k=idx;
    while(1)
        if(data(k)<0.5*data(idx) || k>=length(data))
            idx_end=k;
            break;
        end
        k=k+1;
    end
    half_width=(idx_end-idx_start)*timebin/1000;
end

