function [continueRun] = Yao_initialize__run_all(isNewSet)

% Re-organize CycleIdentification such that dendrites come first
% Verify that no cycles are repeated
%
%   If repeats, inform user and ask if they want to add another cycle
%
% Force user to make initial ROIs for the dendrite samples
% Gather information on entire run
% Initialize stateYao variables



if ~exist('isNewSet','var')
    isNewSet = 1;
end

continueRun = 0;



global stateYao spc gui



% Progress bar
hdlProgInit = waitbar(0,'Initializing...');



continueInitialization = 1;

size1 = size(spc.projects{1,1},1);
size2 = size(spc.projects{1,1},2);
size3 = size(spc.rgbLifetimes{1,1},3);



%% If we are dealing with a new image set, clear stateYao
if isNewSet
    
    fieldList = fieldnames(stateYao);
    
    for iList = 1:size(fieldList,1)
        if ~strcmp( fieldList{iList} ,'StartSettings')
            stateYao = rmfield( stateYao , fieldList{iList} );
        end
    end
    clear fieldList iList
    
end



%% Verify no cycle is repeated
% We need to read the header files
%   Get experiment ID


if ishandle(hdlProgInit)
    waitbar( 0/10,...
        hdlProgInit,'Verify no cycle is repeated...')
    drawnow
end


if continueInitialization

filepath=gui.gy.filename.path;

fileName = spc.filename;
idxSlash = regexp(fileName,'/');
idxFLIM = regexp(fileName,'FLIM');
baseName = fileName( idxSlash(end)+1: idxFLIM(end)-1 );
clear idxSlash idxFLIM fileName

%   Read each cycle's header file to get cycle number
StartSettings.numCycle = zeros( size(stateYao.StartSettings.CycleIdentification,1) ,1);
StartSettings.zoomFactor = zeros( size(stateYao.StartSettings.CycleIdentification,1) ,1);
idxDel = [];
for iCycle = 1:size( stateYao.StartSettings.CycleIdentification ,1)
    % Get header file path
    str_imageNumber = stateYao.StartSettings.CycleIdentification{iCycle,1};
    
    if str_imageNumber < 10
        str_imageNumber = sprintf('00%d',str_imageNumber);
    elseif str_imageNumber < 100
        str_imageNumber = sprintf('0%d',str_imageNumber);
    else
        str_imageNumber = num2str(str_imageNumber);
    end
    
    hdrPath = sprintf('%s%s%s%s',...
        filepath,...
        baseName,...
        str_imageNumber,...
        '_hdr.txt');
    
    
    
    % Verify header file exists
    if ~exist(hdrPath,'file')
        if isempty(idxDel)
            idxDel = iCycle;
        else
            idxDel = cat(1,idxDel,iCycle);
        end
    else
        % Read header file
        StartSettings.numCycle(iCycle) = str2double( GrabCyclePosition(hdrPath) );
        
        
        
        % Get zoom factor
        fid = fopen(hdrPath);
        stateSettings = textscan(fid,'%s');
        fclose(fid);
        
        for iSetting = 1:size(stateSettings{1},1)
            if any(regexp( stateSettings{1}{iSetting} ,'acq'))
            if any(regexp( stateSettings{1}{iSetting} ,'zoom'))
            if any(regexp( stateSettings{1}{iSetting} ,'zoomFactor'))
                idxZoom = regexp( stateSettings{1}{iSetting} ,'=');
                StartSettings.zoomFactor(iCycle) = str2num(...
                    stateSettings{1}{iSetting}(1,idxZoom+1:end) );
                break
            end
            end
            end
        end
        
    end
end
clear iCycle str_imageNumber hdrPath
clear fid stateSettings idxZoom

