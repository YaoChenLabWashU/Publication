function [lft_all,intensity_all, EpochStartAcq_all, AcqTime_all] = FLIM_posthoc_dendriteMode(CyclePositions)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

global stateYao

%% Acquisition time for each cycle position
i_acq_num=size(stateYao.AcqTime,1);
i_cycleposition=length(CyclePositions);

% time stamp of the data for each cycle positions
AcqTime_all = {};

for i=CyclePositions(1):CyclePositions(i_cycleposition)
    eval(['AcqTime',num2str(i),'=stateYao.AcqTime(:,',num2str(i),');'])
    eval(['AcqTime_all{',num2str(i),'}=AcqTime',num2str(i),'-AcqTime',num2str(i),'(1);'])
end

%% extract the information of when epochs start, in the form of number of acquisition

Epochnum=Epochnumbers([stateYao.baseName,'.xlsx']); % customerized function 'Epochnumbers'
Cycleidentifications_all = zeros(1, length(CyclePositions));
for i = 1:length(CyclePositions)
    Cycleidentifications_all(i) = stateYao.CycleIdentification{i,1};
end
Epochnum(1) = min(Cycleidentifications_all);

EpochStartTime=[];
EpochStartAcq=[];
AcqTime=stateYao.AcqTime-stateYao.AcqTime(1); % absolute time to relative time

% based on when epoch numbers change, find the corresponding acquisition
% time and which row should be the time when epoch changes for each cycle
% position.
for i=1:size(Epochnum,2)
    if Epochnum(i) < min(min(stateYao.CyclePositions))
        Epochnum(i) = min(min(stateYao.CyclePositions));
    end
    a=find(stateYao.CyclePositions==Epochnum(i));
    [m,n]=find(stateYao.CyclePositions==Epochnum(i));
    if isempty(a)
        a=find(stateYao.CyclePositions==Epochnum(i)+1);
        [m,n]=find(stateYao.CyclePositions==Epochnum(i)+1);
    end
    
    EpochStartTime(i)=AcqTime(a);
    EpochStartAcq(i)=m;
end

EpochStartAcq_all = {};

for i=CyclePositions(1):CyclePositions(i_cycleposition)
    eval(['AcqEnd=nnz(stateYao.AcqTime(:,',num2str(i),'));'])
    eval(['EpochStartAcq_all{',num2str(i),'}=[EpochStartAcq AcqEnd];'])
    eval(['EpochStartAcq',num2str(i),'=[EpochStartAcq AcqEnd];'])

end


%% lifetime and intensity for each roi of each cycle position
% and calculate baseline and changes
lft_all = {};
intensity_all = {};

% lft_baseline_increase_all=[];
% lft_baseline_decrease_all=[];
for i=CyclePositions(1):CyclePositions(i_cycleposition)
    lft=NaN(nnz(stateYao.AcqTime(:,i)),1);
    lft_baseline=[];

    num_roi_all = zeros(1, size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i},1));
    for i_roi = 1:size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i},1)
        num_roi_all(i_roi)=size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{i_roi},2);
    end
    num_roi = max(num_roi_all);

    roi=1;
    for j=1:num_roi
        for k=1:nnz(stateYao.AcqTime(:,i))
            if isempty(stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{k}) == 0
                lft(k,roi)=stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{k}(j);
            end
        end
        roi=roi+1;
    end
    eval(['lft_all{',num2str(i),'}=lft;']);
    eval(['lft',num2str(i),'=lft;']);
    eval(['EpochStartAcq=EpochStartAcq',num2str(i),';']);
%     for l=1:num_roi
%         lft_increase_roi=[];
%         lft_decrease_roi=[];
%         lft_baseline=mean(lft(1:(EpochStartAcq(2)-1),l));
% %         lft_baseline_max=max(lft(1:(EpochStartAcq(2)-1),l));
% %         lft_baseline_min=min(lft(1:(EpochStartAcq(2)-1),l));
%         lft_change_maxs=max(lft(1:(EpochStartAcq(2)-1),l));
%         lft_change_mins=min(lft(1:(EpochStartAcq(2)-1),l));
%         for o=1:(size(EpochStartAcq,2)-2)
%             lft_change_max=max(lft(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
%             lft_change_min=min(lft(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
%             lft_change_maxs=[lft_change_maxs lft_change_max];
%             lft_change_mins=[lft_change_mins lft_change_min];
%         end
%         lft_increase_roi=lft_change_maxs-lft_baseline;
%         lft_decrease_roi=lft_baseline-lft_change_mins;
%         lft_baseline_increase_roi=[lft_baseline lft_increase_roi];
%         lft_baseline_decrease_roi=[lft_baseline lft_decrease_roi];
%         lft_baseline_increase_all=[lft_baseline_increase_all; lft_baseline_increase_roi];
%         lft_baseline_decrease_all=[lft_baseline_decrease_all; lft_baseline_decrease_roi];
%     end
    
%     eval(['lft_baseline_changes',num2str(i),'=[lft_baseline lft_changes];'])
%     eval(['lft_baseline_changes_all=[lft_baseline_changes_all, lft_baseline_changes',num2str(i),'];'])
end

% intensity_baseline_increase_all=[];
% intensity_baseline_decrease_all=[];
for i=CyclePositions(1):CyclePositions(i_cycleposition)
    intensity=NaN(nnz(stateYao.AcqTime(:,i)),1);
    intensity_baseline=[];

    num_roi_all = zeros(1, size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i},1));
    for i_roi = 1:size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i},1)
        num_roi_all(i_roi)=size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{i_roi},2);
    end
    num_roi = max(num_roi_all);

    roi=1;
    for j=1:num_roi
        for k=1:1:nnz(stateYao.AcqTime(:,i))
            if isempty(stateYao.Results.spc_calculateROIvals.Projection{i}{k}) == 0
                intensity(k,roi)=stateYao.Results.spc_calculateROIvals.Projection{i}{k}(j);
            end
        end
        roi=roi+1;
    end
    eval(['intensity_all{',num2str(i),'}=intensity;']);
    eval(['intensity',num2str(i),'=intensity;']);
    eval(['EpochStartAcq=EpochStartAcq',num2str(i),';']);
%     for l=1:num_roi
%         intensity_increase_roi=[];
%         intensity_decrease_roi=[];
%         intensity_baseline=mean(intensity(1:(EpochStartAcq(2)-1),l));
%         intensity_change_maxs=max(intensity(1:(EpochStartAcq(2)-1),l));
%         intensity_change_mins=min(intensity(1:(EpochStartAcq(2)-1),l));
%         for o=1:(size(EpochStartAcq,2)-2)
%             intensity_change_max=max(intensity(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
%             intensity_change_min=min(intensity(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
%             intensity_change_maxs=[intensity_change_maxs intensity_change_max];
%             intensity_change_mins=[intensity_change_mins intensity_change_min];
%         end
%         intensity_increase_roi=intensity_change_maxs-intensity_baseline;
%         intensity_decrease_roi=intensity_baseline-intensity_change_mins;
%         intensity_baseline_increase_roi=[intensity_baseline intensity_increase_roi];
%         intensity_baseline_decrease_roi=[intensity_baseline intensity_decrease_roi];
%         intensity_baseline_increase_all=[intensity_baseline_increase_all; intensity_baseline_increase_roi];
%         intensity_baseline_decrease_all=[intensity_baseline_decrease_all; intensity_baseline_decrease_roi];
%     end
end
end