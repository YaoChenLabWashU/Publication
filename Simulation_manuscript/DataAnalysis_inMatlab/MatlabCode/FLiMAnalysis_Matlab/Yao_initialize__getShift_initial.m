function Yao_initialize__getShift_initial

global stateYao



hdlProgShift = waitbar(0,'Finding initial shift...');



for iCycle = 1:size(stateYao.curRun,1)
    numCycle = stateYao.curRun(iCycle);
    
    % What are we basing the shift on? As in, how do we pick the master
    % image?
    %   Image 1 - Random
    %   Image selected by user - Probably random
    %   Image with average photon count? - Potentially good choice
    %       Get photon count for all images
    valPhoton = zeros( size( stateYao.CyclePositions ,1) ,1);
    onesMatrix = ones(...
        size(stateYao.images.origData.projects{numCycle},1),...
        size(stateYao.images.origData.projects{numCycle},2) );
    for iImg = 1:size( stateYao.CyclePositions ,1)
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        valPhoton(iImg) = Yao_calc_Photon(...
            stateYao.images.origData.projects{numCycle}(:,:,iImg),...
            onesMatrix);
    end
    end
    
    targetVal = max( valPhoton( valPhoton~=0 ) ); % we changed from mean to max.
    valPhoton = abs( targetVal - valPhoton );
    [min_val min_idx] = min(valPhoton);
    
    stateYao.shift.initial.iImg_mask(numCycle) = min_idx;
    
    clear valPhoton onesMatrix iImg targetVal min_val min_idx
    
    
    
    iImg_mask = stateYao.shift.initial.iImg_mask(numCycle);
    
    img_mask = stateYao.images.origData.projects{numCycle}(:,:,iImg_mask);
    for iImg = 1:size( stateYao.CyclePositions ,1)
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
    if iImg ~= iImg_mask
        
        
        if ishandle(hdlProgShift)
        waitbar(...
            iImg/size(stateYao.CyclePositions,1)/size(stateYao.curRun,1)+(iCycle-1)/size(stateYao.curRun,1),...
            hdlProgShift)
        drawnow
        end
    
        
        
        img =...
            stateYao.images.origData.projects{numCycle}(:,:,iImg);
        
        
        
        
        cc = normxcorr2(...
            img,...
            img_mask );
        [max_cc, imax] = max(abs(cc(:)));
        [ypeak, xpeak] = ind2sub(size(cc),imax(1));
        corr_offset = [ (ypeak-size( img ,1)) ...
            (xpeak-size( img ,2)) ];
        
        
        stateYao.shift.initial.imageShift{numCycle}(iImg,:) =...
            round([corr_offset(2) corr_offset(1)]);
    end
    end
    end
end

if ishandle(hdlProgShift)
close(hdlProgShift)
drawnow
end