function [I_search,ellipseParameters] = Yao_generic_convert2Ellipse(I_search)
% Create an ellipse from current data
%   Record angle and centroid
% Find perimeter pixels
% Create new ellipse from perimeter data
%   Adjust angle and centroid


[pixelList] = Yao_generic_getPixels(I_search);



XY = [pixelList(:,2) pixelList(:,1)];
[A] = Yao_generic_fitEllipse(XY);



[x0,y0,semimajor_axis,semiminor_axis,phi] =...
    Yao_generic_convertEllipseEqt_quad2std(A);


ellipse_centroid = [x0 y0];
ellipse_phi = phi;



clear x0 y0 phi



%%%
% Get perimeter points and repeat the ellipse search
[pixelList_perim] = Yao_generic_getPerimeter(I_search,'PixelList');



XY = [pixelList_perim(:,1) pixelList_perim(:,2)];
[A] = Yao_generic_fitEllipse(XY);


[x0,y0,semimajor_axis,semiminor_axis,phi] =...
    Yao_generic_convertEllipseEqt_quad2std(A);

x0 = ellipse_centroid(1);
y0 = ellipse_centroid(2);



phi = ellipse_phi;





XY = [pixelList_perim(:,2) pixelList_perim(:,1)];
[phi2] = Yao_generic_getOrientation(XY,'Deg');



phi = rad2deg(phi);
if phi < 0
    if phi2 > 0
        phi = -phi;
    end
else
    if phi2 < 0
        phi = -phi;
    end
end
phi = deg2rad(phi);

if abs(phi2) > 45
    phi = (90 - abs( rad2deg(phi) )) * (-1)^(phi2 < 0);
    phi = deg2rad(phi);
end





t = linspace(0,2*pi(),200);
X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);

clear t

X = real(X);
Y = real(Y);

%%%
% Apply elipse to blank image, fill in ellipse
YX = zeros( size(X,2) ,2);
YX(:,1) = round( Y );
YX(:,2) = round( X );
[I_search] = Yao_generic_fillPts(YX,[size(I_search,1) size(I_search,2)]);




% Col 1 = Ellipse center, x coordinate
% Col 2 = Ellipse center, y coordinate
% Col 3 = major axis length
% Col 4 = minor axis length
% Col 5 = angle
ellipseParameters = zeros(1,5);
ellipseParameters(1) = x0;
ellipseParameters(2) = y0;
ellipseParameters(3) = semimajor_axis;
ellipseParameters(4) = semiminor_axis;
ellipseParameters(5) = rad2deg( phi );



end