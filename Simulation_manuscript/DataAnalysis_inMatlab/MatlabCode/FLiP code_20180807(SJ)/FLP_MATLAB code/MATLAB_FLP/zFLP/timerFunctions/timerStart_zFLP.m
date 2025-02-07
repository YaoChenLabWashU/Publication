function timerStart_zFLP
global state 
global FLPdata_time FLPdata_lifetimes FLPdata_fits FLPdata_counter;
global FLIMchannels
global startTime;
global reading_done;
% The following group of commands was moved from timerSetup_zFLIM
% this will allow a 'restart' of acquisition, in the way that 
% (imaging) endAcquisition re-calls timerStart_Imaging for each level of a
% z-stack
%
% GY:  FROM function FLIM_Measurement(hObject,handles)
% GY:  We'll do without the mt timer (updates time display)

% gy multiboard modified 201202

% GY 20110125  
global spc
spc.imageMod = [];  % clear these to start
spc.lifetime=[];
spc.project=[];
spc.errCode=999;

FLPdata_counter=0;
if state.FLP.sequencer==1 %continuous aquistion mode using sequencer (data reading interval is determined by the memory filling time for one memory bank)
    for m=state.spc.acq.modulesInUse
        FLIM_StopMeasurement(m);  
        state.spc.acq.SPCdata{m+1}.mem_bank=0;
        FLIM_setParameters(m);
        FLIM_enable_sequencer(m,2); %turn on sequncer. while for ‘enable’ = 2, the function arms SPC only for current memory bank.
        FLIM_ConfigureMemory(m);
        FLIM_FillMemory(m,-1);  %clear current memory bank, -1 is for all pages
        state.spc.acq.SPCdata{m+1}.mem_bank=1;
        FLIM_setParameters(m);
        FLIM_FillMemory(m,-1);  %clear current memory bank, -1 is for all pages
    end
else
    for m=state.spc.acq.modulesInUse
        FLIM_StopMeasurement(m);
        FLIM_enable_sequencer(m,0); %disable sequencer
        FLIM_ConfigureMemory(m);
        FLIM_SetPage(m,0);
        FLIM_FillMemory(m,0);  %clear page=0
        % FLIM_enable_sequencer(m,1); % removed gy 201204 - not needed in
        % scan sync in mode (and in fact this doubles the memory usage!)
    end
end

startTime=clock;
for m=state.spc.acq.modulesInUse    
    FLIM_StartMeasurement(m);  % start sequencer, flip memory bank, photon collection is started on memory bank 0
    FLIM_getParameters(m);
    %display(['memory bank: ',num2str(state.spc.acq.SPCdata{2}.mem_bank)])
end

timerSetPackageStatus(1, 'zFLP');

if state.cycle.syncPhys==1 %when zFLP is slaved to the physiology
    disp(' ZFLP waiting for trigger');
else
end
