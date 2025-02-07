function ewWriteData(fid, name, prefix)
	if nargin<3
		prefix='';
	end
	
	if ~isempty(prefix)
		prefix=[prefix '_'];
	end
	
	data=get(name, 'data');
	if size(data, 1)>1
		fprintf(fid, 'WAVES/n=(%e,%e) %s\nBEGIN\n', size(data,2), size(data,1), [prefix name]);
	else
		fprintf(fid, 'WAVES %s\nBEGIN\n', [prefix name]);
	end
	for counter=1:size(data, 2)
		if size(data, 1)>1
			for c2=1:size(data, 1)
				fprintf(fid, '   %e ', double(data(c2, counter)));
			end
			fprintf(fid, '\n');
		else			
			fprintf(fid, '   %e\n', double(data(counter)));
		end
	end
	fprintf(fid, 'END\n');	
	xscale=get(name, 'xscale');
	fprintf(fid, 'X SetScale/P x %f, %f, "", %s\n', xscale(1), xscale(2), [prefix name]);
	if size(data, 1)>1
		yscale=get(name, 'yscale');
		fprintf(fid, 'X SetScale/P y %f, %f, "", %s\n', yscale(1), yscale(2), [prefix name]);
	end
    
    %% added by mjh to append timeincell note to each individual wave
   %% if isempty(getWaveUserDataField(name, 'nComponents'))
     %%   cText=['X Note ' [prefix name] ', "time=' num2str(
    
    
	if ~isempty(getWaveUserDataField(name, 'nComponents'))
		cList=(getWaveUserDataField(name, 'Components'));
		cText=['X Note ' [prefix name] ', "nAvg=' num2str(getWaveUserDataField(name, 'nComponents')) ';parts='];
		for comp=cList
			cText=[cText [prefix comp{1}] ','];
			if (length(cText)>350)
				cText=[cText '"'];
				fprintf(fid, '%s\n\n', cText);
				cText=['X Note ' [prefix name] ',"'];
			end
		end
		if strcmp(cText(end), '"')
			cText=[cText(1:end) ';"'];
		else
			cText=[cText(1:end-1) ';"'];
		end
		fprintf(fid, '%s\n\n', cText);
	end
	fprintf(fid, '\n');
