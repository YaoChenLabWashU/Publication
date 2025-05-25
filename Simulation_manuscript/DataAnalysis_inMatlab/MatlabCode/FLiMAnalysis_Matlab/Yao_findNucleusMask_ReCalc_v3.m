function Yao_findNucleusMask_ReCalc_v3(numCycle,iImg,cellID)

global stateYao


str = sprintf('Re-Calculating Masks...');
hdlCompleteTask = waitbar(0,str);


cellID_master = cellID;
iImg_mask = iImg;

idxCell_mask = zeros( length(cellID) ,1);
for iCell = 1:length(cellID)
    idxCell_mask(iCell) = stateYao.cellIdx{numCycle}{iImg}(...
        stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID(iCell) ,1);
end

I_cell__mask_stack =...
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell_mask);
ellipseParameters__mask_stack =...
    stateYao.ellipseParameters{numCycle}{iImg}(idxCell_mask,:);




% Apply mask
size1 = size( stateYao.images.I_cell_stack{numCycle}{iImg} ,1);
size2 = size( stateYao.images.I_cell_stack{numCycle}{iImg} ,2);
for i3 = 1:size(I_cell__mask_stack,3)
    cellID = cellID_master(i3);
    
    I_cell__mask = I_cell__mask_stack(:,:,i3);
    ellipseParameters__mask = ellipseParameters__mask_stack(i3,:);
    
    
    
    pixelList__mask = Yao_generic_getPixels(I_cell__mask);
    orien__mask = Yao_generic_getOrientation(...
        [pixelList__mask(:,2) pixelList__mask(:,1)],'Deg');
    
    
    
    for iImg = 1:size( stateYao.applyMask{numCycle} ,1)
    if iImg ~= iImg_mask
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
    if stateYao.ignoreImage(iImg,numCycle) == 0
    if any( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID )
        idxCell = stateYao.cellIdx{numCycle}{iImg}(...
            stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID ,1);
        
        if ~stateYao.applyMask{numCycle}{iImg}(idxCell)
        else
            
            
            
            
            if ishandle(hdlCompleteTask)
            waitbar(...
                iImg/size( stateYao.CyclePositions ,1) * 1/size(I_cell__mask_stack,3)+...
                (i3-1)/size(I_cell__mask_stack,3),...
                hdlCompleteTask)
            drawnow
            end
            
            
            
            
            
            I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);
            
            
            % Compare the cell to the cell mask
            pixelList = Yao_generic_getPixels(I_cell);
            orien = Yao_generic_getOrientation(...
                [pixelList(:,2) pixelList(:,1)],'Deg');
            
            cc = normxcorr2(I_cell,I_cell__mask);
            [max_cc, imax] = max(abs(cc(:)));
            [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            corr_offset = [ (ypeak-size( I_cell ,1)) ...
                (xpeak-size( I_cell ,2)) ];
            
            dx0 = corr_offset(2);
            dy0 = corr_offset(1);
            
            drx = ( max(pixelList(:,2)) - min(pixelList(:,2)) )/...
                ( max(pixelList__mask(:,2)) - min(pixelList__mask(:,2)) );
            dry = ( max(pixelList(:,1)) - min(pixelList(:,1)) )/...
                ( max(pixelList__mask(:,1)) - min(pixelList__mask(:,1)) );
            
            % Is this dependent on the values?
            dOrien = orien - orien__mask;
            
            
            
            % Adjust the ellipse parameters
            x0 = ellipseParameters__mask(1) -dx0;
            y0 = ellipseParameters__mask(2) -dy0;
            
            if abs( ellipseParameters__mask(5) ) < 45
                % Major axis is x
                semimajor_axis = ellipseParameters__mask(3)*drx;
                semiminor_axis = ellipseParameters__mask(4)*dry;
            elseif abs( ellipseParameters__mask(5)  ) > 135
                % Major axis is x
                semimajor_axis = ellipseParameters__mask(3)*drx;
                semiminor_axis = ellipseParameters__mask(4)*dry;
            else
                % Major axis is y
                semimajor_axis = ellipseParameters__mask(3)*dry;
                semiminor_axis = ellipseParameters__mask(4)*drx;
            end
            
            phi = deg2rad( ellipseParameters__mask(5) + dOrien );
            %                     [orien orien__mask dOrien ...
            %                         ellipseParameters__mask(5) + dOrien]
            % %                     phi = deg2rad( ellipseParameters__mask(5) );
            
            
            % Apply ellipse parameters
            I_search = zeros(size1,size2);
            
            t = linspace(0,2*pi(),100);
            X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
            Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
            
            clear t
            
            X = real(X);
            Y = real(Y);
            
            YX = zeros( size(X,2) ,2);
            YX(:,1) = round( Y );
            YX(:,2) = round( X );
            [I_search] = Yao_generic_fillPts(YX,[size1 size2]);
            
            
            
            I_nucleus = I_search;
            
            % Save
            eval(sprintf('[%s] = %s(%s);',...
                sprintf('%s,%s,%s',...
                'I_nucleus','I_cytoplasm','I_buffer'),...
                stateYao.funcLink.getZones,...
                sprintf('%s,%s',...
                'I_cell','I_nucleus') ))
            %                     [I_nucleus,I_cytoplasm,I_buffer] =...
            %                         Yao_generic_zoneID(I_cell,I_search);
            
            
            [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
            stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = ellipseParameters;
            
            
            
            stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = I_nucleus;
            stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) = I_cytoplasm;
            stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) = I_buffer;
            
            
            
            
            
        end
        
    end
    
    end
    end
    end
    end

end



if ishandle(hdlCompleteTask)
close(hdlCompleteTask)
drawnow
end