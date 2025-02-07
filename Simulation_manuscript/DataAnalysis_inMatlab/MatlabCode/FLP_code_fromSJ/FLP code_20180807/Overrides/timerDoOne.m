function timerDoOne
	global state gh

	state.cycle.cycleStatus=0;

	val=get(gh.timerMainControls.doOne, 'String');

	persistent multipleAbortAttempts
	
	if (exist('multipleAbortAttempts', 'var')~=1)
		multipleAbortAttempts=0;
	end
	
	if strcmp(val, 'DO ONE')
		if timerPausedStatus
			beep;
			setStatusString('Running. Stop processes');
			return
		end

		if ~savingInfoIsOK(~timerGetActiveStatus('Imaging'))
			return
		end	

		multipleAbortAttempts=0;
		state.cycle.loopingStatus=0; 	% not a loop
		applyAdvancedCyclePosition;
		gotoCycleStagePosition(1);	% force a movement for when they hit DO ONE button
        
        state.FLP.sequencer=0;
        timerCallPackageFunctions('FirstSetup');
        timerCallPackageFunctions('Setup');
        timerCallPackageFunctions('Start');
        
        set(gh.timerMainControls.doOne, 'String', 'ABORT');
        hideGUI('gh.timerMainControls.loop');

        state.timer.abort=0;
        timerCallPackageFunctions('ReadyForTrigger');
        timerTrigger;
        
        if timerGetPackageStatus('zFLP')==1 %start the timer for zFLP
            global testTimer;
            testTimer=timer('TimerFcn', @(~,~)ZFLP_timerFunction, 'Period', 0.02); %The Timerfcn is automatically passed two inputs, a handle to the timer and some event data. The '~' just ignores the input.
            set(testTimer, 'ExecutionMode', 'fixedRate');
            start(testTimer);
        end
        
	elseif strcmp(val, 'ABORT')
		timerCallPackageFunctions('Abort');
		multipleAbortAttempts=multipleAbortAttempts+1;
		if multipleAbortAttempts>1
			multipleAbortAttempts=multipleAbortAttempts+1;
			disp('Multiple abort attempts.  Will force abort.');
			timerCallPackageFunctions('ForcedAbort');
		end		
	else
		disp('timerDoOne: Do One button is in unknown state'); 	% BSMOD - error checking
	end
	
	
	
