function Yao_findDendriteShift_v7(numCycle,iImg)



global stateYao



applyRotation = stateYao.dendriteOpt.rotation(numCycle);



% Get image data
img_projects =...
    stateYao.images.origData.projects{numCycle}(:,:,iImg);
img_rgbLifetimes =...
    stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg);




% Get projection value
% val = Yao_calc_Photon(...
%     img_projects,...
%     im2bw( img_rgbLifetimes ,graythresh(img_rgbLifetimes) ) );
val = Yao_calc_Photon(...
    img_projects,...
    ones( size(img_projects,1),size(img_projects,2) ) );

% if numCycle==2 && iImg==19
%     val
% end


if val < stateYao.valPhoton_threshold    % check photon count for the whole image.
    fprintf('%s: Not enough data available to seek dendrite position\n',...
        mfilename)
    fprintf('\tImage %d, part of Cycle %d\n',...
        stateYao.CyclePositions(iImg,numCycle),...
        numCycle )
    stateYao.ignoreImage(iImg,numCycle) = 1;
else



iCell = 1;
% Find shift using the entire field-of-view
% % % img_new = img_projects;
% % % img_mask = stateYao.mask.projects{iCycle}{iCell};





img_new = img_rgbLifetimes;
[img_new] = Yao_generic_applyDensityFilter(img_new);

se = strel('disk',3);
img_new = imsubtract(...
    imadd(img_new,imtophat(img_new,se)),...
    imbothat(img_new,se) );
img_new = max(img_new,0);

img2 = imopen(img_new, se);
if sum(sum(sum(img2))) == 0
    img2 = imclose(img_new,se);
end
img_new = img2;

se = strel('disk',1);
img_new = imsubtract(...
    imadd(img_new,imtophat(img_new,se)),...
    imbothat(img_new,se) );
img_new = max(img_new,0);

I_new = im2bw(img_new, graythresh(img_new)*1.5 );



% img_new = img_new.*I_new;
% 
% [img_new,temp] = bwCleanUp_edgeDetection(img_new,I_new);
% 
% % figure; imshow(img_new)




img_mask = stateYao.images.mask.rgbLifetime{numCycle}{iCell};
[img_mask] = Yao_generic_applyDensityFilter(img_mask);

se = strel('disk',3);
img_mask = imsubtract(...
    imadd(img_mask,imtophat(img_mask,se)),...
    imbothat(img_mask,se) );
img_mask = max(img_mask,0);

img2 = imopen(img_mask, se);
if sum(sum(sum(img2))) == 0
    img2 = imclose(img_mask,se);
end
img_mask = img2;

se = strel('disk',1);
img_mask = imsubtract(...
    imadd(img_mask,imtophat(img_mask,se)),...
    imbothat(img_mask,se) );
img_mask = max(img_mask,0);

I_mask = im2bw(img_mask, graythresh(img_mask)*1.5 );






img_new = img_projects;
img_mask = stateYao.images.mask.projects{numCycle}{iCell};

% I_new = im2bw(img_new, graythresh(img_new) );
% I_mask = im2bw(img_mask, graythresh(img_mask) );


if applyRotation
pixelList = Yao_generic_getPixels(I_new);
orien_new = Yao_generic_getOrientation(...
    [pixelList(:,2) pixelList(:,1)],'Deg');
pixelList = Yao_generic_getPixels(I_mask);
orien_mask = Yao_generic_getOrientation(...
    [pixelList(:,2) pixelList(:,1)],'Deg');

d_orien = orien_new - orien_mask;
end



cc = normxcorr2(...
    img_new,...
    img_mask );

[max_cc, imax] = max(abs(cc(:)));
[ypeak, xpeak] = ind2sub(size(cc),imax(1));
corr_offset = [ (ypeak-size( img_new ,1)) ...
    (xpeak-size( img_new ,2)) ];

