function Yao_mouseFunc_modifyCell_genericDown(src,eventdata)

% Verify source
global stateYao



if src == stateYao.Disp.modifyCell.fig.hdl
    % Mouse click must be with left-click
    if strcmp( get(src,'Selectiontype') ,'normal')
        % Get current mouse position and make sure it's within the image panel
        cPos = get(stateYao.Disp.modifyCell.axis.hdl,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        % Make sure we're within image boundaries
        if all( cPos > 0 )
            cImg = get(stateYao.Disp.modifyCell.plot.hdl,'CData');
            
            if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)
                
                
                
                stateYao.temp.modifyCell.mVars.mDown = 1;
                
                eval( stateYao.temp.modifyCell.mVars.mDownFunc )
                
                
                
            end
        end
        
    end
end