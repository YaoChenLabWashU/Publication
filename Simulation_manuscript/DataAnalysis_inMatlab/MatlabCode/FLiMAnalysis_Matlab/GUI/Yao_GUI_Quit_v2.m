function Yao_GUI_Quit_v2

global stateYao ghYao
    
delete( ghYao.MainWindow.hdl )


opt1 = 'All Cycles';
opt2 = sprintf('Current Cycle Only ( %d )',stateYao.Disp.numCycle);
opt3 = 'Abort - No Save';

quitOpt = questdlg(...
    'Save Work?',...
    'Quiting...',...
    opt1,opt2,opt3,...
    opt1);



switch quitOpt
    case opt1
        stateYao.processCycles = stateYao.numCycle; % should be a list of current cycles
        
        for iCycle = size(stateYao.processCycles):-1:1
            if stateYao.processCycles(iCycle) == 0
                stateYao.processCycles(iCycle) = [];
            end
        end
        
    case opt2
        stateYao.processCycles = stateYao.Disp.numCycle;
        
    case opt3
        stateYao.processCycles = 0;
        
end








%%
Yao_calc_ProjectionAndLifetimeMap



[pnameOut]=Yao_outputWaves;



%% Sample images for nucleus images
Yao_getSampleImages(pnameOut)