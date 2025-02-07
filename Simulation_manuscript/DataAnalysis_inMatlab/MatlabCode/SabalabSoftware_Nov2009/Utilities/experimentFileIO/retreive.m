function found=retreive(waveName, savePaths, forcedisk)
    found=0;
    if nargin==3
        if ischar(savePaths)
            savePaths={savePaths};
        end
    elseif nargin==2
        if ischar(savePaths)
            savePaths={savePaths};
        end
        forcedisk=0;
    elseif nargin==1
        global state
        savePaths={};
        forcedisk=0;
        if isfield(state, 'files')
            if isfield(state.files, 'savePath')
                savePaths={state.files.savePath};
            end
        end
    else
        error('retreive: expect a wave name and optional save path list as arguments');
    end
    
    if evalin('base', ['exist(''' waveName ''')']) & ~forcedisk
        disp(['retrieve : ' waveName ' found in memory']);
        found=1;
    else
        for counter=1:length(savePaths)
            if ~isempty(savePaths{counter})
                filename=fullfile(savePaths{counter}, [waveName '.mat']);
                if ~isempty(dir(filename))
                    evalin('base',['load(''' filename ''');']);
                    disp(['retreive : ' waveName ' found in ' filename]);
                    found=1;
                    return
                end
            end
            filename=[waveName '.mat'];
            if ~isempty(dir(filename))
                evalin('base',['load(''' filename ''');']);
                disp(['retreive : ' waveName ' found in ' filename]);
                found=1;
                return
            end
        end
        if nargout==0
            disp(['retreive : ' waveName ' not found']);
        end
    end
		
						
		