function [pixelList] = Yao_generic_getPixels(imgBW)
% pixelList is given as:
%   y0 x0
%   y1 x1
%   y2 x2
%   y3 x3

pixelList = [];
r = 1:size(imgBW,2);
for iRow = 1:size(imgBW,1)
    if any( imgBW(iRow,:) == 1 )
        temp = imgBW(iRow,:).*r;
        temp = temp( temp ~= 0 );
        
        temp = cat(2,...
            iRow*ones(size(temp,2),1),...
            temp');
        
        
        if isempty(pixelList)
            pixelList = temp;
        else
            pixelList = cat(1,pixelList,temp);
        end
        
    end
end

clear r iRow temp

end