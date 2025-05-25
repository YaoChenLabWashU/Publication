function Yao_GUI_initialize

global stateYao ghYao



% Load first image
Yao_GUI_loadImage



% Prepare cycle positions and current image number
numCycle_list = cell(1, size(stateYao.numCycle,1) );
for i = size(stateYao.numCycle,1):-1:1
    if stateYao.numCycle(i) ~= 0
        numCycle_list{i} = num2str( stateYao.numCycle(i) );
    else
        numCycle_list(i) = [];
    end
end
set(stateYao.Disp.Position_Cycle.Popup.hdl,'String',numCycle_list)

set(stateYao.Disp.Position_Cycle.Popup.hdl,'Value',1)
for i = 1:size(numCycle_list,2)
    if str2num( numCycle_list{i} ) == stateYao.Disp.numCycle
        set(stateYao.Disp.Position_Cycle.Popup.hdl,'Value',i)
        break
    end
end




numImage = stateYao.CyclePositions(stateYao.Disp.iImg,stateYao.Disp.numCycle);



set( stateYao.Disp.Position.Edit.hdl ,'String',num2str( numImage ) )


% Set mouse functions
set( ghYao.MainWindow.hdl ,...
    'WindowButtonDownFcn',...
    @Yao_mouseFunc_genericDown)

set( ghYao.MainWindow.hdl ,...
    'KeyPressFcn',...
    @Yao_keyFunc_genericKey)


end