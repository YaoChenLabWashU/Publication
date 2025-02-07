% For summarizing and plotting the pos-hoc analysis

% %% input how many epochs and what is each epoch
% epoch_num=input('How many epochs are there?: ');
% epoch_names={};
% for i=1:epoch_num
%     epoch_names{i}=input(['What is epoch',num2str(i),'?: '],'s');
% %     epoch_names=[epoch_names;epoch_name];
% end
% 
% 
% %% Acquisition time for each cycle position
i_acq_num=size(stateYao.AcqTime,1);
i_cycleposition=size(stateYao.AcqTime,2);
% 
% 
% for i=1:i_cycleposition
%     eval(['AcqTime',num2str(i),'=stateYao.AcqTime(:,',num2str(i),');'])
%     eval(['AcqTime',num2str(i),'=AcqTime',num2str(i),'-AcqTime',num2str(i),'(1);'])
% end
% 
% %% input the roi numbers for each cycleposition
% 
roi_nums=[];
for i=1:i_cycleposition
    input_roi=input(['How many rois in cycleposition_',num2str(i),'?: '])
    roi_nums=[roi_nums input_roi];
end

%% extract the information of when epochs start, in the form of number of acquisition

Epochnum=Epochnumbers(gui.gy.filename.base); % customerized function 'Epochnumbers'
EpochStartTime=[];
EpochStartAcq=[];
AcqTime=stateYao.AcqTime-stateYao.AcqTime(1); % absolute time to relative time

% based on when epoch numbers change, find the corresponding acquisition
% time and which row should be the time when epoch changes for each cycle
% position.
for i=1:size(Epochnum,2)
    a=find(stateYao.CyclePositions==Epochnum(i));
    [m,n]=find(stateYao.CyclePositions==Epochnum(i));
    EpochStartTime(i)=AcqTime(a);
    EpochStartAcq(i)=m;
end

for i=1:i_cycleposition
    eval(['AcqEnd=nnz(stateYao.AcqTime(:,',num2str(i),'));'])
    eval(['EpochStartAcq',num2str(i),'=[EpochStartAcq AcqEnd];'])

end


%% lifetime and intensity for each roi of each cycle position
% and calculate baseline and changes

lft_baseline_changes_all_c=[];
lft_baseline_changes_all_n=[];
for i=1:1 % i_cycleposition
    lft_c=[];
    lft_n=[];
    lft_baseline_c=[];
    lft_baseline_n=[];
