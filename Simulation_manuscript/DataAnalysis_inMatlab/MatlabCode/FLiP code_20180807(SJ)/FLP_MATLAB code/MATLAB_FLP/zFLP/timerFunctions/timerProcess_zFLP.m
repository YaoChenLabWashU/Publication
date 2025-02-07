function timerProcess_zFLP
% modified gy multiboard 201202
% after all frames and zSlices collected, save FLIM data, then auto fit (and export to Excel) if requested
global state spc gui gh FLIMchannels
global FLPdata_time FLPdata_lifetimes FLPdata_fits

% clean up things that apply only during FLIM acquisition
resetRFswitches; % if they're in use

% GY: for DEBUG
% FLIM_decode_test_state(1);
% END GY: for DEBUG

% set up datainfo structure
spc.datainfo=[];  %GY 20110124 clear it out first
spc.datainfo.multiPages.timing = 0;
spc.datainfo.multiPages.nPages = 0;
spc.datainfo.multiPages.page = 0;
spc.datainfo.multiPages.pageTime = 0;

spc.datainfo.numberOfZSlices=state.FLP.numberOfSlices;

spc.page = 0;
% multiboard:  these new parameters saved in datainfo
spc.datainfo.modulesInUse=state.spc.acq.modulesInUse;
spc.datainfo.modChans=state.spc.acq.modChans;
spc.datainfo.channelDefs=state.spc.acq.channelDefs;
% multiboard:  these parameters always taken from the first module
scan_size_y = state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1}.scan_size_y;
scan_size_x = state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1}.scan_size_x;
res = 2^state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1}.adc_resolution;
% multiboard:  for analysis convenience, this only gets board 1 parameters
spc.SPCdata = state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1};
spc.size = [res, scan_size_y, scan_size_x];
spc.switches.peak = [-1, 4];
try 
    limit = spc.switches.lifetime_limit; 
catch
    limit = [2.4, 3.4];
end
try 
    range = spc.fits{1}.range; 
catch
    range = [1, res];
end
spc.switches.lifetime_limit = limit;
spc.fit.background = 0;
spc.switches.imagemode = 1;
spc.switches.logscale = 1;
spc.fit.range = range;
% set a bunch more stuff in datainfo
spc.datainfo.time = datestr(clock, 13);
spc.datainfo.date = datestr(clock, 1);
spc.datainfo.adc_re = res;
% for multiFLIM
spc.datainfo.FLIMchoices=state.spc.FLIMchoices;
% most of the FLIM board parameters are stored in spc.SPCdata

spc.datainfo.laser.power=state.pcell.pcellScanning1;
try 
    spc.datainfo.laser.wavelength=state.laser.wavelength;
end
try
    spc.datainfo.triggerTime = state.spc.acq.triggerTime;
catch
    spc.datainfo.triggerTime = datestr(now);
end

% spc.datainfo.psPerUnit = spc.datainfo.tac_r/spc.datainfo.tac_g/spc.datainfo.adc_re*1e12;
% multiboard - from first module
spc.datainfo.psPerUnit = state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1}.tac_range ...
    /state.spc.acq.SPCdata{state.spc.acq.modulesInUse(1)+1}.tac_gain/res * 1000;
% spc.datainfo.pulseInt = 12.58;  % GY: what is this?? inverse of laser rate??
spc.datainfo.pulseInt = 1E9/state.spc.internal.syncRate;  % GY 201101
if (spc.errCode~=0)
    error = FLIM_get_error_string (spc.errCode);
    disp(['error during reading data:', error]);
    return;
end

for chan=FLIMchannels
    spc_drawLifetime(chan,1); %draw the lifetime of this slice
end

% GY:  TEMPORARY (?) SAVE CODE
str1 = '000';
str2 = num2str(state.files.lastAcquisition);
str1(end-length(str2)+1:end) = str2;
spc.filename = [state.files.savePath state.files.baseName 'FLIM' str1 '.mat'];

% save(spc.filename,'spc');  %save the SPC structure (includes data)

% GY 201012 - more frugal - save only the key parts of the SPC structure
spcSave.filename=spc.filename;

% SJ 201611 - lifetime data for the last slice for plotting purpose
spcSave.lifetimes=spc.lifetimes; 

FLIMacq=find(bitget(state.spc.FLIMchoices,2));
spcSave.fits=spc.fits(FLIMacq);
spcSave.switchess=spc.switchess;
spcSave.switches=spc.switches;

spcSave.datainfo=spc.datainfo;
spcSave.SPCdata=spc.SPCdata;
spcSave.size=spc.size;

% SJ 201611 - lifetime data for the all slices
spcSave.FLPdata_time = FLPdata_time;
spcSave.FLPdata_lifetimes = FLPdata_lifetimes;
spcSave.FLPdata_fits = FLPdata_fits;

spcSave.imageMod = [];

% multiboard - for correct archiving, save the additional board parameter
%   if it exists, in a special variable
if size(state.spc.acq.modulesInUse)>1
    spcSave.SPCdataMulti=state.spc.acq.SPCdata; %
end
save(spc.filename,'spcSave');  %save the SPC structure (includes data)
set(gui.spc.spc_main.File_N,'String',str1);  % update file number display
spc_updateGUIbyGlobal('spc.filename');

% update the spc_main file info, should we wish to browse back
gui.gy.filename.path = state.files.savePath;
gui.gy.filename.base = state.files.baseName;
gui.gy.filename.num = state.files.lastAcquisition;

spc_setupSliceChooser; % update current value of slice chooser (and choices)

if get(gui.spc.spc_main.fit_eachtime,'Value')
	try
		spc_autoDuringAcq;
	catch
		disp('spc_autoDuringAcq failed in ''timerProcess_zFLP.m''');
	end
end
