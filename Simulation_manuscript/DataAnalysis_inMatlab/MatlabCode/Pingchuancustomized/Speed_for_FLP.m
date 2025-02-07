
speed_time_for_FLP=[];

for i=1:3600
    
    if isnan(time(i))==0
        if time(i)<=3600
           speed_time_for_FLP(i)=find(histc(time(i),[time_from_bonsai; 3600])==1);
        else
            speed_time_for_FLP(i)=size(time_from_bonsai,1);
        end
    end
end


speed_for_FLP=speed(speed_time_for_FLP);


speed_for_FLP=transpose(speed_for_FLP);
