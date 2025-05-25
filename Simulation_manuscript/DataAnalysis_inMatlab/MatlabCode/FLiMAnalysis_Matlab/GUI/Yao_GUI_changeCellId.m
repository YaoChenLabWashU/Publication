function Yao_GUI_changeCellId

global stateYao



str = sprintf('Changing Cell ID...');




cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
cPos = round( cPos(1,1:2) );



% Get current image information
numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



isDendrite = 0;
if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    isDendrite = 1;
end



userInput = [];
if isDendrite
    
    
else
    % Nucleus
    
    
    % Which cell did the user click on?
    idxCell = [];
    for i3 = 1:size(stateYao.images.I_cell_stack{numCycle}{iImg},3)
        if stateYao.images.I_cell_stack{numCycle}{iImg}( cPos(2),cPos(1),i3 )
            idxCell = i3;
            break
        end
    end
    
    
    
    if isempty(idxCell)
        % No cell selected
        fprintf('%s: No cell selection registered\n',mfilename)
    else
        cellID_orig = stateYao.cellIdx{numCycle}{iImg}(...
            stateYao.cellIdx{numCycle}{iImg}(:,1) == idxCell ,2);
        userInput = inputdlg(sprintf('Enter new Cell ID [%d]',cellID_orig));
        
        if ~isempty(userInput)
            userInput = str2num( userInput{1} );
            % Non-numeric inputs will cause userInput to be empty
            
            if ~isempty(userInput)
            if userInput == cellID_orig
                userInput = [];
            end
            end
        end
        
    end
    
    clear idxCell i3
    
end



%%
if ~isempty(userInput)
hdlCompleteTask = waitbar(0,str);

if isDendrite
    
    
else
    % Nucleus
    
    cellID = userInput;
    
    % What if the new cellID is already being used by another cell?
    % Also, does the user want us to make the change to the same cell in
    % every image?
    
    % Get a list of cell IDs for the entire image set, and a list of cell
    % IDs just for this image
    
    cellIdList = [];
    for iImg2 = 1:size( stateYao.CyclePositions ,1)
    if iImg2 ~= iImg
    if stateYao.CyclePositions(iImg2,numCycle) ~= 0 &&...
            ~isempty( stateYao.cellIdx{numCycle}{iImg2} ) % make sure to only go through images with selected cells.
        
        if isempty(cellIdList)
            cellIdList = unique( stateYao.cellIdx{numCycle}{iImg2}(:,2) );
        else
            new_cellIdList = setdiff(...
                stateYao.cellIdx{numCycle}{iImg2}(:,2),...
                cellIdList );
            
            if ~isempty(new_cellIdList)
            cellIdList = cat(1,cellIdList,new_cellIdList);
            end
        end
        
    end
    end
    end
    cellIdList = sortrows(cellIdList);
    
    cellIdList_current = unique( stateYao.cellIdx{numCycle}{iImg}(:,2) );
    
    
    
    isPresent_current = any(cellID == cellIdList_current);
    isPresent_other   = any(cellID == cellIdList);
    
    
    
    if ~isPresent_current
        idxSelection = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
        idxSelection = idxSelection(...
            stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID_orig );
        
        stateYao.cellIdx{numCycle}{iImg}(idxSelection,2) = cellID;
    else
        % This cell will become cellID_orig
        idxSelection = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
        idxSelection = idxSelection(...
            stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID_orig );
        idxSwitch = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
        idxSwitch = idxSwitch(...
            stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
        
        stateYao.cellIdx{numCycle}{iImg}(idxSelection,2) = cellID;
        stateYao.cellIdx{numCycle}{iImg}(idxSwitch,2) = cellID_orig;
    end
    
    
    
    applyOther = 0;
    if isPresent_other
        userInput = questdlg('Apply to other images?', ...
            'Apply Throughout?', ...
            'Yes', 'No', 'No');
        
        switch userInput
            case 'No',
                % Don't do anything further
            case 'Yes',
                applyOther = 1;
        end
    end
    
    
    
    if applyOther
        for iImg2 = 1:size( stateYao.CyclePositions ,1)
        if iImg2 ~= iImg
        if stateYao.CyclePositions(iImg2,numCycle) ~= 0 &&...
                ~isempty( stateYao.cellIdx{numCycle}{iImg2} )
            
            if ishandle(hdlCompleteTask)
            waitbar(...
                iImg/size( stateYao.CyclePositions ,1),...
                hdlCompleteTask)
            drawnow
            end
            
            
            
            idxSelection = [];
            idxSwitch = [];
            if any( stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID_orig )
                idxSelection = 1:size( stateYao.cellIdx{numCycle}{iImg2} ,1);
                idxSelection = idxSelection(...
                    stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID_orig );
            end
            if any( stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID )
                idxSwitch = 1:size( stateYao.cellIdx{numCycle}{iImg2} ,1);
                idxSwitch = idxSwitch(...
                    stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID );
            end
            
            if ~isempty(idxSelection)
                stateYao.cellIdx{numCycle}{iImg2}(idxSelection,2) = cellID;
            end
            if ~isempty(idxSwitch)
                stateYao.cellIdx{numCycle}{iImg2}(idxSwitch,2) = cellID_orig;
            end
            
        end
        end
        end
    end
    
    
    
    stateYao.Disp.cCell = cellID;
    
    
    
end

if ishandle(hdlCompleteTask)
close(hdlCompleteTask)
drawnow
end

Yao_GUI_loadImage

end