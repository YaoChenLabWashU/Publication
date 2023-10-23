




mkdir(['/Users/pingchuanma/Documents/MATLAB/simulation/HEKcell_simulation_0331AchsensorHEK001_9/',num2str(i)]);
cd(['/Users/pingchuanma/Documents/MATLAB/simulation/HEKcell_simulation_0331AchsensorHEK001_9/',num2str(i)]);
AF=ceil(25487*roi_pixel_portion(i)); % autofluorescence size depending on the pixel numbers of the roi (autofluorescence photon of the whole view in total is 25487)
samplesize=ceil(photon_size(i)); % use the sample size from real rois
    for j=1:50
        FLIMsim256_Ach(samplesize,0,AF); % no DC
        load('FLIMSimulation_pm.mat');
        samplename=['/Users/pingchuanma/Documents/MATLAB/simulation/HEKcell_simulation_0331AchsensorHEK001_9/',num2str(i),'/',num2str(i),'_',num2str(j)];
        save(samplename,'n','xout');
    end
