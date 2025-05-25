function Yao_GUI_modifyCell_save

global stateYao



% Gather data
iCell = stateYao.Disp.modifyCell.iCell;
I_cell = stateYao.Disp.modifyCell.data.I_cell;

iCycle = stateYao.Disp.iCycle;
iImg = stateYao.Disp.iImg;



% Save data
stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,iCell) = I_cell;



% Display
Yao_GUI_loadImage