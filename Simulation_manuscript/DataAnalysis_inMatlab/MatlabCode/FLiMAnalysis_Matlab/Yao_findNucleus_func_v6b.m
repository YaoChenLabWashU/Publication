function [I_nucleus,nucleusCheck1] = Yao_findNucleus_func_v6b(...
    numCycle,iImg,iCell__or__I_Cell,colorNucleus)

I_nucleus = [];
nucleusCheck1 = [];



global stateYao



if length( iCell__or__I_Cell ) == 1
    iCell = iCell__or__I_Cell;
    I_cell = stateYao.I_cell_stack{numCycle}{iImg}(:,:,iCell);
    clear iCell
else
    I_cell = iCell__or__I_Cell;
end

se = strel('disk',3);
I_cell = imerode(I_cell,se);



runSearch = 1;
chList = [1 3];
if strcmp( lower(colorNucleus) ,'blue')
    invertChannel = 1;
elseif strcmp( lower(colorNucleus) ,'red')
    invertChannel = 3;
else
    % Try on both
    runSearch = 0;
    
    
    
    color1 = [];
    color2 = [];
    if isfield(stateYao,'temp')
        if isfield(stateYao.temp,'color1') &&...
                isfield(stateYao.temp,'color2')
            
            color1 = stateYao.temp.color1;
            color2 = stateYao.temp.color2;
            
        end
    end
    if isempty(color1)
        color1 = 'red';
        color2 = 'blue';
        if size( colorNucleus ,2) > 4
            if strcmp( lower(colorNucleus(1,1:4)) ,'blue')
                color1 = 'blue';
                color2 = 'red';
            elseif strcmp( lower(colorNucleus(1,1:3)) ,'red')
                color1 = 'red';
                color2 = 'blue';
            end
        end
    end
    
    
    
    colorNucleus = color1;
    eval(sprintf('[%s] = %s(%s);',...
        'I_nucleus,nucleusCheck1',...
        mfilename,...
        sprintf('%s,%s,%s,%s',...
        'iCycle','iImg','iCell__or__I_Cell','colorNucleus') ))
    
    
    
%     [iCycle iImg nucleusCheck1{1,1} nucleusCheck1{1,2}]
    
    if isempty(nucleusCheck1)
        nucleusCheck1 = cell(1,3);
        nucleusCheck1{1} = 0;
        nucleusCheck1{2} = 0;
    end
    if ~nucleusCheck1{1,1} || nucleusCheck1{1,2} < 2
        colorNucleus = color2;
        eval(sprintf('[%s] = %s(%s);',...
            'I_nucleus,nucleusCheck1',...
            mfilename,...
            sprintf('%s,%s,%s,%s',...
            'iCycle','iImg','iCell__or__I_Cell','colorNucleus') ))
        
%         [iCycle iImg nucleusCheck1{1,1} nucleusCheck1{1,2}]
        
        if isempty(nucleusCheck1)
            nucleusCheck1 = cell(1,3);
            nucleusCheck1{1} = 0;
            nucleusCheck1{2} = 0;
        end
        if nucleusCheck1{1,1}
            if nucleusCheck1{1,2} >= 2
                stateYao.temp.color1 = color2;
                stateYao.temp.color2 = color1;
                
                color1 = stateYao.temp.color1;
                color2 = stateYao.temp.color2;
            end
        end
        
        
    else
        stateYao.temp.color1 = color1;
        stateYao.temp.color2 = color2;
        
    end
    
    
    
%     fprintf('%s: color1 = %s, color2 = %s\n',mfilename,color1,color2)
%     nucleusCheck1{1,2}
    
end



clear iCell__or__I_Cell



if runSearch
dispOpt = [0 0 0];


%%
img = stateYao.images.filterDensity.rgbLifetimes{numCycle}(:,:,:,iImg);
[img] = Yao_generic_applyInvertChannel(img,I_cell,chList,invertChannel);

img(:,:,3) = ( img(:,:,1)+img(:,:,2) )/2;

imgDensity = img;

img = stateYao.images.filterFFT.rgbLifetimes{numCycle}(:,:,:,iImg);
[img] = Yao_generic_applyInvertChannel(img,I_cell,chList,invertChannel);

img(:,:,3) = ( img(:,:,1)+img(:,:,2) )/2;

