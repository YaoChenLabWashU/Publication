function [val] = Yao_calc_Photon(projects,mask)

val = sum(sum( projects.*mask ));

end