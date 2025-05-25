function NewMaskFunctions_storemask

global stateYao

% We now have all the masks for the cells in a given image.
%   Stored as (H x W x nCell)
%   Cell 1 is at (H x W x idxCell_1)
%   Cell 2 is at (H x W x idxCell_2)
%       need to find idxCell_iCell

% idxCell is how the program stores the images; Cell1, Cell 2 are based on
% our assignment to match cells across images.



% Pretend we are using cell ID = 1 which is idxCell = 1
idxCell = 1;
cellId = 1;

% Store mask
stateYao.mask.CellMask.img = stateYao.images.I_cell_stack{...
    stateYao.Disp.numCycle,1}{stateYao.Disp.iImage,1}(:,:,idxCell);
stateYao.mask.CellMask.cellId = cellId;


end