imgFFT = img;


if dispOpt(1)
figure;
subplot(2,2,1), imshow(imgDensity);
subplot(2,2,2), imshow(imgFFT);
end

% % The following seems to work well with % smaller cells. (cutoff might be
% % around zoom 5)
distrib = 'exponential';
numTiles = [8 8];
nBins = 20;
for i3 = 1:size(imgDensity,3)
    f = @(x) adapthisteq(x,'Distribution',distrib,'NumTiles',numTiles,'NBins',nBins);
    imgDensity(:,:,i3) = roifilt2(imgDensity(:,:,i3), I_cell , f );
end
for i3 = 1:size(imgFFT,3)
    f = @(x) adapthisteq(x,'Distribution',distrib,'NumTiles',numTiles,'NBins',nBins);
    imgFFT(:,:,i3) = roifilt2(imgFFT(:,:,i3), I_cell , f );
end

if dispOpt(1)
subplot(2,2,3), imshow(imgDensity);
subplot(2,2,4), imshow(imgFFT);
end



imgComb = zeros( size(img,1),size(img,2),size(img,3) );
for i3 = 1:size(img,3)
    imgComb(:,:,i3) = imgDensity(:,:,i3).*imgFFT(:,:,i3);
    
    imgComb(:,:,i3) = imgComb(:,:,i3)*...
        max([max(max(imgDensity(:,:,i3))) max(max(imgFFT(:,:,i3)))])/...
        max(max(imgComb(:,:,i3)));
end



if dispOpt(2)
h_img = figure;
subplot(2,3,1), imshow(imgComb)
end



se = strel('disk',6);

imgComb = imsubtract(...
    imadd(imgComb,imtophat(imgComb,se)),...
    imbothat(imgComb,se) );
imgComb = max(imgComb,0);



if dispOpt(2)
figure(h_img)
subplot(2,3,2), imshow(imgComb)
end



bwComb = im2bw(imgComb, graythresh(imgComb));
if sum(sum(bwComb)) ~= 0



bwComb = imdilate(bwComb, strel('disk',3) );



if dispOpt(2)
h_bw = figure;
subplot(2,3,1), imshow(bwComb)
end



% Remove isolated peaks
pixelThreshold = round(...
    (stateYao.cellPixelCount_threshold_m*stateYao.zoomFactor(numCycle)+...
    stateYao.cellPixelCount_threshold_b)/2);

cc = bwconncomp(bwComb);
numPixels_Comb = zeros( size(cc.PixelIdxList,1),1 );
for iGroup = 1:size(cc,1)
    numPixels_Comb(iGroup) = size( cc.PixelIdxList{iGroup} ,1);
end
if max(numPixels_Comb) > 20*pixelThreshold
    pixelThreshold_Comb = pixelThreshold;
else
    pixelThreshold_Comb = max([pixelThreshold ...
        round( max(numPixels_Comb)/5 )]);
end

bwComb = bwareaopen(bwComb,pixelThreshold_Comb);



if dispOpt(2)
figure(h_bw)
subplot(2,3,2), imshow(bwComb)
end



bwComb = bwComb.*I_cell;



[bwComb,bwComb_sub] = bwCleanUp(bwComb);



if dispOpt(2)
figure(h_bw)
subplot(2,3,3), imshow(bwComb)
end



% bwComb = double( bwareaopen(bwComb,pixelThreshold_Comb) );



se = strel('disk',4);
bwComb = imopen(bwComb,se);



for i3 = 1:size(imgComb,3)
    imgComb(:,:,i3) = imgComb(:,:,i3).*bwComb;
end



if dispOpt(2)
figure(h_img)
subplot(2,3,3), imshow(imgComb)
figure(h_bw)
subplot(2,3,4), imshow(bwComb)
end



%%
se = strel('disk', 6);



img = imgComb(:,:,3);

img2 = imopen(img, se);
if sum(sum(sum(img2))) == 0
    img2 = imclose(img,se);
end
img2Comb = img2;



if dispOpt(2)
figure(h_img)
subplot(2,3,4), imshow(imgComb)
end




% tempR1 = [sum(sum(img2Density))/sum(sum(bwDensity)) ...
%     sum(sum(img2FFT))/sum(sum(bwFFT)) ...
%     sum(sum(img2Comb))/sum(sum(bwComb))];


