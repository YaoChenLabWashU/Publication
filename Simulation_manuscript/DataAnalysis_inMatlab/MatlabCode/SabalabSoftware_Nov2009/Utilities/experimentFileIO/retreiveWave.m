function retreiveWave(waveName, savePaths, forcedisk)

	if nargin==1
		foundFile=retreive(waveName);
	elseif nargin==2
		foundFile=retreive(waveName, savePaths);
	elseif nargin==3
		foundFile=retreive(waveName, savePaths, forcedisk);
	end
	
	if foundFile
        if evalin('base', ['exist(''' waveName ''', ''var'')'])
            if evalin('base', ['isstruct(' waveName ')'])
            	waveStruct=[];
            	waveStruct=setfield(waveStruct, waveName, evalin('base', waveName));
            	evalin('base', ['clear ' waveName]);
            	loadWaveFromStructureo(waveStruct, waveName);
            end
        else
            disp([waveName ' does not exist as variable']);
        end
    end
	if ~iswave(waveName)
		disp('retreiveWave : could not');
	end
