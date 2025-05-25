function Yao_GUI_deleteCell

global stateYao

numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;
status=0;



% This function is called by right-clicking on the GUI to open the context
% menu, and then selecting "Delete Cell". The current mouse position is
% different than the position when the menu was loaded.
%   Mouse position when right-click occurs is stored in stateYao.temp.cPos
cPos = stateYao.temp.cPos;



for i3 = 1:size( stateYao.images.I_cell_stack{numCycle}{iImg} ,3)
if stateYao.images.I_cell_stack{numCycle}{iImg}(cPos(2),cPos(1),i3)
    % Found cell
    idxCell = i3;
    CellID = stateYao.cellIdx{numCycle}{iImg}(idxCell,2); % CellIdx gives cell stats; the second column gives the actual Cell IDs.
    
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) = [];
    stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = [];
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) = [];
    stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) = [];
    
    stateYao.cellIdx{numCycle}{iImg}(idxCell,:) = [];
    if any( stateYao.cellIdx{numCycle}{iImg}(:,1) > idxCell )
        idxCellList = stateYao.cellIdx{numCycle}{iImg}(:,1);
        idxCellList( idxCellList > idxCell ) =...
            idxCellList( idxCellList > idxCell ) - 1;
        stateYao.cellIdx{numCycle}{iImg}(:,1) = idxCellList;
    end
    
    stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = [];
    
    stateYao.applyMask{numCycle}{iImg}(idxCell) = [];
    
    
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}(idxCell) = [];
    stateYao.colorNucleus{numCycle}{iImg}(idxCell) = [];
    
    
    status = 1; % Did we succeed in deleting?
    
    
    break
end
end



%% code to delete all cells based on 1 cell selected in 1 image.

if status==1
    applyOther = 0;
    userInput = questdlg('Apply to other images?', ...
            'Apply Throughout?', ...
            'Yes', 'No', 'No'); % Last one is default
        
        switch userInput
            case 'No',
                % Don't do anything further
            case 'Yes',
                applyOther = 1;
        end

    if applyOther==1
        for iImg2 = 1:size( stateYao.CyclePositions ,1)
            if iImg2 ~= iImg
%                 [iImg2 ...
%                 stateYao.CyclePositions(iImg2,numCycle) ~= 0 ...
%                 ~isempty( stateYao.cellIdx{numCycle}{iImg2} )]
                if stateYao.CyclePositions(iImg2,numCycle) ~= 0 &&...
                        ~isempty( stateYao.cellIdx{numCycle}{iImg2} )
                    
                    
                    %                     if ishandle(hdlCompleteTask)
                    %                         waitbar(...
                    %                             iImg/size( stateYao.CyclePositions ,1),...
                    %                             hdlCompleteTask)
                    %                         drawnow
                    %                     end
                    
                    cellIdList = stateYao.cellIdx{numCycle}{iImg2}(:,2); % cellIDList is the list of the actual IDs of cells (final)
%                     [iImg2 any(cellIdList==CellID)]
                    if any(cellIdList==CellID)
                        indexlist=1:size(stateYao.cellIdx{numCycle}{iImg2},1);
                        indexlist=indexlist(logical(cellIdList==CellID)); % getting the right row corresponding to the cellID.
                        idxCell=stateYao.cellIdx{numCycle}{iImg2}(indexlist,1); % getting the index corresondig to the cellID.
                        if length(idxCell)>1
                            fprintf('more than one cell identified in image %d\n', stateYao.CyclePositions(iImg2,numCycle))
                        else
                            stateYao.images.I_cell_stack{numCycle}{iImg2}(:,:,idxCell) = [];
                            stateYao.images.I_nucleus_stack{numCycle}{iImg2}(:,:,idxCell) = [];
                            stateYao.images.I_cytoplasm_stack{numCycle}{iImg2}(:,:,idxCell) = [];
                            stateYao.images.I_buffer_stack{numCycle}{iImg2}(:,:,idxCell) = [];
                            
                            stateYao.cellIdx{numCycle}{iImg2}(idxCell,:) = [];
                            if any( stateYao.cellIdx{numCycle}{iImg2}(:,1) > idxCell )
                                idxCellList = stateYao.cellIdx{numCycle}{iImg2}(:,1);
                                idxCellList( idxCellList > idxCell ) =...
                                    idxCellList( idxCellList > idxCell ) - 1;
                                stateYao.cellIdx{numCycle}{iImg2}(:,1) = idxCellList;
                            end
                            
                            stateYao.ellipseParameters{numCycle}{iImg2}(idxCell,:) = [];
                            
                            stateYao.applyMask{numCycle}{iImg2}(idxCell) = [];
                            
                            
                            
                            stateYao.funcLink.findNucleus_func{numCycle}{iImg2}(idxCell) = [];
                            stateYao.colorNucleus{numCycle}{iImg2}(idxCell) = [];
                        end
                        
                        
                    end
                end
            end
        end
    end
end
%% 


Yao_GUI_loadImage