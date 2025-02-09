function recordWindowPositions
	global state gh
	
	wins=fieldnames(gh);
	
	for winCount=1:length(wins)
		winName=wins{winCount};
		%GY: changed for the way that zFLIM also uses gh, but with windows
		%put underneath gh.spc (which does not have a figure1)
		% was: % if ishandle(getfield(getfield(gh, winName), 'figure1'))
		try
			saveableWin=ishandle(getfield(getfield(gh, winName), 'figure1'));
		catch
			saveableWin=0;
		end
		if saveableWin  %END of GY modification
			state.windowPositions=setfield(state.windowPositions, [winName '_position'], get(getfield(getfield(gh, winName), 'figure1'), 'Position'));
			setGlobalConfigStatus(['state.windowPositions.' winName '_position'], 4);
			state.windowPositions=setfield(state.windowPositions, [winName '_visible'], get(getfield(getfield(gh, winName), 'figure1'), 'Visible'));
			setGlobalConfigStatus(['state.windowPositions.' winName '_visible'], 4);
		end
	end
		
		for channelCounter = 1:state.init.maximumNumberOfInputChannels
            try
			eval(['state.windowPositions.image' num2str(channelCounter) '_position = get(state.internal.GraphFigure(channelCounter), ''Position'');']);
			setGlobalConfigStatus(['state.windowPositions.image' num2str(channelCounter) '_position'], 4);
			eval(['state.windowPositions.maxImage' num2str(channelCounter) '_position = get(state.internal.MaxFigure(channelCounter), ''Position'');']);
			setGlobalConfigStatus(['state.windowPositions.maxImage' num2str(channelCounter) '_position'], 4);
            catch
            end
		end
	
	try
		state.windowPositions.compositeImage_position = get(state.internal.compositeFigure, 'Position');
		setGlobalConfigStatus(['state.windowPositions.compositeImage_position'], 4);
	catch
	end

	try
		if ishandle(state.phys.internal.scopeHandle)
			pos=get(state.phys.internal.scopeHandle, 'Position');
			state.windowPositions.scopeWindow_position = pos;
			setGlobalConfigStatus(['state.windowPositions.scopeWindow_position'], 4);
		end
	catch
	end
	
	try
		if ishandle(state.phys.internal.pulsePatternPlot)
			pos=get(state.phys.internal.pulsePatternPlot, 'Position');
			state.windowPositions.pulsePatternPlotWindow_position = pos;
			setGlobalConfigStatus(['state.windowPositions.pulsePatternPlotWindow_position'], 4);
		end
	catch
	end