%   Clean-up idxDel first
if ~isempty(idxDel)
    if size(idxDel,1) == size( stateYao.StartSettings.CycleIdentification ,1)
        % Delete all...
        fprintf('%s: Header files unavailable for all selections\n',...
            mfilename)
        fprintf('\tCannot continue...\n')
        stateYao.StartSettings.CycleIdentification = [];
        StartSettings.numCycle = [];
        StartSettings.zoomFactor = [];
        
        continueInitialization = 0;
        
    else
        for iIdx = size(idxDel,1):-1:1
            stateYao.StartSettings.CycleIdentification( idxDel(iIdx) ,:) = [];
            StartSettings.numCycle( idxDel(iIdx) ) = [];
            StartSettings.zoomFactor( idxDel(iIdx) ) = [];
        end
        clear iIdx
    end
end
clear idxDel


%  Check for repeats
if continueInitialization
if size( StartSettings.numCycle ,1) ~= size( unique(StartSettings.numCycle) ,1)
    
    idxDel = [];
    for iCycle = size(StartSettings.numCycle,1):-1:2
        for iCycle2 = 1:iCycle-1
            if StartSettings.numCycle(iCycle) == StartSettings.numCycle(iCycle2)
                
                if isempty(idxDel)
                    idxDel = iCycle;
                else
                    idxDel = cat(1,idxDel,iCycle);
                end
                
                break
            end
        end
    end
    clear iCycle iCycle2
    
    for iIdx = 1:size(idxDel,1)
        stateYao.StartSettings.CycleIdentification( idxDel(iIdx) ,:) = [];
        StartSettings.numCycle( idxDel(iIdx) ) = [];
        StartSettings.zoomFactor( idxDel(iIdx) ) = [];
    end
    clear idxDel iIdx
    
end
end % if continueInitialization



end % if continueInitialization



%% Update stateYao based on stateYao.StartSettings


if ishandle(hdlProgInit)
    waitbar( 1/8,...
        hdlProgInit,'Get StartSettings...')
    drawnow
end



%   Do we need to initializate stateYao.CycleIdentification?
%       We want column arrays
if ~isfield(stateYao,'CycleIdentification') ||...
        isempty(stateYao.CycleIdentification)
    stateYao.CycleIdentification = cell(...
        2,...
        size(stateYao.StartSettings.CycleIdentification,2) );
    stateYao.numCycle = zeros(...
        size(stateYao.CycleIdentification,1),...
        1);
    stateYao.zoomFactor = stateYao.numCycle;
end



for iCycle = 1:size( stateYao.StartSettings.CycleIdentification ,1)
    stateYao.CycleIdentification( StartSettings.numCycle(iCycle) ,:) =...
        stateYao.StartSettings.CycleIdentification(iCycle,:);
    
    stateYao.numCycle( StartSettings.numCycle(iCycle) ) = StartSettings.numCycle(iCycle);
    stateYao.zoomFactor( StartSettings.numCycle(iCycle) ) = StartSettings.zoomFactor(iCycle);
end
clear iCycle



%% Figure out which cycles are for dendrites and which are for nuclei

if ishandle(hdlProgInit)
    waitbar( 2/8,...
        hdlProgInit,'Separate dendrites and nuclei...')
    drawnow
end


if continueInitialization

CycleDendrite = zeros(size(stateYao.CycleIdentification,1),1);
CycleNucleus = CycleDendrite;

for iCycle = 1:size(stateYao.CycleIdentification,1)
if stateYao.numCycle(iCycle) ~= 0
    if isnumeric( stateYao.CycleIdentification{iCycle,2} )
        CycleDendrite(iCycle) = iCycle;
    else
        CycleNucleus(iCycle) = iCycle;
    end
end
end
clear iCycle

stateYao.CycleDendrite = CycleDendrite(CycleDendrite ~= 0);
stateYao.CycleNucleus  = CycleNucleus(CycleNucleus ~= 0);

clear CycleDendrite CycleNucleus



end % if continueInitialization



%% Save which cycles are on this run
% Organize so that dendrites go first


if ishandle(hdlProgInit)
    waitbar( 3/8,...
        hdlProgInit,'Getting current run order...')
    drawnow
