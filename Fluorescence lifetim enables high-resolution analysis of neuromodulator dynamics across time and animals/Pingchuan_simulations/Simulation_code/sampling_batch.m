

mkdir([filepath,'/',num2str(i)]);
cd([filepath,'/',num2str(i)]);
AF=ceil(25487*pixel_num(i)/16384); % autofluorescence size depending on the pixel numbers of the roi (autofluorescence photon of the whole view in total is 25487)
samplesize=photons_all(i); % use the sample size from real rois
for j=1:50
    FLIMsim256_Ach(samplesize,0,AF,prf_peak); % no DC
    load('FLIMSimulation_pm.mat')
    samplename=[filepath,'/',num2str(i),'/',num2str(i),'_',num2str(j)];
    save(samplename,'n','xout');
end













