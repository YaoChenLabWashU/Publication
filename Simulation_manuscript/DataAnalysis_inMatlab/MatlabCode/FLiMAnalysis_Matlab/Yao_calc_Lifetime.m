function [val] = Yao_calc_Lifetime(projects,lifetimeMaps,mask)

nTimesTau = mask .*projects .*lifetimeMaps;

val =...
    sum(nTimesTau(:))/...
    sum( projects(:).*mask(:) );

end