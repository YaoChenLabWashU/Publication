function timerAbort_zFLP
global state
% zFLP handling requested abort
state.timer.abort=1;
for m=state.spc.acq.modulesInUse
    FLIM_StopMeasurement(m);  
end
timerSetPackageStatus(0, 'zFLP');
% clean up things that apply only during FLIM acquisition
resetRFswitches; % if they're in use
% gy modified for dualLaserMode 201204
% if state.acq.dualLaserMode==2
%     for m=state.spc.acq.modulesInUse
%         % undo the setting that was made in timerStart_zFLIM
%         state.spc.acq.SPCdata{m+1}.scan_size_y=state.acq.linesPerFrame;
%         FLIM_setParameters(m);
%         FLIM_getParameters(m);
%     end
% end
% 

