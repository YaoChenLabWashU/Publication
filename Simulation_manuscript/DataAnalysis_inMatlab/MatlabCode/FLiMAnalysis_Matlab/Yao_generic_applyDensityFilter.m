function [img] = Yao_generic_applyDensityFilter(img)


size1 = size(img,1);
size2 = size(img,2);

temp_img = zeros( size(img,1),size(img,2) );
for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        x = i2;
        y = i1;
        
        rx = max([1 x-2]):min([size(img,2) x+2]);
        ry = max([1 y-2]):min([size(img,1) y+2]);
        
        temp_img(y,x) =...
            sum(sum(sum( img(ry,rx,:) ))) /...
            ( size(rx,2)*size(ry,2)*size(img,3) );
    end
end
img1 = temp_img;



padsize = 9;
img = padarray(img,[padsize padsize]);
temp_img2 = zeros( size(img,1),size(img,2) );
temp_img2(padsize+1:padsize+size1,padsize+1:padsize+size2) = temp_img;
for ir = 1:4
    if ir == 1
        rx = 1:6 +padsize;
        ry = 1:size1;
    elseif ir == 2
        rx = size2-6+1 -padsize:size2;
        ry = 1:size1;
    elseif ir == 3
        rx = 1:size2;
        ry = 1:6 +padsize;
    else
        rx = 1:size2;
        ry = size1-6+1 -padsize:size1;
    end
    
    
    
    for i1 = ry
        for i2 = rx
            x = i2;
            y = i1;
            
            rx2 = max([1 x-2]):min([size(img,2) x+2]);
            ry2 = max([1 y-2]):min([size(img,1) y+2]);
            
            temp_img2(y,x) =...
                sum(sum(sum( img(ry2,rx2,:) ))) /...
                ( size(rx2,2)*size(ry2,2)*size(img,3) );
        end
    end

end
temp_img = wiener2( temp_img2 ,[9,9] );
img2 = temp_img(padsize+1:padsize+size1,padsize+1:padsize+size2);



img = zeros( size1,size2 );
for ir = 1:4
    if ir == 1
        rx = 1:6;
        ry = 1:size1;
    elseif ir == 2
        rx = size2-6+1:size2;
        ry = 1:size1;
    elseif ir == 3
        rx = 1:size2;
        ry = 1:6;
    else
        rx = 1:size2;
        ry = size1-6+1:size1;
    end
    img(rx,ry) = img1(rx,ry);
end

rx = 7:size2-6;
ry = 7:size1-6;
img(ry,rx) = img2(ry,rx);



clear i1 i2
clear x y rx ry temp_img
end