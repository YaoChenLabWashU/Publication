function [pixelList_OR_image] = Yao_generic_getPerimeter(imgBW,cond)
% cond can be 'Image' or 'PixelList'
%   No input = 'PixelList'
%
% If set to 'PixelList', output is:
%   y = col 1
%   x = col 2

if ~exist('cond','var')
    cond = 'PixelList';
end



imgBW = bwperim(imgBW);



if strcmp( lower(cond) ,'pixellist')
    [pixelList_perim] = Yao_generic_getPixels(imgBW);
    
    pixelList_OR_image = pixelList_perim;
    
else
    pixelList_OR_image = imgBW;
end

end