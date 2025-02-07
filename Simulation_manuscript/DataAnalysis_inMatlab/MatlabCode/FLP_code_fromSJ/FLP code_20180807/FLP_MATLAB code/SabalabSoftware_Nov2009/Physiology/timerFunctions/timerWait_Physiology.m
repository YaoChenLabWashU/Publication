function timerWait_Physiology
	global state
	
	if timerGetPackageStatus('Physiology')
		return
	end
	
	try
		state.phys.internal.timer=state.internal.secondsCounter;
		updateGUIByGlobal('state.phys.internal.timer');
		readTelegraphs;
		if state.phys.scope.changedScope
			state.phys.scope.changedScope=0;
			setupCyclePosition;
			setupPhysDaqPulse;						
			readBaseline;
		else
			readBaseline;
		end
		updateMinInCell;
    catch
		disp(['timerWait_Physiology: ' lasterr]);
    end