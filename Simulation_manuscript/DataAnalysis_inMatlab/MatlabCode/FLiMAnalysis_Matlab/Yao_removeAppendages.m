function Yao_removeAppendages(numCycle)

global stateYao




str = sprintf('Removing Appendages for Cycle %d...',numCycle);
hdlProgRemove = waitbar(0,str);

for iImg = 1:size( stateYao.CyclePositions ,1)
% for iImg = 33
if stateYao.CyclePositions(iImg,stateYao.numCycle(numCycle)) ~= 0
if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
    
    if ishandle(hdlProgRemove)
    waitbar(...
        iImg/size( stateYao.CyclePositions ,1),...
        hdlProgRemove)
    drawnow
    end
    
for iCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1)
% for iCell = 2
idxCell = stateYao.cellIdx{numCycle}{iImg}(iCell,1);
cellID = stateYao.cellIdx{numCycle}{iImg}(iCell,2);

I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);

pixelList_perim = Yao_generic_getPerimeter(I_cell);



%% Part 1) Removal based perimeter pixel angle and radius
thresh_rhoDif = 3;

x0 = round( stateYao.cellIdx{numCycle}{iImg}(idxCell,5) );
y0 = round( stateYao.cellIdx{numCycle}{iImg}(idxCell,6) );

pixelList_perim2 = zeros( size(pixelList_perim,1) ,2);
pixelList_perim2(:,1) = pixelList_perim(:,1)-y0;
pixelList_perim2(:,2) = pixelList_perim(:,2)-x0;

[theta,rho] = cart2pol(pixelList_perim2(:,2),pixelList_perim2(:,1));
theta = rad2deg(theta);

theta2 = sortrows( cat(2,[1:size(theta,1)]',theta,rho) ,2);
theta2 = cat(1,theta2,theta2(1:5,:)+ones(5,1)*[0 360 0]);

% Check for matches within 2 degrees
% Then check rho. If difference in rho is large, delete outter points
delList = [];
for iPixel = 3:size(theta2,1)-2
    ra = theta2(iPixel,2) + [-2 2];
    theta3 = theta2( theta2(:,2) >= ra(1) & theta2(:,2) <= ra(2) ,:);
    
    if any( theta3(:,3) > theta2(iPixel,3)+thresh_rhoDif )
        if isempty(delList)
            delList = theta3(...
                theta3(:,3) > theta2(iPixel,3)+thresh_rhoDif,...
                1 );
        else
            delList = cat(1,delList,...
                theta3(...
                theta3(:,3) > theta2(iPixel,3)+thresh_rhoDif,...
                1 ) );
        end
    end
    
end

clear iPixel ra theta3 theta2 theta rho x0 y0
clear pixelList_perim2

if ~isempty(delList)
    delList = unique( sortrows(delList) );
    saveList = 1:size(pixelList_perim,1);
    saveList(delList) = [];
    
    pixelList_perim2 = pixelList_perim(saveList,:);
    
    imgTemp = zeros( size(I_cell,1) , size(I_cell,2) );
    for iPixel = 1:size(pixelList_perim2,1)
        imgTemp( pixelList_perim2(iPixel,1),pixelList_perim2(iPixel,2) ) = 1;
    end
    
    imgTemp = Yao_generic_fillPts(imgTemp);
    
    
    
    imgTemp = imgTemp.*I_cell;
    
    
    
    cc = regionprops( imgTemp ,'Centroid');
    
    x0 = cc(1).Centroid(1);
    y0 = cc(1).Centroid(2);
    
    [theta,rho] = cart2pol(x0,y0);
    
    
    
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) = imgTemp;
    
    stateYao.cellIdx{numCycle}{iImg}(iCell,:) =...
        [idxCell cellID rho rad2deg(theta) x0 y0];
    
    clear saveList imgTemp cc x0 y0 theta rho
    clear pixelList_perim2
end

clear delList pixelList_perim




%% Removal based on 
dispOpt = 0;
dispOpt2 = 8;
dispOpt3 = [];



ccOrig = regionprops(...
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell),...
    'Centroid','MajorAxisLength','MinorAxisLength' );

grpRadius = max([10 ccOrig(1).MinorAxisLength/10]);


            if dispOpt == 1
            if any( iImg == dispOpt2 )
            str = sprintf('%s: Minor axis length is %3.0f\n\tgrpRadius = %3.0f\n',...
                mfilename,ccOrig(1).MinorAxisLength,grpRadius);
            if isempty(dispOpt3)
                fprintf(str)
            elseif any(cellID == dispOpt3)
                fprintf(str)
            end
            end
            end



            

