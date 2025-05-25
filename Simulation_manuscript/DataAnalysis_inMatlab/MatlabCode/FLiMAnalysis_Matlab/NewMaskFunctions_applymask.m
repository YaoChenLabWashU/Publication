function NewMaskFunctions_applymask

global stateYao


% Which images?



% Pretend we are on current image
iImg = stateYao.Disp.iImage;
numCycle = stateYao.Disp.numCycle;


%   Get cell Id
cellId = stateYao.mask.CellMask.cellId;

%   Convert cell Id to cell idx
%       Pretend cell idx = 1
idxCell = 1;



% Replace image in I_cell_stack with mask
stateYao.images.I_cell_stack{numCycle,1}{iImg,1}(:,:,idxCell) =...
    stateYao.mask.CellMask.img;


% Re-display GUI window?
% maybe look at "Yao_GUI_loadImage"?