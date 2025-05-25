function Yao_mouseFunc_modifyCell_stop(cond)

global stateYao


set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonDownFcn',[])
set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonUpFcn',[])
set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonMotionFcn',[])
set( stateYao.Disp.modifyCell.fig.hdl ,'KeyPressFcn',[])



stateYao.temp.modifyCell.mVars.mDown = 0;

 

if ~isempty( stateYao.temp.modifyCell.userSelection.hdl )
if ishandle( stateYao.temp.modifyCell.userSelection.hdl )
    delete( stateYao.temp.modifyCell.userSelection.hdl )
    delete( stateYao.temp.modifyCell.userSelectionUnder.hdl )
end
end

if ~isempty( stateYao.temp.modifyCell.fit.hdl )
if ishandle( stateYao.temp.modifyCell.fit.hdl )
    delete( stateYao.temp.modifyCell.fit.hdl )
    delete( stateYao.temp.modifyCell.fitUnder.hdl )
    delete( stateYao.temp.modifyCell.cfit.hdl )
    delete( stateYao.temp.modifyCell.cfitUnder.hdl )
end
end



if exist('cond','var')
if ischar(cond)
if strcmp(cond,'save')

if ~isempty(stateYao.temp.modifyCell.userSelection.data)
    if size(stateYao.temp.modifyCell.userSelection.data,1) > 1
        stateYao.temp.modifyCell.userSelection.data =...
            stateYao.temp.modifyCell.userSelection.data(1:end-1,:);
    end
end



if size(stateYao.temp.modifyCell.userSelection.data,1) > 1
    
    % Load data
    img = stateYao.Disp.modifyCell.origData.rgbLifetimes;
    I_cell = stateYao.Disp.modifyCell.data.I_cell;
    
    
    
    % Trim data
    [I_cell] = Yao_GUI_modifyCell_trim_curve_func(...
        I_cell,...
        stateYao.temp.modifyCell.userSelection.data );
    
    
    
    % Apply
    [pixelList_perim] = Yao_generic_getPerimeter(I_cell,'PixelList');
    for iPt = 1:size(pixelList_perim,1)
        img(...
            pixelList_perim(iPt,1),...
            pixelList_perim(iPt,2), :) = 1;
    end
    
    
    
    % Display
    set(stateYao.Disp.modifyCell.plot.hdl,...
        'CData',...
        img )
    
    
    
    % Save
    stateYao.Disp.modifyCell.data.I_cell = I_cell;
    stateYao.Disp.modifyCell.data.img = img;
    
end

end
end
end