end

curRun = cat(2,...
    StartSettings.numCycle,...
    zeros( size(StartSettings.numCycle,1) ,1) );

for iCycle = 1:size(curRun,1)
    if any( curRun(iCycle,1) == stateYao.CycleDendrite )
        curRun(iCycle,2) = 1;
    end
end
clear iCycle


curRun = sortrows(curRun,-2);
stateYao.curRun = curRun(:,1);
clear curRun



nCycle = max( stateYao.curRun );



%% If new set, initialize stateYao variables

if ishandle(hdlProgInit)
    waitbar( 4/8,...
        hdlProgInit,'First initialization...')
    drawnow
end

if isNewSet
    
    
    % images
    %   origData
    %       projects
    %       lifetimeMaps
    %       rgbLifetimes
    %   filtData
    %       projects
    %       lifetimeMaps
    %       rgbLifetimes
    %
    %   mask
    %       projects
    %       lifetimeMaps
    %       rgbLifetimes
    %       I_ROI
    %       I_mask
    %       img_mask
    %
    %   I_ROI_stack
    %   I_cell_stack
    %   I_nucleus_stack
    %   I_buffer_stack
    %   I_cytoplasm_stack
    %
    % mask
    %   ROI
    %   ellipseParameters
    
    
    stateYao.images.origData.projects = cell(nCycle,1);
    stateYao.images.origData.lifetimeMaps =...
        stateYao.images.origData.projects;
    stateYao.images.origData.rgbLifetimes =...
        stateYao.images.origData.projects;
    
    stateYao.images.filtData.projects =...
        stateYao.images.origData.projects;
    stateYao.images.filtData.lifetimeMaps =...
        stateYao.images.filtData.projects;
    stateYao.images.filtData.rgbLifetimes =...
        stateYao.images.filtData.projects;
    
    stateYao.images.mask.projects =...
        stateYao.images.origData.projects;
    stateYao.images.mask.lifetimeMaps =...
        stateYao.images.mask.projects;
    stateYao.images.mask.rgbLifetimes =...
        stateYao.images.mask.projects;
    stateYao.images.mask.I_ROI =...
        stateYao.images.mask.projects;
    stateYao.images.mask.I_mask =...
        stateYao.images.mask.projects;
    stateYao.images.mask.img_mask =...
        stateYao.images.mask.projects;
    
    stateYao.images.I_ROI_stack = cell(nCycle,1);
    stateYao.images.I_cell_stack = cell(nCycle,1);
    stateYao.images.I_nucleus_stack =...
        stateYao.images.I_cell_stack;
    stateYao.images.I_buffer_stack =...
        stateYao.images.I_nucleus_stack;
    stateYao.images.I_cytoplasm_stack =...
        stateYao.images.I_nucleus_stack;
    
    stateYao.mask.ROI = cell(nCycle,1);
    stateYao.mask.ellipseParameters = cell(nCycle,1);
    
    
    
    % dendriteOpt
    %   rotation
    % nucleusOpt
    %   borderThreshold
    %   valleyDetection
    %   checkAppendages
    
    stateYao.dendriteOpt.rotation = zeros(nCycle,1);
    
    stateYao.nucleusOpt.borderThreshold = zeros(nCycle,1);
    stateYao.nucleusOpt.valleyDetection =...
        stateYao.nucleusOpt.borderThreshold;
    stateYao.nucleusOpt.checkAppendages =...
        stateYao.nucleusOpt.borderThreshold;
    
    
    
    
    
    % cellIdx 
    stateYao.cellIdx = cell( nCycle,1 );
    
    % applyMask
    stateYao.applyMask = cell( nCycle,1 );
    
    
    
    % offset
    % ROI
    % ellipseParameters
    
    stateYao.offset = cell( nCycle,1 );
    stateYao.ROI = cell( nCycle,1 );
    stateYao.ellipseParameters = cell( nCycle,1 );
    
    
    
    % colorNucleus
    % check
    %   type1
    stateYao.colorNucleus = cell( nCycle ,1);
    stateYao.check = [];
    stateYao.check.type1 = cell( nCycle,1 );
    
    
    % ignoreImage
    %   Don't have stateYao.CyclePositions yet
    
    % AcqTime
    %   Don't have stateYao.CyclePositions yet
    

    
    % Shift
    %   Don't have stateYao.CyclePositions yet
    
    
    
    
    
    
    % valPhoton_threshold
    % cellPixelCount_threshold_b
    % cellPixelCount_threshold_m
    % colorList
    stateYao.valPhoton_threshold =...
        stateYao.StartSettings.valPhoton_threshold;
    stateYao.cellPixelCount_threshold_b =...
        stateYao.StartSettings.cellPixelCount_threshold_b;
    stateYao.cellPixelCount_threshold_m =...
        stateYao.StartSettings.cellPixelCount_threshold_m;
    stateYao.colorList =...
        stateYao.StartSettings.colorList;
    
    
    
    % colorNucleus
    stateYao.colorNucleus = cell( nCycle,1 );
    
    
    
    % funcLink
    %   findNucleus_func
    stateYao.funcLink =...
        stateYao.StartSettings.funcLink;
    
    
     stateYao.funcLink.findNucleus_func = cell( nCycle,1 );
    
    
    
     
     