%     num_roi=size(stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{10},1); % Use 10th to read out the size, because sometimes the 1st one is with unneeded roi and even deleted, the lifetime data is still there. 
    roi=1;
    for j=1:roi_nums(i)
        for k=1:nnz(stateYao.AcqTime(:,i))
            lft_c(k,roi)=stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{k}(j,2);
            lft_n(k,roi)=stateYao.Results.spc_calculateROIvals.LifetimeMap{i}{k}(j,1);
        end
        roi=roi+1;
    end
    eval(['lft_c_',num2str(i),'=lft_c;']);
    eval(['lft_n_',num2str(i),'=lft_n;']);
    eval(['EpochStartAcq=EpochStartAcq',num2str(i),';']);
    
    for l=1:roi_nums(i)
        lft_changes_roi_c=[];
        lft_baseline_c=mean(lft_c(1:(EpochStartAcq(2)-1),l));
        lft_change_maxs_c=[];
        lft_change_mins_c=[];
        
        lft_changes_roi_n=[];
        lft_baseline_n=mean(lft_n(1:(EpochStartAcq(2)-1),l));
        lft_change_maxs_n=[];
        lft_change_mins_n=[];
        
        for o=1:(size(EpochStartAcq,2)-2)
            lft_change_max_c=max(lft_c(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            lft_change_min_c=min(lft_c(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            lft_change_maxs_c=[lft_change_maxs_c lft_change_max_c];
            lft_change_mins_c=[lft_change_mins_c lft_change_min_c];
            
            lft_change_max_n=max(lft_n(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            lft_change_min_n=min(lft_n(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            lft_change_maxs_n=[lft_change_maxs_n lft_change_max_n];
            lft_change_mins_n=[lft_change_mins_n lft_change_min_n];
        end
        
%         Use max when there's a lifetime increase
%         lft_changes_roi_c=lft_change_maxs_c-lft_baseline_c;
%         lft_baseline_changes_roi_c=[lft_baseline_c lft_changes_roi_c]
%         lft_baseline_changes_all_c=[lft_baseline_changes_all_c; lft_baseline_changes_roi_c];
%         
%         lft_changes_roi_n=lft_change_maxs_n-lft_baseline_n;
%         lft_baseline_changes_roi_n=[lft_baseline_n lft_changes_roi_n]
%         lft_baseline_changes_all_n=[lft_baseline_changes_all_n; lft_baseline_changes_roi_n];

%         Use min when there's lifetime decrease
        lft_changes_roi_c=lft_baseline_c-lft_change_mins_c;
        lft_baseline_changes_roi_c=[lft_baseline_c lft_changes_roi_c]
        lft_baseline_changes_all_c=[lft_baseline_changes_all_c;
        lft_baseline_changes_roi_c];
        
        lft_changes_roi_n=lft_baseline_n-lft_change_mins_n;
        lft_baseline_changes_roi_n=[lft_baseline_n lft_changes_roi_n]
        lft_baseline_changes_all_n=[lft_baseline_changes_all_n;
        lft_baseline_changes_roi_n];

    end
    
%     eval(['lft_baseline_changes',num2str(i),'=[lft_baseline lft_changes];'])
%     eval(['lft_baseline_changes_all=[lft_baseline_changes_all, lft_baseline_changes',num2str(i),'];'])
end

intensity_baseline_changes_all_c=[];
intensity_baseline_changes_all_n=[];
for i=1:1 %i_cycleposition
    intensity_c=[];
    intensity_baseline_c=[];
    intensity_n=[];
    intensity_baseline_n=[];
%     num_roi=size(stateYao.Results.spc_calculateROIvals.Projection{i}{10},1);
    roi=1;
    for j=1:roi_nums(i)
        for k=1:1:nnz(stateYao.AcqTime(:,i))
            intensity_c(k,roi)=stateYao.Results.spc_calculateROIvals.Projection{i}{k}(j,2);
            intensity_n(k,roi)=stateYao.Results.spc_calculateROIvals.Projection{i}{k}(j,1);
        end
        roi=roi+1;
    end
    eval(['intensity_c_',num2str(i),'=intensity_c;']);
    eval(['intensity_n_',num2str(i),'=intensity_n;']);
    eval(['EpochStartAcq=EpochStartAcq',num2str(i),';']);
    for l=1:roi_nums(i)
        intensity_changes_roi_c=[];
        intensity_baseline_c=mean(intensity_c(1:(EpochStartAcq(2)-1),l));
        intensity_change_maxs_c=[];
        intensity_change_mins_c=[];
        
        intensity_changes_roi_n=[];
        intensity_baseline_n=mean(intensity_n(1:(EpochStartAcq(2)-1),l));
        intensity_change_maxs_n=[];
        intensity_change_mins_n=[];
        for o=1:(size(EpochStartAcq,2)-2)
            intensity_change_max_c=max(intensity_c(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            intensity_change_min_c=min(intensity_c(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            intensity_change_maxs_c=[intensity_change_maxs_c intensity_change_max_c];
            intensity_change_mins_c=[intensity_change_mins_c intensity_change_min_c];
            
            intensity_change_max_n=max(intensity_n(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            intensity_change_min_n=min(intensity_n(EpochStartAcq(o+1):EpochStartAcq(o+2),l));
            intensity_change_maxs_n=[intensity_change_maxs_n intensity_change_max_n];
            intensity_change_mins_n=[intensity_change_mins_n intensity_change_min_n];
        end
        intensity_changes_roi_c=intensity_change_maxs_c-intensity_baseline_c;
        intensity_baseline_changes_roi_c=[intensity_baseline_c intensity_changes_roi_c]
        intensity_baseline_changes_all_c=[intensity_baseline_changes_all_c; intensity_baseline_changes_roi_c];
        
        intensity_changes_roi_n=intensity_change_maxs_n-intensity_baseline_n;
        intensity_baseline_changes_roi_n=[intensity_baseline_n intensity_changes_roi_n]
        intensity_baseline_changes_all_n=[intensity_baseline_changes_all_n; intensity_baseline_changes_roi_n];
    end
end

%% Calculate lifetime and intensity, including baseline and changes
% BaselineandChanges=[];
% for i=1:
% 
% for i=1:i_cycleposition

        