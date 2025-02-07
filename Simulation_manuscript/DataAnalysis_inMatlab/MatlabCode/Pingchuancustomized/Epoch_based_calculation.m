function [epoch_response_intensity_norm_all,epoch_response_lft_norm_all,epoch_response_intensity_all,epoch_response_lft_all] = Epoch_based_calculation(all_epochs, drug_epochs, CyclePositions, baseline_acq_num, epoch_acq_num, EpochStartAcq_all, intensity_all, lft_all, FigureVisible, summary_path)
% This function is used for epoch based calculation from raw traces of
% lifetime or intensity data from 2pFLIM imaging.

% all_pochs: all the epochs this experiment has
% drug_epochs: the epochs you want to analyze out of all the epochs this
% experiment has

% Cyclepositions: cycle position numbers that you want to analyze
% baseline_acq_num: how many data points you want to take for baseline
% start calculation
% epoch_acq_num: how many data points to take for epoch based calculation
% EpochStartAcq_all: the acquisition number of when each epoch start
% intensity_all: intensity traces, each cell represent one cycleposition
% lft_all: lifetime traces, each cell respresent one cycle position

global stateYao

drug_epoch_index = zeros(1,length(drug_epochs));
for i = 1:length(drug_epochs)
    drug_epoch_index(i) = find(all_epochs == drug_epochs(i));
end

epoch_response_intensity_norm_all = {};
epoch_response_lft_norm_all = {};

epoch_response_intensity_all = {};
epoch_response_lft_all = {};

for i_cycle = 1:length(CyclePositions)

    % the intensity and lifetime raw data
    eval(['intensity = intensity_all{',num2str(CyclePositions(i_cycle)),'};']);
    eval(['lft = lft_all{',num2str(CyclePositions(i_cycle)),'};']);

    % the epoch transition points
    eval(['EpochStartAcq = EpochStartAcq_all{', num2str(CyclePositions(i_cycle)), '};'])


    % pre-define the epoch response and baseline start
    epoch_response_intensity = zeros(length(drug_epochs)-1,size(intensity, 2));
    epoch_response_lft = zeros(length(drug_epochs)-1,size(lft,2));
    baseline_start_intensity = zeros(1, size(intensity,2));
    baseline_start_lft = zeros(1, size(lft,2));
    
    % the epoch transition index in the raw data of intensity and lft
    drug_epoch_start_acq = EpochStartAcq(all_epochs-1);
    eval(['drug_epoch_start_acq_',num2str(CyclePositions(i_cycle)), '=drug_epoch_start_acq(drug_epoch_index);'])

    
    % calculation of baseline start (mean of the first x acqs)
    for i = 1:size(intensity, 2)
        baseline_start_intensity(i) = mean(intensity(drug_epoch_start_acq(1):drug_epoch_start_acq(1)+baseline_acq_num-1, i),'omitnan');
        baseline_start_lft(i) = mean(lft(drug_epoch_start_acq(1):drug_epoch_start_acq(1)+baseline_acq_num-1, i),'omitnan');
    end
    

    % calculation epoch based response (mean of last x acqs)
    cell_legends = {};
    for i_cell = 1:size(intensity, 2)
        cell_legends{i_cell} = ['Cell ', num2str(i_cell)];
    end
    intensity(1:drug_epoch_start_acq(1)-1,:) = NaN;
    figure('visible', FigureVisible);
    subplot(2,1,1);
    plot(intensity, 'LineWidth', 2)
    yline(baseline_start_intensity)
    xline(drug_epoch_start_acq(drug_epoch_index))
    title('intensity')
    legend(cell_legends,'Location', 'southeast', 'AutoUpdate','off')
    hold on

    for i = 1:size(intensity, 2)
        for j = 1:length(drug_epochs)-1
        epoch_response_intensity(j,i) = mean(intensity((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)),i),'omitnan');
        scatter((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)), intensity((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)),i),25)
        hold on
        end
    end

    hold off

    lft(1:drug_epoch_start_acq(1)-1,:) = NaN;
    subplot(2,1,2);
    plot(lft, 'LineWidth', 2)
%     ylim([3.8 4.15])
    yline(baseline_start_lft)
    xline(drug_epoch_start_acq(drug_epoch_index))
    title('lifetime')
    legend(cell_legends,'Location', 'southeast', 'AutoUpdate','off')
    hold on

    for i = 1:size(intensity, 2)
        for j = 1:length(drug_epochs)-1
        epoch_response_lft(j,i) = mean(lft((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)),i),'omitnan');
        scatter((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)), lft((drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(2)):(drug_epoch_start_acq(drug_epoch_index(j+1))-epoch_acq_num(1)),i),25)
        hold on
        end
    end
    hold off

    saveas(gcf, [summary_path, stateYao.baseName, '_', 'cycle_', num2str(CyclePositions(i_cycle)),'.fig'])
    saveas(gcf, [summary_path, stateYao.baseName, '_', 'cycle_', num2str(CyclePositions(i_cycle)),'.png'])
    
    
    epoch_response_intensity_norm = zeros(length(drug_epochs)-1,size(intensity, 2));
    epoch_response_lft_norm = zeros(length(drug_epochs)-1,size(lft,2));
    
    % first raw: baseline change, baseline response - baseline start
    epoch_response_intensity_norm(1,:) = (epoch_response_intensity(1,:) - baseline_start_intensity)./baseline_start_intensity;
    epoch_response_lft_norm(1,:) = epoch_response_lft(1,:) - baseline_start_lft;

    % normalized epoch response. intensity: df/f0; lifetime: minus baseline response
    epoch_response_intensity_norm(2:end,:) = (epoch_response_intensity(2:end,:) - epoch_response_intensity(1,:))./epoch_response_intensity(1,:);
    epoch_response_lft_norm(2:end,:) = epoch_response_lft(2:end,:) - epoch_response_lft(1,:);
    
    epoch_response_intensity_all{CyclePositions(i_cycle)} = epoch_response_intensity;
    epoch_response_lft_all{CyclePositions(i_cycle)} = epoch_response_lft;

    epoch_response_intensity_norm_all{CyclePositions(i_cycle)} = epoch_response_intensity_norm;
    epoch_response_lft_norm_all{CyclePositions(i_cycle)} = epoch_response_lft_norm;

end

CyclePositions_in_name = '';
for i_CycleName = 1:length(CyclePositions)
    CyclePositions_in_name = [CyclePositions_in_name, '_', num2str(CyclePositions(i_CycleName))];
end

currTime = datestr(datetime('now'));
currTime = currTime(1:11);
save([summary_path, stateYao.baseName, '_', currTime, CyclePositions_in_name, '.mat'], 'epoch_response_intensity_norm_all','epoch_response_lft_norm_all',...
    'epoch_response_intensity_all','epoch_response_lft_all', 'all_epochs', 'drug_epochs', 'CyclePositions',...
    'baseline_acq_num', 'epoch_acq_num', 'EpochStartAcq_all', 'intensity_all', 'lft_all', 'stateYao')

end