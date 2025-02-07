function draw_tau(chan)
%Drawing lifetime tau vs. trial in real time
global spc

if ~isfield(spc,'tauPlot')
    spc.tauPlot{chan}=[];
end

spc.tauPlot{chan}=[spc.tauPlot{chan},spc.fits{chan}.avgTau];

figure(23);
plot([1:length(spc.tauPlot{chan})],spc.tauPlot{chan},'.');
FigHandle = figure(23);
set(FigHandle,'Position',[1200 900 300 200]);
title('lifetime decay coefficient plot');
xlabel('trial Acq #');
ylabel('coefficient in ns');
ylim([2*min(spc.tauPlot{chan}),0]);
end