pixelList_perim = Yao_generic_getPerimeter(...
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) );




bw = zeros(...
    size( stateYao.images.I_cell_stack{numCycle}{iImg} ,1),...
    size( stateYao.images.I_cell_stack{numCycle}{iImg} ,2) );
for i3 = 1:4
    if i3 == 1
        method = 'euclidean';
    elseif i3 == 2
        method = 'cityblock';
    elseif i3 == 3
        method = 'chessboard';
    else
        method = 'quasi-euclidean';
    end
    
    bw(:,:) = bw +...
        bwulterode(stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell),...
        method);
end
bw = bw ~= 0;










            if dispOpt == 1
            if any( iImg == dispOpt2 )
            
            D = -bwdist(~stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell));
            mask = imextendedmin(D,1);
            D2 = imimposemin(D,mask);
            Ld = watershed(D2);
            bw2 = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            bw2(Ld == 0) = 0;
            
            if isempty(dispOpt3)
            figure; imshow(bw)
            figure; imshow(D,[])
            figure; imshow(bw2)
            elseif any(cellID == dispOpt3)
            figure; imshow(bw)
            figure; imshow(D,[])
            figure; imshow(bw2)
            end
            end
            end




if any(any(bw))
cc = bwconncomp(bw);
for iGrp = 1:cc.NumObjects
    if iGrp == 1
        x = ceil(cc.PixelIdxList{1,iGrp}/cc.ImageSize(2));
        y = mod(cc.PixelIdxList{1,iGrp},cc.ImageSize(1));
    else
        x = cat(1,x,...
            ceil(cc.PixelIdxList{1,iGrp}/cc.ImageSize(2)) );
        y = cat(1,y,...
            mod(cc.PixelIdxList{1,iGrp},cc.ImageSize(1)) );
    end
end
y(y==0) = cc.ImageSize(1);



size1 = size( stateYao.images.origData.projects{numCycle} ,1);
size2 = size( stateYao.images.origData.projects{numCycle} ,2);
grpList = zeros( size(x,1) ,1);
grpList(1) = 1;
grpX = x(1);
grpY = y(1);
grpCount = 1;

for iPixel = 2:size(x,1)
    
    foundGrp = 0;
    for iGrp = 1:size(grpX,1)
        if hypot(...
                x(iPixel)-grpX(iGrp),...
                y(iPixel)-grpY(iGrp) ) <=...
                grpRadius
            
            foundGrp = 1;
            
            grpList(iPixel) = iGrp;
            
            f_grp = grpCount(iGrp)/(grpCount(iGrp)+1);
            f_new = 1/(grpCount(iGrp)+1);
            
            grpX(iGrp) = f_grp*grpX(iGrp) + f_new*x(iPixel);
            grpY(iGrp) = f_grp*grpY(iGrp) + f_new*y(iPixel);
            
            grpCount(iGrp) = grpCount(iGrp)+1;
            
            break
        end
    end
    
    if ~foundGrp
        grpList(iPixel) = size(grpX,1)+1;
        
        grpX = cat(1,grpX,x(iPixel));
        grpY = cat(1,grpY,y(iPixel));
        
        grpCount = cat(1,grpCount,1);
    end
    
end


if size(grpCount,1) == 1
validGrpList = 1;
else
% Remove entries that are too far from centroid
grpRadius2 = max([grpRadius ccOrig(1).MajorAxisLength/5]);




            if dispOpt == 1
            if any( iImg == dispOpt2 )
            str = sprintf('%s: Groups must be within %3.0f pixels of centroid\n',...
                mfilename,grpRadius2);
            if isempty(dispOpt3)
                fprintf(str)
            elseif any(cellID == dispOpt3)
                fprintf(str)
            end
            end
            end





% cc = regionprops(...
%     stateYao.images.I_cell_stack{iCycle}{iImg}(:,:,idxCell),...
%     'Centroid');
x0 = ccOrig(1).Centroid(1);
y0 = ccOrig(1).Centroid(2);



validGrpList = 1:size(grpCount,1);
for iGrp = size(grpCount,1):-1:1
    x1 = x( grpList == validGrpList(iGrp) );
    y1 = y( grpList == validGrpList(iGrp) );
    
    
    
    
                if dispOpt == 1
                if any( iImg == dispOpt2 )
                str = sprintf('%s: Group %d is %3.0f pixels from centroid\n',...
                    mfilename,validGrpList(iGrp),...
                     hypot( x0-mean(x1) , y0-mean(y1) ) );
                if isempty(dispOpt3)
                    fprintf(str)
                elseif any(cellID == dispOpt3)
                    fprintf(str)
                end
                end
                end
    
    
    
    if hypot( x0-mean(x1) , y0-mean(y1) ) > grpRadius2
        validGrpList(iGrp) = [];
    end
    
