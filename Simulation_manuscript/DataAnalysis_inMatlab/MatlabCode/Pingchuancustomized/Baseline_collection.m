
gui.gy.ROImean=[];
gui.gy.ROIcount=[];
gui.gy.ROIlife=[];


spc_adjustTauOffset(1);

Acq=spc.filename(end-6:end-4);
Acq=str2num(Acq);
ROInum=size(gui.gy.ROIlife,1);
Acqs=zeros(ROInum,1);
Acqs(Acqs==0)=Acq;


Acq_nums=[Acq_nums;Acqs];
lfts=[lfts;gui.gy.ROIlife];
photons=[photons;gui.gy.ROIcount];
photons_mean=[photons_mean;gui.gy.ROImean];
roiPositions=[roiPositions gui.gy.roiPositions];
