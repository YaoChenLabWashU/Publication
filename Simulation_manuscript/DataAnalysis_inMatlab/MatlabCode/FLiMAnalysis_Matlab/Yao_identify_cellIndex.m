function Yao_identify_cellIndex(numCycle)

global stateYao



% Get initial cell indices
%   Column 1 I_cell_stack index
%   Column 2 cell ID
%   Column 3 distance from centroid to origin
%   Column 4 angle, from centroid to origin
%   Column 5 X-coordinate of centroid
%   Column 6 Y-coordinate of centroid

idxM1 = 3;
idxM2 = 4;

threshM1 = 20; % Used to determine if two cells are close enough that
% a second method is required to separate (for indexing)

for iImg = 1:size( stateYao.CyclePositions ,1)
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        
        I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
        
        for iCell = 1:size(I_cell_stack,3)
            if sum(sum( I_cell_stack(:,:,iCell) )) ~= 0
                cc = regionprops( I_cell_stack(:,:,iCell) ,'Centroid');
                
                x0 = cc(1).Centroid(1);
                y0 = cc(1).Centroid(2);
                
                [theta,rho] = cart2pol(x0,y0);
                
                stateYao.cellIdx{numCycle}{iImg}(iCell,:) =...
                    [iCell iCell rho rad2deg(theta) x0 y0];
            end
        end
        
    end
end














%% Step 1: Initial index verification
% Need to verify indices
%   First look at images who have probably the right number of cells
%       Always aim for fewer cells, we can add later

nCellList = zeros( size( stateYao.CyclePositions ,1) ,2);
nCellList(:,1) = 1:size( stateYao.CyclePositions ,1);
for iImg = 1:size( stateYao.CyclePositions ,1)
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
            nCellList(iImg,2) = size( stateYao.cellIdx{numCycle}{iImg} ,1);
        end
    end
end
nCellList = nCellList( nCellList(:,2) ~= 0 ,:);

% Best guess as to the correct number of cells
[nCell_true] = Yao_findCells_calc__nCell_true(nCellList);




goodList = nCellList( nCellList(:,2)==nCell_true ,1);



% We now have a list of all the images with the "correct" number of cells.
% We want to verify that the cell IDs match



cellIndex = zeros(...
    nCell_true,...
    size( stateYao.cellIdx{numCycle}{goodList(1,1)} ,2 ),...
    size(goodList,1) );
cellIndex_sorted = cellIndex;

for iList = 1:size(goodList,1)
    iImg = goodList(iList,1);
    
    cellIndex(:,:,iList) = stateYao.cellIdx{numCycle}{iImg};
    cellIndex_sorted(:,:,iList) = sortrows( cellIndex(:,:,iList) ,idxM1);
end
I_thres = abs(cellIndex_sorted(1:end-1,idxM1,:)-...
    cellIndex_sorted(2:end,idxM1,:) ) <= threshM1;