end

% if ~isempty(validGrpList)
%     maxCount = max(grpCount(validGrpList));
%     validGrpList( grpCount(validGrpList) < maxCount/2 ) = [];
% end
end % More than 1 group?




            if dispOpt == 1
            if any( iImg == dispOpt2 )
            str = sprintf('%s: valid groups:\n',...
                mfilename);
            for iGrp = 1:length(validGrpList)
                str = sprintf('%s%s',...
                    str,...
                    sprintf('\t%d\n',validGrpList(iGrp)) );
            end
            if isempty(dispOpt3)
                fprintf(str)
            elseif any(cellID == dispOpt3)
                fprintf(str)
            end
            end
            end





if ~isempty(validGrpList)


bw = zeros(size1,size2);
for iPixel = 1:size(x,1)
    if any(grpList(iPixel) == validGrpList);
        bw(y(iPixel),x(iPixel)) = 1;
    end
end



        if dispOpt == 1
        if any( iImg == dispOpt2 )
        if isempty(dispOpt3)
        figure; imshow(bw)
        elseif any(cellID == dispOpt3)
        figure; imshow(bw)
        end
        end
        end




PixelIdxList = pixelList_perim(:,1);
PixelIdxList( PixelIdxList == size1 ) = 0;
PixelIdxList = PixelIdxList + (pixelList_perim(:,2)-1)*size1;
PixelIdxList( PixelIdxList == 0 ) = size1;



% se = round( min( hypot(...
%     mean(x( any(grpList == validGrpList) ))-pixelList_perim(:,2),...
%     mean(y( any(grpList == validGrpList) ))-pixelList_perim(:,1) ) ) );
se = strel( 'disk', round(...
    ccOrig(1).MinorAxisLength / 2) );

bw = imdilate(bw,se).*...
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);



            if dispOpt == 1
            if any( iImg == dispOpt2 )
            if isempty(dispOpt3)
            figure; imshow(bw)
            elseif any(cellID == dispOpt3)
            figure; imshow(bw)
            end
            end
            end

            
            
se = strel('disk',round(...
    min([6 ...
    max([2 ...
    ccOrig(1).MinorAxisLength/20])]) ) );
    
foundCell = 1;
count = 0;
while sum(sum( bw(PixelIdxList) )) < 0.75*size(PixelIdxList,1)
    count = count+1;
    
    if count > 30
        
                if dispOpt == 1
                if any( iImg == dispOpt2 )
                str = sprintf('\t\t\tCount is at limit, aborting...\n');

                if isempty(dispOpt3)
                    fprintf(str)
                elseif any(cellID == dispOpt3)
                    fprintf(str)
                end
                end
                end
        
        foundCell = 0;
        break
    end
    
    bw = imdilate(bw,se).*...
        stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
    
    
    
    
    
                if dispOpt == 1
                if any( iImg == dispOpt2 )

                if count == 1
                    str = sprintf('%s: iImg %d - cellID %d: Count is %d, percent of perimeter matched = %3.0f\n',...
                        mfilename,iImg,cellID,...
                        count,...
                        sum(sum( bw(PixelIdxList) )) / size(PixelIdxList,1) *100);
                else
                    str = sprintf('\t\t\tCount is %d, percent of perimeter matched = %3.0f\n',...
                        count,...
                        sum(sum( bw(PixelIdxList) )) / size(PixelIdxList,1) *100);
                end
                if isempty(dispOpt3)
                    fprintf(str)
                    imshow(bw)
                elseif any(cellID == dispOpt3)
                    fprintf(str)
                    imshow(bw)
                end
                end
                end
    
end






if foundCell
    cc = regionprops( bw ,'Centroid');
    
    x0 = cc(1).Centroid(1);
    y0 = cc(1).Centroid(2);
    
    [theta,rho] = cart2pol(x0,y0);
    
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) = bw;
    
    stateYao.cellIdx{numCycle}{iImg}(iCell,:) =...
        [idxCell cellID rho rad2deg(theta) x0 y0];
end
end
end





end % for iCell
end
end
end % for iImg



if ishandle(hdlProgRemove)
close(hdlProgRemove)
drawnow
end