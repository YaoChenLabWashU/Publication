function [imgFilled] = Yao_generic_fillPts(img_OR_pixelList,opt)
% If providing pixelList, 'opt' should be image size
%   col 1 = y
%   col 2 = x
% If providing image, no 'opt' needed

if size(img_OR_pixelList,1) == 2 ||...
        size(img_OR_pixelList,2) == 2
    % Pixel list
    pixelList = img_OR_pixelList;
    
    
    pixelList(:,1) = max(pixelList(:,1) ,1 );
    pixelList(:,2) = max(pixelList(:,2) ,1 );
    pixelList(:,1) = min(pixelList(:,1) ,opt(1) );
    pixelList(:,2) = min(pixelList(:,2) ,opt(2) );
    
    imgFilled = zeros( opt(1) , opt(2) );
    for iPixel = 1:size( pixelList,1 )
        imgFilled( pixelList(iPixel,1),pixelList(iPixel,2) ) = 1;
    end
    
    clear iPixel
    
else
    imgFilled = img_OR_pixelList;
    
    [pixelList] = Yao_generic_getPerimeter(imgFilled,'PixelList');
    
    pixelList(:,1) = max(pixelList(:,1) ,1 );
    pixelList(:,2) = max(pixelList(:,2) ,1 );
    pixelList(:,1) = min(pixelList(:,1) ,size(imgFilled,1) );
    pixelList(:,2) = min(pixelList(:,2) ,size(imgFilled,2) );
end



size1 = size(imgFilled,1);
size2 = size(imgFilled,2);






% mfilename
% size(pixelList)
idxList = [1:size(pixelList,1)];
if size(pixelList,1) > 100
    idxList = round( linspace(1,size(pixelList,1),30) );
end




% Create lines between perimeter pixels
x = pixelList(idxList,2);
y = pixelList(idxList,1);





% n = size(x,1);
% for k=1:n-1
%     x1 = x(k);
%     y1 = y(k);
%     
%     for k2 = k+1:n;
%         x2 = x(k2);
%         y2 = y(k2);
%         
%         
%         
%         if x1 == x2 || y1 == y2
%             
%         elseif abs(y2-y1) >5 && abs(x2-x1) >5
%             
%             if x1 < x2
%                 x3 = x1+1:x2-1;
%                 y3 = round( interp1([x1 x2],[y1 y2],x3) );
%             else
%                 x3 = x2+1:x1-1;
%                 y3 = round( interp1([x2 x1],[y2 y1],x3) );
%             end
%             
% % % %             x3 = max(x3,1);
% % % %             x3 = min(x3,size( imgFilled ,2));
% % % %             y3 = max(y3,1);
% % % %             y3 = min(y3,size( imgFilled ,1));
%             
% %             idx3 = size( imgFilled ,2)*(x3-1)+y3;
%             idx3 = size( imgFilled ,1)*(x3-1)+y3;
%             
% %             size(idx3)
%             
%             imgFilled(idx3) = 1;
%             
%         end
%         
%     end
% end
n = size(x,1);
for k=1:n-1
    x1 = x(k);
    y1 = y(k);
    
    
    
%     x1 = min(max(x1,1),size2);
%     y1 = min(max(y1,1),size1);
    
    
    
    for k2 = k+1:n;
        x2 = x(k2);
        y2 = y(k2);
        
        
        
%         x2 = min(max(x2,1),size2);
%         y2 = min(max(y2,1),size1);
        
        
        
        if abs(y2-y1) >2 && abs(x2-x1) >2
            
            if abs(x2-x1) > abs(y2-y1)
                if x1 < x2
                    x3 = x1+1:x2-1;
                    y3 = round( interp1([x1 x2],[y1 y2],x3) );
                else
                    x3 = x2+1:x1-1;
                    
                    y3 = round( interp1([x2 x1],[y2 y1],x3) );
                end
            else
                if y1 < y2
                    y3 = y1+1:y2-1;
                    x3 = round( interp1([y1 y2],[x1 x2],y3) );
                else
                    y3 = y2+1:y1-1;
                    x3 = round( interp1([y2 y1],[x2 x1],y3) );
                end
            end
            
            
% % %             x3 = max(x3,1);
% % %             x3 = min(x3,size2);
% % %             y3 = max(y3,1);
% % %             y3 = min(y3,size1);
            
            
%             idx3 = size( I_ROI ,2)*(x3-1)+y3;
            idx3 = size2*(x3-1)+y3;
            imgFilled(idx3) = 1;
            
            
        else
            
            if abs(x1-x2) < abs(y1-y2)
                
                y3 = min([y1 y2]):max([y1 y2]);
                x3 = round(mean([x1 x2]))*ones(1,size(y3,2));
            else
                x3 = min([x1 x2]):max([x1 x2]);
                y3 = round(mean([y1 y2]))*ones(1,size(x3,2));
            end
            
%             idx3 = size( imgFilled ,2)*(x3-1)+y3;
            idx3 = size2*(x3-1)+y3;
            imgFilled(idx3) = 1;
            
        end
        
%         if x1 == x2 || y1 == y2
%             if x1 == x2
%                 y3 = min([y1 y2]):max([y1 y2]);
%                 x3 = x1*ones(1,size(y3,2));
%             else
%                 x3 = min([x1 x2]):max([x1 x2]);
%                 y3 = y1*ones(1,size(x3,2));
%             end
%             
% %             idx3 = size( imgFilled ,2)*(x3-1)+y3;
%             idx3 = size2*(x3-1)+y3;
%             imgFilled(idx3) = 1;
%             
%         elseif abs(y2-y1) >2 && abs(x2-x1) >2
%             
%             if abs(x2-x1) > abs(y2-y1)
%                 if x1 < x2
%                     x3 = x1+1:x2-1;
%                     y3 = round( interp1([x1 x2],[y1 y2],x3) );
%                 else
%                     x3 = x2+1:x1-1;
%                     
%                     y3 = round( interp1([x2 x1],[y2 y1],x3) );
%                 end
%             else
%                 if y1 < y2
%                     y3 = y1+1:y2-1;
%                     x3 = round( interp1([y1 y2],[x1 x2],y3) );
%                 else
%                     y3 = y2+1:y1-1;
%                     x3 = round( interp1([y2 y1],[x2 x1],y3) );
%                 end
%             end
%             
%             
% % % %             x3 = max(x3,1);
% % % %             x3 = min(x3,size2);
% % % %             y3 = max(y3,1);
% % % %             y3 = min(y3,size1);
%             
%             
% %             idx3 = size( I_ROI ,2)*(x3-1)+y3;
%             idx3 = size2*(x3-1)+y3;
%             imgFilled(idx3) = 1;
%             
%         end
        
    end
end

clear pixelList x y
clear k k2
clear n x1 y1 x2 y2 x3 y3 idx3



% Fill in holes
imgFilled = imfill(imgFilled,'holes');

end