stateYao.offset{numCycle}{iImg} =...
    [corr_offset(2) corr_offset(1)];
clear cc max_cc imax ypeak xpeak corr_offset


if isempty( stateYao.images.I_ROI_stack{numCycle}{iImg} )
    stateYao.cellIdx{numCycle}{iImg} = [];
end
% Apply the same shift and rotation to each ROI
for iCell=1:length(stateYao.mask.ROI{numCycle})
    ROI = stateYao.mask.ROI{numCycle}{iCell};
    ROI(:,1) = ROI(:,1) - stateYao.offset{numCycle}{iImg}(1);
    ROI(:,2) = ROI(:,2) - stateYao.offset{numCycle}{iImg}(2);


    if applyRotation
    x0 = mean(ROI(:,1));
    y0 = mean(ROI(:,2));
    X = ROI(:,1)-x0;
    Y = ROI(:,2)-y0;

    [theta,rho] = cart2pol(X,Y);
    theta = theta + deg2rad( d_orien );
    [X,Y] = pol2cart(theta,rho);

    ROI = [X+x0 Y+y0];
    end



    stateYao.ROI{numCycle}{iImg}{iCell} = ROI;


    [stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell)] =...
        Yao_generic_convertROI2I_ROI(...
        ROI,...
        size(img_projects,1),...
        size(img_projects,2) );
    
    % to-do: allow different cell IDs for different ROIs in dendritic mode?
    % to-do: do we need to store information for dendritic ROIs? 
    stateYao.cellIdx{numCycle}{iImg} = cat(1, stateYao.cellIdx{numCycle}{iImg}, ...
        [iCell, iCell, 0, 0, 0, 0]);
end
clear ROI



% % % % Apply changes
% % % global gui
% % % 
% % % spc_openFiles( stateYao.CyclePositions(iImg,numCycle) ,[])
% % % 
% % % gui.gy.roiPositions{ 1 } =...
% % %     stateYao.ROI{numCycle}{iImg}{iCell};
% % % for roi = 1
% % %     for type=1:2
% % %         setPosition(gui.gy.rois{1,roi}.obj{1,type}, gui.gy.roiPositions{1,roi} )
% % %         spc_conformROIpositions;
% % %     end
% % % end
% % % clear roi type
% % % 
% % % drawnow



% Verify calc
% [val] = Yao_calc_Photon(...
%     img_projects,...
%     stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell) );

% if numCycle==2 && iImg==19
%     val
% end

% if val < stateYao.valPhoton_threshold
%     fprintf('%s: Not enough data available to seek dendrite position\n',...
%         mfilename)
%     fprintf('\tImage %d, part of cycle %d\n',...
%         stateYao.CyclePositions(iImg,numCycle),...
%         numCycle )
%     stateYao.ignoreImage(iImg,numCycle) = 1;
% end



end





