function [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID_v3(I_cell,I_search)
I_nucleus = [];
I_cytoplasm = [];
I_buffer = [];





% Convert I_cell and I_search into perimeters
[pixelList_perim_cell] = Yao_generic_getPerimeter(I_cell);

[pixelList_perim_search] = Yao_generic_getPerimeter(I_search);


x0_search = round( mean(pixelList_perim_search(:,2)) );
y0_search = round( mean(pixelList_perim_search(:,1)) );

if ~I_cell(y0_search,x0_search)    
    x0_cell = round( mean(pixelList_perim_cell(:,2)) );
    y0_cell = round( mean(pixelList_perim_cell(:,1)) );
    
    
    
    pixelList_perim_search(:,1) = pixelList_perim_search(:,1) -...
        (y0_search-y0_cell);
    pixelList_perim_search(:,2) = pixelList_perim_search(:,2) -...
        (x0_search-x0_cell);
    
    
    
    I_search = zeros( size(I_search,1),size(I_search,2) );
    
    pixelList_perim_search = pixelList_perim_search( pixelList_perim_search(:,1) > 0 ,:);
    pixelList_perim_search = pixelList_perim_search( pixelList_perim_search(:,2) > 0 ,:);
    
    pixelList_perim_search = pixelList_perim_search( pixelList_perim_search(:,1) < size(I_search,1) ,:);
    pixelList_perim_search = pixelList_perim_search( pixelList_perim_search(:,2) < size(I_search,2) ,:);
    
    
    pixelIdxList = size(I_search,2)*(pixelList_perim_search(:,2)-1)+...
        pixelList_perim_search(:,1);
    I_search(pixelIdxList) = 1;
    
    [I_search] = Yao_generic_fillPts(I_search);
    
end



% Get distance from each perimeter pixel
dist_Master = zeros( size(pixelList_perim_search,1) ,1);
for i = 1:size(pixelList_perim_search,1)
    
    x = pixelList_perim_search(i,2);
    y = pixelList_perim_search(i,1);
    
    d = hypot(...
        x-pixelList_perim_cell(:,2) ,...
        y-pixelList_perim_cell(:,1) );
    
    dist_Master(i) = min(d);
end


dEdge = min(dist_Master);


clear dist_Master i x y d



dBuffer = max([min([round(dEdge/2) 10]) 1]);



% Make sure I_nucleus isn't too large
I_temp = I_cell.*~I_search;
% [sum(sum(I_temp)) sum(sum(I_cell))]
if sum(sum(I_temp)) < sum(sum(I_cell))/5
    se = strel('disk', dBuffer+2 );
    I_search = imerode(I_search,se);
    I_temp = I_cell.*~I_search;
%     [sum(sum(I_temp)) sum(sum(I_cell))]
    while sum(sum(I_temp)) < sum(sum(I_cell))/5
        se = strel('disk', 2 );
        I_search = imerode(I_search,se);
        I_temp = I_cell.*~I_search;
%         [sum(sum(I_temp)) sum(sum(I_cell))]
    end
end



% Get zones
I_nucleus = I_search;

se = strel('disk', dBuffer );
I_buffer = imdilate(I_search,se);

I_cytoplasm = I_cell;







% for i1 = 1:size(I_cell,1)
%     if any(I_buffer(i1,:))
%         I_buffer(i1,:) = I_buffer(i1,:).*I_cell(i1,:);
%         I_nucleus(i1,:) = I_nucleus(i1,:).*I_cell(i1,:);
%         
%         r2 = I_buffer(i1,:)==1;
%         I_cytoplasm(i1, r2 ) = I_cytoplasm(i1, r2 ).*~I_buffer(i1, r2 );
%         I_buffer(i1,r2) = I_buffer(i1,r2).*~I_nucleus(i1,r2);
%         
%     end
% end


% for i1 = 1:size(I_cell,1)
%     if any( I_buffer(i1,:) )
%         r2 = I_cytoplasm(i1,:)==1;
%         
%         I_cytoplasm(i1, r2 ) = I_cytoplasm(i1, r2 ).*~I_buffer(i1, r2 );
%         I_buffer(i1,:) = I_buffer(i1,:).*I_cell(i1,:);
%     end
%     
%     if any(I_nucleus(i1,:))
%         r2 = I_buffer(i1,:)==1;
%         I_buffer(i1,r2) = I_buffer(i1,r2).*~I_nucleus(i1,r2);
%         I_nucleus(i1,:) = I_nucleus(i1,:).*I_cell(i1,:);
%     end
% end


for i1 = 1:size(I_buffer,1)
    for i2 = 1:size(I_buffer,2)
        
        if I_buffer(i1,i2)
            I_cytoplasm(i1,i2) = 0;
            
            if I_search(i1,i2)
                I_buffer(i1,i2) = 0;
                
                if ~I_cell(i1,i2)
                    I_nucleus(i1,i2) = 0;
                end
            elseif ~I_cell(i1,i2)
                I_buffer(i1,i2) = 0;
            end
            
        end
        
    end
end




% figure;
% subplot(1,4,1), imshow(I_cell);
% subplot(1,4,2), imshow(I_nucleus);
% subplot(1,4,3), imshow(I_buffer);
% subplot(1,4,4), imshow(I_cytoplasm);


end