% Run FLiP Analysis on 'continuous aquistion data_1.mat' through 'continuous aquistion data_endnumber.mat'. 
% Saves analysis to 'Acqj_analysis.mat'. Files are in the current directory.
% Before running function, define 'endnumber' (as the last file number to be analyzed), 'timebin' (slice time), and 'ch' (usually 1).

function FLipAnalysisInRow(rawdat_dir, timebin,ch, start_acq)
global first_flag

file_list = dir(fullfile(rawdat_dir, 'continuous aquistion data_*.mat'));
cd(rawdat_dir)
% mkdir('testing')
for j=start_acq:length(file_list)
    if j == start_acq
        first_flag = 1;
    else
        first_flag = 0;
    end
    cd(rawdat_dir)
    file = sprintf('continuous aquistion data_%d.mat',j);
    disp(file)
    load(file);
    if timebin <= 2
        filename = sprintf('Acq%d_analysis.mat',j);
    end
    if timebin > 2
        filename = sprintf('Acq%d_analysis_binned.mat',j);
    end
    disp(filename)
    FLiPAnalysis_Tau_p1_Photon(FLPdata_time,FLPdata_lifetimes,timebin,ch,filename, 0);
end
return;
