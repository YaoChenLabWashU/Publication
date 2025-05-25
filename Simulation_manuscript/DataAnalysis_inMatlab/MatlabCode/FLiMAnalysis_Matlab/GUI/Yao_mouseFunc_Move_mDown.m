function Yao_mouseFunc_Move_mDown

global stateYao

cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
cPos = cPos(1,1:2);



numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



stateYao.Disp.mVars.idxMove = [];
stateYao.Disp.mVars.moveType = 0;





if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    % Dendrite
    
    
    
    % User is acting on the image. Did they select near the ROI?
    %   First check ROI points (userSelection), then plot points
    %   (ellipse)
    
    pts_all = {};
    for iCell = 1:length(stateYao.Disp.ROI.userSelection.data)
        if iCell == 1
            pts_all = stateYao.Disp.ROI.userSelection.data(iCell);
        else
            pts_all = [pts_all, stateYao.Disp.ROI.userSelection.data(iCell)];
        end
    end
    
    if ~isempty(pts_all)
        for iCell = 1:size(pts_all,2)
            pts = pts_all{iCell};
            
            d = hypot(...
                cPos(1) - pts(:,1),...
                cPos(2) - pts(:,2) );
            
            [min_val min_idx] = min(d);
            if min_val < 2
                % Move this point
                stateYao.Disp.mVars.idxMove = [min_idx iCell];
                stateYao.Disp.mVars.moveType = 1;
                
                stateYao.Disp.cCell = iCell;
                
                
            else
                % Check whole ROI
                pts = stateYao.Disp.ROI.ellipse.data{iCell};
                
                d = hypot(...
                    cPos(1) - pts(:,1),...
                    cPos(2) - pts(:,2) );
                
                [min_val min_idx] = min(d);
                if min_val < 2
                    % Move this point
                    stateYao.Disp.mVars.idxMove = [min_idx iCell];
                    stateYao.Disp.mVars.moveType = 2;
                    
                    stateYao.Disp.cCell = iCell;
                    
                end
                
            end
            
            
            
            if ~isempty( stateYao.Disp.mVars.idxMove )
                break
            end
        end
        
        
        
        if stateYao.Disp.mVars.moveType ~= 0
            stateYao.Disp.ROI.userSelection.data_orig =...
                stateYao.Disp.ROI.userSelection.data;
            stateYao.Disp.ROI.ellipse.data_orig =...
                stateYao.Disp.ROI.ellipse.data;
            
            
            
            global ghYao
            
            set( ghYao.MainWindow.hdl ,'WindowButtonUpFcn',...
                @Yao_mouseFunc_Move_mUp)
            set( ghYao.MainWindow.hdl ,'WindowButtonMotionFcn',...
                @Yao_mouseFunc_Move_mMove)
        end
    end








else
    % Nucleus
    
    
    
    
    % User is acting on the image. Did they select near the ROI?
    %   First check ROI points (userSelection), then plot points
    %   (ellipse)
    
    pts_all = [];
    for iCell = 1:length(stateYao.Disp.ROI.userSelection.data)
        if iCell == 1
            pts_all = stateYao.Disp.ROI.userSelection.data{iCell};
        else
            pts_all = cat(3,pts_all,stateYao.Disp.ROI.userSelection.data{iCell});
        end
    end
    
    if ~isempty(pts_all)        
        cellIdList = 1:size(stateYao.cellIdx{numCycle}{iImg},1);
        cellIdList = cellIdList(...
            ~all( stateYao.ellipseParameters{numCycle}{iImg}' == 0 ) );
        idxCellList = stateYao.cellIdx{numCycle}{iImg}(cellIdList,1);
        cellIdList  = stateYao.cellIdx{numCycle}{iImg}(cellIdList,2);
        for iCell = 1:size(cellIdList,1)
            
            pts = pts_all(:,:, idxCellList(iCell) );
            
            d = hypot(...
                cPos(1) - pts(:,1),...
                cPos(2) - pts(:,2) );
            
            [min_val min_idx] = min(d);
            if min_val < 2
                % Move this point
                stateYao.Disp.mVars.idxMove = [min_idx idxCellList(iCell) ];
                stateYao.Disp.mVars.moveType = 1;
                
                stateYao.Disp.cCell = cellIdList(iCell);
                
                
            else
                % Check whole ROI
                pts = stateYao.Disp.ROI.ellipse.data{ idxCellList(iCell) };
                
                d = hypot(...
                    cPos(1) - pts(:,1),...
                    cPos(2) - pts(:,2) );
                
                [min_val min_idx] = min(d);
                if min_val < 2
                    % Move this point
                    stateYao.Disp.mVars.idxMove = [min_idx idxCellList(iCell)];
                    stateYao.Disp.mVars.moveType = 2;
                    
                    stateYao.Disp.cCell = cellIdList(iCell);
                    
                end
                
            end
            
            
            
            if ~isempty( stateYao.Disp.mVars.idxMove )
                break
            end
        end
        
        
        
        if stateYao.Disp.mVars.moveType ~= 0
            stateYao.Disp.ROI.userSelection.data_orig =...
                stateYao.Disp.ROI.userSelection.data;
            stateYao.Disp.ROI.ellipse.data_orig =...
                stateYao.Disp.ROI.ellipse.data;
            
            
            
            global ghYao
            
            set( ghYao.MainWindow.hdl ,'WindowButtonUpFcn',...
                @Yao_mouseFunc_Move_mUp)
            set( ghYao.MainWindow.hdl ,'WindowButtonMotionFcn',...
                @Yao_mouseFunc_Move_mMove)
        end
    end
    
    
    
end







end