else
    
    
    % Update funcLink settings
    fieldList = fieldnames( stateYao.StartSettings.funcLink );
    for iList = 1:size(fieldList,1)
        stateYao.funcLink.( fieldList{iList} ) =...
            stateYao.StartSettings.funcLink.( fieldList{iList} );
    end
    
    
    
end



%% Dendrite and Nucleus Option check
% First we need to get which indices of the current run are dendrites and
% which are nucleui

if ishandle(hdlProgInit)
    waitbar( 5/8,...
        hdlProgInit,'Dendrite and Nucleus Option check...')
    drawnow
end

idxList_Dendrite = zeros(size(stateYao.curRun,1),1);
idxList_Nucleus = idxList_Dendrite;
for iRun = 1:size(stateYao.curRun,1)
    if any( stateYao.curRun(iRun) == stateYao.CycleDendrite )
        idxList_Dendrite(iRun) = iRun;
    elseif any( stateYao.curRun(iRun) == stateYao.CycleNucleus )
        idxList_Nucleus(iRun) = iRun;
    end
end

idxList_Dendrite = idxList_Dendrite( idxList_Dendrite~=0 );
idxList_Nucleus  = idxList_Nucleus(  idxList_Nucleus~=0 );



% Do we have any dendrites in the current run?
if ~isempty(idxList_Dendrite)
    % Yes
    % What options are there?
    %   rotation
    
    % Can we automate this process so that the options can change later?
    %   Yes!
    fieldList = fieldnames( stateYao.StartSettings.dendriteOpt );
    
    % Go through each option, 1 by 1
    for iList = 1:size(fieldList,1)
        
        if length( stateYao.StartSettings.dendriteOpt.(fieldList{iList}) ) == 1
            % All values are the same
            for numCycle = stateYao.curRun(idxList_Dendrite)
                stateYao.dendriteOpt.(fieldList{iList})(numCycle) = ...
                    stateYao.StartSettings.dendriteOpt.(fieldList{iList});
            end
            
        elseif length( stateYao.StartSettings.dendriteOpt.(fieldList{iList}) ) ==...
                length( idxList_Dendrite )
            % Same number of values as dendrites in the current run
            %   Is option 1 related to first run in idxList_Dendrite?
            %       Yes! When we did sortrows on curRun, that was just on
            %       whether it was a dendrite or a nucleus
            for iD = 1:length(idxList_Dendrite)
                numCycle = stateYao.curRun( idxList_Dendrite(iD) );
                
                stateYao.dendriteOpt.(fieldList{iList})(numCycle) = ...
                    stateYao.StartSettings.dendriteOpt.(fieldList{iList})(iD);
                
            end
            
        else
            % Mismatch between number of values in the option and number of
            % dendrites present in the current run
            %   Ask user for correct values
            
            dlg_name = fieldList{iList};
            dlg_prompt = cell(1,length(idxList_Dendrite));
            dlg_default = dlg_prompt;
            for iD = 1:length(idxList_Dendrite)
                dlg_prompt{iD} = sprintf('%s Img %d',...
                    fieldList{iList},...
                    stateYao.CycleIdentification{ stateYao.curRun(idxList_Dendrite(iD)) ,1} );
                dlg_default{iD} = '0';
            end
            
            
            ANSWER = inputdlg(dlg_prompt,dlg_name,1,dlg_default);
            
            
            
            % Did the user answer correctly?
            %   If not, cycle to each image, then ask for that image
            askAgain = 0;
            
            if isempty(ANSWER)
                askAgain = 1;
            else
                for iA = 1:length(ANSWER)
                    
                    if isempty( str2num(ANSWER{iA}) )
                        % Not a number!
                        askAgain = 1;
                    end
                    
                end
            end
            
            if ~askAgain
                % Save results
                for iD = 1:length(idxList_Dendrite)
                    numCycle = stateYao.curRun( idxList_Dendrite(iD) );
                    
                    stateYao.dendriteOpt.(fieldList{iList})(numCycle) = ...
                        str2num(ANSWER{iD});
                end
            else
                
                for iD = 1:length(idxList_Dendrite)
                    numCycle = stateYao.curRun( idxList_Dendrite(iD) );
                    numImg = stateYao.CycleIdentification{numCycle,1};
                    
                    spc_openFiles(numImg,[])
                    
                    while askAgain
                        askAgain = 0;
                        
                        dlg_name = fieldList{iList};
                        dlg_prompt = cell(1,1);
                        dlg_prompt{1} =...
                            sprintf('%s Img %d',fieldList{iList},numImg);
                        dlg_default = cell(1,1);
                        dlg_default{1} = '0';
                        ANSWER = inputdlg(dlg_prompt,dlg_name,1,dlg_default);
                        
                        if isempty(ANSWER)
                            askAgain = 1;
                        elseif isempty( str2num(ANSWER{1}) )
                            % Not a number!
                            askAgain = 1;
                        end
                    end
                    
                    % Save result
                    stateYao.dendriteOpt.(fieldList{iList})(numCycle) = ...
                        str2num(ANSWER{1});
                    
                    % Reset askAgain
                    askAgain = 1;
                    
                end
                
            end
            
        end
        
    end % for iList
    
    
    
