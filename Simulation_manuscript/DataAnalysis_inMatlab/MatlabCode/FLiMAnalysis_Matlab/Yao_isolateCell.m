function [I_cell] = Yao_isolateCell(...
    imgProject,imgRGB,numCycle,iImg,...
    cellPixelCount_threshold,valleyDetection,...
    borderThreshold)

I_cell = [];



warning('off','images:multithresh:noConvergence')
warning('off','images:multithresh:degenerateInput')


dispOpt = [0];
% mfilename



% if iImg == 32
%     dispOpt = 1;
% end




if length( cellPixelCount_threshold )  > 1
    zoomFactor = cellPixelCount_threshold(1);
    thres_b = cellPixelCount_threshold (2);
    thres_m = cellPixelCount_threshold(3);
    cellPixelCount_threshold = thres_m * zoomFactor + thres_b;
end


% Remove any cell which is predominately in the border
d_thresh = borderThreshold;



img = imgRGB;
imgGray = rgb2gray(img);

Ld = [];
if valleyDetection
% if zoomFactor < 5
    % Small cells -> may have cells that are touching
    
    if dispOpt(1) == 1
    figure;
    subplot(4,2,1), imshow( imgProject ,[0 max(max(imgProject))] ), title('Project');
    subplot(4,2,2), imshow( imgGray ,[0 max(max(imgGray))] ), title('LifetimeMap');
    elseif dispOpt(1) == 2
    figure;
    subplot(4,2,1), imshow( imgProject ,[0 max(max(imgProject))] ), title('Project');
    subplot(4,2,2), imshow( imgGray ,[0 max(max(imgGray))] ), title('LifetimeMap');
    end
    
    
    
    img2 = imopen(imgGray, strel('disk',3) );
    img3 = imgProject.*img2;
    
    if dispOpt(1) == 1
    subplot(4,2,3), imshow( img2 ,[0 max(max(img2))] ), title('LifetimeMap Opened');
    subplot(4,2,4), imshow( img3 ,[0 max(max(img3))] ), title('Project x LifetimeMap');
    end
    
    
    
    bw = im2bw(img2, graythresh(img2) );
    bw2 = im2bw(img3, graythresh(img3) );
    bw = bw2.*bw;
    
    bw = bwareaopen(bw,cellPixelCount_threshold);
    bw = imfill(bw,'holes');
    
    bw2 = bwareaopen(bw2,cellPixelCount_threshold);
    bw2 = imfill(bw2,'holes');
    
    
    
    bw_clrBorder  = imclearborder(bw);
    bw2_clrBorder = imclearborder(bw2);
    
    bw_Border  = bw.*~bw_clrBorder;
    bw2_Border = bw2.*~bw2_clrBorder;
    
    cc = bwconncomp(bw_Border);
    cc2 = bwconncomp(bw2_Border);
    
    for iCC = 1:cc.NumObjects
        
        x = ceil( cc.PixelIdxList{1,iCC} / cc.ImageSize(2) );
        y = mod( cc.PixelIdxList{1,iCC} , cc.ImageSize(1) );
        y(y==0) = cc.ImageSize(1);
        
        xc = mean(x);
        yc = mean(y);
        
        if xc <= d_thresh ||...
                xc >= size(bw_Border,1)-d_thresh+1 ||...
                yc <= d_thresh ||...
                yc >= size(bw_Border,2)-d_thresh+1
            % remove
            bw( cc.PixelIdxList{1,iCC} ) = 0;
        end
    end
    for iCC = 1:cc2.NumObjects
        
        x = ceil( cc2.PixelIdxList{1,iCC} / cc2.ImageSize(2) );
        y = mod( cc2.PixelIdxList{1,iCC} , cc2.ImageSize(1) );
        y(y==0) = cc2.ImageSize(1);
        
        xc = mean(x);
        yc = mean(y);
        
        if xc <= d_thresh ||...
                xc >= size(bw2_Border,1)-d_thresh+1 ||...
                yc <= d_thresh ||...
                yc >= size(bw2_Border,2)-d_thresh+1
            % remove
            bw2( cc2.PixelIdxList{1,iCC} ) = 0;
        end
    end
    
    
    
    
