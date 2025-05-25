function Yao_findCells(numCycle)



global stateYao


str = sprintf('Isolating Cycle %d...',numCycle);
hdlProgIsolate = waitbar(0,str);

onesMatrix = ones(...
    size(stateYao.images.origData.projects{numCycle},1),...
    size(stateYao.images.origData.projects{numCycle},2) );
for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,numCycle) ~= 0
    
    if ishandle(hdlProgIsolate)
    waitbar(...
        iImg/size( stateYao.CyclePositions ,1),...
        hdlProgIsolate)
    drawnow
    end
    
    
    img_projects =...
        stateYao.images.origData.projects{numCycle}(:,:,iImg);
    
    val = Yao_calc_Photon(img_projects,onesMatrix );
    
    
% [iImg val stateYao.valPhoton_threshold]
    
    if val < stateYao.valPhoton_threshold % check photon counts for the whole image
        fprintf('%s: Total number of photons are below the set threshold \n',...
            mfilename)
        fprintf('\tImage %d, part of cycle %d\n',...
            stateYao.CyclePositions(iImg,numCycle),...
            numCycle )
        stateYao.ignoreImage(iImg,numCycle) = 1;
    else
        % Isolate cells
        
        img_rgbLifetimes =...
            stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg);
        
        [I_cell_stack] = Yao_isolateCell(...
            img_projects,img_rgbLifetimes,numCycle,iImg,...
            [stateYao.zoomFactor(numCycle) ...
            stateYao.cellPixelCount_threshold_b ...
            stateYao.cellPixelCount_threshold_m],...
            stateYao.nucleusOpt.valleyDetection(numCycle),...
            stateYao.nucleusOpt.borderThreshold(numCycle));
%         eval(sprintf('[%s] = %s(%s,%s,%s,%s,%s,%s,%s);',...
%             'I_cell_stack',...
%             stateYao.funcLink.isolateCell,...
%             'img_projects','img_rgbLifetimes','numCycle','iImg',...
%             sprintf('[%s,%s,%s]',...
%             'stateYao.zoomFactor(numCycle)',...
%             'stateYao.cellPixelCount_threshold_b',...
%             'stateYao.cellPixelCount_threshold_m'),...
%             'stateYao.nucleusOpt.valleyDetection(numCycle)',...
%             'stateYao.nucleusOpt.borderThreshold(numCycle)' ))
        
   
        
        if isempty(I_cell_stack)
            fprintf('%s: No cells found\n',...
                mfilename)
            fprintf('\tImage %d, part of cycle %d\n',...
                stateYao.CyclePositions(iImg,numCycle),...
                numCycle )
            stateYao.ignoreImage(iImg,numCycle) = 1;
            stateYao.images.I_cell_stack{numCycle}{iImg} = [];
            
            stateYao.cellIdx{numCycle}{iImg} = [];
        elseif sum(sum(sum(I_cell_stack))) == 0
            fprintf('%s: No cells found\n',...
                mfilename)
            fprintf('\tImage %d, part of cycle %d\n',...
                stateYao.CyclePositions(iImg,numCycle),...
                numCycle )
            stateYao.ignoreImage(iImg,numCycle) = 1;
            stateYao.images.I_cell_stack{numCycle}{iImg} = [];
            
            stateYao.cellIdx{numCycle}{iImg} = [];
        else
            % Double check that all empty layers are removed
            for i3 = size(I_cell_stack,3):-1:1
                if sum(sum( I_cell_stack(:,:,i3) )) == 0
                    I_cell_stack(:,:,i3) = [];
                end
            end
            
            
            
            stateYao.images.I_cell_stack{numCycle}{iImg} = I_cell_stack;
            stateYao.images.I_nucleus_stack{numCycle}{iImg} =...
                zeros( size(I_cell_stack,1),size(I_cell_stack,2),...
                size(I_cell_stack,3) );
            stateYao.images.I_cytoplasm_stack{numCycle}{iImg} =...
                zeros( size(I_cell_stack,1),size(I_cell_stack,2),...
                size(I_cell_stack,3) );
            stateYao.images.I_buffer_stack{numCycle}{iImg} =...
                zeros( size(I_cell_stack,1),size(I_cell_stack,2),...
                size(I_cell_stack,3) );
            stateYao.ellipseParameters{numCycle}{iImg} =...
                zeros( size(I_cell_stack,3) ,5);
            
            
            
            stateYao.cellIdx{numCycle}{iImg} = zeros(size(I_cell_stack,3),6);
        end
        
    end
    
