function piezoWait()

global state

wasMoving=0;
while ~strcmp(get(state.piezo.Output, 'Running'), 'Off')
	wasMoving=1;
	pause(.01);
end

extraPause=0.5;	% wait extraPause sec even after the end of the movement

if wasMoving && (extraPause>0)
	pause(extraPause);
end
	