%     figure; imshow(bw)
%     figure; imshow(bw2)
    
    cc = bwconncomp(bw);
    cc2 = bwconncomp(bw2);
    if cc.NumObjects < cc2.NumObjects
        
        for iGroup = 1:cc2.NumObjects
            temp = zeros( size(img,1),size(img,2) );
            temp( cc2.PixelIdxList{1,iGroup} ) = 1;
            
            temp = imerode(temp,strel('disk',3));
            temp = bwareaopen(temp,cellPixelCount_threshold);
            
            if sum(sum(temp)) == 0
                bw2( cc2.PixelIdxList{1,iGroup} ) = 0;
            end
        end
        
        
        
        se = strel('disk',2);
        temp_bw = imclose(bw,se);
        temp_bw2 = imclose(bw2,se);
        
        cc = bwconncomp(bw);
        cc2 = bwconncomp(bw2);
        
        if cc.NumObjects < cc2.NumObjects
            bw = bw2;
        end
    else
        bwA = sum(sum(bw));
        bwP = sum(sum( bwperim(bw) ));
        
        bw2A = sum(sum( bw2 ));
        bw2P = sum(sum( bwperim(bw2) ));
        
        SI = 4*pi()*bwA / bwP^2;
        SI2 = 4*pi()*bw2A / bw2P^2;
        
        
        if SI2 > 1.5*SI || bw2A > 1.75*bwA
            bw = bw2;
            bw = imclose(bw,strel('disk',3));
        end
    end



    