end
end

if ishandle(hdlProgIsolate)
close(hdlProgIsolate)
drawnow
end



clear hdlProgIsolate str 
clear iImg img_projects val onesMatrix img_rgbLifetimes I_cell_stack i3




if all(stateYao.ignoreImage(:,numCycle)==1)
    fprintf('all images have total photon counts below set threshold %d\n', numCycle)
else






%% Find shift again
hdlProgShift = waitbar(0,'Finding shift...');

img_mask = stateYao.images.origData.projects{numCycle}(:,:,...
    stateYao.shift.initial.iImg_mask(numCycle) );



bw_stack_mask = stateYao.images.I_cell_stack{numCycle}{...
    stateYao.shift.initial.iImg_mask(numCycle)};

if isempty(bw_stack_mask)
    % Find new iImg_mask
    
    valPhoton = zeros( size( stateYao.CyclePositions ,1) ,1);
    onesMatrix = ones(...
        size(stateYao.images.origData.projects{numCycle},1),...
        size(stateYao.images.origData.projects{numCycle},2) );
    
    iImg_haveData = 1:size( stateYao.CyclePositions ,1);
    for iImg = size( stateYao.CyclePositions ,1):-1:1
        if isempty(stateYao.images.I_cell_stack{numCycle}{iImg})
            iImg_haveData(iImg) = [];
        end
    end
    
    for iImg = iImg_haveData
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        valPhoton(iImg) = Yao_calc_Photon(...
            stateYao.images.origData.projects{numCycle}(:,:,iImg),...
            onesMatrix);
    end
    end
    
    targetVal = mean( valPhoton( valPhoton~=0 ) );
    valPhoton = abs( targetVal - valPhoton );
    [min_val min_idx] = min(valPhoton);
    
    stateYao.shift.initial.iImg_mask(numCycle) = min_idx;
    bw_stack_mask = stateYao.images.I_cell_stack{numCycle}{...
    stateYao.shift.initial.iImg_mask(numCycle)};
end


bw_mask = zeros( size(bw_stack_mask,1),size(bw_stack_mask,2) );
for i3 = 1:size(bw_stack_mask,3)
    bw_mask = bw_mask + bw_stack_mask(:,:,i3);
end
bw_mask = bw_mask ~= 0; % bw_mask is now converted to 1s and 0s.

% size(img_mask)
% size(bw_mask)

% if isempty(bw_mask)
%     % skip operation
%     img_mask_Cleaned = img_mask;
% else
%     img_mask_Cleaned = img_mask.*bw_mask;
% end

img_mask_Cleaned = img_mask.*bw_mask;



for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,numCycle) ~= 0
if iImg ~= stateYao.shift.initial.iImg_mask(numCycle)
if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
    fprintf('%s: No cell isolated for iImg = %d\n',...
        mfilename,iImg)
else
    
    
    if ishandle(hdlProgShift)
    waitbar(...
        iImg/size( stateYao.CyclePositions ,1),...
        hdlProgShift)
    drawnow
    end
    
    
    
    img =...
        stateYao.images.origData.projects{numCycle}(:,:,iImg);
    
    
    img_Cleaned = zeros( size(img,1),size(img,2) );
    if ~isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
        bw_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
        bw = zeros( size(bw_stack,1),size(bw_stack,2) );
        for i3 = 1:size(bw_stack,3)
            bw = bw + bw_stack(:,:,i3);
        end
        bw = bw ~= 0;
        
        img_Cleaned = img.*bw;
    end
    
    
    cc = normxcorr2(...
        img,...
        img_mask );
    [max_cc, imax] = max(abs(cc(:)));
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    corr_offset = [ (ypeak-size( img ,1)) ...
        (xpeak-size( img ,2)) ];
    
    if ~isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
        cc = normxcorr2(...
            img_Cleaned,...
            img_mask_Cleaned );
        [max_cc, imax] = max(abs(cc(:)));
        [ypeak, xpeak] = ind2sub(size(cc),imax(1));
        corr_offset_Cleaned = [ (ypeak-size( img ,1)) ...
            (xpeak-size( img ,2)) ];
    end
    
    
    
    if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
        stateYao.shift.second.imageShift{numCycle}(iImg,:) =...
                round([corr_offset(2) corr_offset(1)]);
    else
        d = hypot( corr_offset(1) , corr_offset(2) );
        
        d_Cleaned = hypot( corr_offset_Cleaned(1) , corr_offset_Cleaned(2) );
        
        
        if d <= d_Cleaned
            stateYao.shift.second.imageShift{numCycle}(iImg,:) =...
                round([corr_offset(2) corr_offset(1)]);
        else
            stateYao.shift.second.imageShift{numCycle}(iImg,:) =...
                round([corr_offset_Cleaned(2) corr_offset_Cleaned(1)]);
        end
    end
    
