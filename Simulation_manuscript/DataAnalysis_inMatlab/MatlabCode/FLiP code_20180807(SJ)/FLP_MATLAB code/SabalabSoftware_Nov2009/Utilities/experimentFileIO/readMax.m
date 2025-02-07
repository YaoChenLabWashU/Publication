function readMax(fname, pname)
	global state projectionData
	state.internal.lastTaskDone=3;
	state.internal.status=0;
	try
		imageInfo=imfinfo(fullfile(pname, [fname '.tif']));
		length(imageInfo);
		state.lastHeader=imageInfo(1).ImageDescription;
	catch
		lasterr
		return
	end
	
	pixelsPerLine=state.acq.pixelsPerLine;
	valueFromHeaderString(projectionData=cell(1,3);
	try
		for counter=1:state.init.maximumNumberOfInputChannels
			if valueFromHeaderString(['state.acq.savingChannel' num2str(counter)], state.lastHeader)
				projectionData{counter}=imread(fullfile(pname, [fname '.tif']), counter);
				set(state.internal.maximagehandle(counter), 'EraseMode', 'none', 'CData', projectionData{counter});
			else
				projectionData{counter}=[];
				set(state.internal.maximagehandle(counter), 'EraseMode', 'none', 'CData', projectionData{counter});
			end
		end
	catch
		lasterr
	end
			
	