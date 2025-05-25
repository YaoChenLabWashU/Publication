function [orientation] = Yao_generic_getOrientation(XY,cond)
% cond can be 'Rad' or 'Deg'
%   Default is degrees

if ~exist('cond','var')
    cond = 'Deg';
end

x0 = mean(XY(:,1));
y0 = mean(XY(:,2));

XY(:,1) = XY(:,1) - x0;
XY(:,2) = XY(:,2) - y0;

clear x0 y0

[theta_orig,rho_orig] = cart2pol( XY(:,1) , XY(:,2) );

rot = 0;
fRot = 1;
dRot = pi/4;

r = [];
r_prev = [];


x = zeros( size(XY,1) ,1);
y = x;
theta = x;

while dRot > pi/1800;
    
    
    
    rot = rot + fRot*dRot;
    
    theta = theta_orig +rot;
    
    [x,y] = pol2cart(theta,rho_orig);
    
    r = std(y);
    
    if isempty(r_prev)
        r_prev = r;
    end
    
    if r > r_prev
        rot = rot - fRot*dRot;
        
        fRot = fRot * -1;
        dRot = dRot/4;
    else
        r_prev = r;
    end
    
end

phi2 = -rad2deg(rot);
if abs(phi2) > 90
    if abs(phi2) < 180
        phi2 = phi2 - (-1)^( phi2 < 0) *180;
    elseif abs(phi2) < 270
        phi2 = phi2 - (-1)^( phi2 < 0) *180;
    elseif abs(phi2) < 360
        phi2 = phi2 - (-1)^( phi2 < 0) *360;
    end
end

clear theta_orig rho_orig
clear rot fRot dRot r r_prev x y theta



if strcmp( lower(cond) ,'rad') ||...
        strcmp( lower(cond) ,'radians')
    phi2 = deg2rad(phi2);
end

orientation = phi2;

end