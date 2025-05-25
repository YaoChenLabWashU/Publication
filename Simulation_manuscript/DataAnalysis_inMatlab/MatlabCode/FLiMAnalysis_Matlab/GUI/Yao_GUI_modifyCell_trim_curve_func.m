function [I_cell] = Yao_GUI_modifyCell_trim_curve_func(I_cell,pts)




% Get perimeter
[pixelList_perim] = Yao_generic_getPerimeter(I_cell,'PixelList');



% % % figure;
% % % temp = zeros( size(I_cell,1),size(I_cell,2) );
% % % for i = 1:size(pixelList_perim,1)
% % %     temp( pixelList_perim(i,1),pixelList_perim(i,2) ) = 1;
% % % end
% % % subplot(1,4,1), imshow( temp )



% Get cell centroid
cc = regionprops(I_cell,'Centroid');
x0 = cc(1).Centroid(1);
y0 = cc(1).Centroid(2);
clear cc



% Trim
x = pts(:,1);
y = pts(:,2);

max_x = 0;
max_y = 0;
for i = 1:size(x,1)-1
    for j = i+1:size(x,1)
        max_x = max([max_x abs(x(i)-x(j))]);
        max_y = max([max_y abs(y(i)-y(j))]);
    end
end


if max_x > max_y
    if size(x,1) == 2
        p = polyfit(x,y,1);
    else
        p = polyfit(x,y,2);
    end
    temp_x = linspace(min(x),max(x), max(x)-min(x) );
    temp_y = polyval(p,temp_x);
    
    [min_val min_idx] = min(x);
    [max_val max_idx] = max(x);
else
    if size(y,1) == 2
        p = polyfit(y,x,1);
    else
        p = polyfit(y,x,2);
    end
    temp_y = linspace(min(y),max(y), max(y)-min(y) );
    temp_x = polyval(p,temp_y);
    
    [min_val min_idx] = min(y);
    [max_val max_idx] = max(y);
end
pts_end = pts([min_idx max_idx],:);
pts = [temp_x' temp_y'];


%   Convert all points to radians
%       Remove perimeter pixels whose angle is between end point angles
%           IF rho_perimeter > rho_pts
pixelList_perim(:,2) = pixelList_perim(:,2)-x0;
pixelList_perim(:,1) = pixelList_perim(:,1)-y0;

pts_end(:,1) = pts_end(:,1)-x0;
pts_end(:,2) = pts_end(:,2)-y0;

pts(:,1) = pts(:,1)-x0;
pts(:,2) = pts(:,2)-y0;



[theta_perim,rho_perim] = cart2pol(...
    pixelList_perim(:,2),...
    pixelList_perim(:,1) );
[theta_pts_end,rho_pts_end] = cart2pol(...
    pts_end(:,1),...
    pts_end(:,2) );
[theta_pts,rho_pts] = cart2pol(...
    pts(:,1),...
    pts(:,2) );



idxList_change = [];
threshold_angleDif = 2*pi() * 5/360;
min_theta_pts_end = min(theta_pts_end);
max_theta_pts_end = max(theta_pts_end);
for iPerim = 1:size(pixelList_perim,1)
    if theta_perim(iPerim) >= min_theta_pts_end &&...
            theta_perim(iPerim) <= max_theta_pts_end
        
        % Find nearest theta
        [min_val min_idx] = min( abs(...
            theta_perim(iPerim)-theta_pts ) );
        
        if min_val < threshold_angleDif
        if rho_perim(iPerim) > rho_pts(min_idx)
            % Delete points
            if isempty(idxList_change)
                idxList_change = [iPerim rho_pts(min_idx)];
            else
                idxList_change = cat(1,idxList_change,...
                    [iPerim rho_pts(min_idx)]);
            end
        end
        end
        
    end
end



if ~isempty(idxList_change)
% Update perimeter
theta_new = theta_perim(idxList_change(:,1));
rho_new = idxList_change(:,2);
[x,y] = pol2cart(theta_new,rho_new);

pixelList_perim( idxList_change(:,1) ,:) = [y x];



pixelList_perim(:,2) = pixelList_perim(:,2)+x0;
pixelList_perim(:,1) = pixelList_perim(:,1)+y0;

pixelList_perim = round(pixelList_perim);



% % % subplot(1,4,2), imshow(I_cell)
% % % temp = zeros( size(I_cell,1),size(I_cell,2) );
% % % for i = 1:size(pixelList_perim,1)
% % %     temp( pixelList_perim(i,1),pixelList_perim(i,2) ) = 1;
% % % end
% % % subplot(1,4,3), imshow( temp )


I_cell2 = Yao_generic_fillPts(pixelList_perim,...
    [size(I_cell,1) size(I_cell,2)]);

for i1 = 1:size(I_cell2,1)
    for i2 = 1:size(I_cell2,2)
        
        if I_cell(i1,i2) == 0
            I_cell2(i1,i2) = 0;
        end
        
    end
%     if any( I_cell2(i1,:) )
%         I_cell(i1,:) = I_cell2(i1,:).*I_cell(i1,:);
%     end
end
I_cell = I_cell2;


% % % subplot(1,4,4), imshow(I_cell)

end