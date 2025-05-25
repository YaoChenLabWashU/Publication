function Yao_mouseFunc_Move_mMove(src,eventdata)

global stateYao

if stateYao.Disp.mVars.mDown
stateYao.Disp.mVars.mDown = 0;
if stateYao.Disp.mVars.moveType ~= 0
% Get current mouse position and make sure it's within the image panel
cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
cPos = cPos(1,1:2);



isValid = 0;
if all( cPos > 0 )
cImg = get(stateYao.Disp.plot.hdl,'CData');
    
if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)

    isValid = 1;
    
end
end



if isValid
    idxMove = stateYao.Disp.mVars.idxMove(1);
    iCell = stateYao.Disp.mVars.idxMove(2);
    
    % Move ROI
    if stateYao.Disp.mVars.moveType == 1
        % Move ROI vertex
%         refPos = stateYao.Disp.ROI.userSelection.data_orig(...
%             idxMove,:,iCell);
        refPos = stateYao.Disp.ROI.userSelection.data_orig{iCell}(...
            idxMove,:);
        
        dx = cPos(1) - refPos(1);
        dy = cPos(2) - refPos(2);
        
        pts = stateYao.Disp.ROI.userSelection.data_orig{iCell};
        pts(idxMove,1) = pts(idxMove,1)+dx;
        pts(idxMove,2) = pts(idxMove,2)+dy;
        
        Yao_GUI_applyROI(pts,iCell,'limited')
        drawnow
        
    else
        % Move whole ROI
        refPos = stateYao.Disp.ROI.ellipse.data_orig{iCell}(...
            idxMove,:);
        
        dx = cPos(1) - refPos(1);
        dy = cPos(2) - refPos(2);
        
        pts = stateYao.Disp.ROI.userSelection.data_orig{iCell};
        pts(:,1) = pts(:,1)+dx;
        pts(:,2) = pts(:,2)+dy;
        
        Yao_GUI_applyROI(pts,iCell,'limited')
        drawnow
        
    end
    
end



end
stateYao.Disp.mVars.mDown = 1;
end