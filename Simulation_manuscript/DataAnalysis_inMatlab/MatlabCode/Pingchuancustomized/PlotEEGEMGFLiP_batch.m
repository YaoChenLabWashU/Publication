rawdat_dir=pwd;
fileprefix=ExperimentName;% '20220323_1629_SW_003';
filepostfix='20220426';
frequency=1;
constant=FirstAcq-1;
mouse='112mut';

for acqn=22:22
    PlotEEGEMGFLiP(rawdat_dir, mouse, fileprefix, filepostfix, acqn, frequency, constant);
end