if ~any(any(I_thres))
    % Should be able to do a simple sort
    for iList = 1:size(cellIndex,3)
        temp_cellIndex = cellIndex(:,[2 idxM1],iList);
        temp_cellIndex = sortrows(temp_cellIndex,2);
        temp_cellIndex = cat(2,temp_cellIndex,...
            [1:size(temp_cellIndex,1)]');
        
        cellIndex( temp_cellIndex(:,1) ,2,iList) =...
            temp_cellIndex(:,3);
        
        
        iImg = goodList(iList,1);
        stateYao.cellIdx{numCycle}{iImg} = cellIndex(:,:,iList);
    end
    
else
    % Reshape from (m x 1 x n) to (m x n)
    I_thres2 = reshape(I_thres,size(I_thres,1),size(I_thres,3));
    % Get indices which meet <=threshM1
    idxI = 1:size(I_thres2,1);
    idxI = idxI( any(I_thres2') )';
    % Add the complementary index
    %   If index 2 was found to have <=threshM1, then that means cell 2
    %   and 3 are equally far from the origin
    %   A second method must be used to determine which is truly cell 2
    %   and which is cell 3
    idxI = cat(2,idxI,idxI+1);
    
    % If we had
    %   tempIdx =
    %               1   5
    %               2   3
    %               3   4
    %               6   7
    %
    % We would want
    %   tempIdx =
    %               1   5   0
    %               2   3   4
    %               6   7   0
    if size(idxI,1) > 1
        for iIdx = size(idxI,1):-1:2
            if any( idxI(iIdx-1,2:end) == idxI(iIdx,1) )
                
                idxNonZero = 1:size(idxI,2);
                idxNonZero = idxNonZero( idxI(iIdx-1,:) ~= 0 );
                for i1 = 1:size(idxNonZero,2)
                    i2 = idxNonZero(i1);
                    idxI(iIdx-1,i2) = idxI(iIdx-1,i1);
                end
                idxNonZero2 = 1:size(idxI,2);
                idxNonZero2 = idxNonZero2( idxI(iIdx,:) ~= 0 );
                for i1 = 2:size(idxNonZero2,2)
                    i2 = idxNonZero2(i1);
                    idxI(iIdx-1,size(idxNonZero,2)+i1-1) =...
                        idxI(iIdx,i2);
                end
                
                idxI(iIdx,:) = [];
            end
        end
    end
    
    
    
    cellID = zeros(nCell_true,2,size(cellIndex,3));
    % % %         idxNotContested = 1:size(I_thres2,1);
    % % %         idxNotContested = idxNotContested( ~any(I_thres2') )';
    % % %         if ~isempty(idxNotContested)
    % % %         for iList = 1:size(cellIndex,3)
    % % %             temp_cellIndex = cellIndex(:,[2 idxM1],iList);
    % % %             temp_cellIndex = sortrows(temp_cellIndex,2);
    % % %             temp_cellIndex = cat(2,temp_cellIndex,...
    % % %                 [1:size(temp_cellIndex,1)]');
    % % %
    % % %             % Now we have
    % % %             %   temp_cellIndex
    % % %             %           Col 1               Col 2           Col 3
    % % %             %       I_cell_stack index   dist. to origin    Cell ID
    % % %             %
    % % %             % We want to store in cellID the I_cell_stack index for the
    % % %             % Cell IDs given in idxNotContested
    % % %             for iIdx = 1:size(temp_cellIndex,1)
    % % %             if any(temp_cellIndex(iIdx,end) == idxNotContested)
    % % %                 cellID(iIdx,:,iList) = [...
    % % %                     temp_cellIndex(iIdx,1) ...
    % % %                     temp_cellIndex(iIdx,end)];
    % % %             end
    % % %             end
    % % %
    % % %         end
    % % %         end
    for iList = 1:size(cellIndex,3)
        temp_cellIndex = cellIndex(:,[2 idxM1 idxM2],iList);
        temp_cellIndex = sortrows(temp_cellIndex,2);
        
        for iGroup = 1:size(idxI,1)
            temp_idxI = idxI(iGroup,:);
            temp_idxI = temp_idxI( temp_idxI~=0 );
            temp_temp_cellIndex = temp_cellIndex(temp_idxI,:);
            temp_temp_cellIndex = sortrows(temp_temp_cellIndex,3);
            temp_cellIndex(temp_idxI,:) = temp_temp_cellIndex;
        end
        
        
        temp_cellIndex = cat(2,temp_cellIndex,...
            [1:size(temp_cellIndex,1)]');
        
        
        % Now we have
        %   temp_cellIndex
        %           Col 1               Col 2           Col 3   Col 4
        %       I_cell_stack index   dist. to origin    Angle   Cell ID
        %
        % We want to store in cellID the I_cell_stack index for the
        % Cell IDs given in idxI
        cellID(:,:,iList) =...
            [temp_cellIndex(:,1) temp_cellIndex(:,end)];
        
    end
    
    
    
    % Save
    for iList = 1:size(goodList,1)
        iImg = goodList(iList,1);
        stateYao.cellIdx{numCycle}{iImg}(cellID(:,1,iList),2) =...
            cellID(:,2,iList);
        
    end
    
end % if any(any(I_thres))



% We already have imageShift data. Let's do a check
%   Need new iImg_mask
valPhoton = zeros( size(goodList,1) ,1);
onesMatrix = ones(...
    size(stateYao.images.origData.projects{numCycle},1),...
    size(stateYao.images.origData.projects{numCycle},2) );
for iList = 1:size(goodList,1)
    iImg = goodList(iList,1);
    
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        valPhoton(iList) = Yao_calc_Photon(...
            stateYao.images.origData.projects{numCycle}(:,:,iImg),...
            onesMatrix);
    end
end

[max_val max_idx] = max(valPhoton);
iImg_mask = goodList(max_idx);
idx_goodList_mask = max_idx;


imageShift = stateYao.shift.second.imageShift{numCycle}(goodList,:);
imageShift = [...
    imageShift(:,1)-imageShift(idx_goodList_mask,1) ...
    imageShift(:,2)-imageShift(idx_goodList_mask,2)];



% % % size1 = size(stateYao.images.I_cell_stack{iCycle}{goodList(1,1)},1);
% % % size2 = size(stateYao.images.I_cell_stack{iCycle}{goodList(1,1)},2);
% % % imgTemp = zeros(size1*3,size2*3 );
% % % figure;
% % % for iList = 1:size(goodList,1)
% % %     iImg = goodList(iList,1);
% % %
% % %     for iCell = 1:nCell_true
% % %         if any(stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell)
% % %
% % %             idxCell = 1:size(stateYao.cellIdx{iCycle}{iImg},1);
% % %             idxCell = idxCell( stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell );
% % %             idxCell = stateYao.cellIdx{iCycle}{iImg}(idxCell,1);
% % %
% % %             imgTemp(:,:) = zeros(size1*3,size2*3 );
% % %             imgTemp(...
% % %                 1+size1+imageShift(iList,2):size1*2+imageShift(iList,2),...
% % %                 1+size2+imageShift(iList,1):size2*2+imageShift(iList,1) ) =....
% % %                 stateYao.images.I_cell_stack{iCycle}{iImg}(:,:,idxCell);
% % %
% % %             subplot(nCell_true,1,iCell), imshow(...
% % %                 imgTemp(1+size1:size1*2,1+size2:size2*2) );
% % %
% % %         end
% % %     end
% % %     pause(0.5)
% % % end



cellList = [];
for iList = 1:size(goodList,1)
    iImg = goodList(iList,1);
    
    cellID = stateYao.cellIdx{numCycle}{iImg}(:,2);
    
    if isempty(cellList)
        cellList = sortrows( cellID );
    else
        for iCell = 1:size(cellID,1)
            if ~any( cellID(iCell) == cellList )
                cellList = sortrows( cat(1,cellList,cellID(iCell)) );
            end
        end
    end
end

% % % size1 = size(stateYao.images.I_cell_stack{iCycle}{goodList(1,1)},1);
% % % size2 = size(stateYao.images.I_cell_stack{iCycle}{goodList(1,1)},2);
% % % bwTemp = zeros(size1*3,size2*3 ,size(cellList,1));

x0 = zeros( size(goodList,1),size(cellList,1) );
y0 = x0;

for iList = 1:size(goodList,1)
    iImg = goodList(iList,1);
    
    cellID = stateYao.cellIdx{numCycle}{iImg}(:,2);
    for iCell = 1:size(cellID,1)
        
        % % %         ry = 1+size1+imageShift(iList,2):size1*2+imageShift(iList,2);
        % % %         rx = 1+size2+imageShift(iList,1):size2*2+imageShift(iList,1);
        % % %
        % % %         bwTemp(ry,rx,cellID(iCell)) = bwTemp(ry,rx,cellID(iCell))+...
        % % %             stateYao.images.I_cell_stack{iCycle}{iImg}(:,:,...
        % % %             stateYao.cellIdx{iCycle}{iImg}(iCell,1) );
        
        x0(iList,cellID(iCell)) = stateYao.cellIdx{numCycle}{iImg}(iCell,5)+...
            imageShift(iList,1);
        y0(iList,cellID(iCell)) = stateYao.cellIdx{numCycle}{iImg}(iCell,6)+...
            imageShift(iList,2);
    end
end

d = hypot(x0,y0);


% % % figure;
% % % for iCell = 1:size(cellList,1)
% % %     subplot(size(cellList,1),1,iCell), imshow(bwTemp(:,:,iCell));
% % %     impixelinfo
% % % end



delList = [];
for iCell = 1:size(cellID,1)
    
    temp_x0 = x0( x0(:,iCell)~=0 ,iCell);
    temp_y0 = y0( x0(:,iCell)~=0 ,iCell);
    temp_d  =  d( x0(:,iCell)~=0 ,iCell);
    temp_goodList = goodList(x0(:,iCell)~=0);
    
    
    
    if size(temp_goodList,1) < 5
        fprintf('%s: Low goodList count for cell %d\n',...
            mfilename,cellID(iCell))
        
        if isempty(delList)
            delList = temp_goodList;
        else
            delList = cat(2,delList,temp_goodList);
        end
    else
        if any( abs(temp_x0-mean(temp_x0)) > 10 ) ||...
                any( abs(temp_y0-mean(temp_y0)) > 10 ) ||...
                any( abs(temp_d-mean(temp_d)) > threshM1 )
            
            tempList = 1:size(temp_goodList,1);
            tempList = tempList(...
                abs(temp_x0-mean(temp_x0)) > 10 |...
                abs(temp_y0-mean(temp_y0)) > 10 |...
                abs(temp_d-mean(temp_d)) > threshM1 );
            
            
            if isempty(delList)
                delList = temp_goodList(tempList)';
            else
                delList = cat(2,delList,temp_goodList(tempList)');
            end
            
        end
    end
end

if ~isempty(delList)
    % delList contains iImg values
    delList = unique( sortrows(delList') );
    for iList = size(delList,1):-1:1
        goodList( goodList == delList(iList) ) = [];
    end
end



cellIdList = [];
if isempty(goodList)
    % :(
    goodList = nCellList;
end
for iList = 1:size(goodList,1)
    iImg = goodList(iList,1);
    
    if iList == 1
        cellIdList = sortrows( stateYao.cellIdx{numCycle}{iImg}(:,2) );
        cellIdList = cat(2,cellIdList, ones( size(cellIdList,1) ,1) );
    else
        temp_cellIdList = sortrows( stateYao.cellIdx{numCycle}{iImg}(:,2) );
        for iTemp = 1:size(temp_cellIdList,1)
            if any( cellIdList(:,1) == temp_cellIdList(iTemp) )
                cellIdList( cellIdList(:,1) == temp_cellIdList(iTemp) ,2) =...
                    cellIdList( cellIdList(:,1) == temp_cellIdList(iTemp) ,2)+1;
            else
                cellIdList = cat(1,cellIdList,[temp_cellIdList(iTemp) 1]);
            end
        end
    end
end

if any( cellIdList(:,2) < max(cellIdList(:,2)) )
    cellIdList = cat(2,sortrows(cellIdList(:,1),-1),[1:size(cellIdList,1)]');
    for iList = 1:size(goodList,1)
        iImg = goodList(iList,1);
        
        for iCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1)
            stateYao.cellIdx{numCycle}{iImg}(iCell,2) =...
                cellIdList(...
                cellIdList(:,1)==stateYao.cellIdx{numCycle}{iImg}(iCell,2) ,...
                2);
        end
    end
end



badList = nCellList(:,1);
for iList = 1:size(goodList,1)
    badList( badList == goodList(iList) ) = [];
end

if ~isempty(badList)
    % Reset cellID in cellIdx
    for iList = 1:size(badList,1)
        iImg = badList(iList,1);
        
        stateYao.cellIdx{numCycle}{iImg}(:,2) = 0;
    end
end



clear iList iImg iCell
clear I_cell_stack imgTemp
clear cc x0 y0 d theta rho
clear onesMatrix valPhoton
clear cellIdList temp_cellIdList
clear I_thres I_thres2 idxI iIdx i1 i2 idxNonZero idxNonZero2
clear temp_idxI temp_cellIndex temp_temp_cellIndex
clear temp_x0 temp_y0 temp_d temp_goodList tempList iTemp





%% Step 2: Find good cells in remaining images
if ~isempty(badList)
    % Previous Steps
    %   Step 1: Initial index verification
    %       Find initial list of good cells and good images
    %
    % Current process
    %   From our list of good cells, seek match in remaining images
    %       Create mask of good cells from good images
    
    
    
    % Create mask for each good cell using the good images
    size1 = size( stateYao.images.I_cell_stack{numCycle}{goodList(1,1)} ,1);
    size2 = size( stateYao.images.I_cell_stack{numCycle}{goodList(1,1)} ,2);
    for iList = 1:size(goodList,1)
        iImg = goodList(iList,1);
        
        cellID2idxCell = cat(2,...
            stateYao.cellIdx{numCycle}{iImg}(:,2),...
            stateYao.cellIdx{numCycle}{iImg}(:,1) );
        
        
        
        rx = 1+size2+stateYao.shift.second.imageShift{numCycle}(iImg,1):...
            size2*2+stateYao.shift.second.imageShift{numCycle}(iImg,1);
        ry = 1+size1+stateYao.shift.second.imageShift{numCycle}(iImg,2):...
            size1*2+stateYao.shift.second.imageShift{numCycle}(iImg,2);
        
        
        
        if iList == 1
            bw_stack_mask = zeros(size1*3,size2*3, max(cellID2idxCell(:,1)) );
            for iCell = 1:size(cellID2idxCell,1)
                cellID  = cellID2idxCell(iCell,1);
                idxCell = cellID2idxCell(iCell,2);
                
                bw_stack_mask(ry,rx,cellID) =...
                    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            end
        else
            for iCell = 1:size(cellID2idxCell,1)
                cellID  = cellID2idxCell(iCell,1);
                idxCell = cellID2idxCell(iCell,2);
                
                if size(bw_stack_mask,3) < cellID
                    bw_stack_mask(:,:, size(bw_stack_mask,3)+1:cellID ) =...
                        zeros(size1*3,size2*3, cellID-size(bw_stack_mask,3) );
                    bw_stack_mask(ry,rx,cellID) =...
                        stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
                else
                    bw_stack_mask(ry,rx,cellID) =...
                        bw_stack_mask(ry,rx,cellID)+...
                        stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
                end
            end
        end
    end
    bw_stack_mask = bw_stack_mask(1+size1:size1*2,1+size2:size2*2,:);
    for i3 = 1:size(bw_stack_mask,3)
        bw_stack_mask(:,:,i3) = bw_stack_mask(:,:,i3) >=...
            max(max(bw_stack_mask(:,:,i3)))/3;
        bw_stack_mask(:,:,i3) = imclose(...
            bw_stack_mask(:,:,i3),...
            strel('disk',3) );
        bw_stack_mask(:,:,i3) = imfill(bw_stack_mask(:,:,i3),'holes');
    end
    
    bw_mask = zeros(size1,size2);
    for i3 = 1:size(bw_stack_mask,3)
        bw_mask = bw_mask+bw_stack_mask(:,:,i3);
    end
    bw_mask = bw_mask ~= 0;
    
    
    
    
    
    
    % Now compare against badList cells
    for iList = 1:size(badList,1)
        iImg = badList(iList,1);
        
        
        
        rx = 1+size2+stateYao.shift.second.imageShift{numCycle}(iImg,1):...
            size2*2+stateYao.shift.second.imageShift{numCycle}(iImg,1);
        ry = 1+size1+stateYao.shift.second.imageShift{numCycle}(iImg,2):...
            size1*2+stateYao.shift.second.imageShift{numCycle}(iImg,2);
        
        
        
        I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
        
        % % %     imgTemp = zeros(size1*3,size2*3);
        % % %     for i3 = 1:size(I_cell_stack,3)
        % % %         imgTemp(ry,rx) = imgTemp(ry,rx)+I_cell_stack(:,:,i3);
        % % %     end
        % % %     imgTemp = imgTemp(1+size1:size1*2,1+size2:size2*2);
        % % %
        % % %
        % % %     figure;
        % % % %     subplot(1,2,1),imshow(bw_mask);
        % % % %     subplot(1,2,2),imshow(imgTemp);
        % % %     imshowpair(bw_mask,imgTemp,'blend')
        
        
        
        for i3 = 1:size(I_cell_stack,3)
            
            imgTemp = zeros(size1*3,size2*3);
            imgTemp(ry,rx) = I_cell_stack(:,:,i3);
            imgTemp = imgTemp(1+size1:size1*2,1+size2:size2*2);
            
            % % %         [iImg i3 sum(sum( bw_mask.*imgTemp ))]
            
            if sum(sum( bw_mask.*imgTemp )) > 0
                % There is overlap!
                
                cellIdList = 1:size(bw_stack_mask,3);
                for i3mask = size(bw_stack_mask,3):-1:1
                    if sum(sum( bw_stack_mask(:,:,i3mask).*imgTemp )) == 0
                        cellIdList(i3mask) = [];
                    end
                end
                
                if length(cellIdList) > 1
                    % This cell touches multiple masks
                    %   Find the centroid and see which mask it is in or
                    %   closest to
                    cc = regionprops(imgTemp,'Centroid');
                    if size(cc,1) == 1
                        x0 = round( cc(1).Centroid(1) ); % Round here because it won't get saved
                        y0 = round( cc(1).Centroid(2) );
                    else
                        fprintf('\n\n!! %s: Serious error at (badList) iImg %d!!\n\n',...
                            mfilename,iImg)
                    end
                    
                    cellIdList2 = cellIdList;
                    for iCellIdList2 = length(cellIdList2):-1:1
                        if bw_stack_mask(y0,x0,cellIdList2(iCellIdList2)) == 0
                            cellIdList2(iCellIdList2) = [];
                        end
                    end
                    
                    if ~isempty(cellIdList2)
                        if length(cellIdList2) > 1
                            fprintf('\n\n!! %s: Serious error at (badList) iImg %d!!\n',...
                                mfilename,iImg)
                            fprintf('\tOverlapping masks\n\n')
                            cellIdList = cellIdList(1);
                        else
                            cellIdList = cellIdList2;
                        end
                    else
                        % The center of the cell doesn't lie in either mask
                        %   Find largest match
                        for iCellIdList = length(cellIdList):-1:1
                            if iCellIdList == length(cellIdList)
                                sumOverlap =...
                                    sum(sum( bw_stack_mask(:,:,cellIdList(iCellIdList)).*...
                                    imgTemp ));
                                prevIdx = iCellIdList;
                            else
                                tempSumOverlap =...
                                    sum(sum( bw_stack_mask(:,:,cellIdList(iCellIdList)).*...
                                    imgTemp ));
                                if tempSumOverlap > sumOverlap
                                    sumOverLap = tempSumOverlap;
                                    cellIdList(prevIdx) = [];
                                    prevIdx = iCellIdList;
                                else
                                    cellIdList(iCellIdList) = [];
                                end
                            end
                        end
                    end
                    
                end
                cellID = cellIdList;
                
                
                
                % We found that there was overlap. cellID now tells us which is
                % the best matched overlap, if multiple.
                iCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
                iCell = iCell( stateYao.cellIdx{numCycle}{iImg}(:,1) == i3 );
                stateYao.cellIdx{numCycle}{iImg}(iCell,2) = cellID;
            end
            
        end
        
        
        
        % We may have multiple cells identified as one cell. These should be
        % merged.
        cellIdList = stateYao.cellIdx{numCycle}{iImg}(...
            stateYao.cellIdx{numCycle}{iImg}(:,2)~=0 ,2);
        
        if ~isempty( cellIdList )
            if size( unique(cellIdList) ,1) ~= size( cellIdList ,1)
                % Repeats! Need to merge these
                master_delIdx = [];
                master_saveBW = [];
                master_cellID = [];
                matched_cellID_unique = unique(cellIdList);
                matched_cellID = cat(2,...
                    [1:size(cellIdList,1)]',...
                    cellIdList,...
                    stateYao.cellIdx{numCycle}{iImg}(...
                    stateYao.cellIdx{numCycle}{iImg}(:,2)~=0 ,1) );
                for iUnique = 1:size( matched_cellID_unique ,1)
                    % Get indices
                    matched_idxList = [];
                    for iIdx = 1:size(matched_cellID,1)
                        if matched_cellID(iIdx,2) == matched_cellID_unique(iUnique)
                            idxCell = matched_cellID(iIdx,3);
                            if isempty(matched_idxList)
                                matched_idxList = idxCell;
                            else
                                matched_idxList = cat(1,matched_idxList,idxCell);
                            end
                        end
                    end
                    
                    % Is there more than 1 entry in this list?
                    if size( matched_idxList ,1) > 1
                        % Yes!  Merge these indices
                        bw = zeros(size1,size2);
                        for i3 = matched_idxList'
                            bw = bw +...
                                stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,i3);
                        end
                        bw = bw ~= 0;
                        
                        % Close gap between the cells
                        %   strel('disk',2) will close a gap <= 4
                        %   strel('disk',3) will close a gap <= 6
                        %   strel('disk',4) will close a gap <= 8
                        bw = imclose(bw,strel('disk',4));
                        
                        % Did this actually close the gap?
                        areMerged = 1;
                        cc = bwconncomp(bw);
                        if cc.NumObjects == 1
                            % Yes!
                            %   Proceed to next steps
                        else
                            % No!
                            areMerged = 0;
                            for d = 5:2:7
                                bw = imclose(bw,strel('disk',d));
                                cc = bwconncomp(bw);
                                if cc.NumObjects == 1
                                    areMerged = 1;
                                    break
                                end
                            end
                        end
                        
                        if areMerged
                            if isempty(master_delIdx)
                                master_delIdx = matched_idxList;
                                master_saveBW = bw;
                                master_cellID = matched_cellID_unique(iUnique);
                            else
                                master_delIdx = cat(1,...
                                    master_delIdx,...
                                    matched_idxList );
                                master_saveBW = cat(3,...
                                    master_saveBW,...
                                    bw );
                                master_cellID = cat(1,...
                                    master_cellID,...
                                    matched_cellID_unique(iUnique) );
                            end
                        end
                    end
                    
                end % for iUnique
                
                if ~isempty(master_delIdx)
                    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,...
                        master_delIdx) = [];
                    stateYao.cellIdx{numCycle}{iImg}(master_delIdx,:) = [];
                    if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
                        stateYao.images.I_cell_stack{numCycle}{iImg} =...
                            master_saveBW;
                        stateYao.cellIdx{numCycle}{iImg} = zeros(...
                            size(master_saveBW,3),...
                            6);
                    else
                        stateYao.images.I_cell_stack{numCycle}{iImg} =...
                            cat(3,stateYao.images.I_cell_stack{numCycle}{iImg},...
                            master_saveBW );
                        stateYao.cellIdx{numCycle}{iImg} = cat(1,...
                            stateYao.cellIdx{numCycle}{iImg},...
                            zeros( size(master_saveBW,3) ,6) );
                    end
                    
                    
                    
                    % Update cellIdx
                    %   Update previous entries that weren't deleted
                    %       Just need to update the indexing
                    if size( stateYao.cellIdx{numCycle}{iImg} ,1) > size(master_saveBW,3)
                        idxCellList = stateYao.cellIdx{numCycle}{iImg}(...
                            1:size(stateYao.cellIdx{numCycle}{iImg},1)-size(master_saveBW,3),1);
                        idxCellList = cat(2,idxCellList,[1:size(idxCellList,1)]');
                        idxCellList = sortrows(idxCellList,1);
                        stateYao.cellIdx{numCycle}{iImg}(...
                            1:size(stateYao.cellIdx{numCycle}{iImg},1)-size(master_saveBW,3),1) =...
                            idxCellList(:,2);
                    end
                    
                    %   Update new entries
                    for iCell = 1:size(master_saveBW,3)
                        idxCell = iCell +...
                            size(stateYao.cellIdx{numCycle}{iImg},1)-...
                            size(master_saveBW,3);
                        
                        cc = regionprops(...
                            stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell),...
                            'Centroid');
                        
                        x0 = cc(1).Centroid(1);
                        y0 = cc(1).Centroid(2);
                        
                        [theta,rho] = cart2pol(x0,y0);
                        
                        stateYao.cellIdx{numCycle}{iImg}(idxCell,:) =...
                            [idxCell master_cellID(iCell) rho rad2deg(theta) x0 y0];
                    end
                    
                end
                
            end
        end
        
        
        
    end
    
    
    
    
    clear size1 size2 iCell cellID idxCell iList iImg i3
    clear cellID2idxCell
    clear imgTemp
    clear x0 y0 rx ry
    clear cellIdList cellIdList2 iCellIdList iCellIdList2 i3mask
    clear sumOverlap tempSumOverlap prevIdx
    clear master_delIdx master_saveBW master_cellID master_cellID_unique
    clear iUnique matched_idxList iIdx bw i3 areMerged cc
    clear idxCellList theta rho
    
    
    
    
    
    
    
    
end % if ~isempty(badList)













%% Step 3: Identify remaining cells
% Previous Steps
%   Step 1: Initial index verification
%       Find initial list of good cells and good images
%   Step 2: Find good cells in remaining images
%       From our list of good cells, seek match in remaining images
%
% Current Process
%   Go through bad images and check for unidentified cells. Group these as
%   you come across them
%       Go through each image
%           Find any cells with cellID = 0
%           Record their centroid + imageShift
%       Now Group nearby centroids
%           Create mask for each group
%       Verify groups don't overlap
%       Go back to the image list and give appropriate cellIDs



grpRadius = 10;



% nextCellId = nCell_true+1;


if ~isempty(badList)
    % Some images in this list may no longer be "bad"
    count = 0;
    x0 = zeros( size(badList,1)*10 ,1);
    y0 = x0;
    iImg_AND_idxCell = zeros( size(x0,1) ,2);
    for iList = 1:size(badList,1)
        iImg = badList(iList,1);
        
        if any( stateYao.cellIdx{numCycle}{iImg}(:,2) == 0 )
            for iCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1)
                if stateYao.cellIdx{numCycle}{iImg}(iCell,2) == 0
                    count = count+1;
                    x0(count) = stateYao.cellIdx{numCycle}{iImg}(iCell,5)+...
                        stateYao.shift.second.imageShift{numCycle}(iImg,1);
                    y0(count) = stateYao.cellIdx{numCycle}{iImg}(iCell,6)+...
                        stateYao.shift.second.imageShift{numCycle}(iImg,2);
                    
                    iImg_AND_idxCell(count,:) = [iImg ...
                        stateYao.cellIdx{numCycle}{iImg}(iCell,1)];
                end
            end
        end
    end
    
    if count ~= 0
        
        
        
        x0y0 = cat(2,x0,y0);
        iImg_AND_idxCell = iImg_AND_idxCell( all(x0y0'~=0) ,:);
        x0y0 = x0y0( all(x0y0'~=0) ,:);
        x0 = x0y0(:,1);
        y0 = x0y0(:,2);
        clear x0y0
        
        
        
        size1 = size( stateYao.images.origData.projects{numCycle} ,1);
        size2 = size( stateYao.images.origData.projects{numCycle} ,2);
        tempImg = zeros(size1*3,size2*3);
        
        grpList = zeros( size(x0,1) ,1);
        grpList(1) = 1;
        grpX0 = x0(1);
        grpY0 = y0(1);
        grpCount = 1;
        grpMask = zeros(size1,size2);
        
        for iCentroid = 2:size(x0,1)
            
            iImg    = iImg_AND_idxCell(iCentroid,1);
            idxCell = iImg_AND_idxCell(iCentroid,2);
            
            rx = 1+size2+stateYao.shift.second.imageShift{numCycle}(iImg,1):...
                size2*2+stateYao.shift.second.imageShift{numCycle}(iImg,1);
            ry = 1+size1+stateYao.shift.second.imageShift{numCycle}(iImg,2):...
                size1*2+stateYao.shift.second.imageShift{numCycle}(iImg,2);
            tempImg(:,:) = zeros(size1*3,size2*3);
            tempImg(ry,rx) =...
                stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            
            foundGrp = 0;
            for iGrp = 1:size(grpX0,1)
                if hypot(...
                        x0(iCentroid)-grpX0(iGrp),...
                        y0(iCentroid)-grpY0(iGrp) ) <=...
                        grpRadius
                    
                    foundGrp = 1;
                    
                    grpList(iCentroid) = iGrp;
                    
                    f_grp = grpCount(iGrp)/(grpCount(iGrp)+1);
                    f_new = 1/(grpCount(iGrp)+1);
                    
                    grpX0(iGrp) = f_grp*grpX0(iGrp) + f_new*x0(iCentroid);
                    grpY0(iGrp) = f_grp*grpY0(iGrp) + f_new*y0(iCentroid);
                    
                    grpCount(iGrp) = grpCount(iGrp)+1;
                    
                    grpMask(:,:,iGrp) = grpMask(:,:,iGrp) +...
                        tempImg(1+size1:size1*2,1+size2:size2*2);
                    
                    break
                end
            end
            
            if ~foundGrp
                grpList(iCentroid) = size(grpX0,1)+1;
                
                grpX0 = cat(1,grpX0,x0(iCentroid));
                grpY0 = cat(1,grpY0,y0(iCentroid));
                
                grpCount = cat(1,grpCount,1);
                
                grpMask = cat(3,grpMask, tempImg(1+size1:size1*2,1+size2:size2*2) );
            end
            
        end
        for iGrp = 1:size(grpMask,3)
            grpMask(:,:,iGrp) = grpMask(:,:,iGrp) >= grpCount(iGrp)/3;
        end
        
        clear iList iImg iCell iCentroid foundGrp f_grp f_new
        clear tempImg
        
        
        
        
        
        if size(grpX0,1) == 1
            % Only one other cell found
            %   No need to check for overlapping
        else
            
            grpList = [1:size(grpX0,1)]';
            overlapList = [];
            for iGrp = 1:size(grpX0,1)
                
                temp_grpList = grpList;
                temp_grpList(iGrp) = [];
                
                if ~isempty(overlapList)
                    for iList = 1:size(overlapList,1)
                        if any( temp_grpList == overlapList(iList,1) )
                            iGrp2 = 1:size(temp_grpList,1);
                            iGrp2 = iGrp2( temp_grpList == overlapList(iList,1) );
                            temp_grpList(iGrp2) = [];
                        end
                    end
                end
                
                
                if ~isempty(temp_grpList)
                    
                    if size(temp_grpList,1) > 1 && size(temp_grpList,2) == 1 % Are there >1 row and only 1 column in temp_grpList?
                        temp_grpList = temp_grpList';
                    end
                    
                    for iGrp2 = temp_grpList
%                         disp('size iGrp');
%                         size(grpMask(:,:,iGrp))
%                         disp ('sum iGrp');
%                         sum(grpMask(:,:,iGrp))
%                         disp ('size iGrp2');
%                         size(grpMask(:,:,iGrp2))
                       % if sum(sum(grpMask(:,:,iGrp)))~=0 && sum(sum(grpMask(:,:,iGrp2)))~=0 % Yao added on 7/13/2015
                            if sum(sum(grpMask(:,:,iGrp).*grpMask(:,:,iGrp2))) ~= 0
                                % Overlap of (cell masks)!
                                if isempty(overlapList)
                                    overlapList = [iGrp iGrp2];
                                else
                                    
                                    % Does iGrp have other overlaps?
                                    if any( overlapList(:,1) == iGrp )
                                        iList = 1:size(overlapList,1);
                                        iList = iList( overlapList(:,1) == iGrp );
                                        if any( overlapList(iList,:) == 0 )
                                            iIdx = 1:size(overlapList,2);
                                            iIdx = iIdx( overlapList(iList,:) == 0 );
                                            iIdx = iIdx(1);
                                            overlapList(iList,iIdx) = iGrp2;
                                        else
                                            overlapList = cat(2,overlapList,...
                                                zeros(size(overlapList,1),1) );
                                            overlapList(iList,end) = iGrp2;
                                        end
                                    else
                                        overlapList = cat(1,overlapList,...
                                            zeros(1,size(overlapList,2)) );
                                        overlapList(end,[1 2]) = [iGrp iGrp2];
                                    end
                                    
                                end
                            end
                      %  end
                    end
                end
                
            end
            
            
            
            if ~isempty(overlapList)
                % Could have something like
                %   overlapList =
                %       1 2
                %       2 5
                %       3 4
                %
                % would need to combine rows 1 and 2
                
                if size(overlapList,1) == 1
                    % nothing to do right now, skip to next step
                else
                    for iList = size(overlapList,1):-1:2
                        
                        for iList2 = 1:iList-1
                            if any( overlapList(iList2,:) == overlapList(iList,1) )
                                % Match!
                                
                                addIndices = overlapList(iList,...
                                    overlapList(iList,:) ~= 0 &...
                                    overlapList(iList,:) ~= overlapList(iList,1) );
                                
                                overlapList(iList,:) = [];
                                
                                if any( overlapList(iList2,:) == 0 )
                                    iIdx = 1:size(overlapList,2);
                                    iIdx = iIdx( overlapList(iList2,:) == 0 );
                                    
                                    if size(iIdx,2) >= size(addIndices,2)
                                        iIdx = iIdx( 1:size(addIndices,2) );
                                    else
                                        iIdx = iIdx(1):iIdx(1)+size(addIndices,2)-1;
                                        overlapList = cat(2,overlapList,...
                                            zeros(...
                                            size(overlapList,1),...
                                            size(addIndices,2)-size(iIdx,2) ) );
                                    end
                                    overlapList(iList2,iIdx) = addIndices;
                                    
                                else
                                    overlapList = cat(2,overlapList,...
                                        zeros(...
                                        size(overlapList,1),...
                                        size(addIndices,2) ) );
                                    overlapList(iList2,end-size(addIndices,2)+1:end) =...
                                        addIndices;
                                end
                                
                                
                                
                                break
                                
                            end
                        end
                        
                    end
                    
                    
                    
                    % Remove repeats
                    for iList = 1:size(overlapList,1)
                        temp_overlapList = overlapList(iList,:);
                        unique_overlapList = unique(temp_overlapList);
                        unique_overlapList = unique_overlapList( unique_overlapList~= 0 );
                        temp_overlapList(1,:) = zeros(1,size(overlapList,2));
                        temp_overlapList(1,1:size(unique_overlapList,2)) =...
                            unique_overlapList;
                        overlapList(iList,:) = temp_overlapList(1,:);
                    end
                    
                end
                %   overlapList =
                %       1 2
                %       2 5
                %       3 4
                %
                %   would now be
                %   overlapList =
                %       1 2 5
                %       3 4 0
                
                
                
                % We're now ready merge groups
                %   Update grpList
                for iCentroid = 1:size(grpList,1)
                    % Only update grpList for those where the group # is found in
                    % overlapList in a column > 1
                    
                    if any(any( overlapList == grpList(iCentroid) )) &&...
                            ~any( overlapList(:,1) == grpList(iCentroid) )
                        % This group is overlapping with another group
                        
                        for iOverlapList = 1:size(overlapList,1)
                            if any( overlapList(iOverlapList,2:end) == grpList(iCentroid) )
                                % Found the overlap group
                                grpList(iCentroid) = overlapList(iOverlapList,1);
                                break
                            end
                        end
                        
                        
                    end
                    
                end
                
                
                
                % So now we would have groups 1 and 3
                % We want group 3 to become group 2
                unique_grpList = unique(grpList);
                unique_grpList = cat(2,unique_grpList,[1:size(unique_grpList,1)]');
                grpList_ConvTable = zeros( max(unique_grpList(:)) ,1);
                grpList_ConvTable(unique_grpList(:,1),1) = unique_grpList(:,2);
                
                grpList = grpList_ConvTable(grpList);
                
                clear unique_grpList grpList_ConvTable
                
            end % if ~isempty(overlapList)
        end
        
        
        
        grpList = grpList + nCell_true;
        
        
        identical_id_after_all = false(length(grpList));
        for iCentroid = 1:size(grpList,1)
            iImg    = iImg_AND_idxCell(iCentroid,1);
            idxCell = iImg_AND_idxCell(iCentroid,2);
            
            stateYao.cellIdx{numCycle}{iImg}(idxCell,2) = grpList(iCentroid);
            
            if stateYao.cellIdx{numCycle}{iImg}(idxCell,2) == ...
                    any(stateYao.cellIdx{numCycle}{iImg}(1:idxCell,2))
                identical_id_after_all(iCentroid) = true;
            end
        end
        
        % Xubo 102320: If cell ID conflict is not resolved by this point, remove the
        % second cell with the same ID. 
        for iCentroid = 1:size(grpList,1)
            iImg    = iImg_AND_idxCell(iCentroid,1);
            idxCell = iImg_AND_idxCell(iCentroid,2);
            
            if identical_id_after_all(iCentroid)
                stateYao.cellIdx{numCycle}{iImg}(idxCell, :) = [];
            end
        end
        
        
        
        
        
        clear overlapList iGrp iGrp2 temp_grpList iList iIdx iCentroid
        clear iImg idxCell
        clear x0 y0 grpList grpX0 grpY0 grpCount grpMask
        
        
        
    end % if count ~= 0    - check to make sure some cellIDs are 0
end % if ~isempty(badList)