end



% Do we have any nuclei in the current run?
if ~isempty(idxList_Nucleus)
    % Yes
    % What options are there?
    %   borderThreshold
    %   valleyDetection
    %   checkAppendages
    
    % Can we automate this process so that the options can change later?
    %   Yes!
    fieldList = fieldnames( stateYao.StartSettings.nucleusOpt );
    
    % Go through each option, 1 by 1
    for iList = 1:size(fieldList,1)
        
        if length( stateYao.StartSettings.nucleusOpt.(fieldList{iList}) ) == 1
            % All values are the same
            for numCycle = stateYao.curRun(idxList_Nucleus)
                stateYao.nucleusOpt.(fieldList{iList})(numCycle) = ...
                    stateYao.StartSettings.nucleusOpt.(fieldList{iList});
            end
            
        elseif length( stateYao.StartSettings.nucleusOpt.(fieldList{iList}) ) ==...
                length( idxList_Nucleus )
            % Same number of values as nuclei in the current run
            %   Is option 1 related to first run in idxList_Nucleus?
            %       Yes! When we did sortrows on curRun, that was just on
            %       whether it was a dendrite or a nucleus
            for iN = 1:length(idxList_Nucleus)
                numCycle = stateYao.curRun( idxList_Nucleus(iN) );
                
                stateYao.nucleusOpt.(fieldList{iList})(numCycle) = ...
                    stateYao.StartSettings.nucleusOpt.(fieldList{iList})(iN);
                
            end
            
        else
            Mismatch between number of values in the option and number of
            nuclei present in the current run
              Ask user for correct values
            
            dlg_name = fieldList{iList};
            dlg_prompt = cell(1,length(idxList_Nucleus));
            dlg_default = dlg_prompt;
            for iN = 1:length(idxList_Nucleus)
                dlg_prompt{iN} = sprintf('%s Img %d',...
                    fieldList{iList},...
                    stateYao.CycleIdentification{ stateYao.curRun(idxList_Nucleus(iN)) ,1} );
                dlg_default{iN} = '0';
            end
            
            
            ANSWER = inputdlg(dlg_prompt,dlg_name,1,dlg_default);
            
            
            
            % Did the user answer correctly?
            %   If not, cycle to each image, then ask for that image
            askAgain = 0;
            
            if isempty(ANSWER)
                askAgain = 1;
            else
                for iA = 1:length(ANSWER)
                    
                    if isempty( str2num(ANSWER{iA}) )
                        % Not a number!
                        askAgain = 1;
                    end
                    
                end
            end
            
            if ~askAgain
                % Save results
                for iN = 1:length(idxList_Nucleus)
                    numCycle = stateYao.curRun( idxList_Nucleus(iN) );
                    
                    stateYao.nucleusOpt.(fieldList{iList})(numCycle) = ...
                        str2num(ANSWER{iN});
                end
            else
                
                for iN = 1:length(idxList_Nucleus)
                    numCycle = stateYao.curRun( idxList_Nucleus(iN) );
                    numImg = stateYao.CycleIdentification{numCycle,1};
                    
                    spc_openFiles(numImg,[])
                    
                    while askAgain
                        askAgain = 0;
                        
                        dlg_name = fieldList{iList};
                        dlg_prompt = cell(1,1);
                        dlg_prompt{1} =...
                            sprintf('%s Img %d',fieldList{iList},numImg);
                        dlg_default = cell(1,1);
                        dlg_default{1} = '0';
                        ANSWER = inputdlg(dlg_prompt,dlg_name,1,dlg_default);
                        
                        if isempty(ANSWER)
                            askAgain = 1;
                        elseif isempty( str2num(ANSWER{1}) )
                            % Not a number!
                            askAgain = 1;
                        end
                    end
                    
                    % Save result
                    stateYao.nucleusOpt.(fieldList{iList})(numCycle) = ...
                        str2num(ANSWER{1});
                    
                    % Reset askAgain
                    askAgain = 1;
                    
                end
                
            end
            
        end
        
    end % for iList
    
    
    
