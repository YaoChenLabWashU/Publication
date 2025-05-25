function Yao_GUI_removeROI_all

global stateYao



% Get current image information
numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



isDendrite = 0;
if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    isDendrite = 1;
end



if isDendrite
    % Should only be 1 ROI
    %   Remove it
    if ~isempty( stateYao.ROI{numCycle}{iImg} )
        stateYao.ROI{numCycle}{iImg} = [];
    end
    if ~isempty( stateYao.images.I_ROI_stack{numCycle}{iImg} )
        stateYao.images.I_ROI_stack{numCycle}{iImg} = zeros(...
            size( stateYao.images.I_ROI_stack{numCycle}{iImg} ,1),...
            size( stateYao.images.I_ROI_stack{numCycle}{iImg} ,2) );
    end
    
%     stateYao.ignoreImage(iImg,iCycle) = 1;
    
%     Yao_GUI_applyROI([],1)
    
else
    
    for iCell = 1:size( stateYao.ellipseParameters{numCycle}{iImg} ,1)
        stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = 0;
        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
            size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,1),...
            size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,2) );
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
            size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,1),...
            size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,2) );
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
            size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,1),...
            size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,2) );
        
        
        
        stateYao.funcLink.findNucleus_func{numCycle}{iImg}{iCell} =...
            deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
        stateYao.colorNucleus{numCycle}{iImg}{iCell} =...
                    stateYao.CycleIdentification{numCycle,2};
        
%         Yao_GUI_applyROI([],iCell)
    end
    
end



% % % stateYao.ignoreImage(iImg, stateYao.numCycle(iCycle) ) = 1;



Yao_GUI_loadImage



end