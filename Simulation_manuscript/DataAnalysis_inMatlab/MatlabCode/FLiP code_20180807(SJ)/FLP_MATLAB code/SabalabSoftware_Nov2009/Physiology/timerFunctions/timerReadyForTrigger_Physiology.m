function status=timerReadyForTrigger_Physiology
	global state physOutputDevice physAuxOutputDevice
		
	status=1;	% good to do
   	if (~isempty(state.phys.daq.auxOutputBoardIndex)) && any(state.cycle.lastUsedAuxPulses) 
		if state.phys.internal.forceTrigger || ~state.cycle.imageOnList(state.cycle.currentCyclePosition)
			if strcmp(get(physAuxOutputDevice, 'Running'), 'Off')
				status=0; % not ready
				disp('timerReadyForTrigger_Physiology: auxOutputDevice not ready');
			end
		end			
	end	

	if ~state.phys.internal.runningMode && ((state.cycle.pulseToUse0>0) || (state.cycle.pulseToUse1>0))
		if strcmp(get(physOutputDevice, 'Running'), 'Off')	
			status=0; % not ready
			disp('timerReadyForTrigger_Physiology: outputDevice not ready');
		end
	end


