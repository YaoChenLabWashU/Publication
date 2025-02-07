function [sample] = check_length(ref_length,sample)
%Checks the length of input for plotting and makes equal if the values
%differ less then 10 values. Can add max 10 datapoints at the end of the
%graph which are equal to the last datapoint!
%   Detailed explanation goes here
sample_length = length(sample);



if ref_length == sample_length || isempty(sample)
    return
    
elseif sample_length>ref_length
    difference =  sample_length - ref_length;
    if difference< 10
        sample = sample(:,1:ref_length);
        return
    else
        disp('length of sample is more then 10 values bigger then the regular trial. Script stopped')
        uiwait()
        return
    end
    
elseif sample_length<ref_length
    rows = size(sample,1);
    difference = ref_length - sample_length;
    if difference< 10
        endvalue = sample(end);
        addedrows = [];
        for x = 1:rows
            addedrows(x) = endvalue;
        end   
        
        
        for i = 1:difference
            sample = [sample addedrows'];
        end
        disp( [num2str(difference) ' values were added to the end of the data for plotting purposes'])
        return
    else
        disp(['length of sample is more then 10 values bigger then the regular trial. Script stopped'])
        uiwait()
        return
    end
    
end

