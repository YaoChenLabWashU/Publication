function timerUserSettings_Physiology
	global state

%	loadPulseSet(state.pulses.pulseSetPath, state.pulses.pulseSetName);

	changeChannelType(0);
	changeChannelType(1);
	
	if ~state.analysisMode
		phSetDAQRates	
		setupPhysDaqInputChannels;
	end


	
