function spc_drawAll(chan, flag, fast)
% drawLifetimeMap, plot ROIs and vals, drawLifetime, fixLifetimeAxes
global state spc;
global gui;

%Fig2 = lifetime in ROI.

%set(gui.spc.figure.projectImage, 'CData', spc.project);

if (spc.switches.imagemode == 1 && state.spc.acq.SPCdata{chan}.mode~=0);
%Fig3 = Lifetime map.
    spc_drawLifetimeMap(chan, flag, fast);
    %spc_plotGYrois(chan,2);
    %disp('need to work on spc_calculateROIvals and other gy-rois'); %spc_calculateROIvals(0);
    disp('drawLifetimeMap');
end;

spc_drawLifetime (chan,fast);
disp('drawLifetime');
spc_fixLifetimeAxes; % needed if there are any zeros in lifetime data, to prevent incorrect autoscaling of top axis

%draw_tau(chan);