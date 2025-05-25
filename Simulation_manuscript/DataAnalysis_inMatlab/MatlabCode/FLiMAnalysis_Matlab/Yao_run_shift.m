% Run this function to find shift from image to image, within the same
% cycle
%
% Standard Operating Procedure
%   Find a good starting image with spc_main
%   Adjust the ROI for this image
%   Run this function






%%
iChan = 1;





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
%   ROI stack
stateYao.numImage_orig = stateYao.numImage;
stateYao.img_orig = spc.projects{1,iChan};
if isempty( gui.gy.roiPositions )
    hMsg = msgbox('No ROI detected. Please add one now. Press OK when finished');
    uiwait(hMsg)
end
stateYao.ROI_orig = gui.gy.roiPositions{iChan};

stateYao.imageStack = zeros(...
    size(spc.projects{1,1},1),...
    size(spc.projects{1,1},2),...
    size( stateYao.CyclePositions( stateYao.CyclePositions(:,stateYao.numCycle) ~= 0 ,stateYao.numCycle) ,1) );
stateYao.ROI = cell( size(stateYao.imageStack,3) ,1);

stateYao.offset = zeros( size(stateYao.imageStack,3) ,2);



iImg = [1:size(stateYao.CyclePositions,1)]*...
    (stateYao.CyclePositions(:,stateYao.numCycle)==stateYao.numImage);

stateYao.ROI{iImg} = gui.gy.roiPositions{iChan};
stateYao.imageStack(:,:,iImg) = stateYao.img_orig;








stateYao.angle = zeros( size(stateYao.imageStack,3) ,1);

imgBW = im2bw( uint8(stateYao.img_orig) ,0.1);
[pixelList] = Yao_generic_getPixels(imgBW);

XY = [pixelList(:,1) pixelList(:,2)];
[orientation] = Yao_generic_getOrientation(XY);

stateYao.angle_orig = orientation;
stateYao.angle(iImg) = orientation;












%%
% Grab all images for this cycle
for iImg = 1:size( stateYao.CyclePositions( stateYao.CyclePositions(:,stateYao.numCycle) ~= 0 ,stateYao.numCycle) ,1)
% for iImg = 7
    if stateYao.CyclePositions(iImg,stateYao.numCycle) ~= 0
    if stateYao.CyclePositions(iImg,stateYao.numCycle) ~= stateYao.numImage_orig;
        stateYao.numImage = stateYao.CyclePositions(iImg,stateYao.numCycle);
        
        % Tell spc_main to load new image
        spc_openFiles(stateYao.numImage,[])
        
        % Save image to image stack
        stateYao.imageStack(:,:,iImg) = spc.projects{1,iChan};
        
        
        
% % %         figure; subplot(1,2,1), imshow( uint8(stateYao.img_orig) );
% % %         subplot(1,2,2), imshow( uint8(stateYao.imageStack(:,:,7)) );
        
        
        
        % Find shift
        cc = normxcorr2(...
            stateYao.imageStack(:,:,iImg),...
            stateYao.img_orig );
        [max_cc, imax] = max(abs(cc(:)));
        [ypeak, xpeak] = ind2sub(size(cc),imax(1));
        corr_offset = [ (ypeak-size( stateYao.imageStack ,1)) ...
            (xpeak-size( stateYao.imageStack ,2)) ];
        
        stateYao.offset(iImg,1) = corr_offset(2);
        stateYao.offset(iImg,2) = corr_offset(1);
        clear cc max_cc imax ypeak xpeak corr_offset
        
        
        
        % Apply shift
        newROI = stateYao.ROI_orig;
        newROI(:,1) = newROI(:,1) - stateYao.offset(iImg,1);
        newROI(:,2) = newROI(:,2) - stateYao.offset(iImg,2); 
        stateYao.ROI{iImg} = newROI;
        clear newROI
        
        
        
        
        
        
        % Rotate
        imgBW = im2bw( uint8(stateYao.imageStack(:,:,iImg)) ,0.2);
        
        if sum(sum(imgBW)) < 1/100 *...
                size(stateYao.imageStack(:,:,iImg),1)*...
                size(stateYao.imageStack(:,:,iImg),2)
            
            fprintf('\n\t%s: Not enough pixels found for image %d\n\n',...
                mfilename,stateYao.numImage)
            stateYao.CyclePositions(iImg,stateYao.numCycle) = 0;
            
        else
%         figure; imshow(imgBW);
        [pixelList] = Yao_generic_getPixels(imgBW);
        
        XY = [pixelList(:,1) pixelList(:,2)];
        [orientation] = Yao_generic_getOrientation(XY);
        
        stateYao.angle(iImg) = orientation;
        
        
        
        
        
        
        dAngle = stateYao.angle_orig - stateYao.angle(iImg);
        newROI = stateYao.ROI{iImg};
        
        
        XY = newROI;
        % cond can be 'Rad' or 'Deg'
        %   Default is degrees
        
        x0 = mean(XY(:,1));
        y0 = mean(XY(:,2));
        
        XY(:,1) = XY(:,1) - x0;
        XY(:,2) = XY(:,2) - y0;
        
        [theta,rho] = cart2pol( XY(:,1) , XY(:,2) );
        
        rot = deg2rad( dAngle );
        
        theta = theta +rot;
        
        [x,y] = pol2cart(theta,rho);
        
        XY(:,1) = x+x0;
        XY(:,2) = y+y0;
        
        newROI = XY;
        
        stateYao.ROI{iImg} = newROI;
        clear newROI
        
        
        
        
        
        
        % Apply changes
        gui.gy.roiPositions{iChan} = stateYao.ROI{iImg};
        for roi = iChan
        for type=1:2
            setPosition(gui.gy.rois{1,roi}.obj{1,type}, gui.gy.roiPositions{1,roi} )
            spc_conformROIpositions;
        end
        end
        clear roi type
        
        
        pause(0.5)
        
        end
        
    end
    end
end



% Rest to first image
stateYao.numImage = stateYao.numImage_orig;

% Tell spc_main to load new image
spc_openFiles(stateYao.numImage,[])

gui.gy.roiPositions{1} = stateYao.ROI_orig;
for roi = 1
    for type=1:2
        setPosition(gui.gy.rois{1,roi}.obj{1,type}, gui.gy.roiPositions{1,roi} )
        spc_conformROIpositions;
    end
end
clear roi type