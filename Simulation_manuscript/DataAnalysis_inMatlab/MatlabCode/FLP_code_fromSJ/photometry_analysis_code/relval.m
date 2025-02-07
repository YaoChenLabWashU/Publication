function [rel_values] = relval(TrialData,var_name,d,trial_types,idx_start,idx_end)
%Calculates values of behavioral parameter based on difference between
%minimal and maximal amplitude of the graph
%   Detailed explanation goes here
%df/f aligned to LED DA


%getting the raw data
all_trials=selectTrialData(TrialData,var_name,d,trial_types,idx_start,idx_end);

%sorting data
transposed_trials = transpose(all_trials);
temp = [];
for i = 1:size(transposed_trials,2)
    temp2 = sortrows(transposed_trials(:,i));
    if i == 1
        temp = temp2;
    else
        temp = horzcat(temp,temp2);
    end
end

%getting min and max values from every trial
min_val = transpose(temp(1,:));
max_val = transpose(temp(round(size(temp,1)),:));
max_val = max_val - min_val;

%applying relative values based on min and max values
rel_values = zeros( size(all_trials,1), size(all_trials,2));
for trial = 1:size(all_trials,1)
    for point = 1:size(all_trials,2)
        rel_values(trial,point) = (all_trials(trial,point)-min_val(trial))/max_val(trial);
    end
end
return
