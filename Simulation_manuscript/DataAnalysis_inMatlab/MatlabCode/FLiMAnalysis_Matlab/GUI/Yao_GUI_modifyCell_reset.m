function Yao_GUI_modifyCell_reset

global stateYao



% Display
set(stateYao.Disp.modifyCell.plot.hdl,...
    'CData',...
    stateYao.Disp.modifyCell.origData.img )



% Save
stateYao.Disp.modifyCell.data.I_cell =...
    stateYao.Disp.modifyCell.origData.I_cell;
stateYao.Disp.modifyCell.data.img =...
    stateYao.Disp.modifyCell.origData.img;