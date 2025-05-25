function [val] = Yao_calc_Projection(projects,mask)

% size(projects)
% size(mask)
val = sum(sum( projects.*mask ))/sum(sum( mask ));

end