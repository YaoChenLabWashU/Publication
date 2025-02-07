
% The first three variables need to be changed every time, based on each
% experiment
ExperimentName='1019_1422_001_'; 
FirstAcq=10;
number_of_acq = 24;


analysis_name=[ExperimentName,'analysis'];
timebin=1;
ch=1;
FLPfiles='continuous aquistion data_'; 

tau_avg_all=[];
tau_avgTrunc_all=[];
tau_empTrunc_all=[];
p1_all=[];
photoncount_all=[];
time_all=[];
chi2_all=[];

tau_avg_all2=[];
tau_avgTrunc_all2=[];
tau_empTrunc_all2=[];
p1_all2=[];
photoncount_all2=[];
time_all2=[];
chi2_all2=[];


for i=1:number_of_acq
    load([FLPfiles num2str(i+FirstAcq-1) '.mat']);
    filename=[ExperimentName,num2str(i),'h.mat'];
    FLiPAnalysis_Tau_p1_Photon(FLPdata_time, FLPdata_lifetimes, timebin,ch, filename)
    load(filename);
    
    tau_avg_all=[tau_avg_all;tau_avg];
    tau_avgTrunc_all=[tau_avgTrunc_all;tau_avgTrunc];
    tau_empTrunc_all=[tau_empTrunc_all;tau_empTrunc];
    p1_all=[p1_all;p1];
    photoncount_all=[photoncount_all;photoncount];
    time_all=[time_all;time];
    chi2_all=[chi2_all;chi2];
    
    tau_avg_all2=[tau_avg_all2 tau_avg];
    tau_avgTrunc_all2=[tau_avgTrunc_all2 tau_avgTrunc];
    tau_empTrunc_all2=[tau_empTrunc_all2 tau_empTrunc];
    p1_all2=[p1_all2 p1];
    photoncount_all2=[photoncount_all2 photoncount];
    time_all2=[time_all2 time];
    chi2_all2=[chi2_all2 chi2];
    
    
%     subplot(24,3,((i-1)*3+1));
%     plot(time,photoncount,'.');
%     xlabel('time (s)');
%     ylabel('photoncount');
%     title('photoncount vs. time (s)');
%     
%     subplot(24,3,((i-1)*3+2));
%     plot(time,tau,'.');
%     xlabel('time (s)');
%     ylabel('lifetime (ns)');
%     title('lifetime (ns) vs. time (s)');
%     
%     subplot(24,3,((i-1)*3+3));
%     plot(time,p1,'.');
%     xlabel('time (s)');
%     ylabel('p1');
%     title('free fraction vs. time (s)');
    
end

save(analysis_name,'tau_avg_all','tau_avgTrunc_all','tau_empTrunc_all','p1_all','photoncount_all','tau_avg_all2','tau_avgTrunc_all2','tau_empTrunc_all2','p1_all2','photoncount_all2','time_all','time_all2','chi2_all','chi2_all2')

    

