function timerStart_Physiology
	global state gh physOutputDevice physAuxOutputDevice physInputDevice
	timerSetPackageStatus(1, 'Physiology');

	set(gh.physControls.liveModeButton, 'String', 'abort');
	
	if ~state.phys.internal.runningMode && (get(physInputDevice, 'SamplesPerTrigger')==Inf)
		set(gh.physControls.startButton, 'String', 'end acq');
	else
		set(gh.physControls.startButton, 'String', 'ABORT');
	end
	set(gh.scope.start, 'Enable', 'off');
	setPhysStatusString('Running...');
	state.phys.internal.stripeCounter=1;
	state.phys.internal.stopInfiniteAcq=0;
	
	phSetChannelGains
		
	if state.phys.internal.runningMode==0
		if state.phys.daq.auxOutputBoardIndex
			state.cycle.lastUsedAuxPulses = [...
				state.cycle.aux4List(state.cycle.currentCyclePosition) ...
				state.cycle.aux5List(state.cycle.currentCyclePosition) ...
				state.cycle.aux6List(state.cycle.currentCyclePosition) ...
				state.cycle.aux7List(state.cycle.currentCyclePosition)];
		end

		state.files.lastAcquisition=state.files.fileCounter;

		if (~isempty(state.phys.daq.auxOutputBoardIndex)) && any(state.cycle.lastUsedAuxPulses) 
			if state.phys.internal.forceTrigger || ~state.cycle.imageOnList(state.cycle.currentCyclePosition)
				start(physAuxOutputDevice);
			end			
		end	

		if state.cycle.imageOnList(state.cycle.currentCyclePosition)
			set(physOutputDevice, 'HwDigitalTriggerSource', 'RTSI0')
		else
			set(physOutputDevice, 'HwDigitalTriggerSource', 'RTSI1')
		end

		if state.phys.internal.forceTrigger
			set(physOutputDevice, 'HwDigitalTriggerSource', 'RTSI1');
		end
		if (state.cycle.lastPulseUsed0>0) || (state.cycle.lastPulseUsed1>0)
			start(physOutputDevice);
		else
%			disp('*** Physiology output is off');
		end
	else
		
%		disp('*** Physiology output is off');
	end
	
	if get(physInputDevice, 'SamplesPerTrigger')==Inf
		if state.phys.internal.runningMode 
			if state.phys.settings.streamToDisk 
				% continuious acquisition, turn on disk loggin
				set(physInputDevice, 'LoggingMode', 'Disk&Memory')
				set(physInputDevice, 'LogToDiskMode', 'Overwrite')
				set(physInputDevice, 'LogFileName', fullfile(state.files.savePath, 'physLoggingFile.daq'))
			else
				set(physInputDevice, 'LoggingMode', 'Memory')
			end
		elseif state.files.autoSave	
			% continuious acquisition, turn on disk loggin
			set(physInputDevice, 'LoggingMode', 'Disk&Memory')
			set(physInputDevice, 'LogToDiskMode', 'Overwrite')
			set(physInputDevice, 'LogFileName', fullfile(state.files.savePath, physDiskLogName))
		else
			set(physInputDevice, 'LoggingMode', 'Memory')
		end
	else
		set(physInputDevice, 'LoggingMode', 'Memory')
	end
	
	% allocate memory
	global physData
	physData=zeros(...
		size(get(physInputDevice, 'Channel'),1), ...
		state.phys.internal.samplesPerStripe*state.phys.internal.stripes);
	
	state.phys.internal.forceTrigger=0;