end






%% Get initial dendrite ROIs
% Do we have any dendrites?


if ishandle(hdlProgInit)
    waitbar( 6/8,...
        hdlProgInit,'Get initial dendrite ROIs...')
    drawnow
end



if any( stateYao.CycleDendrite == stateYao.curRun(1) )
    % Yes
    % Get dendrite list
    lastDendrite = 1;
    if size( stateYao.CycleIdentification ,1) == 1 ||...
            size( stateYao.curRun ,1) == 1
        lastDendrite = 1;
    else
        for iCycle = 2:size( stateYao.curRun ,1)
            if ~any( stateYao.CycleDendrite == stateYao.curRun(iCycle) )
                iCycle = iCycle-1;
                break
            end
        end
        lastDendrite = iCycle;
        
        clear iCycle
    end    
    
    
    
    % Load each image and ask for user to select ROI
    for iCycle = 1:lastDendrite
        numCycle = stateYao.curRun(iCycle);
        
        
        
        % Which image is being loaded?
        numImg = stateYao.CycleIdentification{numCycle,1};
        
        % Load image
        spc_openFiles(numImg,[])
        
        
        
        % Wait for user to create ROI
        hMsg = msgbox('Delete all ROIs. Add new ROI. Click OK when done');
        uiwait(hMsg)
        
        
        
        count = 0;
        while ~isfield(gui.gy,'roiPositions')
            count = count+1;
            if count > 2
                break
            end
            hMsg = msgbox('No ROI found. Add new ROI. Click OK when done');
            uiwait(hMsg)
        end
        count = 0;
        while isempty(gui.gy.roiPositions)
            count = count+1;
            if count > 2
                break
            end
            hMsg = msgbox('No ROI found. Add new ROI. Click OK when done');
            uiwait(hMsg)
        end
        
        % Get user selection
        %   Only 1 ROI for dendrites
        %   Nucleus images can have multiple
        stateYao.images.mask.projects{numCycle}{1} = spc.projects{1,1};
        stateYao.images.mask.lifetimeMaps{numCycle}{1} = spc.lifetimeMaps{1,1};
        stateYao.images.mask.rgbLifetime{numCycle}{1} = spc.rgbLifetimes{1,1};
        
        stateYao.mask.ROI{numCycle} = gui.gy.roiPositions;
    end
    clear lastDendrite numImg hMsg iCycle numCycle
    drawnow
