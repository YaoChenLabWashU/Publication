function makeNewPcellBinaryOutput
	return
    
	global state 
    
	state.internal.lineDelay = state.acq.lineDelay/state.acq.msPerLine; % calculate fractional line delay
	pOut = zeros(state.internal.lengthOfXData ,1);					% Fill with zero for the flyback
	if state.acq.bidi
		state.internal.flybackDecimal = 1-state.acq.fillFraction-state.internal.lineDelay;
		pStart =  1+round(state.internal.lengthOfXData * ...
			((state.internal.lineDelay/2+state.acq.mirrorLag-state.pcell.pcellDelay)/state.acq.msPerLine));
		pEnd =  1+round(state.internal.lengthOfXData * ...
			((state.acq.mirrorLag-state.pcell.pcellDelay)/state.acq.msPerLine+state.acq.fillFraction));
	else
		pStart = round(state.internal.lengthOfXData * ...
			(state.acq.lineDelay+state.acq.mirrorLag-state.pcell.pcellDelay)/state.acq.msPerLine);
		pEnd =  round(state.internal.lengthOfXData * ...
			((state.acq.lineDelay+state.acq.mirrorLag-state.pcell.pcellDelay)/state.acq.msPerLine+state.acq.fillFraction));
	end
	pOut(max(pStart,1):min(pEnd,state.internal.lengthOfXData))=1;			% Fill with 1 for scanning portion
	state.acq.pcellSingleLineBinary=pOut;
	
	if state.acq.bidi
		% for bidirectional scan, the pcell in the second line must be
		% inverted timing compared to line 1
		pOutBack = zeros(state.internal.lengthOfXData ,1);					% Fill with zero for the flyback
		pOutBack(max(end-pEnd+1,1):min(end-pStart+1,state.internal.lengthOfXData))=1; % Fill with 1 for scanning portion
		
		if state.acq.dualLaserMode==1
			state.acq.pcellBinaryOutput = repmat([pOut; flipdim(pOut,1)], [state.acq.linesPerFrame/2 1]); 						% Final Pockell Data for one frame
		elseif state.acq.dualLaserMode==2
			state.acq.pcellBinaryOutput = repmat([pOut' zeros(1, length(pOut))]', [state.acq.linesPerFrame 1]); 						% Final Pockell Data for one frame
			state.acq.pcellBinaryOutputComp = repmat([zeros(1, length(pOutBack)) pOutBack']', [state.acq.linesPerFrame 1]); 						% Final Pockell Data for one frame
		end		
	else
		if state.acq.dualLaserMode==1
			state.acq.pcellBinaryOutput = repmat(pOut, [state.acq.linesPerFrame 1]); 						% Final Pockell Data for one frame
		elseif state.acq.dualLaserMode==2
			state.acq.pcellBinaryOutput = repmat([pOut' zeros(1, length(pOut))]', [state.acq.linesPerFrame 1]); 						% Final Pockell Data for one frame
			state.acq.pcellBinaryOutputComp = repmat([zeros(1, length(pOut)) pOut']', [state.acq.linesPerFrame 1]); 						% Final Pockell Data for one frame
		end		
	end
	
