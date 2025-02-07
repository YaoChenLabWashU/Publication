

% Find sample files
mainFolder =...
    'I:\For Paul(Yao_images)';

% subFolder = 'soma1';
subFolder = 'soma2 (nucleus more obvious)';
% subFolder = 'Dendrite';



fileList = dir(sprintf('%s\\%s',mainFolder,subFolder));
fileList = fileList(3:end);



% Load sample files into image stack
for iFile = 1:size(fileList,1)
% for iFile = 1
    load( sprintf('%s\\%s\\%s',...
        mainFolder,...
        subFolder,...
        fileList(iFile).name ) ,'-mat' )
    
    
    
    img = spcSave.projects{1,1};
    
    
    
    if iFile == 1
        % Initialize image stack
        imgStack = zeros( size(img,1),size(img,2),size(fileList,1) );
    end
    imgStack(:,:,iFile) = img;
    
    
    
% % %     figure; imshow( imadjust(uint16(spcSave.projects{1,1})) )
% % %     impixelinfo
    
end
clear img spcSave
clear mainFolder subFolder fileList



%% Overview
% We will have three stages to this code.
%
% In the first stage, we will use Bernardo's suggestion of normxcorr2
%
% In the second stage, we will use normxcorr2 twice such that the offset
% found in the first pass is halved, then a new offset is found.

offset_final = zeros( size(imgStack,3)-1 ,2,2);

imgStack_Disp = zeros( size(imgStack,1),size(imgStack,2),...
    size(imgStack,3)-1,...
    3 );



% Determine which images will match with another
% Simple
%   Image 1 is matched to Image 2, etc
% % % idxMatch = 2:size(imgStack,3);
% Complex - randomly selected image matching
idxMatch = zeros(1,size(imgStack,3)-1);
for i = 1:size(idxMatch,2)
    idx = round( rand(1)*size(imgStack,3) );
    
    if idx > 0 && idx ~= i && ~any(idx == idxMatch)
        idxMatch(i) = idx;
    else
        while idxMatch(i) == 0
            idx = round( rand(1)*size(imgStack,3) );
            
            if idx > 0 && idx ~= i && ~any(idx == idxMatch)
                idxMatch(i) = idx;
            end
        end
    end
    
end



for iImg = 1:size(imgStack,3)-1
    
    idx = idxMatch(iImg);
    
% %     figure; imshow( uint8( imgStack(:,:,idx) ) )
%     imgStack_Disp(:,:,iImg,1) = imgStack(:,:,idx);
    
    
    img1 = imgStack(:,:,iImg);
    img2 = imgStack(:,:,idx);
    
    img1 = img1/2;
    img2 = img2/2;
    
    for i = 1:size(img1,1)
        imgStack_Disp(i,:,iImg,1) = img1(i,:)+img2(i,:);
    end
end



%% First stage - 1 pass of normxcoor2
% Find shift
%   Bernardo's sample code is taken from
%       help normxcorr2
iStage = 1;

offset = zeros( size(imgStack,3)-1 ,2);
for iImg = 1:size(imgStack,3)-1
    idx = idxMatch(iImg);
    
    cc = normxcorr2(imgStack(:,:,iImg),imgStack(:,:,idx));
    [max_cc, imax] = max(abs(cc(:)));
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    corr_offset = [ (ypeak-size( imgStack(:,:,iImg) ,1)) ...
        (xpeak-size( imgStack(:,:,iImg) ,2)) ];
    
    offset(iImg,1) = corr_offset(2);
    offset(iImg,2) = corr_offset(1);
end
clear iImg cc max_cc imax ypeak xpeak corr_offset



