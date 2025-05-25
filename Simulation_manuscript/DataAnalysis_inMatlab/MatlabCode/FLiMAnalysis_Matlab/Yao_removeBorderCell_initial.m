function Yao_removeBorderCell_initial(numCycle)

global stateYao



% Get list of cells; get a master list of all the cells in the set based on
% cell IDs.
cellIdList = [];
for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,numCycle) ~= 0
if ~isempty(stateYao.images.I_cell_stack{numCycle}{iImg})
if ~isempty(stateYao.cellIdx{numCycle}{iImg})
    
    temp_cellIdList = unique( stateYao.cellIdx{numCycle}{iImg}(:,2) );
    
    if isempty(cellIdList)
        cellIdList = temp_cellIdList;
    else
        temp_setdiff = setdiff(temp_cellIdList,cellIdList);
        if ~isempty( temp_setdiff )
            cellIdList = cat(1,cellIdList,temp_setdiff);
        end
    end
    
end
end
end
end
clear temp_cellIdList temp_setdiff



% Get iImg list for each cell
iImgList = cell(size(cellIdList,1),1);

for iCellId = 1:size(cellIdList,1)
    iImgList{iCellId} = cat(2,...
        [1:size( stateYao.CyclePositions ,1)]',...
        zeros(size( stateYao.CyclePositions ,1),1) );
end
% initialized with iImg list in column 1, 0s in column 2.

% Fill in iImgList: each cell corresponds to data related to a cell Id (e.g. 1) --
% the first column shows you the iImgs that contain the cellID (e.g. 1);
% the second column shows you the cell indices that correspond to that cell
% ID (e.g. 1).
for iImg = size( stateYao.CyclePositions ,1):-1:1
    if stateYao.CyclePositions(iImg,numCycle) == 0
        for iCellId = 1:size(cellIdList,1)
            iImgList{iCellId}(iImg,:) = [];
        end
        
    else
        if isempty(stateYao.images.I_cell_stack{numCycle}{iImg})
            for iCellId = 1:size(cellIdList,1)
                iImgList{iCellId}(iImg,:) = [];
            end
        else
            if isempty(stateYao.cellIdx{numCycle}{iImg})
                for iCellId = 1:size(cellIdList,1)
                    iImgList{iCellId}(iImg,:) = [];
                end
            else
                for iCellId = 1:size(cellIdList,1)
                    cellID = cellIdList(iCellId);
                    if ~any( cellID == stateYao.cellIdx{numCycle}{iImg}(:,2) )
                        iImgList{iCellId}(iImg,:) = [];
                    else
                        % This will give an error if more than 1 cell has the same
                        % cellID
                        temp_iCellList = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
                        
                        if length( temp_iCellList(...
                                stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID  ) ) > 1
                            fprintf('%s: 2 cells have the same ID!\n',mfilename)
                            fprintf('\tOccurs at Cycle %d, iImg %d\n',numCycle,iImg)
                            iImgList{iCellId}(iImg,:) = [];
                        else
                            iImgList{iCellId}(iImg,2) = temp_iCellList(...
                                stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID  );
                        end
                        
                    end
                    
                end
                
            end
        end
    end
    
end % for iImg




for iCellId = size(cellIdList,1):-1:1
    if size( iImgList{iCellId} ,1) == 0
        % Remove
        cellIdList(iCellId) = [];
        iImgList(iCellId) = [];
    end
end





% Find if any cells are too close to the border
%   For each cell, find the furthest-from-border position
delList = [];
for iCellId = 1:size(cellIdList,1)
    
    x0 = zeros( size(iImgList{iCellId},1) ,1);
    y0 = x0;
    
    for i1 = 1:size(iImgList{iCellId},1)
        iImg  = iImgList{iCellId}(i1,1);
        iCell = iImgList{iCellId}(i1,2);
        
        x0(i1) = stateYao.cellIdx{numCycle}{iImg}(iCell,5); %grab x coordinate of centroild
        y0(i1) = stateYao.cellIdx{numCycle}{iImg}(iCell,6); %grab y coordinate of centroild
    end
    
    % Close to which boundary?
    if mean(x0) > size(stateYao.images.origData.projects{numCycle},2)-mean(x0)
        % x is closer to right boundary
        dx = max(size(stateYao.images.origData.projects{numCycle},2)-x0);
    else
        % x is closer to left boundary
        dx = max(x0);
    end
    if mean(y0) > size(stateYao.images.origData.projects{numCycle},1)-mean(y0)
        % y is closer to bottom boundary
        dy = max(size(stateYao.images.origData.projects{numCycle},1)-y0);
    else
        % y is closer to top boundary
        dy = max(y0);
    end
    
%     mfilename
%     dx
%     stateYao.nucleusOpt.borderThreshold(numCycle)
%     dy
    
    if dx < stateYao.nucleusOpt.borderThreshold(numCycle) ||...
            dy < stateYao.nucleusOpt.borderThreshold(numCycle)
        if isempty(delList)
            delList = iCellId;
        else
            delList = cat(1,delList,iCellId);
        end
    end
    
end



if ~isempty(delList)
    % Delete
    for iList = 1:size(delList,1)
        iCellId = delList(iList);
        cellID = cellIdList(iCellId);
        
        for iImg = iImgList{iCellId}(:,1)'
            iCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1);
            iCell = iCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
            idxCell = stateYao.cellIdx{numCycle}{iImg}(iCell,1);
            
            if idxCell < max(stateYao.cellIdx{numCycle}{iImg}(:,1))
                % We need to update these cells
                idxCellList = stateYao.cellIdx{numCycle}{iImg}(:,1);
                idxCellList = cat(2,...
                    [1:size(stateYao.cellIdx{numCycle}{iImg},1)]',...
                    idxCellList );
                
                idxCellList = idxCellList( idxCellList(:,2) > idxCell ,:);
                idxCellList(:,2) = idxCellList(:,2)-1;
                stateYao.cellIdx{numCycle}{iImg}( idxCellList(:,1) ,1) =...
                    idxCellList(:,2);
            end
            
            
            
            stateYao.cellIdx{numCycle}{iImg}(iCell,:) = [];
            stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) = [];
            
        end
        
    end
end