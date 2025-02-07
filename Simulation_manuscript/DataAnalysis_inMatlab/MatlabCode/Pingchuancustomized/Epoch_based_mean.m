function [epoch_response_intensity_norm_all, epoch_response_lft_norm_all] = Epoch_based_mean(drug_epochs,CyclePositions, baseline_acq_num, epoch_acq_num)
% 'drug_epochs' needs to be 
%   Detailed explanation goes here

epoch_response_intensity_norm_all = {};
epoch_response_lft_norm_all = {};

for i_cycle = 1:length(CyclePositions)

    eval(['intensity = intensity', num2str(CyclePositions(i_cycle)), ';'])
    eval(['lft = lft', num2str(CyclePositions(i_cycle)), ';'])
    eval(['EpochStartAcq = EpochStartAcq', num2str(CyclePositions(i_cycle)), ';'])


    epoch_response_intensity = zeros(length(drug_epochs),size(intensity, 2));
    epoch_response_lft = zeros(length(drug_epochs),size(lft,2));
    baseline_start_intensity = zeros(1, size(intensity,2));
    baseline_start_lft = zeros(1, size(lft,2));
    
    drug_epoch_start_acq = EpochStartAcq(drug_epochs-1);
    
    for i = 1:size(intensity, 2)
        baseline_start_intensity(i) = mean(intensity(drug_epoch_start_acq(1):drug_epoch_start_acq(1)+baseline_acq_num, i));
        baseline_start_lft(i) = mean(lft(drug_epoch_start_acq(1):drug_epoch_start_acq(1)+baseline_acq_num, i));
    end
    
    for i = 1:size(intensity, 2)
        for j = 1:length(drug_epochs)-1
        epoch_response_intensity(j,i) = mean(intensity((drug_epoch_start_acq(j+1)-epoch_acq_num):(drug_epoch_start_acq(j+1)-1),i));
        epoch_response_lft(j,i) = mean(lft((drug_epoch_start_acq(j+1)-epoch_acq_num):(drug_epoch_start_acq(j+1)-1),i));
        end
    end
    
    epoch_response_intensity_norm = (epoch_response_intensity - baseline_start_intensity)./baseline_start_intensity;
    epoch_response_lft_norm = epoch_response_lft - baseline_start_lft;

end



end