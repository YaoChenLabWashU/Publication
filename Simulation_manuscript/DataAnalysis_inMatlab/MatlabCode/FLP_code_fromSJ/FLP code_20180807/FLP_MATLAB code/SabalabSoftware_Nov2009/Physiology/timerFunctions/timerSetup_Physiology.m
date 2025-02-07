function timerSetup_Physiology
	global state

	state.phys.internal.abort=0;
	
	try
		readTelegraphs;
		updateMinInCell;
	catch
		disp(['timerSetup_Physiology: ' lasterr]);
	end
			
	setupPhysDaqPulse;
	state.phys.internal.forceTrigger=0;
	