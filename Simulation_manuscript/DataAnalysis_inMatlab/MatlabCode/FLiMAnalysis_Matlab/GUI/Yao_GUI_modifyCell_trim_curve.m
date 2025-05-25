function Yao_GUI_modifyCell_trim_curve

global stateYao



% Terminate previous trim operation if in-progress





% Initialize variables
stateYao.temp.modifyCell.userSelection.data = [];
stateYao.temp.modifyCell.userSelection.hdl = [];
stateYao.temp.modifyCell.userSelectionUnder.hdl = [];

stateYao.temp.modifyCell.fit.hdl = [];
stateYao.temp.modifyCell.fitUnder.hdl = [];
stateYao.temp.modifyCell.cfit.hdl = [];
stateYao.temp.modifyCell.cfitUnder.hdl = [];

stateYao.temp.modifyCell.mVars.mDown = 0;
stateYao.temp.modifyCell.mVars.mDownFunc =...
    'Yao_mouseFunc_modifyCell_trim_mDown';





% Apply functions to figure
set(stateYao.Disp.modifyCell.fig.hdl,...
    'WindowButtonDownFcn',...
    @Yao_mouseFunc_modifyCell_genericDown)

set(stateYao.Disp.modifyCell.fig.hdl,...
    'KeyPressFcn',...
    @Yao_mouseFunc_modifyCell_genericKey)