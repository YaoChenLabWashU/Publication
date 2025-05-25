function Yao_GUI_resetManyImages(numCycle,iImg)

global stateYao


% Load original data here!
global stateYao_tempCopy





% numCycle = stateYao.Disp.numCycle;
% iImg = stateYao.Disp.iImg;


if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    % Dendrite
    stateYao.ROI{numCycle}{iImg} =...
        stateYao_tempCopy.ROI{numCycle}{iImg};
else
    % Nucleus
    stateYao.images.I_cell_stack{numCycle}{iImg} =...
        stateYao_tempCopy.images.I_cell_stack{numCycle}{iImg};
    
    stateYao.images.I_nucleus_stack{numCycle}{iImg} =...
        stateYao_tempCopy.images.I_nucleus_stack{numCycle}{iImg};
    stateYao.ellipseParameters{numCycle}{iImg} =...
        stateYao_tempCopy.ellipseParameters{numCycle}{iImg};
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg} =...
        stateYao_tempCopy.images.I_cytoplasm_stack{numCycle}{iImg};
    stateYao.images.I_buffer_stack{numCycle}{iImg} =...
        stateYao_tempCopy.images.I_buffer_stack{numCycle}{iImg};
    
    stateYao.cellIdx{numCycle}{iImg} =...
        stateYao_tempCopy.cellIdx{numCycle}{iImg};
    
    
    stateYao.applyMask{numCycle}{iImg} = stateYao_tempCopy.applyMask{numCycle}{iImg};
    
    
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg} =...
        stateYao_tempCopy.funcLink.findNucleus_func{numCycle}{iImg};
    stateYao.colorNucleus{numCycle}{iImg} =...
        stateYao_tempCopy.colorNucleus{numCycle}{iImg};
    
end


Yao_GUI_loadImage