%     function [img,imgBW] = bwCleanUp_edgeDetection(img,imgBW)
% 
%     % The algorithm parameters:
%     % 1. Parameters of edge detecting filters:
%     %    X-axis direction filter:
% %     Nx1=10;Sigmax1=1;Nx2=10;Sigmax2=1;Theta1=pi/2;
%     Nx1=8;Sigmax1=1.5;Nx2=8;Sigmax2=1.5;Theta1=pi/2;
%     %    Y-axis direction filter:
% %     Ny1=10;Sigmay1=1;Ny2=10;Sigmay2=1;Theta2=0;
%     Ny1=8;Sigmay1=1.5;Ny2=8;Sigmay2=1.5;Theta2=0;
%     % 2. The thresholding parameter alfa:
%     alfa=0.1;
%     
%     
%     
% %     se = strel('disk',6);
% %     img = imsubtract(...
% %         img,...
% %         imbothat(img,se) );
% %     img = max(img,0);
%     
%     
%     
%     w = img;
%     wBW = imgBW;
%     figure
%     subplot(2,3,1)
%     imshow(w);
% 
%     % X-axis direction edge detection
%     filterx=d2dgauss(Nx1,Sigmax1,Nx2,Sigmax2,Theta1);
%     Ix= conv2(w,filterx,'same');
%     subplot(2,3,2), imshow(Ix);
%     title('Ix');
% 
%     % Y-axis direction edge detection
%     filtery=d2dgauss(Ny1,Sigmay1,Ny2,Sigmay2,Theta2);
%     Iy=conv2(w,filtery,'same'); 
%     subplot(2,3,3), imshow(Iy);
%     title('Iy');
% 
%     NVI=sqrt(Ix.*Ix+Iy.*Iy);
%     subplot(2,3,4);
%     imshow(NVI); impixelinfo
%     title('Norm of Gradient');
% 
%     % Thresholding
%     I_max=max(max(NVI));
%     I_min=min(min(NVI));
%     % level=alfa*(I_max-I_min)+I_min;
%     % Ibw=max(NVI,level.*ones(size(NVI)));
%     level = max(max(NVI))/3;
%     Ibw = NVI;
%     for i1 = 1:size(NVI,1)
%         for i2 = 1:size(NVI,2)
%             if NVI(i1,i2) < level
%                 Ibw(i1,i2) = 0;
%             end
%         end
%     end
%     subplot(2,3,5);
%     imshow(Ibw); impixelinfo
%     title('After Thresholding');
% 
% 
% 
%     % Thinning (Using interpolation to find the pixels where the norms of 
%     % gradient are local maximum.)
%     [n,m]=size(Ibw);
%     I_temp = zeros(n,m);
%     for i=2:n-1,
%     for j=2:m-1,
%         if Ibw(i,j) > level,
%         X=[-1,0,+1;-1,0,+1;-1,0,+1];
%         Y=[-1,-1,-1;0,0,0;+1,+1,+1];
%         Z=[Ibw(i-1,j-1),Ibw(i-1,j),Ibw(i-1,j+1);
%            Ibw(i,j-1),Ibw(i,j),Ibw(i,j+1);
%            Ibw(i+1,j-1),Ibw(i+1,j),Ibw(i+1,j+1)];
%         XI=[Ix(i,j)/NVI(i,j), -Ix(i,j)/NVI(i,j)];
%         YI=[Iy(i,j)/NVI(i,j), -Iy(i,j)/NVI(i,j)];
%         ZI=interp2(X,Y,Z,XI,YI);
%             if Ibw(i,j) >= ZI(1) & Ibw(i,j) >= ZI(2)
%             I_temp(i,j)=I_max;
%             else
%             I_temp(i,j)=I_min;
%             end
%         else
%         I_temp(i,j)=I_min;
%         end
%     end
%     end
%     subplot(2,3,6);
%     imshow(I_temp);
%     title('After Thinning');
%     colormap(gray);
%     
%     
%     
%     
% 
%     I_temp = im2bw(I_temp,I_min);
%     I_temp = bwareaopen(I_temp,5);
% 
% 
%     I_temp = imclose(I_temp, strel('disk',3) );
% 
%     % figure;
%     % subplot(2,2,1), imshow(I_temp);
%     % 
%     % I_temp2 = imfill(I_temp,'holes');
%     % cc = regionprops(I_temp2,'Centroid');
%     % x0 = round( cc(1).Centroid(1) );
%     % y0 = round( cc(1).Centroid(2) );
%     % 
%     % I_temp2 = ~I_temp;
%     % I_temp2 = I_temp2.*wBW;
%     % 
%     % subplot(2,2,2), imshow(I_temp2);
%     % 
%     % % idxDel = [];
%     % % cc = regionprops(I_temp2,'PixelList');
%     % % for iGroup = 1:size(cc,1)
%     % %     PixelList = cc(iGroup).PixelList;
%     % %     for iList = 1:size(PixelList,1)
%     % %         if PixelList(iList,1) == x0 && PixelList(iList,2) == y0
%     % %             idxDel = iGroup;
%     % %             break
%     % %         end
%     % %     end
%     % %     if ~isempty(idxDel)
%     % %         
%     % %         for iList = 1:size(PixelList,1)
%     % %             I_temp2( PixelList(iList,2),PixelList(iList,1) ) = 0;
%     % %         end
%     % %         
%     % %         break
%     % %     end
%     % % end
%     % % 
%     % % subplot(2,2,3), imshow(I_temp2);
%     % % 
%     % % for i1 = 1:size(I_temp,1)
%     % %     for i2 = 1:size(I_temp,2)
%     % %         if I_temp2(i1,i2) && ~I_temp(i1,i2)
%     % %             I_temp(i1,i2) = 1;
%     % %         end
%     % %     end
%     % % end
%     % % 
%     % % 
%     % % subplot(2,2,4), imshow(I_temp);
%     
%     
%     
%     I_temp = imerode(I_temp,strel('disk',1));
% %     figure; imshow(I_temp)
% 
%     wBW = wBW.*~I_temp;
%     wBW = imopen(wBW, strel('disk',2) );
% 
% 
%     
% %     figure; imshow(wBW)
%     
%     cc_wBW = bwconncomp(wBW);
%     if cc_wBW.NumObjects > 1
%         nPixel_wBW = zeros( cc_wBW.NumObjects ,1);
%         for i_wBW = 1:cc_wBW.NumObjects
%             nPixel_wBW(i_wBW) = size(cc_wBW.PixelIdxList{1,i_wBW},1);
%         end
%         [max_val max_idx] = max(nPixel_wBW);
%         wBW = zeros( size(wBW,1),size(wBW,2) );
%         wBW( cc_wBW.PixelIdxList{1,max_idx} ) = 1;
%     end
%     
% %     cc_wBW = regionprops(wBW,'PixelIdxList');
% %     if size(cc_wBW,1) > 1
% %         nPixel_wBW = zeros( size(cc_wBW,1) ,1);
% %         for i_wBW = 1:size(cc_wBW,1)
% %             nPixel_wBW(i_wBW) = size(cc_wBW(i_wBW).PixelIdxList,1);
% %         end
% %         [max_val max_idx] = max(nPixel_wBW);
% %         wBW = zeros( size(wBW,1),size(wBW,2) );
% %         wBW( cc_wBW(max_idx).PixelIdxList ) = 1;
% %     end
%     
%     
%     
%     w = w.*wBW;
% 
% %     figure; imshow(w);
%     
%     
%     
%     img = w;
%     imgBW = wBW;
%     
%     
%     
%     
%     
%         % Function "d2dgauss.m":
%         % This function returns a 2D edge detector (first order derivative
%         % of 2D Gaussian function) with size n1*n2; theta is the angle that
%         % the detector rotated counter clockwise; and sigma1 and sigma2 are the
%         % standard deviation of the gaussian functions.
%         function h = d2dgauss(n1,sigma1,n2,sigma2,theta)
%         r=[cos(theta) -sin(theta);
%            sin(theta)  cos(theta)];
%         for i = 1 : n2 
%             for j = 1 : n1
%                 u = r * [j-(n1+1)/2 i-(n2+1)/2]';
%                 h(i,j) = gauss(u(1),sigma1)*dgauss(u(2),sigma2);
%             end
%         end
%         h = h / sqrt(sum(sum(abs(h).*abs(h))));
%         end
% 
%         % Function "gauss.m":
%         function y = gauss(x,std)
%         y = exp(-x^2/(2*std^2)) / (std*sqrt(2*pi));
%         end
% 
%         % Function "dgauss.m"(first order derivative of gauss function):
%         function y = dgauss(x,std)
%         y = -x * gauss(x,std) / std^2;
%         end
% 
%     end
end