se = strel('disk',1);

img2Comb = imsubtract(...
    imadd(img2Comb,imtophat(img2Comb,se)),...
    imbothat(img2Comb,se) );
img2Comb = max(img2Comb,0);



img2Comb = img2Comb.*bwComb;



if dispOpt(2)
figure(h_img)
subplot(2,3,5), imagesc(img2Comb)
figure(h_bw)
subplot(2,3,5), imshow(bwComb)
end



% tempR2 = [sum(sum(img2Density))/sum(sum(bwDensity)) ...
%     sum(sum(img2FFT))/sum(sum(bwFFT)) ...
%     sum(sum(img2Comb))/sum(sum(bwComb))];





% % [iImg iImg;tempR1;tempR2;tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)]
% nucleusCheck1 = cell(1,3);
% % cell(1,1) holds 1s and 0s to mean check is good or bad
% % cell(1,2) holds qualifier information
% %   0 = bad
% %   1 = uncertain leaning towards bad
% %   2 = uncertain leaning towards good
% %   3 = likely to be good
% % cell(1,3) hold more cells that have supporting data
% %   cell{1,3}{1} is the data for cell{1,1}(1)
% %   cell{1,3}{2} is the data for cell{1,1}(2)
% 
% 
% nucleusCheck1{1,3} = cell(1,1);
% nucleusCheck1{1,3}{1} = [tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)];
% if all([tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)] > 1.75)
%     nucleusCheck1{1,1} = 0; % bad
%     nucleusCheck1{1,2} = 0;
% elseif any([tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)] > 1.75)
%     if any([tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)] < 1.25)
%         nucleusCheck1{1,1} = 1; % should be ok
%         nucleusCheck1{1,2} = 1; % uncertain leaning towards bad
%     else
%         nucleusCheck1{1,1} = 0; % probably bad
%         nucleusCheck1{1,2} = 0;
%     end
% else
%     nucleusCheck1{1,1} = 1; % should be ok
%     if all([tempR2(1)/tempR1(1) tempR2(2)/tempR1(2)] < 1.1)
%         nucleusCheck1{1,2} = 3; % likely to be good
%     else
%         nucleusCheck1{1,2} = 2; % uncertain leaning towards good
%     end
% end
    



bwComb_preEdgeDetect = bwComb;
% img2Comb_preEdgeDetect = img2Comb;
[img2Comb,bwComb] = bwCleanUp_edgeDetection(img2Comb,bwComb);


if sum(sum(bwComb)) == 0
    bwComb = bwComb_preEdgeDetect;
%     img2Comb = img2Comb_preEdgeDetect;
elseif sum(sum(bwComb)) < 0.50 * sum(sum(bwComb_preEdgeDetect))
    bwComb = bwComb_preEdgeDetect;
%     img2Comb = img2Comb_preEdgeDetect;
end





sumOrig = sum(sum(bwComb));
newBW = imclose(bwComb,strel('disk',3));
newBW = imfill(newBW,'holes');
sumNew = sum(sum(newBW));
if sumNew < sumOrig*1.2
    bwComb = newBW;
end







if dispOpt(2)
figure(h_img)
subplot(2,3,6), imagesc(img2Comb)
figure(h_bw)
subplot(2,3,6), imshow(bwComb)
end



se = strel('disk',2);
I_nucleus = imclose(bwComb,se);



if sum(sum(I_nucleus)) == 0
    I_nucleus = bwComb;
end
if sum(sum(I_nucleus)) == 0
    I_nucleus = [];
end



if ~isempty(I_nucleus)

pixelList = Yao_generic_getPixels(I_nucleus);
pixelList_perim = Yao_generic_getPerimeter(I_nucleus);
SI = 4*pi()*size(pixelList,1) / ( size(pixelList_perim,1) )^2;









img = imgFFT(:,:,3);

% % % figure; imagesc(img);impixelinfo


f = @(x) adapthisteq(x,'Distribution','exponential');
img = roifilt2(img, I_cell , f );


% % % figure; imagesc(img);impixelinfo





% img = imgDensity(:,:,3);

pixelIdxList = size(img,2)*(pixelList(:,2)-1)+pixelList(:,1);
tempR1 = [min(img(pixelIdxList)) mean(img(pixelIdxList))];

