function Yao_mouseFunc_modifyCell_trim_mUp(src,eventdata)

global stateYao



% set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonUpFcn',[])



if src ~= stateYao.Disp.modifyCell.fig.hdl
    % Abort operation
    Yao_mouseFunc_modifyCell_stop('abort')
    
else
    % Get current mouse position and make sure it's within the image panel
    cPos = get(stateYao.Disp.modifyCell.axis.hdl,'CurrentPoint');
    cPos = cPos(1,1:2);
    
    % Make sure we're within image boundaries
    if all( cPos > 0 )
        cImg = get(stateYao.Disp.modifyCell.plot.hdl,'CData');
        
        if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)
            
            
            
            if isempty( stateYao.temp.modifyCell.userSelection.data )
                stateYao.temp.modifyCell.userSelection.data =...
                    cat(1,cPos,cPos);
                
                set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonMotionFcn',...
                    @Yao_mouseFunc_modifyCell_trim_mMove)
            else
                stateYao.temp.modifyCell.userSelection.data(end,:) =...
                    cPos;
                
                stateYao.temp.modifyCell.userSelection.data =...
                    cat(1,stateYao.temp.modifyCell.userSelection.data,cPos);
                
            end
            
            
            
            
            if ~isempty( stateYao.temp.modifyCell.userSelection.hdl )
            if ishandle( stateYao.temp.modifyCell.userSelection.hdl )
                delete( stateYao.temp.modifyCell.userSelection.hdl )
                delete( stateYao.temp.modifyCell.userSelectionUnder.hdl )
            end
            end
            
            axes(stateYao.Disp.modifyCell.axis.hdl)
            hold on
            stateYao.temp.modifyCell.userSelectionUnder.hdl = plot(...
                stateYao.temp.modifyCell.userSelection.data(:,1),...
                stateYao.temp.modifyCell.userSelection.data(:,2),...
                'm.','MarkerSize',26);
            stateYao.temp.modifyCell.userSelection.hdl = plot(...
                stateYao.temp.modifyCell.userSelection.data(:,1),...
                stateYao.temp.modifyCell.userSelection.data(:,2),...
                'w.','MarkerSize',14);
            hold off
            drawnow
            
            
            
            
        end
    end
    
end