end
end
end
end

if ishandle(hdlProgShift)
close(hdlProgShift)
drawnow
end

clear hdlProgShift
clear iImg img bw_stack bw cc max_cc imax ypeak xpeak corr_offset






%% Initial clean-up - Part 1
% Try to find how many cells there should be. Browse image list for images
% with more cells. Check to see if any of these cells can be merged.

% How many cells do we have?
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
% if mean(nCellList( nCellList(:,2)~=0 ,2)) -...
%         floor( mean(nCellList( nCellList(:,2)~=0 ,2)) ) < 0.25
%     nCell_true = floor( mean(nCellList( nCellList(:,2)~=0 ,2)) );
% else
%     nCell_true = ceil( mean(nCellList( nCellList(:,2)~=0 ,2)) );
% end



fprintf('\n\n\n%s: Cycle %d is believed to have predominately %d cells \n\n\n',...
    mfilename,numCycle,nCell_true);

[mfilename ' 1']

% Try to find mask from images with (maybe) correct number of cells
goodList = nCellList( nCellList(:,2) == nCell_true ,1);
%   Use photon count again
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

% Get image shift
imageShift = [...
    stateYao.shift.second.imageShift{numCycle}(:,1)-...
    stateYao.shift.second.imageShift{numCycle}(iImg_mask,1) ....
    stateYao.shift.second.imageShift{numCycle}(:,2)-...
    stateYao.shift.second.imageShift{numCycle}(iImg_mask,2)];
imageShift( stateYao.CyclePositions(:,numCycle) == 0 ,:) = 0;

clear valPhoton onesMatrix iList iImg max_val max_idx