end



%% Get cycle position info

if ishandle(hdlProgInit)
    waitbar( 7/8,...
        hdlProgInit,'Get cycle position info...')
    drawnow
end

if isNewSet
  Yao_generic_getCyclePositions_v2(spc,gui)
  
%  The next section is to redefine the CyclePositions when multiple episodes of imaging are included in one
% imaging dataset and we only analyze one episode at one time.

  global redefine Epochstart Epochend NonValidAcqs
  
  if redefine == 1
     stateYao.CyclePositions=[];
     stateYao.CyclePositions(:,1)=Epochstart:1:Epochend;
     for i_NonValid = 1:length(NonValidAcqs)

         Nonvalid_index = find(stateYao.CyclePositions == NonValidAcqs(i_NonValid));
         stateYao.CyclePositions(Nonvalid_index) = [];
     end
  end
  
  if redefine == 0
      stateYao.CyclePositions(stateYao.CyclePositions<Epochstart)=[];
      stateYao.CyclePositions(stateYao.CyclePositions>Epochend)=[];
      
  end






    % Do we need to initialize any stateYao fields?
    %   ignoreImage
    %   AcqTime
    %   shift
    %       initial
    %       second
    %       final?
    
    stateYao.ignoreImage = zeros(...
        size(stateYao.CyclePositions,1),...
        size(stateYao.CyclePositions,2) );
    
    stateYao.AcqTime = zeros(...
        size(stateYao.CyclePositions,1),...
        size(stateYao.CyclePositions,2) );
    
    stateYao.shift = [];
    stateYao.shift.initial.iImg_mask = zeros(nCycle,1);
    stateYao.shift.initial.imageShift = cell(nCycle,1);
    
    stateYao.shift.second.imageShift =...
        stateYao.shift.initial.imageShift;
    stateYao.shift.second.bwShift =...
        stateYao.shift.initial.imageShift;
    stateYao.shift.final.imageShift =...
        stateYao.shift.initial.imageShift;
end



%% Finish initializing stateYao

if ishandle(hdlProgInit)
    waitbar( 7/8,...
        hdlProgInit,'Finish initializing stateYao...')
    drawnow
end

