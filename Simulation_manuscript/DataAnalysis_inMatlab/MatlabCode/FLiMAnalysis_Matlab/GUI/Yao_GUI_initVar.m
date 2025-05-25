function Yao_GUI_initVar

global stateYao



stateYao.processCycles = 0;



stateYao.Disp.mode.runningCB = 0;



stateYao.Disp.numCycle = stateYao.curRun(1);
stateYao.Disp.iImg = 1;
stateYao.Disp.cCell = 1;



stateYao.Disp.plot.hdl = [];
stateYao.Disp.axis.hdl = [];



stateYao.Disp.ROI.userSelection.hdl = 0;
stateYao.Disp.ROI.userSelectionUnder.hdl = 0;
stateYao.Disp.ROI.ellipse.hdl = 0;
stateYao.Disp.ROI.ellipseUnder.hdl = 0;
stateYao.Disp.ROI.buffer.hdl = 0;
stateYao.Disp.ROI.bufferUnder.hdl = 0;
stateYao.Disp.ROI.cell.hdl = 0;
stateYao.Disp.ROI.cellUnder.hdl = 0;

stateYao.Disp.ROI.userSelection.data = [];
stateYao.Disp.ROI.ellipse.data = [];
stateYao.Disp.ROI.cell.data = [];

stateYao.Disp.ROI.userSelection.data_orig = [];
stateYao.Disp.ROI.ellipse.data_orig = [];
stateYao.Disp.ROI.cell.data_orig = [];



stateYao.Disp.mVars.mDownFunc = 'Yao_mouseFunc_Move_mDown';
stateYao.Disp.mVars.mDownFunc_default = stateYao.Disp.mVars.mDownFunc;

stateYao.Disp.mVars.mDown = 0;
stateYao.Disp.mVars.idxMove = [];
stateYao.Disp.mVars.moveType = 0; % 1 = ROI vertex, 2 = whole ROI



stateYao.Disp.menu.hdl = [];
stateYao.Disp.menu.dendrite.optList = {...
    'Remove ROI','Yao_GUI_removeROI';...
    'Add ROI','Peter_GUI_addROI';...
    %'Reset','Yao_GUI_resetImage';...
    'Apply to Rest', 'Peter_apply2all'};
stateYao.Disp.menu.nucleus.optList = {...
    'Remove Nucleus','Yao_GUI_removeROI';...
    'Remove ALL Nuclei','Yao_GUI_removeROI_all';...
    'Add Nucleus','Yao_GUI_addROI';...
    'Change Cell ID','Yao_GUI_changeCellId';...
    'Modify Cell','Yao_GUI_modifyCell';...
    'Delete Cell','Yao_GUI_deleteCell';...
    'Add Cell','Yao_GUI_addCell';...
    'Reset','Yao_GUI_resetImage';...
    'Apply to Rest', 'Peter_apply2all'};

end
