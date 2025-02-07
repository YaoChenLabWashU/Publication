function siSelectionChannelToFront
	global state
	if state.internal.selectionChannel<=4
		figure(state.internal.GraphFigure(state.internal.selectionChannel));
	elseif state.internal.selectionChannel==5
		figure(state.internal.refFigure);
	elseif state.internal.selectionChannel==6
		figure(state.internal.compositeFigure);
	end