% %     ccOrig = bwconncomp(bw);
% %     for iGroup = 1:ccOrig.NumObjects        
% %         idxList = [1:size(ccOrig.PixelIdxList{1,iGroup},1)];
% %         idxList = idxList( img2(ccOrig.PixelIdxList{1,iGroup})~=0 );
% %         minVal_temp = ...
% %             min( img2(ccOrig.PixelIdxList{1,iGroup}(idxList)) );
% %         
% %         if iGroup == 1
% %             minVal = minVal_temp;
% %         else
% %             minVal = min([minVal minVal_temp]);
% %         end
% %     end
% %     bw2 = bwareaopen( img2 >= minVal ,cellPixelCount_threshold);
% %     
% %     
% %     
% %     bw = imclose(bw,strel('disk',1));
%     bw = imfill(bw,'holes');
%     
% %     bw2 = imclose(bw2,strel('disk',1));
% %     bw2 = imfill(bw2,'holes');
% %     
% %     bw = bw+bw2;
    
    
    
    D = -bwdist(~bw);
    
    if dispOpt(1) == 1
    subplot(4,2,5), imshow( bw );
    subplot(4,2,6), imshow(D,[]); impixelinfo;
    end
    
    
    
    
    
    stopLoop = 0;
    iH_end = 2;
    for iH = [0.005 0.01 0.015 0.025 0.075 0.2 0.35 0.5 0.65 0.8 1 1.5 iH_end]
        
        mask = imextendedmin(D,iH); % 1
        ccOrig = bwconncomp(mask);
        for iGroup = 1:ccOrig.NumObjects
            x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
            y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
            y(y==0) = size(img,1);
            
            if mean(x) <= 5 || mean(x) >= size(img,1)-4 ||...
                    mean(y) <= 5 || mean(y) >= size(img,1)-4
                mask( ccOrig.PixelIdxList{1,iGroup} ) = 0;
            end
        end
        if dispOpt(1) == 1
        subplot(4,2,7), imshowpair(bw,mask,'blend');
        end
        
        D2 = imimposemin(D,mask);
        Ld = watershed(D2);
        bw2 = bw;
        bw2(Ld == 0) = 0;
        
        if dispOpt(1) == 1
        subplot(4,2,8), imshow(bw2);
        drawnow
        end
        
        
        
        ccOrig = bwconncomp(bw2);
        nCell = ccOrig.NumObjects;
        
        
        
        nPixel = zeros(nCell,1);
        for iCell = 1:nCell
            nPixel(iCell) = size( ccOrig.PixelIdxList{1,iCell} ,1);
        end
        if all( nPixel > cellPixelCount_threshold )
            stopLoop = 1;
        end
        
        
        if stopLoop
            if dispOpt(1) == 2
            subplot(4,2,5), imshowpair(bw,mask,'blend');
            subplot(4,2,6), imshow(bw2);
            drawnow
            end
            break
        elseif iH == iH_end
            if dispOpt(1) == 2
            subplot(4,2,5), imshowpair(bw,mask,'blend');
            subplot(4,2,6), imshow(bw2);
            drawnow
            end
        else
            if dispOpt(1) == 2
            subplot(4,2,3), imshowpair(bw,mask,'blend');
            subplot(4,2,4), imshow(bw2);
            drawnow
            end
        end
        
    end
    iH1 = iH;
    nPixel1 = nPixel;
    
    
    
    
    
    % Make sure there are no close mins
    %   As determined by 'mask = imextendedmin(D,iH)'
    ccOrig = bwconncomp(mask);
    
    x0 = zeros( ccOrig.NumObjects ,1);
    y0 = x0;
    for iGroup = 1:ccOrig.NumObjects
        
        x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
        y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
        y(y==0) = size(img,1);
        
        if length(x) == 1
            x0(iGroup) = x;
            y0(iGroup) = y;
        else
            x0(iGroup) = mean(x);
            y0(iGroup) = mean(y);
        end
        
    end
    
    d_min =[];
    for i1 = 1:ccOrig.NumObjects-1
        for i2 = i1+1:ccOrig.NumObjects
            
            d = hypot( x0(i1)-x0(i2) , y0(i1)-y0(i2) );
            
            if i1 == 1 && i2 == 2
                d_min = d;
            else
                d_min = min(d,d_min);
            end
            
        end
    end
    
    
    
    while d_min < 10
        iH = iH+0.025;
        
        
        
        mask = imextendedmin(D,iH); % 1
        ccOrig = bwconncomp(mask);
        for iGroup = 1:ccOrig.NumObjects
            x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
            y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
            y(y==0) = size(img,1);
            
            if mean(x) <= 5 || mean(x) >= size(img,1)-4 ||...
                    mean(y) <= 5 || mean(y) >= size(img,1)-4
                mask( ccOrig.PixelIdxList{1,iGroup} ) = 0;
            end
        end
        if dispOpt(1) == 1
            subplot(4,2,7), imshowpair(bw,mask,'blend');
        end
        
        D2 = imimposemin(D,mask);
        Ld = watershed(D2);
        bw2 = bw;
        bw2(Ld == 0) = 0;
        
        if dispOpt(1) == 1
            subplot(4,2,8), imshow(bw2);
            drawnow
        end
        if dispOpt(1) == 2
            subplot(4,2,5), imshowpair(bw,mask,'blend');
            subplot(4,2,6), imshow(bw2);
            drawnow
        end
        
        
        
        ccOrig = bwconncomp(mask);
        
        x0 = zeros( ccOrig.NumObjects ,1);
        y0 = x0;
        for iGroup = 1:ccOrig.NumObjects
            
            x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
            y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
            y(y==0) = size(img,1);
            
            if length(x) == 1
                x0(iGroup) = x;
                y0(iGroup) = y;
            else
                x0(iGroup) = mean(x);
                y0(iGroup) = mean(y);
            end
            
        end
        
        d_min =[];
        for i1 = 1:ccOrig.NumObjects-1
            for i2 = i1+1:ccOrig.NumObjects
                
                d = hypot( x0(i1)-x0(i2) , y0(i1)-y0(i2) );
                
                if i1 == 1 && i2 == 2
                    d_min = d;
                else
                    d_min = min(d,d_min);
                end
                
            end
        end
    end
    
    
    
    
    
    ccOrig = bwconncomp(mask);
    for iGroup = 1:ccOrig.NumObjects
        if size( ccOrig.PixelIdxList{1,iGroup} ,1) > 15
            
            cc2 = bwconncomp(bw2);
            for iGroup2 = 1:cc2.NumObjects
                temp_bw2 = zeros(size(bw2,1),size(bw2,2));
                temp_bw2( cc2.PixelIdxList{1,iGroup2} ) = 1;
                
                if all( temp_bw2(ccOrig.PixelIdxList{1,iGroup}) )
                    
                    bw2( cc2.PixelIdxList{1,iGroup2} ) = 0;
                    temp_bw2 = imclose(temp_bw2,strel('disk',1));
                    
                    bw2 = bw2 + temp_bw2;
                    bw2 = bw2>0;
                    
                    break
                end
                
            end
            
        end
    end
    if dispOpt(1) == 1
        subplot(4,2,8), imshow(bw2);
        drawnow
    end
    if dispOpt(1) == 2
        subplot(4,2,5), imshowpair(bw,mask,'blend');
        subplot(4,2,6), imshow(bw2);
        drawnow
    end
    
    
    
    
