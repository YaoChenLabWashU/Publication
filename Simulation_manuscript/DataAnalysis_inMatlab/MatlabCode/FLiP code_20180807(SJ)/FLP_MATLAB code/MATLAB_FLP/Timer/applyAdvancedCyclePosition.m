function applyAdvancedCyclePosition(position)
	global state

	if nargin==1
		state.cycle.currentCyclePosition=position;
		updateGUIByGlobal('state.cycle.currentCyclePosition');
	end

	% is there is a text functiona call in the cycle
	% execute it
	if ~isempty(state.cycle.functionNameList{state.cycle.currentCyclePosition})
		evalin('base', state.cycle.functionNameList{state.cycle.currentCyclePosition});
	end
	
	timerSetActiveStatus('Imaging', state.cycle.imageOnList(state.cycle.currentCyclePosition));	
	if state.cycle.imageOnList(state.cycle.currentCyclePosition) % imaging is on
		try
			setupImagingCyclePosition;
		catch
			disp(['applyAdvancedCyclePosition : ' lasterr]);
		end
	end
	
	timerSetActiveStatus('Physiology', state.cycle.physOnList(state.cycle.currentCyclePosition));	
	if state.cycle.physOnList(state.cycle.currentCyclePosition) % physiology is on
		try
			if (state.cycle.da0List(state.cycle.currentCyclePosition) ~= state.cycle.pulseToUse0) ...
					|| (state.cycle.da1List(state.cycle.currentCyclePosition) ~= state.cycle.pulseToUse1)
				state.phys.internal.needNewOutputData=1;
			end
			state.cycle.pulseToUse0=state.cycle.da0List(state.cycle.currentCyclePosition);
			state.cycle.pulseToUse1=state.cycle.da1List(state.cycle.currentCyclePosition);
            state.cycle.physRepeatsToOutput=state.cycle.repeatOutputList(state.cycle.currentCyclePosition);
            
			if (state.cycle.lastPulseUsed0 ~= state.cycle.pulseToUse0) || ...
                    (state.cycle.lastPulseUsed1 ~= state.cycle.pulseToUse1) || ...
                    (state.cycle.physLastRepeatsToOutput ~= state.cycle.physRepeatsToOutput)
				state.phys.internal.needNewOutputData=1;
			end
			updateGUIByGlobal('state.cycle.pulseToUse0');
			updateGUIByGlobal('state.cycle.pulseToUse1');
			
			phCheckAcquisitionChannels
			
            if state.phys.daq.auxOutputBoardIndex
                try
                    if ~all(state.cycle.lastUsedAuxPulses == [state.cycle.aux4List(state.cycle.currentCyclePosition) ...
                            state.cycle.aux5List(state.cycle.currentCyclePosition) ...
                            state.cycle.aux6List(state.cycle.currentCyclePosition) ...
                            state.cycle.aux7List(state.cycle.currentCyclePosition)])
   		                state.phys.internal.needNewAuxOutputData=1;
                    end
                catch
            		state.phys.internal.needNewAuxOutputData=1;
                end
            end
		catch
			disp(['applyAdvancedCyclePosition : ' lasterr]);
		end
	else
		state.cycle.pulseToUse0=0;
		state.cycle.lastPulseUsed0=0;
	end
	
	state.cycle.nextTimeDelay=state.cycle.delayList(state.cycle.currentCyclePosition);
	updateGUIByGlobal('state.cycle.nextTimeDelay');

	state.cycle.lastPositionUsed=state.cycle.currentCyclePosition;
    
    timerSetActiveStatus('zFLP', state.cycle.photometryOnList(state.cycle.currentCyclePosition));	
    if state.cycle.photometryOnList(state.cycle.currentCyclePosition) %if FLP is on
        for m=state.spc.acq.modulesInUse %set external trigger status (0=internal trigger, 1,2=external trigger) -> 01 - ( value 1 ) active low, 10 - ( value 2 ) active high
            if state.cycle.trigger==1
                if(state.cycle.sequencer==1)
                    state.spc.acq.SPCdata{m+1}.trigger = 2 + 768; %2=active high, 768=trigger on each curve in the bank
                else
                    state.spc.acq.SPCdata{m+1}.trigger = 2; %2=active high
                end
            else
                state.spc.acq.SPCdata{m+1}.trigger = 0;
            end
        end
    end
	
	