nImg = size( stateYao.CyclePositions ,1);
for iCycle = 1:size(stateYao.curRun,1)
    numCycle = stateYao.curRun(iCycle);    
    
    
    
    if isNewSet
    % images
    %   origData
    %       projects
    %       lifetimeMaps
    %       rgbLifetimes
    %   filtData
    %       projects
    %       lifetimeMaps
    %       rgbLifetimes
    
    stateYao.images.origData.projects{numCycle} = zeros(size1,size2,nImg);
    stateYao.images.origData.lifetimeMaps{numCycle} =...
        stateYao.images.origData.projects{numCycle};
    stateYao.images.origData.rgbLifetimes{numCycle} = zeros(size1,size2,size3,nImg);
    
    stateYao.images.filtData.projects{numCycle} =...
        stateYao.images.origData.projects{numCycle};
    stateYao.images.filtData.lifetimeMaps{numCycle} =...
        stateYao.images.filtData.projects{numCycle};
    stateYao.images.filtData.rgbLifetimes{numCycle} =...
        stateYao.images.origData.rgbLifetimes{numCycle};
    
    
    
    stateYao.shift.initial.imageShift{numCycle} =...
        zeros( nImg ,2);
    
    stateYao.shift.second.imageShift{numCycle} =...
        stateYao.shift.initial.imageShift{numCycle};
    stateYao.shift.second.bwShift{numCycle} =...
        stateYao.shift.initial.imageShift{numCycle};
    stateYao.shift.final.imageShift{numCycle} =...
        stateYao.shift.initial.imageShift{numCycle};
    end
    
    
    
    
    stateYao.cellIdx{numCycle} = cell(nImg,1);
    
    stateYao.applyMask{numCycle} = cell(nImg,1);
    
    stateYao.offset{numCycle} = cell(nImg,1);
    
    stateYao.ignoreImage(:,numCycle) = 0;
    
    
    
    
    
    
    
    
    if any( numCycle == stateYao.CycleDendrite )
        % Dendrite
        stateYao.ROI{numCycle} = cell(nImg,1);
        
        stateYao.images.I_ROI_stack{numCycle} = cell(nImg,1 );
        
    elseif any( numCycle == stateYao.CycleNucleus )
        % Nucleus
        stateYao.ellipseParameters{numCycle} = cell(nImg,1);
        
        stateYao.colorNucleus{numCycle} = cell(nImg,1);
        
        stateYao.check.type1{numCycle} = cell(nImg,1);
        
        
        % images
        %   mask
        %       projects
        %       lifetimeMaps
        %       rgbLifetimes
        %       I_ROI
        %       I_mask
        %           Done after we have the cells
        %
        %   I_ROI_stack
        %   I_cell_stack
        %   I_nucleus_stack
        %   I_buffer_stack
        %   I_cytoplasm_stack
        %
        % mask
        %   ROI
        %   ellipseParameters
        
        stateYao.images.mask.projects{numCycle} = zeros(size1,size2);
        stateYao.images.mask.lifetimeMaps{numCycle} = zeros(size1,size2);
        stateYao.images.mask.rgbLifetimes{numCycle} = zeros(size1,size2,size3);
        stateYao.images.mask.I_ROI{numCycle} = zeros(size1,size2);
        
        stateYao.images.I_ROI_stack{numCycle} = cell(nImg,1);
        stateYao.images.I_cell_stack{numCycle} =...
            stateYao.images.I_ROI_stack{numCycle};
        stateYao.images.I_nucleus_stack{numCycle} =...
            stateYao.images.I_ROI_stack{numCycle};
        stateYao.images.I_buffer_stack{numCycle} =...
            stateYao.images.I_ROI_stack{numCycle};
        stateYao.images.I_cytoplasm_stack{numCycle} =...
            stateYao.images.I_ROI_stack{numCycle};
        
        stateYao.mask.ROI{numCycle} = [];
        stateYao.mask.ellipseParameters{numCycle} = [];
        
        
        
        
        % Update when we get cells:
        %   colorNucleus
        %   funcLink
        %       findNucleus_func
        stateYao.colorNucleus{numCycle} = cell(nImg,1);
        stateYao.funcLink.findNucleus_func{numCycle} = cell(nImg,1);
        
        
    end
    
    
    
end















%% Very last thing to do
if continueInitialization
    continueRun = 1;
end



if ishandle(hdlProgInit)
close(hdlProgInit)
drawnow
end