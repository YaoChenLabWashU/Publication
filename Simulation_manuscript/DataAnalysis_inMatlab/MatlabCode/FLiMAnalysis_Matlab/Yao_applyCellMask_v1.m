function Yao_applyCellMask_v1(numCycle,iImg,cellID)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
global stateYao
template_iImg=iImg;

% Find iCell (also referred to as idxcell sometimes).
iCell = stateYao.cellIdx{numCycle}{iImg}(...
        stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID,1);

for iImg=1:size(stateYao.applyMask{numCycle},1)
    stateYao.applyMask{numCycle}{iImg}{iCell}=stateYao.images.mask.I_mask...
        {numCycle}{template_iImg}(:,:,cellID);
end

end

