function Yao_mouseFunc_modifyCell_trim_mDown

global stateYao



if isempty( stateYao.temp.modifyCell.userSelection.data )
    set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonUpFcn',...
        @Yao_mouseFunc_modifyCell_trim_mUp)
else
%     set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonUpFcn',...
%         @Yao_mouseFunc_modifyCell_trim_mUp)
%     set( stateYao.Disp.modifyCell.fig.hdl ,'WindowButtonMotionFcn',...
%         @Yao_mouseFunc_modifyCell_trim_mMove)
end