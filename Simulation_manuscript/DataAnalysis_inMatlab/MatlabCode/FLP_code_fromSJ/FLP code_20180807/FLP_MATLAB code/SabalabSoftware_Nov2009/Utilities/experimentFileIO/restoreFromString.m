function restoreFromString(headerString, exempt)
	if ~ischar(headerString)
		error('restoreFromString : expect string as input');
	end
	if nargin<2
		exempt={'state.analysis.'};
	end
	if ischar(exempt)
		exempt={exempt};
	end
	
	rets=[0 find(headerString==13)];
	for counter=1:length(rets)-1
		line=headerString(rets(counter)+1:rets(counter+1)-1);
		evalin('base', [line ';']);
		f=find(line=='=');
		if ~isempty(f)
			ok=1;
			if ~isempty(exempt)
				for norestore=exempt
					if strfind(f, norestore{1})==1
						ok=0;
						break
					end
				end
			end 
			if ok
				updateGUIByGlobal(line(1:f-1));
			end
		end
	end
	