% Display shift
for iImg = 1:size(imgStack,3)-1
    idx = idxMatch(iImg);
    
    img1 = imgStack(:,:,iImg); % shift this data
    img2 = imgStack(:,:,idx); % compare to this data
    
    img1 = img1/2;
    img2 = img2/2;
    
    % Shift img1
    img3 = zeros( size(img1,1),size(img1,2) );
    offset_x = round( offset(iImg,1) );
    offset_y = round( offset(iImg,2) );
    
    for x = 1:size(img1,2)
        for y = 1:size(img1,1)
            x2 = x+offset_x;
            y2 = y+offset_y;
            
            if x2 > 0 && x2 < size(img1,2) &&...
                    y2 > 0 && y2 < size(img1,1)
                img3(y2,x2) = img1(y,x);
            end
            
        end
    end
    
    
    
    for i = 1:size(img1,1)
        img4(i,:) = img2(i,:)+img3(i,:);
    end
    
%     figure; imshow( uint8(img4) )
    imgStack_Disp(:,:,iImg,1+iStage) = img4;
    
    
    offset_final(iImg,1,iStage) = offset_x;
    offset_final(iImg,2,iStage) = offset_y;
end



%% Second stage - Two passes of normxcoor2
% What happens when we try to make a small shift and then find a new
% correction?
iStage = 2;

imgStack2 = zeros( size(imgStack,1),size(imgStack,2),size(imgStack,3)-1 );
offset2 = zeros( size(imgStack2,3) ,2);
for iImg = 1:size(imgStack2,3)
    idx = idxMatch(iImg);
    
    img1 = imgStack(:,:,iImg); % shift this data
    img2 = zeros( size(img1,1),size(img1,2) );
    
    offset_x = round( offset(iImg,1) /2 );
    offset_y = round( offset(iImg,2) /2 );
    
    for x = 1:size(img1,2)
        for y = 1:size(img1,1)
            x2 = x+offset_x;
            y2 = y+offset_y;
            
            if x2 > 0 && x2 < size(img1,2) &&...
                    y2 > 0 && y2 < size(img1,1)
                img2(y2,x2) = img1(y,x);
            end
            
        end
    end
    
    imgStack2(:,:,iImg) = img2;
    
    
    
    cc = normxcorr2(imgStack(:,:,idx),imgStack2(:,:,iImg));
    [max_cc, imax] = max(abs(cc(:)));
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    corr_offset = [ (ypeak-size( imgStack(:,:,iImg) ,1)) ...
        (xpeak-size( imgStack(:,:,iImg) ,2)) ];
    
    offset2(iImg,1) = -corr_offset(2);
    offset2(iImg,2) = -corr_offset(1);
end



for iImg = 1:size(imgStack2,3)
    idx = idxMatch(iImg);
    
    img1 = imgStack(:,:,iImg); % shift this data
    img2 = imgStack(:,:,idx);
    
    img1 = img1/2;
    img2 = img2/2;
    
    img3 = zeros( size(img1,1),size(img1,2) );
    offset_x = round( offset(iImg,1)/2 + offset2(iImg,1) );
    offset_y = round( offset(iImg,2)/2 + offset2(iImg,2) );
    
    for x = 1:size(img1,2)
        for y = 1:size(img1,1)
            x2 = x+offset_x;
            y2 = y+offset_y;
            
            if x2 > 0 && x2 < size(img1,2) &&...
                    y2 > 0 && y2 < size(img1,1)
                img3(y2,x2) = img1(y,x);
            end
            
        end
    end
    
    
    
    for i = 1:size(img1,1)
        img4(i,:) = img2(i,:)+img3(i,:);
    end
    
%     figure; imshow( uint8(img4) )
    imgStack_Disp(:,:,iImg,1+iStage) = img4;
    
    
    offset_final(iImg,1,iStage) = offset_x;
    offset_final(iImg,2,iStage) = offset_y;
end



%% Display
figure; 
for i1 = 1:size(imgStack_Disp,3)
    for i2 = 1:size(imgStack_Disp,4)
        
        iPlot = i2 + size(imgStack_Disp,4) * (i1-1);
        
        subplot( size(imgStack_Disp,3),size(imgStack_Disp,4) ,...
            iPlot ), ...
            imshow( uint8(imgStack_Disp(:,:,i1,i2)) )
        
        if i1 == 1
            if i2 == 1
                title('Original')
            elseif i2 == 2
                title('One Pass')
            elseif i2 == 3
                title('Two Passes')
            end
        end
        
    end
end