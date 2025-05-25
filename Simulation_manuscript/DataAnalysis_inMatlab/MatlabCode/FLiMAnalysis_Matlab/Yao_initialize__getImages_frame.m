function Yao_initialize__getImages

global stateYao spc



hdlProgInit = waitbar(0,'Grabbing images...');



for iCycle = 1:size(stateYao.curRun,1);
    numCycle = stateYao.curRun(iCycle);
    
    
    
    isDendrite = 0;
    if any( numCycle == stateYao.CycleDendrite )
        isDendrite = 1;
    end
    
    
    
    for iImg = size(stateYao.CyclePositions,1):-1:1        
    if stateYao.CyclePositions(iImg,numCycle) ~= 0
        
        
        
        if ishandle(hdlProgInit)
        waitbar(...
            iImg/size(stateYao.CyclePositions,1)/size(stateYao.curRun,1)+(iCycle-1)/size(stateYao.curRun,1),...
            hdlProgInit,sprintf('Grabbing images for Cycle %d...',numCycle))
        drawnow
        end
        
        
        
        numImg = stateYao.CyclePositions(iImg,numCycle);
        
        valthreshold=stateYao.StartSettings.valPhoton_threshold/4;
        
        if isDendrite
%             [isvalid] = Yao_generic_loadImage_v3(numImg,'fast',valthreshold);
            
            % Dendirte
            eval(sprintf('%s=%s(%s);',...
                'isvalid',...
                stateYao.funcLink.loadImage,...
                sprintf('%s,''%s'',%s',...
                'numImg','fast','valthreshold') ))
        else
            % Nucleus
            eval(sprintf('%s=%s(%s);',...
                'isvalid',...
                stateYao.funcLink.loadImage,...
                sprintf('%s,%s,%s',...
                'numImg','[]','valthreshold') ))
        end
        
        
        
        
        if isvalid==false
            stateYao.CyclePositions(iImg,numCycle)=0;
%             stateYao.CyclePositions(iImg:end-1,numCycle)=...
%                 stateYao.CyclePositions(iImg+1:end,numCycle);
%             stateYao.CyclePositions(end,numCycle)=0;
        else
        
        stateYao.images.origData.projects{numCycle}(:,:,iImg) =....
            spc.projects{1,1};
        stateYao.images.origData.lifetimeMaps{numCycle}(:,:,iImg) =....
            spc.lifetimeMaps{1,1};
        stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg) =....
            spc.rgbLifetimes{1,1};
        
        
        
        % Apply filters
        if ~isDendrite
            % Nucleus
            stateYao.images.filterDensity.rgbLifetimes{numCycle}(:,:,:,iImg) =...
                Yao_applyFilter('density',1);
            
            stateYao.images.filterFFT.rgbLifetimes{numCycle}(:,:,:,iImg) =...
                Yao_generic_applyFFTFilter( spc.rgbLifetimes{1,1} );
        end
        
        
        
        % Get acquisition time
        TimeVector=datevec(spc.datainfo.time);
        TimeVector=TimeVector(4:6);
        TimeInMinutes=TimeVector(1)*60+TimeVector(2)+TimeVector(3)/60;
        stateYao.AcqTime(iImg,numCycle) = TimeInMinutes;
        end
        
    end
    end
end



if ishandle(hdlProgInit)
close(hdlProgInit)
drawnow
end