%     bwOrig = bw;
%     bw = bw2;
% %     D = -bwdist(~bw2);
% %     mask = imextendedmin(D,iH);
    
    
    
    ccOrig = bwconncomp(bw2);
    nCell = ccOrig.NumObjects;
    
    
    
    nPixel = zeros(nCell,1);
    for iCell = 1:nCell
        nPixel(iCell) = size( ccOrig.PixelIdxList{1,iCell} ,1);
    end
    
    
    
    nPixel_thresh = max( nPixel ) *0.4;
    if ~all( nPixel > nPixel_thresh )
        
        
        mask2 = imextendedmin(D,iH1+2);
        ccOrig = bwconncomp(mask2);
        for iGroup = 1:ccOrig.NumObjects
            x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
            y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
            y(y==0) = size(img,1);
            
            if mean(x) <= 10 || mean(x) >= size(img,1)-9 ||...
                    mean(y) <= 10 || mean(y) >= size(img,1)-9
                mask2( ccOrig.PixelIdxList{1,iGroup} ) = 0;
            end
        end
        
        ccOrig = bwconncomp(mask);
        for iGroup = 1:ccOrig.NumObjects
            if any( ~mask2( ccOrig.PixelIdxList{1,iGroup} ) )
                mask( ccOrig.PixelIdxList{1,iGroup} ) = 0;
            end
            
            
            
            x = ceil( ccOrig.PixelIdxList{1,iGroup} /size(img,2));
            y = mod( ccOrig.PixelIdxList{1,iGroup} ,size(img,1));
            y(y==0) = size(img,1);
            
            if mean(x) <= 10 || mean(x) >= size(img,1)-9 ||...
                    mean(y) <= 10 || mean(y) >= size(img,1)-9
                mask( ccOrig.PixelIdxList{1,iGroup} ) = 0;
            end
        end
        
        
        
        if dispOpt(1) == 1
        subplot(4,2,7), imshowpair(bw,mask,'blend');
        end
        
        D2 = imimposemin(D,mask);
        Ld = watershed(D2);
        bw2 = bw;
        bw2(Ld == 0) = 0;
        
        if dispOpt(1) == 1
        subplot(4,2,8), imshow(bw2);
        drawnow
        end
        
        if dispOpt(1) == 2
        subplot(4,2,7), imshowpair(bw,mask,'blend');
        subplot(4,2,8), imshow(bw2);
        drawnow
        end
        
    end
    
    
    
    
    imgGray = imgGray.*bw2;
    



% % %     imgDisp = imgRGB;
% % %     [pixelList] = Yao_generic_getPerimeter(bw2);
% % %     for iList = 1:size(pixelList,1)
% % %         imgDisp(pixelList(iList,1),pixelList(iList,2),:) = 1;
% % %     end
% % %     figure; imshow(imgDisp);
% % %     
% % %     
% % %     
% % %     ccOrig = bwconncomp(bw2);
% % %     nCell = ccOrig.NumObjects;
% % %     figure;
% % %     for iCell = 1:nCell
% % %         temp = zeros( size(bw2,1),size(bw2,2) );
% % %         temp( ccOrig.PixelIdxList{1,iCell} ) = 1;
% % %         
% % %         temp2 = imgRGB;
% % %         for i3 = 1:size(imgRGB,3)
% % %             temp2(:,:,i3) = imgRGB(:,:,i3).*temp;
% % %         end
% % %         
% % %         subplot(nCell,1,iCell), imshow( temp2 );
% % %     end
% end
end % if stateYao.valleyDetection






img2 = imopen(imgGray, strel('disk',6) );

imgBW = im2bw(img2,graythresh(img2)/4);

if ~isempty(Ld)
    imgBW(Ld == 0) = 0;
end



if dispOpt == 1
figure;
subplot(1,2,1), imshow(imgBW);
end

