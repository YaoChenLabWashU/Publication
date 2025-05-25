function [img] = Yao_generic_applyInvertChannel(img,I_cell,chList,invertChannel)

img2 = zeros( size(img,1),size(img,2),size(chList,2) );
maxVal = max(max(max(img)));
for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        
        if I_cell(i1,i2)
            for i3 = 1:size(chList,2)
                
                if any(chList(i3) == invertChannel)
                    img2(i1,i2,i3) =...
                        maxVal - img(i1,i2, chList(i3) );
                else
                    img2(i1,i2,i3) = img(i1,i2, chList(i3) );
                end
                
            end
        end
        
    end
end
clear maxVal

% Erode the inverted channel as the edge will be artificially brightened
se = strel('disk',5);
tempMask = imerode(I_cell,se);

for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        if ~tempMask(i1,i2)
            img2(i1,i2,invertChannel) = 0;
        end
    end
end
img = img2;
clear img2