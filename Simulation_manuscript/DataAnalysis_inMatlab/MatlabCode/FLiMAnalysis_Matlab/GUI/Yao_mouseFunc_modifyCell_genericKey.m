function Yao_mouseFunc_modifyCell_genericKey(src,eventdata)

global stateYao



if src == stateYao.Disp.modifyCell.fig.hdl
    cKey = get(src,'CurrentKey');
    
    
    
    if strcmp(cKey,'return') || strcmp(cKey,'space')
        % End of operation
        Yao_mouseFunc_modifyCell_stop('save')
        
    elseif strcmp(cKey,'backspace')
        % End of operation
        Yao_mouseFunc_modifyCell_stop('abort')
        
        
        
    elseif strcmp(cKey,'e')
        Yao_GUI_modifyCell_erode
    elseif strcmp(cKey,'d')
        Yao_GUI_modifyCell_dilate
    end
end