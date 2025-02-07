function timerSetup_zFLP
% GY
% from FLIM_setupScanning (focus) -- only does grab mode

global state spc RFswitchOutput;
global FLPdata_time FLPdata_lifetimes FLPdata_counter FLPdata_tau FLPdata_pc;
global FLIMchannels;
%%global FLPdata_fits;

state.FLP.totalAcqTime=state.cycle.totalAcqTime;
state.FLP.sliceTime=state.cycle.sliceTime;
state.FLP.sequencer=state.cycle.sequencer;

%FLPdata_time=[]; FLPdata_lifetimes=[]; FLPdata_fits=[];
FLPdata_time = zeros(state.cycle.totalAcqTimeList,1);
res = 2^state.spc.acq.SPCdata{FLIMchannels(1)}.adc_resolution;
FLPdata_lifetimes = zeros(state.cycle.totalAcqTimeList,4,res); %maximum 4 channels
FLPdata_tau = zeros(1,state.cycle.totalAcqTimeList);
FLPdata_pc = zeros(1,state.cycle.totalAcqTimeList);

if ~isempty(RFswitchOutput)
    % enable the RF switches for those channels used for FLIM
    chansEnable=bitget(state.spc.FLIMchoices,2);
    % this sets the active channels to the opposite of the offState
    putvalue(RFswitchOutput, xor(state.spc.init.RFswitchesOffState,chansEnable(1:4)));
end

for m=state.spc.acq.modulesInUse  % gy multiboard 201202
    
    % GY: trigger 1 is active low, trigger 2 is active hi
    % state.spc.acq.SPCdata{m+1}.trigger = 1;  % GY: this WAS in Grab button code before this code; not sure of correct setting...
    % state.spc.acq.SPCdata{m+1}.trigger = 0;  % GY: this WAS 2.  Changed to 0 for no external trigger (is default 1st FRAME clk)?
    
    error = 0;
    
    state.spc.acq.SPCdata{m+1}.scan_borders = 0;
    state.spc.acq.SPCdata{m+1}.scan_polarity = 0;
    state.spc.acq.SPCdata{m+1}.pixel_clock = 0;  % GY:  internally generated pixel clock
    
    state.spc.acq.SPCdata{m+1}.stop_on_time = 1; %When the programmed collection time has expired, the measurement is stopped automatically if stop_on_time has been set (system parameters).
    state.spc.acq.SPCdata{m+1}.stop_on_ovfl = 0;
    state.spc.acq.SPCdata{m+1}.dead_time_comp = 0;
  
    state.spc.acq.SPCdata{m+1}.scan_size_x =1;
    state.spc.acq.SPCdata{m+1}.scan_size_y =1;
    state.spc.acq.SPCdata{m+1}.img_size_x = 1;
    state.spc.acq.SPCdata{m+1}.img_size_y = 1;

    state.spc.acq.SPCdata{m+1}.pixel_time = 1; 
    state.spc.acq.SPCdata{m+1}.line_compression = 1;
    
    %state.spc.acq.SPCdata{m+1}.adc_resolution = state.spc.acq.resolution;
    
    state.spc.acq.SPCdata{m+1}.collect_time = state.FLP.sliceTime;
    state.FLP.numberOfSlices=state.FLP.totalAcqTime/state.FLP.sliceTime;
    
    FLIM_setParameters(m);
    FLIM_getParameters(m);
end

global tauplot photoncountplot
global h_tauplot h_photoncountplot;
try
    close('Real time lifetime plot');
    close('Photoncount plot');
catch
end

tauplot=figure('Name','Real time lifetime plot','NumberTitle','off');
photoncountplot = figure('Name','Photoncount plot','NumberTitle','off');

figure(tauplot);
xlabel('time(s)');
ylabel('average tau(ns)');
hold on;

figure(photoncountplot);
xlabel('time(s)');
ylabel('photon counts per unit time');
hold on;




