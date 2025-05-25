function [I_ROI] = Yao_generic_convertROI2I_ROI(ROI,size1,size2)

ROI = round(ROI); % rounding the numbers

I_ROI = zeros( size1,size2 ); % create a mask matrix with the right dimension.
% for i = 1:size(ROI,1)
%     
%     x = ROI(i,1);
%     y = ROI(i,2);
%     
%     x = max(1,x);
%     x = min(size2,x);
%     y = max(1,y);
%     y = min(size1,y);
%     
%     I_ROI(y,x) = 1;
% end



% mfilename
% size(ROI)

idxList = [1:size(ROI,1)]; %index of all the coordinates
if size(ROI,1) > 100
    idxList = round( linspace(1,size(ROI,1),30) );
end %if too many indices, take every 30th of them.


x = min(max(ROI(idxList,1),1),size2);% Get the x coordinates
y = min(max(ROI(idxList,2),1),size1);% Get the y coordinates

[I_ROI] = poly2mask(x,y, size1, size2); %Yao added on 11/15/2022

% Yao commented out the following on 11/15/2022



% n = size(x,1);% How many coordinates are there.
% for k=1:n-1 %Cycle through each coodinate
%     x1 = x(k);
%     y1 = y(k);
%     
%     
%     
% %     x1 = min(max(x1,1),size2);
% %     y1 = min(max(y1,1),size1);
%     
%     
%     
%     for k2 = k+1:n;
%         x2 = x(k2);
%         y2 = y(k2);
%         
%         
%         
% %         x2 = min(max(x2,1),size2);
% %         y2 = min(max(y2,1),size1);
%         
%         
%         
%         if x1 == x2 || y1 == y2
%             if x1 == x2
%                 y3 = min([y1 y2]):max([y1 y2]);
%                 x3 = x1*ones(1,size(y3,2));
%             else
%                 x3 = min([x1 x2]):max([x1 x2]);
%                 y3 = y1*ones(1,size(x3,2));
%             end
%             
%             idx3 = size( I_ROI ,2)*(x3-1)+y3;
%             I_ROI(idx3) = 1;
%             
%         elseif abs(y2-y1) >4 && abs(x2-x1) >4
%             
%             if abs(x2-x1) > abs(y2-y1)
%                 if x1 < x2
%                     x3 = x1+1:x2-1;
%                     y3 = round( linterp([x1 x2],[y1 y2],x3) );
%                 else
%                     x3 = x2+1:x1-1;
%                     
%                     y3 = round( linterp([x2 x1],[y2 y1],x3) );
%                 end
%             else
%                 if y1 < y2
%                     y3 = y1+1:y2-1;
%                     x3 = round( linterp([y1 y2],[x1 x2],y3) );
%                 else
%                     y3 = y2+1:y1-1;
%                     x3 = round( linterp([y2 y1],[x2 x1],y3) );
%                 end
%             end
%             
%             
% %             x3 = max(x3,1);
% %             x3 = min(x3,size2);
% %             y3 = max(y3,1);
% %             y3 = min(y3,size1);
%             
%             
%             idx3 = size( I_ROI ,2)*(x3-1)+y3;
% %             idx3 = size( I_ROI ,1)*(x3-1)+y3;
%             I_ROI(idx3) = 1;
%             
%         end
%         
%     end
% end
% 
% 
% 
% [I_ROI] = Yao_generic_bw_joinBlocks(I_ROI);




end