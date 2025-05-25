function Yao_mouseFunc_genericDown(src,eventdata)

global ghYao

if src == ghYao.MainWindow.hdl
    global stateYao
    
    % Mouse click should be with left-click
    if strcmp( get(src,'Selectiontype') ,'normal')
        % Get current mouse position and make sure it's within the image panel
        cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        % Make sure we're within image boundaries
        if all( cPos > 0 )
            cImg = get(stateYao.Disp.plot.hdl,'CData');
            
            if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)
                
                
                
                stateYao.Disp.mVars.mDown = 1;
                
                eval( stateYao.Disp.mVars.mDownFunc )
                
                
                
            end
        end
        
        
    
    elseif strcmp( get(src,'Selectiontype') ,'alt')
        % Context menu will be loaded. Some options in the context menu may
        % require knowing the initial position of the mouse when the user
        % right-clicked
        
        cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        stateYao.temp.cPos = round( cPos );
        
    end
    
end