imgBW = bwareaopen(imgBW,cellPixelCount_threshold);

if dispOpt == 1
subplot(1,2,2), imshow(imgBW);
end


% Get advanced cells
ccOrig = bwconncomp(imgBW);
nCell = ccOrig.NumObjects;
I_cell_stack = zeros( size(img,1),size(img,2), nCell );




% % % h_disp = figure;
% % % subplot(2,2,1), imshow( imgProject ,[0 max(max(imgProject))] ), title('Project')
% % % subplot(2,2,2), imshow(imgRGB), title('LifetimeMap')
% % % imgDisp = imgRGB;
% % % imgDisp2 = imgRGB;



for iCell = 1:nCell
% for iCell = 2
    imgBW_basic = zeros( size(img,1),size(img,2) );
    imgBW_basic( ccOrig.PixelIdxList{1,iCell} ) = 1;
    imgBW_basic = imfill(imgBW_basic,'holes');
    
    
    
    
    if dispOpt == 1
        figure;
        subplot(1,2,1), imshow(imgBW);
    end
    
    
    
    
    for iRun = 1:2
        if iRun == 1
            imgBW_orig = imgBW_basic;
        else
            imgBW_orig = imgBW_adv;
        end
        img_orig = imgProject.*imgBW_orig;
        
        
        
        pixelList = Yao_generic_getPerimeter(imgBW_orig);
        imgBWperim_orig = zeros( size(img,1),size(img,2) );
        for iList = 1:size(pixelList,1)
            imgBWperim_orig( pixelList(iList,1),pixelList(iList,2) ) = 1;
        end
        
        perimSum_orig = size(pixelList,1);
        
        
        
        imgTemp = imerode(img_orig,strel('disk',1));
        
        
        
        for iErode = 1:5
            [thresh,metric] = multithresh(imgTemp,15);
%             [iImg iCell metric]
            
            if metric <= 0
                break
            else
                imgTemp = imgTemp-thresh(1);
                imgTemp = max(imgTemp,0);
            end
        end
        
        I = imgTemp;
        
        
        
        se = strel('disk', 4);        
        Ie = imerode(I, se);
        Iobr = imreconstruct(Ie, I);
        
        Iobrd = imdilate(Iobr, se);
        Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
        Iobrcbr = imcomplement(Iobrcbr);
        
        thresh = multithresh(Iobrcbr,15);
        imgTemp = Iobrcbr - thresh(7);
        imgTemp = max(imgTemp,0);
        
        imgTemp = im2bw( imgTemp , graythresh(imgTemp) );
        
        
        
        if sum(sum(imgTemp)) == 0
            imgTemp = imgBW_basic;
        else
            se = strel('disk',2);
            continueDilate = 1;
            count = 0;
            while continueDilate
                count = count+1;
                imgTemp = imdilate(imgTemp,se);
                
                if sum(sum( imgTemp.*imgBWperim_orig )) > 0.5*perimSum_orig
                    continueDilate = 0;
                elseif count > 20
                    imgTemp = imgBW_basic;
                    break
                end
            end
        end
        imgBW_adv = imgTemp.*imgBW_orig;
        
        
        
        if iRun == 1
            imgBW_run1 = imgBW_adv;
        end
        
    end
    clear imgTemp thresh metric
    clear I Ie Iobr Iobrd Iobrcbr
    clear continueDilate
    
    
    
    pixelList = Yao_generic_getPerimeter(imgBW_basic);
    SI_orig = ( 4*pi() * sum(sum(imgBW_basic)) ) / ( size(pixelList,1) )^2;
    
    pixelList = Yao_generic_getPerimeter(imgBW_adv);
    SI = ( 4*pi() * sum(sum(imgBW_adv)) ) / ( size(pixelList,1) )^2;
    
    if sum(sum(imgBW_adv))/sum(sum(imgBW_basic)) < 0.9 && SI_orig > 0.9
        if sum(sum(imgBW_adv))/sum(sum(imgBW_basic)) < 0.8
            imgBW_adv = imgBW_basic;
            fprintf('%s: switching to basic for iImg %d\n',...
                mfilename,iImg)
        elseif SI < SI_orig + 0.3
            imgBW_adv = imgBW_run1;
            fprintf('%s: reverting to run1 for iImg %d\n',...
                mfilename,iImg)
        end
        
    end
    
    
    
    if sum(sum(imgBW_adv)) < sum(sum(imgBW_basic))
        % Find difference
        imgBW_dif = imgBW_basic.*~imgBW_adv;
        cc = bwconncomp(imgBW_dif);
        
        idxTest = [];
        for iGroup = 1:cc.NumObjects
            if size( cc.PixelIdxList{iGroup} ,1) >...
                    cellPixelCount_threshold/2;
                
                if size( cc.PixelIdxList{iGroup} ,1) >...
                        sum(sum(imgBW_adv))/12
                    % From set 711
                    
                    if isempty(idxTest)
                        idxTest = iGroup;
                    else
                        idxTest = cat(2,idxTest,iGroup);
                    end
                    
                end
                
            end
        end
        
        
        
        if ~isempty(idxTest)
            idxAdd = [];
            
            pixelList = Yao_generic_getPerimeter(imgBW_adv);
            SI_adv = 4*pi()*sum(sum(imgBW_adv)) / ( size(pixelList,1) )^2;
            for iGroup = idxTest
                imgBW = imgBW_adv;
                imgBW( cc.PixelIdxList{iGroup} ) = 1;
                
                pixelList = Yao_generic_getPerimeter(imgBW);
                SI = 4*pi()*sum(sum(imgBW)) / ( size(pixelList,1) )^2;
                
                
                
                % Set 705
                if SI > SI_adv-0.21
                    if isempty(idxAdd)
                        idxAdd = iGroup;
                    else
                        idxAdd = cat(2,idxAdd,iGroup);
                    end
                end
                
            end
            
            
            
            if ~isempty(idxAdd)
                for iGroup = idxAdd
                    imgBW_adv( cc.PixelIdxList{iGroup} ) = 1;
                end
            end
            
        end
        
        
        
    end
    
    
    if dispOpt == 1
        subplot(1,2,2), imshow(imgBW_adv);
    end
    
    
    
    imgBW_adv = imfill(imgBW_adv,'holes');
    I_cell_stack(:,:,iCell) = imgBW_adv;
    
    
    
