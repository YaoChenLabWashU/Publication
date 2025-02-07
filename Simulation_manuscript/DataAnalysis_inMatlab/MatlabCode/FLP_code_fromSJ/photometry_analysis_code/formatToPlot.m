function [output] = formatToPlot(TrialData,var_name,d,trial_types,idx_start,idx_end)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
    output=[];
    counter=0;
    
    for i=idx_start:idx_end
        flag=0;
        for j=1:length(trial_types)
            if(TrialData(i).trialtype == trial_types(j))
                flag=1;
            end
        end
        
        if(flag==1)
            x=eval(['TrialData(i).',var_name]);
            
            if(x(d,1)~=0) %if data (TrialData(i).varname(d,:)) exists
                counter=counter+1;
                output(counter,:)=x(d,:);
            end
        end
    end
end