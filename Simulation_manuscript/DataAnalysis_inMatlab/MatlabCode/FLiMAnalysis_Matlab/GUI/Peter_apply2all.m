function Peter_apply2all

global stateYao spc gui



numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;


if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    % Dendrite
    [stateYao.ROI{numCycle}{iImg:end}] =...
        deal(stateYao.ROI{numCycle}{iImg});
%Find Shift
%Initialization

spc_openFiles(stateYao.CyclePositions(iImg, numCycle),[])
spc_deleteAllROIs(1:2)
my_vertices = stateYao.ROI{numCycle}{iImg}{1};
try
    numROI=length(gui.gy.rois)+1;
catch
    numROI=1;
end
thisObj=impoly(gui.spc.projects{1}.axes, my_vertices);
gui.gy.rois{numROI}.mask=createMask(thisObj);
posROI=getPosition(thisObj);
gui.gy.roiPositions{numROI}=posROI;

delete(thisObj);
stateYao.images.mask.projects{numCycle}{1} = spc.projects{1,1};
stateYao.images.mask.lifetimeMaps{numCycle}{1} = spc.lifetimeMaps{1,1};
stateYao.images.mask.rgbLifetime{numCycle}{1} = spc.rgbLifetimes{1,1};
% Photon value threshold
valPhoton_threshold = 200000; %200,000 is a reasonable value for 20 frames; it gives a stdev of 0.0035ns, 2.8X0.01ns.

% function links
funcLink = [];

funcLink.findDendriteShift =...
    'Peter_UpdateDendriteShift';


hdlProgDendrite = waitbar(0,...
    sprintf('Getting Dendrite Shift for Cycle %d',numCycle) );


for Img = iImg:size( stateYao.CyclePositions ,1)
    if stateYao.CyclePositions(Img,numCycle) ~= 0
    if stateYao.ignoreImage(Img,numCycle) == 0


        if ishandle(hdlProgDendrite)
        waitbar(...
            Img/size(stateYao.CyclePositions,1),...
            hdlProgDendrite)
        drawnow
        end


        eval( sprintf('%s(numCycle,Img)',...
            funcLink.findDendriteShift) )

    end
    end
end

if ishandle(hdlProgDendrite)
close(hdlProgDendrite)
drawnow
end

    

else
    % Nucleus
    [stateYao.images.I_cell_stack{numCycle}{iImg:end}] =...
        deal(stateYao.images.I_cell_stack{numCycle}{iImg});
    
    [stateYao.images.I_nucleus_stack{numCycle}{iImg:end}] =...
        deal(stateYao.images.I_nucleus_stack{numCycle}{iImg});
    [stateYao.ellipseParameters{numCycle}{iImg:end}] =...
        deal(stateYao.ellipseParameters{numCycle}{iImg});
    [stateYao.images.I_cytoplasm_stack{numCycle}{iImg:end}] =...
        deal(stateYao.images.I_cytoplasm_stack{numCycle}{iImg});
    [stateYao.images.I_buffer_stack{numCycle}{iImg:end}] =...
        deal(stateYao.images.I_buffer_stack{numCycle}{iImg});
    
    [stateYao.cellIdx{numCycle}{iImg:end}] =...
        deal(stateYao.cellIdx{numCycle}{iImg});
    
    
    [stateYao.applyMask{numCycle}{iImg:end}] = deal(stateYao.applyMask{numCycle}{iImg});
    
    
    
    [stateYao.funcLink.findNucleus_func{numCycle}{iImg:end}] =...
        deal(stateYao.funcLink.findNucleus_func{numCycle}{iImg});
    [stateYao.colorNucleus{numCycle}{iImg:end}] =...
        deal(stateYao.colorNucleus{numCycle}{iImg});
    
end



Yao_GUI_loadImage
