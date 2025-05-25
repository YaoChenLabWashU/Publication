function [I_search] = Yao_generic_bw_joinBlocks(I_search)
% Get perimeter pixels
% Create lines between these pixels and fill in the image
% Fill in any remaining holes

[I_search] = Yao_generic_fillPts(I_search);

end