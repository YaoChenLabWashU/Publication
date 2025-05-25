% Run this function to find nucleus from image to image, within the same
% cycle
%
% Standard Operating Procedure
%   Find a good starting image with spc_main
%   Adjust tau
%   Edit this file to specify which channel is to be inverted
%   Run this function


%% Which color is the nucleus?
colorNucleus = 'red';




%%
% Have we already found all the images tied to each cycle position?
global stateYao

findCyclePositions = 0;
if isempty(stateYao)
    findCyclePositions = 1;
else
    fileName = spc.filename;
    
    idxSlash = regexp(fileName,'\');
    idxFLIM = regexp(fileName,'FLIM');
    baseName = fileName( idxSlash(end)+1: idxFLIM(end)-1 );
    
    if ~strcmp(stateYao.baseName,baseName)
        findCyclePositions = 1;
    end

end



if findCyclePositions
    filepath=gui.gy.filename.path;
    basename=gui.gy.filename.base;
    filename=sprintf('%s%sFLIM.xlsx',filepath,basename);
    [num, txt, raw]=xlsread(filename, 1, 'A:A');
    clear num txt
    
    
    stateYao.baseName = basename;
    
    
    indexbeginning=[]; indexend=[];PositionMatrix=[];
    for irow=1:size(raw,1)
        entry=raw{irow,1}; % {} gives you the characters inside the cell.
        if ischar(entry)
            if any(regexp(entry, basename))
                indexbasename=regexp(entry,basename);
                entrynumberSTR=...
                    entry(indexbasename(end)+size(basename,2)+size('FLIM',2):...
                    end-size('.mat',2));
                entrynumber=str2num(entrynumberSTR);
                if isempty(indexbeginning)
                    indexbeginning=entrynumber;
                    indexend=entrynumber;
                else
                    indexbeginning=min([indexbeginning entrynumber]);
                    indexend=max([indexbeginning entrynumber]);
                end
                
                
                
                % Get cycle position from hdr file
                newName = sprintf('%s%s%s%s',...
                    filepath,...
                    basename,...
                    entrynumberSTR,...
                    '_hdr.txt');
                CyclePosition=str2double(GrabCyclePosition(newName));
                if isempty(PositionMatrix)
                    PositionMatrix(1,CyclePosition)=entrynumber;
                    
                elseif size(PositionMatrix,2) < CyclePosition
                    temp_PositionMatrix = PositionMatrix;
                    PositionMatrix = zeros( size(temp_PositionMatrix,1),CyclePosition);
                    PositionMatrix(1:size(temp_PositionMatrix,1),1:size(temp_PositionMatrix,2))=...
                        temp_PositionMatrix;
                    PositionMatrix(1,CyclePosition) = entrynumber;
                    clear temp_PositionMatrix
                    
                else
                    if PositionMatrix(end,CyclePosition)==0
                        [min_val min_idx] = min(PositionMatrix(:,CyclePosition));
                        PositionMatrix(min_idx,CyclePosition)=entrynumber;
                        clear min_val min_idx
                    else
                        PositionMatrix(end+1,CyclePosition)=entrynumber;
                    end
                end
                
            end
        end
    end
    clear irow entry indexbasename entrynumberSTR entrynumber
    clear newName CyclePosition
    
    % Not all file information may have been recorded
    for number=indexbeginning:indexend
        if ~any(any(PositionMatrix==number))
            if number<10
                entrynumberSTR=sprintf('00%d', number);
            elseif number<100
                entrynumberSTR=sprintf('0%d', number);
            else
                entrynumberSTR=num2str(number);
            end
            newName = sprintf('%s%s%s%s',...
                filepath,...
                basename,...
                entrynumberSTR,...
                '_hdr.txt');
            
            if exist(newName,'file')
                CyclePosition=str2double(GrabCyclePosition(newName));
                if PositionMatrix(end,CyclePosition)==0
                    [min_val min_idx] = min(PositionMatrix(:,CyclePosition));
                    PositionMatrix(min_idx,CyclePosition)=number;
                    clear min_val min_idx
                else
                    PositionMatrix(end+1,CyclePosition)=number;
                end
                clear CyclePosition
            end
            
        end
    end
    clear number indexbeginning indexend entrynumberSTR newName
    
    
    stateYao.CyclePositions = PositionMatrix;
    clear PositionMatrix
end



%%
% Get the current image and cycle number
numImage = [];
numCycle = [];



numImage = gui.gy.filename.num;



for iCycle = 1:size(stateYao.CyclePositions,2)
    if any( stateYao.CyclePositions(:,iCycle) == numImage)
        numCycle = iCycle;
        break
    end
end



stateYao.numImage = numImage;
stateYao.numCycle = numCycle;

clear numImage numCycle iCycle



%%
% Initialize key variables
%   Image stack
stateYao.numImage_orig = stateYao.numImage;
stateYao.img_orig = spc.rgbLifetimes{1,1};


stateYao.imageStack = zeros(...
    size(spc.rgbLifetimes{1,1},1),...
    size(spc.rgbLifetimes{1,1},2),...
    size(spc.rgbLifetimes{1,1},3),...
    size( stateYao.CyclePositions( stateYao.CyclePositions(:,stateYao.numCycle) ~= 0 ,stateYao.numCycle) ,1) );

stateYao.offset = zeros( size(stateYao.imageStack,4) ,2);



iImg = [1:size(stateYao.CyclePositions,1)]*...
    (stateYao.CyclePositions(:,stateYao.numCycle)==stateYao.numImage_orig);

stateYao.imageStack(:,:,:,iImg) = stateYao.img_orig;




stateYao.I_cell_stack = cell( size(stateYao.imageStack,4) ,1);
stateYao.I_nucleus_stack = cell( size(stateYao.imageStack,4) ,1);
stateYao.I_cytoplasm_stack = cell( size(stateYao.imageStack,4) ,1);

stateYao.applyMask = cell( size(stateYao.imageStack,4) ,1);
stateYao.ellipseParameters = cell( size(stateYao.imageStack,4) ,1);







%% Run on first image

iImg = [1:size(stateYao.CyclePositions,1)]*...
    (stateYao.CyclePositions(:,stateYao.numCycle)==stateYao.numImage_orig);
Yao_generic_findNucleus_v1(iImg,colorNucleus)



%%
% Grab all images for this cycle
for iImg = 1:size(stateYao.CyclePositions,1)
% for iImg = 1
    if stateYao.CyclePositions(iImg,stateYao.numCycle) ~= 0
    if stateYao.CyclePositions(iImg,stateYao.numCycle) ~= stateYao.numImage_orig;
        
        Yao_generic_findNucleus_v1(iImg,colorNucleus)
        
        
    end
    end
end



% Check to see if a mask needs to be applied to any of the images
applyMask = 0;
userInput = 0;
for iImg = 1:size(stateYao.applyMask,1)
    if any( stateYao.applyMask{iImg} )
        applyMask = 1;
        break
    end
end

% disp('Forcing applyMask = 1')
% applyMask = 1;
if applyMask
    mask_I_cell = [];
    mask_ellipseParameters = [];
    
    
    % Verify that the original nucleus was found
    iImg = [1:size(stateYao.CyclePositions,1)]*...
        (stateYao.CyclePositions(:,stateYao.numCycle)==stateYao.numImage_orig);
    
    if all( stateYao.applyMask{iImg} )
        userInput = 1;
    else
        userInput = 1;
        % Find mask
        for iCell = 1:size( stateYao.I_nucleus_stack{iImg} ,3)
            
            if stateYao.applyMask{iImg}(iCell) == 0
            
            I_search = stateYao.I_nucleus_stack{iImg}(:,:,iCell);
            
            if sum(sum(I_search)) > 0
                I_cell = stateYao.I_cell_stack{iImg}(:,:,iCell);
                
                [I_search,ellipseParameters] =...
                    Yao_generic_convert2Ellipse(I_search);
                
                mask_I_cell = I_cell;
                mask_ellipseParameters = ellipseParameters;
                
                userInput = 0;
                break
            end
            
            end
            
        end
        
        
%         disp('Force userInput = 1')
%         userInput = 1;
        if userInput
            for iImg = 1:size( stateYao.applyMask )
                if ~all( stateYao.applyMask{iImg} )
                    for iCell = 1:size( stateYao.I_nucleus_stack{iImg} ,3)
                        
                        if stateYao.applyMask{iImg}(iCell) == 0
                        
                        I_search = stateYao.I_nucleus_stack{iImg}(:,:,iCell);
                        
                        if sum(sum(I_search)) > 0
                            I_cell = stateYao.I_cell_stack{iImg}(:,:,iCell);
                            
                            [I_search,ellipseParameters] =...
                                Yao_generic_convert2Ellipse(I_search);
                            
                            mask_I_cell = I_cell;
                            mask_ellipseParameters = ellipseParameters;
                            
                            userInput = 0;
                            break
                        end
                        
                        end
                        
                    end
                end
            end
        end
        
    end
    
    
    
    for iImg = 1:size(stateYao.CyclePositions,1)
        
%     iImg = [1:size(stateYao.CyclePositions,1)]*...
%         (stateYao.CyclePositions(:,stateYao.numCycle)==stateYao.numImage);
    
    
    
%     disp('Forcing userInput = 1')
%     userInput = 1;
    if userInput
        % User needs to be asked to identify the nucleus
        %   Display original image
        
        stateYao.temp.I_cell = [];
        stateYao.temp.I_search = [];
        
        hFig = figure;
        imshow( stateYao.imageStack(:,:,:,iImg) )
        hAxis = gca;
        I_cell_stack = stateYao.I_cell_stack{iImg};
        Yao_run_nucleus_UserSelection(hFig,hAxis,I_cell_stack);
        uiwait(hFig)
        
        if ~isempty( stateYao.temp.I_cell ) &&...
                ~isempty( stateYao.temp.I_search )
        userInput = 0;
            
        I_cell = stateYao.temp.I_cell;
        I_search = stateYao.temp.I_search;
        
        [I_search,ellipseParameters] =...
            Yao_generic_convert2Ellipse(I_search);
        
        mask_I_cell = I_cell;
        mask_ellipseParameters = ellipseParameters;
        
% %         figure; subplot(1,2,1), imshow(I_cell);
% %         subplot(1,2,2), imshow(I_search);
%         
%         [I_nucleus,I_cytoplasm,I_buffer] =...
%             Yao_generic_zoneID(I_cell,I_search);
%         
%         [pixelList_perim_cyto] = Yao_generic_getPerimeter(I_cytoplasm,'PixelList');
%         [pixelList_perim_nucl] = Yao_generic_getPerimeter(I_nucleus,'PixelList');
%         
%         temp_img = stateYao.imageStack(:,:,:,iImg);
%         for iCyto = 1:size(pixelList_perim_cyto,1)
%             temp_img(...
%                 pixelList_perim_cyto(iCyto,1),...
%                 pixelList_perim_cyto(iCyto,2), :) = 1;
%         end
%         for iNucl = 1:size(pixelList_perim_nucl,1)
%             temp_img(...
%                 pixelList_perim_nucl(iNucl,1),...
%                 pixelList_perim_nucl(iNucl,2), :) = 1;
%         end
%         
%         figure; imshow(temp_img)
        end
    end
    
    if userInput == 0
        break
    end
    end
    
    
    
    % Apply mask
    mask_pixelList = Yao_generic_getPixels(mask_I_cell);    
    mask_orien = Yao_generic_getOrientation(...
        [mask_pixelList(:,2) mask_pixelList(:,1)],'Deg');
    
    if ~isempty( mask_ellipseParameters )
    for iImg = 1:size(stateYao.applyMask,1)
%     for iImg = 1:5
    if ~any( stateYao.applyMask{iImg} )
        for iCell = 1:size( stateYao.I_cell_stack{iImg} ,3)
            I_nucleus = stateYao.I_nucleus_stack{iImg}(:,:,iCell);
            I_cytoplasm = stateYao.I_cytoplasm_stack{iImg}(:,:,iCell);
            
            [pixelList_perim_cyto] = Yao_generic_getPerimeter(I_cytoplasm,'PixelList');
            [pixelList_perim_nucl] = Yao_generic_getPerimeter(I_nucleus,'PixelList');
            
            temp_img = stateYao.imageStack(:,:,:,iImg);
            for iCyto = 1:size(pixelList_perim_cyto,1)
                temp_img(...
                    pixelList_perim_cyto(iCyto,1),...
                    pixelList_perim_cyto(iCyto,2), :) = 1;
            end
            for iNucl = 1:size(pixelList_perim_nucl,1)
                temp_img(...
                    pixelList_perim_nucl(iNucl,1),...
                    pixelList_perim_nucl(iNucl,2), :) = 1;
            end
            
            figure; imshow(temp_img)
        end
        
    else
        I_cell_stack = stateYao.I_cell_stack{iImg};
        
        for iCell = 1:size(I_cell_stack,3)
            I_cell = I_cell_stack(:,:,iCell);
            
            % Compare the cell to the cell mask
            pixelList = Yao_generic_getPixels(I_cell);
            orien = Yao_generic_getOrientation(...
                [pixelList(:,2) pixelList(:,1)],'Deg');
            
            cc = normxcorr2(I_cell,mask_I_cell);
            [max_cc, imax] = max(abs(cc(:)));
            [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            corr_offset = [ (ypeak-size( I_cell ,1)) ...
                (xpeak-size( I_cell ,2)) ];
            
            dx0 = corr_offset(2);
            dy0 = corr_offset(1);
            
            drx = ( max(pixelList(:,2)) - min(pixelList(:,2)) )/...
                ( max(mask_pixelList(:,2)) - min(mask_pixelList(:,2)) );
            dry = ( max(pixelList(:,1)) - min(pixelList(:,1)) )/...
                ( max(mask_pixelList(:,1)) - min(mask_pixelList(:,1)) );
            
            dOrien = orien - mask_orien;
            
            
            
            % Adjust the ellipse parameters            
            x0 = mask_ellipseParameters(1) -dx0;
            y0 = mask_ellipseParameters(2) -dy0;
            
            if abs( mask_ellipseParameters(5) ) < 45
                % Major axis is x
                semimajor_axis = mask_ellipseParameters(3)*drx;
                semiminor_axis = mask_ellipseParameters(4)*dry;
            elseif abs( mask_ellipseParameters(5)  ) > 135
                % Major axis is x
                semimajor_axis = mask_ellipseParameters(3)*drx;
                semiminor_axis = mask_ellipseParameters(4)*dry;
            else
                % Major axis is y
                semimajor_axis = mask_ellipseParameters(3)*dry;
                semiminor_axis = mask_ellipseParameters(4)*drx;
            end
            
            phi = deg2rad( mask_ellipseParameters(5) + dOrien );
            
            
            
            % Apply ellipse parameters
            I_search = zeros( size(I_cell,1),size(I_cell,2) );
            
            t = linspace(0,2*pi(),100);
            X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
            Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
            
            clear t
            
            X = real(X);
            Y = real(Y);
            
            YX = zeros( size(X,2) ,2);
            YX(:,1) = round( Y );
            YX(:,2) = round( X );
            [I_search] = Yao_generic_fillPts(YX,[size(I_search,1) size(I_search,2)]);
            
            
            
            % Save
            [I_nucleus,I_cytoplasm,I_buffer] =...
                Yao_generic_zoneID(I_cell,I_search);
            
            [pixelList_perim_cyto] = Yao_generic_getPerimeter(I_cytoplasm,'PixelList');
            [pixelList_perim_nucl] = Yao_generic_getPerimeter(I_nucleus,'PixelList');
            
            temp_img = stateYao.imageStack(:,:,:,iImg);
            for iCyto = 1:size(pixelList_perim_cyto,1)
                temp_img(...
                    pixelList_perim_cyto(iCyto,1),...
                    pixelList_perim_cyto(iCyto,2), :) = 1;
            end
            for iNucl = 1:size(pixelList_perim_nucl,1)
                temp_img(...
                    pixelList_perim_nucl(iNucl,1),...
                    pixelList_perim_nucl(iNucl,2), :) = 1;
            end
            
            figure; imshow(temp_img)
            
        end
    end
    end
    end
end






% Rest to first image
stateYao.numImage = stateYao.numImage_orig;

% Tell spc_main to load new image
spc_openFiles(stateYao.numImage,[])


% Make changes to Tau and upper/lower limits
spc_adjustTauOffset(1)

spc.switchess{1,1}.lifeLimitUpper =...
    spc.fits{1,1}.avgTau -0.25;
spc.switchess{1,1}.lifeLimitLower =...
    spc.fits{1,1}.avgTau +0.25;

% Redraw lifetime map
spc_redrawSetting