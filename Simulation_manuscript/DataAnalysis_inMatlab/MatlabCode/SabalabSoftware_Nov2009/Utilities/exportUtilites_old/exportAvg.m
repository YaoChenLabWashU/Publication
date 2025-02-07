function exportAvg(waveList, prefix, outputFile)

	if any(iswave(waveList))
		if ~iscell(waveList) & ~ischar(waveList) 
			waveList=inputname(1);
		end
	else
		error('exportWave : expect wave name or cell array of wave names as input');
	end
	
	if ischar(waveList)
		waveList={waveList};
	end

	if nargin<3
		[filename, pathname] = uiputfile('*.itx', 'Save wave as');
		if isnumeric(filename)
			return
		end
		outputFile=fullfile(pathname, filename);
	end
	if isempty(find(outputFile=='.'))
		outputFile=[outputFile '.itx'];
	end
	if nargin<2
		prefix='';
	end

	[fid, message] = fopen(outputFile, 'w');
	if fid==-1
		message
		error(['exportAvg : could not open ' outputFile ' for output']);
	end
	
	fprintf(fid, 'IGOR\n');
	for avgName=waveList
		disp([' Exporting : ' avgName{1} ' and its components']);
		for name=[avgName avgComponentList(avgName{1})];
			if iswave(name{1})
				ewWriteData(fid, name{1}, prefix);
			else
				disp(['exportAvg : ' name{1} ' does not exist or is not a wave.  Skipping...']);
			end
		end
	end
	fclose(fid);