% % %     pixelList = Yao_generic_getPerimeter(imgBW_basic);
% % %     for iList = 1:size(pixelList,1)
% % %         imgDisp( pixelList(iList,1),pixelList(iList,2) ,:) = 1;
% % %     end
% % %     pixelList = Yao_generic_getPerimeter(imgBW_adv);
% % %     for iList = 1:size(pixelList,1)
% % %         imgDisp2( pixelList(iList,1),pixelList(iList,2) ,:) = 1;
% % %     end
    
end
% % % figure(h_disp)
% % % subplot(2,2,3), imshow(imgDisp), title('Basic Isolation')
% % % subplot(2,2,4), imshow(imgDisp2), title('Adv Isolation')



% % % goodList = size(I_cell_stack,3):-1:1;
% % % for i3 = 1:size(I_cell_stack,3)
% % %     bw = I_cell_stack(:,:,i3);
% % %     
% % %     bw_clrBorder  = imclearborder(bw);
% % %     
% % %     bw_Border  = bw.*~bw_clrBorder;
% % %     
% % %     cc = bwconncomp(bw_Border);
% % %     
% % %     for iCC = 1:cc.NumObjects
% % %         
% % %         x = ceil( cc.PixelIdxList{1,iCC} / cc.ImageSize(2) );
% % %         y = mod( cc.PixelIdxList{1,iCC} , cc.ImageSize(1) );
% % %         y(y==0) = cc.ImageSize(1);
% % %         
% % %         xc = mean(x);
% % %         yc = mean(y);
% % %         
% % %         if xc <= d_thresh ||...
% % %                 xc >= size(bw_Border,1)-d_thresh+1 ||...
% % %                 yc <= d_thresh ||...
% % %                 yc >= size(bw_Border,2)-d_thresh+1
% % %             % remove
% % %             goodList(i3) = [];
% % %         end
% % %     end
% % % end
% % % I_cell_stack = I_cell_stack(:,:,goodList);



I_cell = I_cell_stack;



warning('on','images:multithresh:noConvergence')
warning('on','images:multithresh:degenerateInput')