% For images with more cells, see if any can be merged based on mask
if any( nCellList(:,2) > nCell_true )
badList = nCellList( nCellList(:,2) > nCell_true ,1);
I_cell_stack_mask = stateYao.images.I_cell_stack{numCycle}{iImg_mask};
for iList = 1:size(badList,1)
    iImg = badList(iList,1);
    
    I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
    
    x0 = zeros( size(I_cell_stack,3) ,1);
    y0 = x0;
    for i3 = 1:size(I_cell_stack,3)
        cc = regionprops( I_cell_stack(:,:,i3) ,'Centroid');
        
        if size(cc,1) == 1
            x0(i3) = cc(1).Centroid(1);
            y0(i3) = cc(1).Centroid(2);
        else
            fprintf('\n\n!! %s: Serious error at iImg %d!!\n\n',...
                mfilename,iImg)
        end
    end
    
    x0 = round( x0+ imageShift(iImg,1) );
    y0 = round( y0+ imageShift(iImg,2) );
    
    
    
    matched_idxCell = zeros( size(I_cell_stack,3) ,1);
    for i3 = 1:size(I_cell_stack,3)
        
        if ~any([...
                x0(i3) < 1 ...
                x0(i3) > size(I_cell_stack,2) ...
                y0(i3) < 1 ...
                y0(i3) > size(I_cell_stack,1)])
            
            for idxCell = 1:size( I_cell_stack_mask ,3)
                if I_cell_stack_mask( y0(i3),x0(i3) ,idxCell)
                    matched_idxCell(i3) = idxCell;
                    break
                end
            end
            
        end
        
    end
    
    if isempty( matched_idxCell(matched_idxCell~=0) )
        fprintf('\n\n!! %s: Shift error at badList (>nCell_true) iImg %d!!\n\n',...
            mfilename,iImg)
    else
        if size( unique(matched_idxCell(matched_idxCell~=0)) ,1) ~=...
                size( matched_idxCell(matched_idxCell~=0) ,1)
            % There's a repeat
            master_delIdx = [];
            master_saveBW = [];
            matched_idxCell_unique = unique(matched_idxCell);
            matched_idxCell = cat(2,[1:size(matched_idxCell,1)]',matched_idxCell);
            for iUnique = 1:size( matched_idxCell_unique ,1)
                % Get indices
                matched_idxList = [];
                for iIdx = 1:size(matched_idxCell,1)
                    if matched_idxCell(iIdx,2) == matched_idxCell_unique(iUnique)
                        if isempty(matched_idxList)
                            matched_idxList = iIdx;
                        else
                            matched_idxList = cat(1,matched_idxList,iIdx);
                        end
                    end
                end
                
                % Is there more than 1 entry in this list?
                if size( matched_idxList ,1) > 1
                    bw = zeros( size(I_cell_stack,1),size(I_cell_stack,2) );
                    for i3 = matched_idxList'
                        bw = bw + I_cell_stack(:,:,i3);
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
                        else
                            master_delIdx = cat(1,...
                                master_delIdx,...
                                matched_idxList );
                            master_saveBW = cat(3,...
                                master_saveBW,...
                                bw );
                        end
                    end
                    
                end
                
            end
            
            
            
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
                
            end
            
            
        end
    end
    
end
end






% How many cells do we have NOW?
nCell_true_PREV = nCell_true;
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
% if mean(nCellList( nCellList(:,2)~=0 ,2)) -...
%         floor( mean(nCellList( nCellList(:,2)~=0 ,2)) ) < 0.25
%     nCell_true = floor( mean(nCellList( nCellList(:,2)~=0 ,2)) );
% else
%     nCell_true = ceil( mean(nCellList( nCellList(:,2)~=0 ,2)) );
% end





while nCell_true ~= nCell_true_PREV
%     fprintf('\n\n\n%s: iCycle %d is NOW believed to have predominately %d cells \n\n\n',...
%         mfilename,iCycle,nCell_true);
     fprintf('\n\n\n%s: Cycle %d is NOW believed to have predominately %d cells \n\n\n',...
        mfilename,numCycle,nCell_true);
    
    
    
    
    
    
    
    
    
    % For images with more cells, see if any can be merged based on mask
    if any( nCellList(:,2) > nCell_true )
        badList = nCellList( nCellList(:,2) > nCell_true ,1);
        I_cell_stack_mask = stateYao.images.I_cell_stack{numCycle}{iImg_mask};
        for iList = 1:size(badList,1)
            iImg = badList(iList,1);
            
            I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
            
            x0 = zeros( size(I_cell_stack,3) ,1);
            y0 = x0;
            for i3 = 1:size(I_cell_stack,3)
                cc = regionprops( I_cell_stack(:,:,i3) ,'Centroid');
                
                if size(cc,1) == 1
                    x0(i3) = cc(1).Centroid(1);
                    y0(i3) = cc(1).Centroid(2);
                else
                    fprintf('\n\n!! %s: Serious error at iImg %d!!\n\n',...
                        mfilename,iImg)
                end
            end
            
            x0 = round( x0+ imageShift(iImg,1) );
            y0 = round( y0+ imageShift(iImg,2) );
            
            
            
            matched_idxCell = zeros( size(I_cell_stack,3) ,1);
            for i3 = 1:size(I_cell_stack,3)
                
                for idxCell = 1:size( I_cell_stack_mask ,3)
                    if I_cell_stack_mask( y0(i3),x0(i3) ,idxCell)
                        matched_idxCell(i3) = idxCell;
                        break
                    end
                end
                
            end
            
            if isempty( matched_idxCell(matched_idxCell~=0) )
                fprintf('\n\n!! %s: Shift error at badList (>nCell_true) iImg %d!!\n\n',...
                    mfilename,iImg)
            else
                if size( unique(matched_idxCell(matched_idxCell~=0)) ,1) ~=...
                        size( matched_idxCell(matched_idxCell~=0) ,1)
                    % There's a repeat
                    master_delIdx = [];
                    master_saveBW = [];
                    matched_idxCell_unique = unique(matched_idxCell);
                    matched_idxCell = cat(2,[1:size(matched_idxCell,1)]',matched_idxCell);
                    for iUnique = 1:size( matched_idxCell_unique ,1)
                        % Get indices
                        matched_idxList = [];
                        for iIdx = 1:size(matched_idxCell,1)
                            if matched_idxCell(iIdx,2) == matched_idxCell_unique(iUnique)
                                if isempty(matched_idxList)
                                    matched_idxList = iIdx;
                                else
                                    matched_idxList = cat(1,matched_idxList,iIdx);
                                end
                            end
                        end
                        
                        % Is there more than 1 entry in this list?
                        if size( matched_idxList ,1) > 1
                            bw = zeros( size(I_cell_stack,1),size(I_cell_stack,2) );
                            for i3 = matched_idxList'
                                bw = bw + I_cell_stack(:,:,i3);
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
                                else
                                    master_delIdx = cat(1,...
                                        master_delIdx,...
                                        matched_idxList );
                                    master_saveBW = cat(3,...
                                        master_saveBW,...
                                        bw );
                                end
                            end
                            
                        end
                        
                    end
                    
                    
                    
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
                        
                    end
                    
                    
                end
            end
            
        end
    end
    
    
    
    
    [mfilename ' 2']
    
    
    
    
    
    
    % How many cells do we have NOW?
    nCell_true_PREV = nCell_true;
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
%     if mean(nCellList( nCellList(:,2)~=0 ,2)) -...
%             floor( mean(nCellList( nCellList(:,2)~=0 ,2)) ) < 0.25
%         nCell_true = floor( mean(nCellList( nCellList(:,2)~=0 ,2)) );
%     else
%         nCell_true = ceil( mean(nCellList( nCellList(:,2)~=0 ,2)) );
%     end
end

clear iList iImg i3 d iIdx
clear I_cell_stack bw
clear x0 y0 cc
clear matched_idxCell matched_idxCell_unique idxCell
clear master_delIdx master_saveBW 
clear areMerged

clear img_mask bw_stack_mask bw_mask





[mfilename ' 3']

%% Initial clean-up - Part 2
% For images with fewer cells, see if any can be split
if any( nCellList(:,2) < nCell_true )
badList = nCellList( nCellList(:,2) < nCell_true ,1);
I_cell_stack_mask = stateYao.images.I_cell_stack{numCycle}{iImg_mask};
size1 = size( stateYao.images.origData.projects{numCycle} ,1);
size2 = size( stateYao.images.origData.projects{numCycle} ,2);
imgTemp = zeros(size1*3,size2*3);
for iList = 1:size(badList,1)
    iImg = badList(iList,1);
    
    I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
    
    i3DelList = [];
    stack_newImages = [];
    
    for i3 = 1:size(I_cell_stack,3)
        
        rx = 1+size2+imageShift(iImg,1):...
            size2*2+imageShift(iImg,1);
        ry = 1+size1+imageShift(iImg,2):...
            size1*2+imageShift(iImg,2);
        
        imgTemp(:,:) = zeros(size1*3,size2*3);
        imgTemp(ry,rx) = I_cell_stack(:,:,i3);
        
        bw = imgTemp(1+size1:size1*2,1+size2:size2*2);
        
        match_idxList = [];
        for i3mask = 1:size(I_cell_stack_mask,3)
            if sum(sum( I_cell_stack_mask(:,:,i3mask).*bw )) >...
                    sum(sum(bw))/20
                if isempty(match_idxList)
                    match_idxList = i3mask;
                else
                    match_idxList = cat(1,match_idxList,i3mask);
                end
            end
        end
        
        if ~isempty(match_idxList)
        if size(match_idxList,1) > 1
            % Split!
            %   Find the empty space between the masks
            tempMask = zeros(size1,size2);
            for i3mask = match_idxList'
                tempMask = tempMask + I_cell_stack_mask(:,:,i3mask);
            end
            tempMask = tempMask~=0;
            
            
            % Use bwdist on tempMask to get minimums. Apply to bw in order
            % to get separation between cells.
% % %             figure;
% % %             subplot(2,2,1), imshowpair(bw,tempMask,'blend')
            
            D = -bwdist(~tempMask);
            
% % %             subplot(2,2,2), imshow(D,[])
% % %             subplot(2,2,3), imshowpair(bw,~D,'blend')
            
            isSeparated = 0;
            for iH = [0.01 0.1 0.25 0.5 0.75 1 1.5 2]
                mask = imextendedmin(D,iH);
                D2 = imimposemin(D,mask);
                Ld = watershed(D2);
                bw2 = bw;
                bw2(Ld == 0) = 0;
                
% % %                 subplot(2,2,4), imshow(bw2)
                
                cc = bwconncomp(bw2);
                if cc.NumObjects > 1
                    % Success!
                    isSeparated = 1;
                    bw = bw2;
                    break
                end
            end
            
            if isSeparated
                
                if isempty(i3DelList)
                    i3DelList = i3;
                else
                    i3DelList = cat(1,i3DelList,i3);
                end
                
                
                cellPixelCount_threshold =...
                    stateYao.cellPixelCount_threshold_m*...
                    stateYao.zoomFactor +...
                    stateYao.cellPixelCount_threshold_b;
                for iCC = 1:cc.NumObjects
                if size( cc.PixelIdxList{1,iCC} ,1) >...
                        cellPixelCount_threshold
                    
                    % Convert pixel indicies to coordinates, then apply
                    % imageShift
                    %   We used +imageShift earlier, so now we need
                    %   -imageShift
                    
                    
                    pixelList = [...
                        ceil(cc.PixelIdxList{1,iCC}/cc.ImageSize(2)) ...
                        mod(cc.PixelIdxList{1,iCC},cc.ImageSize(1))];
                    pixelList( pixelList(:,2) == 0 ,2) = cc.ImageSize(1);
                    
                    pixelList(:,1) = pixelList(:,1)-imageShift(iImg,1);
                    pixelList(:,2) = pixelList(:,2)-imageShift(iImg,2);
                    
                    imgTemp2 = zeros(size1,size2);
                    for iPixel = 1:size(pixelList,1)
                        imgTemp2(pixelList(iPixel,2),pixelList(iPixel,1)) = 1;
                    end
                    
                    if isempty(stack_newImages)
                        stack_newImages = imgTemp2;
                    else
                        stack_newImages = cat(3,stack_newImages,imgTemp2);
                    end
                    
                end
                end
                
            end
            
        end
        end
        
    end
    
    
    
    if ~isempty(i3DelList)
        stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,i3DelList) = [];
        stateYao.cellIdx{numCycle}{iImg}(i3DelList,:) = [];
        
        if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
            stateYao.images.I_cell_stack{numCycle}{iImg} = stack_newImages;
            stateYao.cellIdx{numCycle}{iImg} =...
                zeros( size(stack_newImages,3) ,6);
        else
            stateYao.images.I_cell_stack{numCycle}{iImg} = cat(3,...
                stateYao.images.I_cell_stack{numCycle}{iImg},...
                stack_newImages);
            stateYao.cellIdx{numCycle}{iImg} = cat(1,...
                stateYao.cellIdx{numCycle}{iImg},...
                zeros( size(stack_newImages,3) ,6) );
        end
        
    end
    
end




clear badList iList iImg i3 i3mask rx ry
clear I_cell_stack_mask I_cell_stack size1 size2
clear i3DelList stack_newImages isSeparated
clear imgTemp imgTemp2 bw bw2 cc pixelList
clear D D2 iH mask Ld tempMask

end


[mfilename ' 4']



%% Apply masks
% Can we apply masks to any image?
%   Get an updated list of the images with fewer cells
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



if any( nCellList(:,2) < nCell_true )
badList = nCellList( nCellList(:,2) < nCell_true ,1);
I_cell_stack_mask = stateYao.images.I_cell_stack{numCycle}{iImg_mask};
size1 = size( stateYao.images.origData.projects{numCycle} ,1);
size2 = size( stateYao.images.origData.projects{numCycle} ,2);
imgTemp  = zeros(size1*3,size2*3);
imgTemp2 = zeros(size1,size2);
onesMatrix = ones(size1,size2);
for iList = 1:size(badList,1)
    iImg = badList(iList,1);
    
    I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
    
    rx = 1+size2+imageShift(iImg,1):...
        size2*2+imageShift(iImg,1);
    ry = 1+size1+imageShift(iImg,2):...
        size1*2+imageShift(iImg,2);
    
    imgTemp(:,:)  = zeros(size1*3,size2*3);
    imgTemp2(:,:) = zeros(size1,size2);
    for i3 = 1:size(I_cell_stack,3)
        imgTemp(ry,rx) = I_cell_stack(:,:,i3);
        
        imgTemp2(:,:) = imgTemp2 +...
            imgTemp(1+size1:size1*2,1+size2:size2*2); % b/w images of all cells.
    end
    
    
    
    
    stack_newImages = [];
    rx = 1+size2-imageShift(iImg,1):...
        size2*2-imageShift(iImg,1);
    ry = 1+size1-imageShift(iImg,2):...
        size1*2-imageShift(iImg,2);
    for i3mask = 1:size(I_cell_stack_mask,3)
        if sum(sum( imgTemp2.*I_cell_stack_mask(:,:,i3mask) )) <=...
                sum(sum( I_cell_stack_mask(:,:,i3mask) ))/20
            
            imgTemp(:,:) = zeros(size1*3,size2*3);
            imgTemp(ry,rx) = I_cell_stack_mask(:,:,i3mask);
            
            % Verify 
            val = Yao_calc_Photon(...
                stateYao.images.origData.projects{numCycle}(:,:,iImg).*...
                imgTemp(1+size1:size1*2,1+size2:size2*2),...
                onesMatrix );
            if val >= stateYao.valPhoton_threshold
                if isempty(stack_newImages)
                    stack_newImages = imgTemp(1+size1:size1*2,1+size2:size2*2);
                else
                    stack_newImages = cat(3,stack_newImages,...
                        imgTemp(1+size1:size1*2,1+size2:size2*2) );
                end
            end
            
        end
    end
    
    if ~isempty(stack_newImages)
        stateYao.images.I_cell_stack{numCycle}{iImg} = cat(3,...
            stateYao.images.I_cell_stack{numCycle}{iImg},...
            stack_newImages );
        
        stateYao.cellIdx{numCycle}{iImg} = cat(1,...
            stateYao.cellIdx{numCycle}{iImg},...
            zeros( size(stack_newImages,3) ,6) );
    end
    
    
    
end

clear badList I_cell_stack_mask
clear size1 size2 imgTemp
clear iList iImg
clear onesMatrix

end










%% Get cell indexing
Yao_identify_cellIndex(numCycle)




%% Initial try at removing border cells
Yao_removeBorderCell_initial(numCycle)






%% Final clean-up of individual cells
if stateYao.nucleusOpt.checkAppendages(numCycle)
Yao_removeAppendages(numCycle)
end







%% Update which cells will get which findNucleus function
for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,numCycle) ~= 0
if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
    
    findNucleus_func = stateYao.funcLink.findNucleus_func_default;
    
    for iCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1)
        idxCell = stateYao.cellIdx{numCycle}{iImg}(iCell,1);
        stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} =...
            findNucleus_func;
        
        stateYao.colorNucleus{numCycle}{iImg}{idxCell} =...
                stateYao.CycleIdentification{numCycle,2};
    end
    
end
end
end



%% Anything else to update?

% mask variables
%       stateYao.images.mask.I_mask
%       stateYao.images.mask.img_mask
%       stateYao.mask.ellipseParameters
%   How many cells do we have?
nCell = 0;
for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,numCycle) ~= 0
if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
    nCell = max([nCell max( stateYao.cellIdx{numCycle}{iImg}(:,2) ) ]);
end
end
end
stateYao.images.mask.I_mask{numCycle} = zeros(...
    size( stateYao.images.origData.projects{numCycle} ,1),...
    size( stateYao.images.origData.projects{numCycle} ,2),...
    nCell);
stateYao.images.mask.img_mask{numCycle} =...
    stateYao.images.mask.I_mask{numCycle};
stateYao.mask.ellipseParameters{numCycle} = zeros(nCell,5);
end
[mfilename ' 5']