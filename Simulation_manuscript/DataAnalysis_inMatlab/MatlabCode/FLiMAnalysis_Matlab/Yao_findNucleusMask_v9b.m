function Yao_findNucleusMask_v9b(numCycle,iImg,cellIdList)

global stateYao

str = sprintf('Finding Mask for Cycle %d...',numCycle);
hdlProgFindMask = waitbar(0,str);




forceMask = 1;
if ~exist('iImg','var')
    iImg = [];
end
if isempty(iImg)
    forceMask = 0;
    iImg = 1:size( stateYao.CyclePositions ,1);
end
iImgList = iImg;

nCell = 0;
for iImg = 1:size( stateYao.CyclePositions ,1)
if stateYao.CyclePositions(iImg,stateYao.numCycle(numCycle)) ~= 0
if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
    nCell = max(nCell, max( stateYao.cellIdx{numCycle}{iImg}(:,2) ) );
end
end
end
% for iImg = 1:size(stateYao.CyclePositions,1)
% if stateYao.CyclePositions(iImg,stateYao.numCycle(iCycle)) ~= 0
%     if stateYao.ignoreImage(iImg,stateYao.numCycle(iCycle)) == 0
%         nCell = max([nCell size(stateYao.images.I_cell_stack{iCycle}{iImg},3)]);
%     end
% end
% end
if ~exist('cellIdList','var')
    cellIdList = 1:nCell;
else
    if size(cellIdList,1) > 1
        cellIdList = cellIdList';
    end
end



applyMask = 1;
if ~forceMask
% Check to see if a mask needs to be applied to any of the images
applyMask = 0;
userInput = 0;
for i_iImgList = 1:length(iImgList)
    iImg = iImgList(i_iImgList);
    if any( stateYao.applyMask{numCycle}{iImg} )
        for cellID = cellIdList
            
        idxCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1);
        idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
        idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
        
        if length(stateYao.applyMask{numCycle}{iImg}) >= idxCell
        if any( stateYao.applyMask{numCycle}{iImg}(idxCell) )
            applyMask = 1;
            break
        end
        end
        end
    end
    
    if applyMask
        break
    end
    
end
end



% disp('Forcing applyMask = 1')
% applyMask = 1;
if applyMask
    size1 = [];
    size2 = [];
    for iImg = 1:size(stateYao.CyclePositions,1)
        if stateYao.CyclePositions(iImg,numCycle) ~= 0
        if stateYao.ignoreImage(iImg,numCycle) == 0
            size1 = size(stateYao.images.I_cell_stack{numCycle}{iImg},1);
            size2 = size(stateYao.images.I_cell_stack{numCycle}{iImg},2);
            break
        end
        end
    end
    
    
    
    % Prepare mask variables
    mask_I_cell = zeros(size1,size2,nCell);
    mask_ellipseParameters = zeros(5,nCell);
    
    
    
    % Get masks
    haveMask = zeros( max(cellIdList) ,1);
    idxCreateMask = cell( max(cellIdList) ,1);
    userInput = 0;
    for cellID = cellIdList
        
        for checkThres = [3 2 1]
            for iImg = 1:size(stateYao.CyclePositions,1)
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
            if stateYao.ignoreImage(iImg,numCycle) == 0
                
                if any( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID )
                    idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
                    idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
                    idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
                    
                    if ~stateYao.applyMask{numCycle}{iImg}(idxCell)
                        if stateYao.check.type1{numCycle}{iImg}{idxCell,1} == 1
                        if stateYao.check.type1{numCycle}{iImg}{idxCell,2} == checkThres
                            
                            if isempty(idxCreateMask{cellID})
                                idxCreateMask{cellID} = iImg;
                            else
                                idxCreateMask{cellID} = cat(1,idxCreateMask{cellID},iImg);
                            end
                            
                        end
                        end
                        
                    end
                    
                end
                
            end
            end
            end
            
            if ~isempty( idxCreateMask{cellID} )
                break
            end
            
        end
        
