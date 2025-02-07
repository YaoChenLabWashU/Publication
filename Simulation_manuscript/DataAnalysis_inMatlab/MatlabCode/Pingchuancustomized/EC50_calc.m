function [intensity_response_EC50,lft_response_EC50] = EC50_calc(drug_epochs, epoch_response_intensity, epoch_response_lft)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
intensity_response_EC50 = zeros(length(drug_epochs)-1,size(epoch_response_intensity, 2));
lft_response_EC50 = zeros(length(drug_epochs)-1,size(epoch_response_intensity, 2));

for i = 1:size(epoch_response_intensity, 2)
    baseline_intensity = epoch_response_intensity(1,i);
    max_response_intensity = max(epoch_response_intensity(:,i));
    intensity_response_EC50(:,i) = (epoch_response_intensity(:,i) - baseline_intensity)/(max_response_intensity - baseline_intensity);
    
    baseline_lft = epoch_response_lft(1,i);
    max_response_lft = max(epoch_response_lft(:,i));
    lft_response_EC50(:,i) = (epoch_response_lft(:,i) - baseline_lft)/(max_response_lft - baseline_lft);
end

end