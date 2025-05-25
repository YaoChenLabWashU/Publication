function Yao_mouseFunc_Move_mUp(src,eventdata)

global stateYao ghYao



% Reset mouse functions
set( ghYao.MainWindow.hdl ,'WindowButtonDownFcn',@Yao_mouseFunc_genericDown)
set( ghYao.MainWindow.hdl ,'WindowButtonUpFcn',[])
set( ghYao.MainWindow.hdl ,'WindowButtonMotionFcn',[])

    
% Reset mDown
stateYao.Disp.mVars.mDown = 0;



% Are we at a valid position?
isValid = 0;



if src == ghYao.MainWindow.hdl

% Get current mouse position and make sure it's within the image panel
cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
cPos = cPos(1,1:2);



if all( cPos > 0 )
cImg = get(stateYao.Disp.plot.hdl,'CData');
    
if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)

    isValid = 1;
    
end
end

end



if isValid
    idxMove = stateYao.Disp.mVars.idxMove(1);
    iCell = stateYao.Disp.mVars.idxMove(2);
    
    % Move ROI
    if stateYao.Disp.mVars.moveType == 1
        % Move ROI vertex
        refPos = stateYao.Disp.ROI.userSelection.data_orig{iCell}(...
            idxMove,:);
        
        dx = cPos(1) - refPos(1);
        dy = cPos(2) - refPos(2);
        
        pts = stateYao.Disp.ROI.userSelection.data_orig{iCell}(:,:);
        pts(idxMove,1) = pts(idxMove,1)+dx;
        pts(idxMove,2) = pts(idxMove,2)+dy;
        
%         Yao_GUI_applyROI(pts,iCell)
%         drawnow
        
    else
        % Move whole ROI
        refPos = stateYao.Disp.ROI.ellipse.data_orig{iCell}(...
            idxMove,:);
        
        dx = cPos(1) - refPos(1);
        dy = cPos(2) - refPos(2);
        
        pts = stateYao.Disp.ROI.userSelection.data_orig{iCell};
        pts(:,1) = pts(:,1)+dx;
        pts(:,2) = pts(:,2)+dy;
        
%         Yao_GUI_applyROI(pts,iCell)
%         drawnow
        
    end
    
    % Save
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    
    
    
    if isnumeric( stateYao.CycleIdentification{numCycle,2} )
        % Dendrite 
        stateYao.ROI{numCycle}{iImg}{iCell} = pts;
        
        [stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell)] =...
            Yao_generic_convertROI2I_ROI(...
            stateYao.ROI{numCycle}{iImg}{iCell},...
            size( stateYao.images.origData.projects{numCycle} ,1),...
            size( stateYao.images.origData.projects{numCycle} ,2) );
        
        
        
    else
        % Nucleus
        I_nucleus = zeros( size(cImg,1),size(cImg,2) );
        pts = stateYao.Disp.ROI.ellipse.data{iCell};
        pts = round(pts);
        pts(:,1) = min(max(1,pts(:,1)),size(cImg,2));
        pts(:,2) = min(max(1,pts(:,2)),size(cImg,1));
        I_nucleus( size(cImg,1)*(pts(:,1)-1)+pts(:,2) ) = 1;
        
        I_nucleus = Yao_generic_fillPts(I_nucleus);
        
        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) = I_nucleus;
        
        
        
        [I_nucleus,ellipseParameters] =...
            Yao_generic_convert2Ellipse(I_nucleus);
        
        stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = ellipseParameters;
        
        
        
        % Update cytoplasm
        I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,iCell);
        
        eval(sprintf('[%s] = %s(%s);',...
            sprintf('%s,%s,%s',...
            'I_nucleus','I_cytoplasm','I_buffer'),...
            stateYao.funcLink.getZones,...
            sprintf('%s,%s',...
            'I_cell','I_nucleus') ))
%         [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID(I_cell,I_nucleus);
        

        
        [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
        stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = ellipseParameters;



        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) = I_nucleus;
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell) = I_cytoplasm;
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell) = I_buffer;
    end
    
    
    
    % Display
    Yao_GUI_loadImage
%     Yao_GUI_applyROI(pts,iCell)
% %     Yao_GUI_drawPoints([],iCell,'buffer')
% %     drawnow
    
    
    
else
    % Reset move
    for iCell = 1:length(stateYao.Disp.ROI.userSelection.data_orig)
    pts = stateYao.Disp.ROI.userSelection.data_orig{iCell};
    
    Yao_GUI_applyROI(pts)
    end
    drawnow
end



end