% dataNucleus = img(pixelIdxList);


pixelList = Yao_generic_getPixels(I_cell);
pixelIdxList = size(img,2)*(pixelList(:,2)-1)+pixelList(:,1);
tempR2 = [min(img(pixelIdxList)) mean(img(pixelIdxList))];

% dataCell = img(pixelIdxList);


% A1






% img = stateYao.images.origData.rgbLifetimes{iCycle}(:,:,:,iImg);
% [pixelList] = Yao_generic_getPerimeter(I_nucleus,'PixelList');
% for iPixel = 1:size(pixelList,1)
%     img(pixelList(iPixel,1),pixelList(iPixel,2),:) = 1;
% end
% 
% figure; imshow(img)
% truesize(gcf,[300 300])









if dispOpt(3)
[iImg SI]
[tempR1;tempR2]
end



nucleusCheck1 = cell(1,3);
% cell(1,1) holds 1s and 0s to mean check is good or bad
% cell(1,2) holds qualifier information
%   0 = bad
%   1 = uncertain leaning towards bad
%   2 = uncertain leaning towards good
%   3 = likely to be good
% cell(1,3) hold more cells that have supporting data
%   cell{1,3}{1} is the data for cell{1,1}(1)
%   cell{1,3}{2} is the data for cell{1,1}(2)


nucleusCheck1{1,3} = cell(1,1);

% nucleusCheck1{1,1} = 1;
% nucleusCheck1{1,2} = 2;
nucleusCheck1{1,3}{1} = [SI tempR1(1) tempR2(1) tempR1(2) tempR2(2)];


nucleusCheck1{1,1} = 0; % bad
nucleusCheck1{1,2} = 0;
if SI > 0.6 && tempR1(2) > 0.4
    
    
    
    if tempR1(2) > tempR2(2)*2
        % From Set 691
        nucleusCheck1{1,1} = 1;
        nucleusCheck1{1,2} = 2;
        
        % From Set 692
        if tempR1(1) > 0.125
            if SI > 0.85
                nucleusCheck1{1,3} = 3;
            end
        end
        
    elseif tempR1(2) > 0.8
        % From Set 700
        nucleusCheck1{1,1} = 1;
        nucleusCheck1{1,1} = 1;
        
        if tempR1(2) > tempR2(2)+0.2;
            nucleusCheck1{1,2} = 2;
            
             % Set 700 || Set 717
            if tempR1(1) > 0.3 || SI > 0.95
                nucleusCheck1{1,2} = 3;
            end
        end
        
    elseif tempR1(2) > tempR2(2) +0.2
        % From Set 696
        nucleusCheck1{1,1} = 1;
        nucleusCheck1{1,2} = 2;
        
        
        
    elseif tempR1(2) > tempR2(2) +0.15
        % From Set 705
        if SI > 0.95
            nucleusCheck1{1,1} = 1;
            nucleusCheck1{1,2} = 2;
        elseif SI > 0.85
            nucleusCheck1{1,1} = 1;
            nucleusCheck1{1,2} = 1;
        end
        
        
        
    elseif tempR1(1) > tempR2(1) *2.5 && tempR1(2) > tempR2(2) + 0.125
        % From Set 711
        if SI > 0.725
        nucleusCheck1{1,1} = 1;
        nucleusCheck1{1,2} = 1;
        end
        
        
        
        
    end
    
    
    
% elseif SI > 1
%     % From Set 705
%     nucleusCheck1{1,1} = 1;
%     nucleusCheck1{1,2} = 2;



    

    
end



if dispOpt(3)
   nucleusCheck1 
end



end % isempty(I_nucleus)
end % initial check on bwComb







end