%         % Try with checks == 3
%         checkThres = 3;
%         for iImg = 1:size(stateYao.CyclePositions,1)
%         if stateYao.CyclePositions(iImg,stateYao.numCycle(iCycle)) ~= 0
%         if stateYao.ignoreImage(iImg,stateYao.numCycle(iCycle)) == 0
%             
%             if any( stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell )
%             idxCell = 1:size( stateYao.cellIdx{iCycle}{iImg} ,1);
%             idxCell = idxCell( stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell );
%             idxCell = stateYao.cellIdx{iCycle}{iImg}(idxCell,1);
%             
%             if ~stateYao.applyMask{iCycle}{iImg}(idxCell)
%                 
%                 if stateYao.check.type1{iCycle}{iImg}{idxCell,2} == checkThres
%                     
%                     if isempty(idxCreateMask{iCell})
%                         idxCreateMask{iCell} = iImg;
%                     else
%                         idxCreateMask{iCell} = cat(1,idxCreateMask{iCell},iImg);
%                     end
%                     
%                 end
%                 
%             end
%             
%             end
%             
%         end
%         end
%         end
%         
%         
%         
%         % If we didn't find any mask, try with checks == 2
%         if isempty(idxCreateMask{iCell})
%         % Try with checks == 2
%         checkThres = 2;
%         for iImg = 1:size(stateYao.CyclePositions,1)
%         if stateYao.CyclePositions(iImg,stateYao.numCycle(iCycle)) ~= 0
%         if stateYao.ignoreImage(iImg,stateYao.numCycle(iCycle)) == 0
%             
%             if any( stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell )
%             idxCell = 1:size( stateYao.cellIdx{iCycle}{iImg} ,1);
%             idxCell = idxCell( stateYao.cellIdx{iCycle}{iImg}(:,2) == iCell );
%             idxCell = stateYao.cellIdx{iCycle}{iImg}(idxCell,1);
%             
%             if ~stateYao.applyMask{iCycle}{iImg}(idxCell)
%                 
%                 if stateYao.check.type1{iCycle}{iImg}{idxCell,2} == checkThres
%                     
%                     if isempty(idxCreateMask{iCell})
%                         idxCreateMask{iCell} = iImg;
%                     else
%                         idxCreateMask{iCell} = cat(1,idxCreateMask{iCell},iImg);
%                     end
%                     
%                 end
%                 
%             end
%             
%             end
%             
%         end
%         end
%         end
%         end
        
        
        
        % If we didn't find any mask, need user input
        if isempty(idxCreateMask{cellID})
            userInput = 1;
        end
        
        
        
    end
    
    
    
    if ishandle(hdlProgFindMask)
    waitbar(...
        1/4,...
        hdlProgFindMask)
    drawnow
    end
    
    
    
    % If any cell didn't find a mask, have user create one
    if userInput
        for cellID = cellIdList
        if isempty(idxCreateMask{cellID})
            
            stateYao.temp.I_search = [];
            for iImg = 1:size( stateYao.applyMask{numCycle} ,1)
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
            if stateYao.ignoreImage(iImg,numCycle) == 0
                
                if any( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID )
                    idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
                    idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
                    idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
                    
                    
                    % Isolate cell of interest
                    img = stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg);
                    I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
                    
                    for i3 = 1:size(img,3)
                        img(:,:,i3) = img(:,:,i3).*I_cell;
                    end
                    
                    hFig = figure;
                    set(hFig,'Name','Select >= 5 points. Close window when done')
                    imshow( img )
                    truesize(gcf,[300 300])
                    hAxis = gca;
                    Yao_run_nucleus_UserSelection_v4(hFig,hAxis,I_cell);
                    uiwait(hFig)
                    drawnow
                    
                    
                    
                    if ~isempty( stateYao.temp.I_search ) &&...
                            ~isempty(stateYao.temp.ellipseParameters)
                        
                        stateYao.images.mask.I_mask{numCycle}(:,:,cellID) =...
                            I_cell;
                        stateYao.images.mask.img_mask{numCycle}(:,:,cellID) =...
                            stateYao.images.origData.projects{numCycle}(:,:,iImg).*...
                            I_cell;
                        stateYao.mask.ellipseParameters{numCycle}(cellID,:) =...
                            stateYao.temp.ellipseParameters';
                        
                        break
                    end
                    
                end
                
            end
            end
            
            end
        end
        end
        
    end
    
    
    
    
    if ishandle(hdlProgFindMask)
    waitbar(...
        2/4,...
        hdlProgFindMask)
    drawnow
    end
    
    
    
    
    % What if there are multiple masks available?
    for cellID = cellIdList
    if ~isempty( idxCreateMask{cellID} )
        
        tempList = idxCreateMask{cellID};
        temp__I_mask = zeros(...
            size( stateYao.images.I_cell_stack{numCycle}{ tempList(1) } ,1),...
            size( stateYao.images.I_cell_stack{numCycle}{ tempList(1) } ,2),...
            size(tempList,1) );
        temp__img_mask = zeros(...
            size( stateYao.images.I_cell_stack{numCycle}{ tempList(1) } ,1),...
            size( stateYao.images.I_cell_stack{numCycle}{ tempList(1) } ,2),...
            size(tempList,1) );
        temp__ellipseParameters = zeros(...
            size(tempList,1),...
            size( stateYao.ellipseParameters{numCycle}{ tempList(1) } ,2) );
        
        for iList = 1:size(tempList,1)
            iImg = tempList(iList);
            
            idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
            idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
            idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
            
            temp__I_mask(:,:,iList) =...
                stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            temp__img_mask(:,:,iList) =...
                stateYao.images.origData.projects{numCycle}(:,:,iImg);
            temp__ellipseParameters(iList,:) =...
                stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:);
        end
        
        
        
        temp__idx = 1;
        ellipseParameters =...
            zeros(1, size(temp__ellipseParameters,2) );
        ellipseParameters(1,3) = mean( temp__ellipseParameters(:,3) );
        ellipseParameters(1,4) = mean( temp__ellipseParameters(:,4) );
        ellipseParameters(1,5) = mean( temp__ellipseParameters(:,5) );
        if size(tempList,1) > 1
            % How do we pick I_mask? And therefore the nucleus center?
            %   Use ellipseParameters to get cell which is closest to
            %   the rest
            %       This becomes I_mask
            temp__dif =...
                ( temp__ellipseParameters(:,3:end)-...
                ones(size(temp__ellipseParameters,1),1)*...
                ellipseParameters(1,3:end) )./...
                ( ones(size(temp__ellipseParameters,1),1)*...
                ellipseParameters(1,3:end) );
            [min_val min_idx] = min( sum( abs(temp__dif') ) );
            
            temp__idx = min_idx;
        end
        
        
        
        I_mask = temp__I_mask(:,:,temp__idx);
        img_mask = temp__img_mask(:,:,temp__idx);
        img_mask = img_mask.*I_mask;
        ellipseParameters(1,1:2) =...
            temp__ellipseParameters(temp__idx,1:2);
        
        
        
        
        stateYao.images.mask.I_mask{numCycle}(:,:,cellID) = I_mask;
        stateYao.images.mask.img_mask{numCycle}(:,:,cellID) = img_mask;
        stateYao.mask.ellipseParameters{numCycle}(cellID,:) =...
            ellipseParameters;
    end
    end
    
    
    
    
    if ishandle(hdlProgFindMask)
    waitbar(...
        3/4,...
        hdlProgFindMask)
    drawnow
    end
    
    
    
    
    
    % Apply mask
    for cellID = cellIdList
        
        I_mask = stateYao.images.mask.I_mask{numCycle}(:,:,cellID);
        img_mask = stateYao.images.mask.img_mask{numCycle}(:,:,cellID);
        ellipseParameters_mask =...
            stateYao.mask.ellipseParameters{numCycle}(cellID,:);
               
        
        
        for iImg = 1:size(stateYao.CyclePositions,1)
        ellipseParameters = ellipseParameters_mask;
        if stateYao.CyclePositions(iImg,numCycle) ~= 0
        if stateYao.ignoreImage(iImg,numCycle) == 0
            
        if any( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID )
        idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
        idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
        idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
        
        
        
        if length(idxCell) > 1
            fprintf('%s: Cannot apply mask. Mutliple cells have the same cell ID\n',...
                mfilename)
            fprintf('\tCycle = %d, iImg = %d, Cell ID = %d\n',...
                numCycle,iImg,cellID)
        else
        
        
        if ~stateYao.applyMask{numCycle}{iImg}(idxCell)
            % Don't apply mask
            
        else
            % Apply mask
            %   Get shift
            I_cell =...
                stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            
            img_cell =...
                stateYao.images.origData.projects{numCycle}(:,:,iImg);
            img_cell = img_cell.*I_cell;
            
            cc = normxcorr2(img_cell,img_mask);
            [max_cc, imax] = max(abs(cc(:)));
            [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            corr_offset = [ (ypeak-size( I_cell ,1)) ...
                (xpeak-size( I_cell ,2)) ];
            %                 cc = normxcorr2(I_cell,I_mask);
            %                 [max_cc, imax] = max(abs(cc(:)));
            %                 [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            %                 corr_offset = [ (ypeak-size( I_cell ,1)) ...
            %                     (xpeak-size( I_cell ,2)) ];
            
            
            %                 figure;
            %                 subplot(1,3,1), imshow(I_mask);
            %                 subplot(1,3,2), imshow(I_cell);
            %                 temp = zeros( size(I_cell,1),size(I_cell,2) );
            %                 pixelList = Yao_generic_getPixels(I_cell);
            %                 pixelList(:,1) = pixelList(:,1) +corr_offset(1);
            %                 pixelList(:,2) = pixelList(:,2) +corr_offset(2);
            %                 pixelList(:,1) = min(max(pixelList(:,1),1),size(I_cell,1));
            %                 pixelList(:,2) = min(max(pixelList(:,2),1),size(I_cell,2));
            %                 for iList = 1:size(pixelList,1)
            %                     temp( pixelList(iList,1),pixelList(iList,2) ) = 1;
            %                 end
            %                 subplot(1,3,3), imshow(temp);
            %                 corr_offset
            %
            %                 figure;
            %                 subplot(1,2,1), imshow(img_mask)
            %                 subplot(1,2,2), imshow(img_cell)
            
            
            %   Apply changes to ellipseParameters
            temp_ellipseParameters = ellipseParameters;
            temp_ellipseParameters(1) =...
                temp_ellipseParameters(1) -corr_offset(2);
            temp_ellipseParameters(2) =...
                temp_ellipseParameters(2) -corr_offset(1);
            
            
            
            %   Create I_nucleus
            x0 = temp_ellipseParameters(1);
            y0 = temp_ellipseParameters(2);
            semimajor_axis = temp_ellipseParameters(3);
            semiminor_axis = temp_ellipseParameters(4);
            phi = deg2rad( temp_ellipseParameters(5) );
            
            t = linspace(0,2*pi(),100);
            X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
            Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
            
            X = real(X);
            Y = real(Y);
            
            YX = zeros( size(X,2) ,2);
            YX(:,1) = round( Y );
            YX(:,2) = round( X );
            [I_nucleus] = Yao_generic_fillPts(YX,[size(I_mask,1) size(I_mask,2)]);
            
            
            
            %   Get cytopasm and buffer
            eval(sprintf('[%s] = %s(%s);',...
                sprintf('%s,%s,%s',...
                'I_nucleus','I_cytoplasm','I_buffer'),...
                stateYao.funcLink.getZones,...
                sprintf('%s,%s',...
                'I_cell','I_nucleus') ))
            
            
            
            
            %   Save
            stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = I_nucleus;
            stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) = I_cytoplasm;
            stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) = I_buffer;
            
            
            
            if sum(sum(I_nucleus)) ~= 0 && sum(sum(I_nucleus)) > length(YX)
                [I_nucleus,ellipseParameters] =...
                    Yao_generic_convert2Ellipse(I_nucleus);
                
                stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = I_nucleus;
            else
                ellipseParameters = zeros(1,5);
            end
            stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = ellipseParameters;
            
            
            
            stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} =...
                deblank( stateYao.funcLink.findNucleus_func_List(3,:) );
            
        end
        
        end
        
        end
        
        end
        end
        end
    end
    
    
    
end




if ishandle(hdlProgFindMask)
close(hdlProgFindMask)
drawnow
end