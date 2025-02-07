function siRedrawImages(channelList, frame)
	global state imageData compositeData
	
	if nargin<1
		channelList=[];
	end

	if isempty(channelList)
		channelList=find(state.acq.acquiringChannel.*state.acq.imagingChannel);
		
		if state.acq.dualLaserMode==2
			channelList=[channelList channelList+10];
		end
	end
	
	global lastAcquiredFrame
	

	for channel=channelList
		if nargin<2
			set(state.internal.imagehandle(channel), 'EraseMode', 'none', 'CData', lastAcquiredFrame{channel}(:,:), ...
				'YData', [1 state.acq.linesPerFrame]);
		else
			frame=min(size(imageData{channel},3), frame);
			set(state.internal.imagehandle(channel), 'EraseMode', 'none', 'CData', imageData{channel}(:,:,frame), ...
				'YData', [1 state.acq.linesPerFrame]);
		end
	end

	if state.internal.composite			
		compositeData = (zeros(state.acq.linesPerFrame, state.acq.pixelsPerLine, 3)); 	% BSMOD 7/17/2
		for counter=1:3
			channel=state.internal.compositeChannelSelections(counter);
			
			if channel==99 % they want the reference image
				if all([state.acq.linesPerFrame, state.acq.pixelsPerLine]==size(state.acq.trackerReferenceAll))
					low = getfield(state.internal, ['lowPixelValue' num2str(state.acq.trackerChannel)]);
					high = getfield(state.internal, ['highPixelValue' num2str(state.acq.trackerChannel)]);

					compositeData(:,:,counter)=...
						min(max(...
						(state.acq.trackerReferenceAll - low) / ...
						max(high-low,1)...
						,0)...
						,1);
				end
			elseif channel>0 && state.acq.acquiringChannel(mod(channel,10)) && ...
					(state.acq.dualLaserMode==2 || (state.acq.dualLaserMode==1 && channel<=4))
				
				low = getfield(state.internal, ['lowPixelValue' num2str(channel)]);
				high = getfield(state.internal, ['highPixelValue' num2str(channel)]);

				if nargin<2
					compositeData(:,:,counter)=...
						min(max(...
						(lastAcquiredFrame{channel} - low) / ...
						max(high-low,1)...
						,0)...
						,1);
				else
					frame=min(size(imageData{channel},3), frame);
					compositeData(:,:,counter)=...
						min(max(...
						(imageData{channel}(:,:,frame) - low) / ...
						max(high-low,1)...
						,0)...
						,1);
				end
			end
		end
	end
		set(state.internal.compositeImagehandle, 'EraseMode', 'none', 'CData', ...
			compositeData, 'YData', [1 state.acq.linesPerFrame]);
	end
