function timerInit_zFLP
% open up FLIM configuration windows
%   photon count monitor window
% open up FLIM fitting windows
% gy multiboard 201202
global gui state
evalin('base','global spc');
openini('zFLIM.ini');
openini('FLP.ini');

% initialize cycle definition
state.cycle.photometryOn=1;
updateGUIByGlobal('state.cycle.photometryOn');
state.cycle.photometryOnList(1)=1;
state.cycle.totalAcqTime=1;
updateGUIByGlobal('state.cycle.totalAcqTime');
state.cycle.sliceTime=0.01;
updateGUIByGlobal('state.cycle.sliceTime');
state.cycle.syncPhys=0;
updateGUIByGlobal('state.cycle.syncPhys');
state.cycle.sequencer=0;
updateGUIByGlobal('state.cycle.sequencer');

% loads library and initializes SPC module parameters
FLIM_Init; 

% launch laserControl - disabled for photometry set up, modified by Suk Joon Lee 9/27/2016
%gui.spc.figure.laser=laserControl;

% open FLIM channel choice / photon count monitor window and FLIM-specific windows 
FLIMgui;  

% Setup RF switches if needed
initializeRFswitches;
    