%%
    function [imgBW,imgBW_sub] = bwCleanUp(imgBW)
    imgBW_sub = [];
    
    nErode = 2;
    tempBW = bwmorph(imgBW, 'erode' ,nErode);
    
    cc_orig = regionprops(imgBW,'PixelIdxList');
    cc_temp = regionprops(tempBW,'PixelIdxList');
    
    if size(cc_orig,1) < size(cc_temp,1)
        % Remove smallest structure
        nPixels_temp = zeros( size(cc_temp,1) ,1);
        for iTemp = 1:size(cc_temp,1)
            nPixels_temp(iTemp) = size( cc_temp(iTemp).PixelIdxList ,1);
        end
        clear iTemp
        nPixels_temp = cat(2,nPixels_temp,[1:size(cc_temp,1)]');
        nPixels_temp = sortrows(nPixels_temp,-1);
        
        
%         idxRemoveBlob = nPixels_temp( size(cc_orig,1)+1:end ,2);
        idxRemoveBlob = [];
        if any( nPixels_temp(2:end,1) < 0.6*nPixels_temp(1,1) )
            idxRemoveBlob = nPixels_temp(...
                nPixels_temp(2:end,1) < 0.6*nPixels_temp(1,1) ,2);
        end
        clear nPixels_temp
        
        
        
        if ~isempty(idxRemoveBlob)
            tempBW = zeros( size(imgBW,1),size(imgBW,2) );
            for iIdx = 1:size(idxRemoveBlob,1)
                tempBW( cc_temp( idxRemoveBlob(iIdx) ).PixelIdxList ) = 1;
            end
            clear iIdx idxRemoveBlob
            tempBW = bwmorph(tempBW, 'dilate' ,nErode+2);
            
            
            
            imgBW = imsubtract( logical(imgBW) ,tempBW);
            imgBW = max(imgBW,0);
            
            imgBW_sub = tempBW;
        end
        
    end
    clear nErode tempBW cc_orig cc_temp
    
    end
%%



    function [img,imgBW] = bwCleanUp_edgeDetection(img,imgBW)

    % The algorithm parameters:
    % 1. Parameters of edge detecting filters:
    %    X-axis direction filter:
    Nx1=10;Sigmax1=1;Nx2=10;Sigmax2=1;Theta1=pi/2;
    %    Y-axis direction filter:
    Ny1=10;Sigmay1=1;Ny2=10;Sigmay2=1;Theta2=0;
    % 2. The thresholding parameter alfa:
    alfa=0.1;
    
    
    
    w = img;
    wBW = imgBW;
% % %     figure
% % %     subplot(2,3,1)
% % %     imshow(w);

    % X-axis direction edge detection
    filterx=d2dgauss(Nx1,Sigmax1,Nx2,Sigmax2,Theta1);
    Ix= conv2(w,filterx,'same');
% % %     subplot(2,3,2), imshow(Ix);
% % %     title('Ix');

    % Y-axis direction edge detection
    filtery=d2dgauss(Ny1,Sigmay1,Ny2,Sigmay2,Theta2);
    Iy=conv2(w,filtery,'same'); 
% % %     subplot(2,3,3), imshow(Iy);
% % %     title('Iy');

    NVI=sqrt(Ix.*Ix+Iy.*Iy);
% % %     subplot(2,3,4);
% % %     imshow(NVI); impixelinfo
% % %     title('Norm of Gradient');

    % Thresholding
    I_max=max(max(NVI));
    I_min=min(min(NVI));
    % level=alfa*(I_max-I_min)+I_min;
    % Ibw=max(NVI,level.*ones(size(NVI)));
    level = max(max(NVI))/3;
    Ibw = NVI;
    for i1 = 1:size(NVI,1)
        for i2 = 1:size(NVI,2)
            if NVI(i1,i2) < level
                Ibw(i1,i2) = 0;
            end
        end
    end
% % %     subplot(2,3,5);
% % %     imshow(Ibw); impixelinfo
% % %     title('After Thresholding');



    % Thinning (Using interpolation to find the pixels where the norms of 
    % gradient are local maximum.)
    [n,m]=size(Ibw);
    I_temp = zeros(n,m);
    for i=2:n-1,
    for j=2:m-1,
        if Ibw(i,j) > level,
        X=[-1,0,+1;-1,0,+1;-1,0,+1];
        Y=[-1,-1,-1;0,0,0;+1,+1,+1];
        Z=[Ibw(i-1,j-1),Ibw(i-1,j),Ibw(i-1,j+1);
           Ibw(i,j-1),Ibw(i,j),Ibw(i,j+1);
           Ibw(i+1,j-1),Ibw(i+1,j),Ibw(i+1,j+1)];
        XI=[Ix(i,j)/NVI(i,j), -Ix(i,j)/NVI(i,j)];
        YI=[Iy(i,j)/NVI(i,j), -Iy(i,j)/NVI(i,j)];
        ZI=interp2(X,Y,Z,XI,YI);
            if Ibw(i,j) >= ZI(1) & Ibw(i,j) >= ZI(2)
            I_temp(i,j)=I_max;
            else
            I_temp(i,j)=I_min;
            end
        else
        I_temp(i,j)=I_min;
        end
    end
    end
% % %     subplot(2,3,6);
% % %     imshow(I_temp);
% % %     title('After Thinning');
% % %     colormap(gray);
    
    
    
    

    I_temp = im2bw(I_temp,I_min);
    I_temp = bwareaopen(I_temp,5);

% % %     figure; imshow(I_temp);
    
    
    
    I_temp = imclose(I_temp, strel('disk',3) );
    
% % %     figure; imshow(I_temp);
    
    

    % figure;
    % subplot(2,2,1), imshow(I_temp);
    % 
    % I_temp2 = imfill(I_temp,'holes');
    % cc = regionprops(I_temp2,'Centroid');
    % x0 = round( cc(1).Centroid(1) );
    % y0 = round( cc(1).Centroid(2) );
    % 
    % I_temp2 = ~I_temp;
    % I_temp2 = I_temp2.*wBW;
    % 
    % subplot(2,2,2), imshow(I_temp2);
    % 
    % % idxDel = [];
    % % cc = regionprops(I_temp2,'PixelList');
    % % for iGroup = 1:size(cc,1)
    % %     PixelList = cc(iGroup).PixelList;
    % %     for iList = 1:size(PixelList,1)
    % %         if PixelList(iList,1) == x0 && PixelList(iList,2) == y0
    % %             idxDel = iGroup;
    % %             break
    % %         end
    % %     end
    % %     if ~isempty(idxDel)
    % %         
    % %         for iList = 1:size(PixelList,1)
    % %             I_temp2( PixelList(iList,2),PixelList(iList,1) ) = 0;
    % %         end
    % %         
    % %         break
    % %     end
    % % end
    % % 
    % % subplot(2,2,3), imshow(I_temp2);
    % % 
    % % for i1 = 1:size(I_temp,1)
    % %     for i2 = 1:size(I_temp,2)
    % %         if I_temp2(i1,i2) && ~I_temp(i1,i2)
    % %             I_temp(i1,i2) = 1;
    % %         end
    % %     end
    % % end
    % % 
    % % 
    % % subplot(2,2,4), imshow(I_temp);
    
    
    
    I_temp = imerode(I_temp,strel('disk',1));
%     figure; imshow(I_temp)

    wBW = wBW.*~I_temp;
    wBW = imopen(wBW, strel('disk',2) );


    
%     figure; imshow(wBW)
    
    cc_wBW = bwconncomp(wBW);
    if cc_wBW.NumObjects > 1
        nPixel_wBW = zeros( cc_wBW.NumObjects ,1);
        for i_wBW = 1:cc_wBW.NumObjects
            nPixel_wBW(i_wBW) = size(cc_wBW.PixelIdxList{1,i_wBW},1);
        end
        [max_val max_idx] = max(nPixel_wBW);
        wBW = zeros( size(wBW,1),size(wBW,2) );
        wBW( cc_wBW.PixelIdxList{1,max_idx} ) = 1;
    end
    
%     cc_wBW = regionprops(wBW,'PixelIdxList');
%     if size(cc_wBW,1) > 1
%         nPixel_wBW = zeros( size(cc_wBW,1) ,1);
%         for i_wBW = 1:size(cc_wBW,1)
%             nPixel_wBW(i_wBW) = size(cc_wBW(i_wBW).PixelIdxList,1);
%         end
%         [max_val max_idx] = max(nPixel_wBW);
%         wBW = zeros( size(wBW,1),size(wBW,2) );
%         wBW( cc_wBW(max_idx).PixelIdxList ) = 1;
%     end
    
    
    
    w = w.*wBW;

    % figure; imshow(w);
    
    
    
    img = w;
    imgBW = wBW;
    
    
    
    
    
        % Function "d2dgauss.m":
        % This function returns a 2D edge detector (first order derivative
        % of 2D Gaussian function) with size n1*n2; theta is the angle that
        % the detector rotated counter clockwise; and sigma1 and sigma2 are the
        % standard deviation of the gaussian functions.
        function h = d2dgauss(n1,sigma1,n2,sigma2,theta)
        r=[cos(theta) -sin(theta);
           sin(theta)  cos(theta)];
        for i = 1 : n2 
            for j = 1 : n1
                u = r * [j-(n1+1)/2 i-(n2+1)/2]';
                h(i,j) = gauss(u(1),sigma1)*dgauss(u(2),sigma2);
            end
        end
        h = h / sqrt(sum(sum(abs(h).*abs(h))));
        end

        % Function "gauss.m":
        function y = gauss(x,std)
        y = exp(-x^2/(2*std^2)) / (std*sqrt(2*pi));
        end

        % Function "dgauss.m"(first order derivative of gauss function):
        function y = dgauss(x,std)
        y = -x * gauss(x,std) / std^2;
        end

    end
    

%%











% % % % figure;
% % % % subplot(1,2,1), imshow(img);
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % img = img(:,:,3);
% % % 
% % % 
% % % 
% % % % % % figure;
% % % % % % subplot(1,3,1), imshow(img);
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % %Blur Kernel
% % % ksize = 10;
% % % padsize = ksize;
% % % kernel = zeros(ksize);
% % % 
% % % %Gaussian Blur
% % % s = 3;
% % % m = ksize/2;
% % % [X, Y] = meshgrid(1:ksize);
% % % kernel = (1/(2*pi*s^2))*exp(-((X-m).^2 + (Y-m).^2)/(2*s^2));
% % % 
% % % %Pad image
% % % % origimagepad = padimage(img, padsize);
% % % origimagepad = padarray(img,[padsize padsize]);
% % % 
% % % %Embed kernel in image that is size of original image + padding
% % % [h, w] = size(img);
% % % [h1, w1] = size(origimagepad);
% % % kernelimagepad = zeros(h1,w1);
% % % 
% % % kernelimagepad(1:ksize, 1:ksize) = kernel;
% % % 
% % % %Perform 2D FFTs
% % % fftimagepad = fft2(origimagepad);
% % % fftkernelpad = fft2(kernelimagepad);
% % % 
% % % fftkernelpad(find(fftkernelpad == 0)) = 1e-6;
% % % 
% % % %Multiply FFTs
% % % fftblurimagepad = fftimagepad.*fftkernelpad;
% % % 
% % % %Perform Reverse 2D FFT
% % % blurimagepad = ifft2(fftblurimagepad);
% % % 
% % % %Remove Padding
% % % blurimageunpad = blurimagepad(round(padsize*1.5)+1:round(padsize*1.5)+h,round(padsize*1.5)+1:round(padsize*1.5)+w);
% % % 
% % % %Display Blurred Image
% % % % % % subplot(1,3,2), imagesc(blurimageunpad); impixelinfo
% % % % % % % figure, imagesc(blurimageunpad)
% % % % % % axis square
% % % % % % title('Blurred Image - with Padding')
% % % % % % colormap gray
% % % % % % set(gca, 'XTick', [], 'YTick', [])
% % % 
% % % 
% % % 
% % % 
% % % temp = img.*blurimageunpad;
% % % % % % subplot(1,3,3), imshow(temp)
% % % 
% % % 
% % % [img] = Yao_generic_applyDensityFilter(temp);
% % % 
% % % temp = img;
% % % 
% % % 
% % % 
% % % % figure;
% % % % temp = img;
% % % % % temp(:,:,3) = temp(:,:,2);
% % % % % temp(:,:,2) = img(:,:,3);
% % % % subplot(1,3,1), imshow(temp);
% % % 
% % % 
% % % se = strel('disk', 6);
% % % img2 = imopen(img, se);
% % % if sum(sum(sum(img2))) == 0
% % %     img2 = imclose(img,se);
% % % end
% % % 
% % % 
% % % % subplot(1,3,2), imshow(img2); impixelinfo
% % % 
% % % level = graythresh( img2 );
% % % img3 = im2bw(img2,level*1.5);
% % % 
% % % img3 = imdilate(img3, strel('disk',2));
% % % I_nucleus = imerode(img3, strel('disk',3));
% % % 
% % % 
% % % % subplot(1,2,2), imshow(I_nucleus);
% % % 
% % % 
% % % nucleusCheck1 = [0 max(max(img2))];
% % % if max(max(img2)) > 0.15
% % %     nucleusCheck1(1) = 1;
% % % end
% % % 
% % % 
% % % 
% % % 
% % % % figure; imshow(img2.*I_nucleus)









% % % % nCluster = 6;
% % % nCluster = round( sqrt( sum(sum(I_nucleus))/2 ) );
% % % 
% % % 
% % % % % % pixelList = Yao_generic_getPixels(I_nucleus);
% % % % % % X = [pixelList(:,1) pixelList(:,2)];
% % % % % % 
% % % % % % options = statset('Display','final');
% % % % % % gm = gmdistribution.fit(X,nCluster,'Options',options);
% % % % % % 
% % % % % % figure; plot( X(:,1),X(:,2), 'k.');
% % % % % % hold on
% % % % % % ezcontour(@(x,y)pdf(gm,[x y]),[1 size(I_nucleus,2)],[1 size(I_nucleus,1)]);
% % % % % % hold off
% % % 
% % % 
% % % 
% % % 
% % % 
% % % nBin = 6;
% % % % temp = img2(:,:,3); % Third column should be average of 1 and 2
% % % temp = img2.*I_nucleus;
% % % 
% % % pixelList = Yao_generic_getPixels(I_nucleus);
% % % pixelIdx = size(temp,1)*(pixelList(:,2)-1)+pixelList(:,1);
% % % 
% % % 
% % % 
% % % minval = min(temp(pixelIdx));
% % % maxval = max(temp(pixelIdx));
% % % difval = maxval-minval;
% % % 
% % % for iBin = 1:nBin
% % %     bound_lower = minval+difval*(iBin-1)/nBin;
% % %     bound_upper = minval+difval*iBin/nBin;
% % %     
% % %     
% % %     I_temp = (temp>bound_lower).*(temp<=bound_upper);
% % %     
% % %     
% % %     if sum(sum(I_temp)) > 0
% % %     
% % %     pixelList2 = Yao_generic_getPixels(I_temp);
% % %     
% % %     if iBin > 1
% % %     for iRep = 2:iBin
% % %         pixelList = cat(1,pixelList,pixelList2);
% % %     end
% % %     end
% % %     
% % %     end
% % %     
% % % end
% % % X = [pixelList(:,1) pixelList(:,2)];
% % % 
% % % options = statset('Display','final');
% % % 
% % % global gm
% % % gm = gmdistribution.fit(X,nCluster,'Options',options);
% % % 
% % % figure; 
% % % subplot(1,2,1), imshow(img2);
% % % subplot(1,2,2),
% % % plot( X(:,1),X(:,2), 'k.');
% % % hold on
% % % ezcontour(@(x,y)pdf(gm,[x y]),[1 size(I_nucleus,2)],[1 size(I_nucleus,1)]);
% % % hold off
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % d = zeros(nCluster,nCluster);
% % % for i1 = 1:nCluster-1
% % %     
% % %     x0 = gm.mu(i1,1);
% % %     y0 = gm.mu(i1,2);
% % %     
% % %     for i2 = i1+1:nCluster
% % %         
% % %         x1 = gm.mu(i2,1);
% % %         y1 = gm.mu(i2,2);
% % %         
% % %         d(i1,i2) = hypot(x1-x0,y1-y0);
% % %         d(i2,i1) = d(i1,i2);
% % %         
% % %     end
% % % end
% % % 
% % % d
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % % 
% % % % cc = regionprops(I_nucleus,'MajorAxisLength');
% % % % 
% % % % max(max(d))/cc.MajorAxisLength
% % % 
% % % 
% % % 
% % % 
% % % % cc = regionprops(I_nucleus,'Centroid');
% % % % d = zeros(nCluster,1);
% % % % for i1 = 1:nCluster
% % % %     
% % % %     x0 = gm.mu(i1,1);
% % % %     y0 = gm.mu(i1,2);
% % % %     
% % % %     x1 = cc.Centroid(1);
% % % %     y1 = cc.Centroid(2);
% % % %     
% % % %     d(i1) = hypot(x0-x1,y0-y1);
% % % % end
% % % % 
% % % % d
% % % 
% % % 
% % % 
% % % 


end