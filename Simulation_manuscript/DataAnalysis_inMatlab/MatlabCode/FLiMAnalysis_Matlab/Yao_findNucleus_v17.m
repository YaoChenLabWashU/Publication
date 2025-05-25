function Yao_findNucleus_v17(numCycle,iImg,cellID)

global stateYao



if ~exist('cellID','var')
    cellID = [];
end
if isempty(cellID)
    cellID = stateYao.cellIdx{numCycle}{iImg}(:,2);
end



if length(cellID) ~= length( unique(cellID) )
    fprintf('%s: Warning -  2 cells with the same cell ID\n\tCycle %d iImg %d\n',...
        mfilename,numCycle,iImg)
end





colorNucleus = stateYao.colorNucleus{numCycle}{iImg};



if ~isempty( stateYao.images.I_cell_stack{numCycle}{iImg} ) &&...
        ~isempty( stateYao.cellIdx{numCycle}{iImg} )
% Find nucleus for each cell
%   Initialize
if isempty( stateYao.ellipseParameters{numCycle}{iImg} )
    stateYao.ellipseParameters{numCycle}{iImg} =...
        zeros( size( stateYao.images.I_cell_stack{numCycle}{iImg} ,3) ,5);
end





if isempty( stateYao.images.I_nucleus_stack{numCycle}{iImg} )
    stateYao.images.I_nucleus_stack{numCycle}{iImg} =...
        zeros( size(I_cell,1),size(I_cell,2),...
        size(stateYao.cellIdx{numCycle}{iImg},1) );
end
if isempty( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} )
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg} =...
        zeros( size(I_cell,1),size(I_cell,2),...
        size(stateYao.cellIdx{numCycle}{iImg},1) );
end
if isempty( stateYao.images.I_buffer_stack{numCycle}{iImg} )
    stateYao.images.I_buffer_stack{numCycle}{iImg} =...
        zeros( size(I_cell,1),size(I_cell,2),...
        size(stateYao.cellIdx{numCycle}{iImg},1) );
end








for iCell = 1:length(cellID)
idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID(iCell) );


if iscell(colorNucleus)
    if length(colorNucleus) >= idxCell
        colorNucleus_ThisCell = colorNucleus{idxCell};
    else
        colorNucleus_ThisCell = stateYao.CycleIdentification{numCycle,2};
    end
else
    colorNucleus_ThisCell = colorNucleus;
end
if ~ischar( colorNucleus_ThisCell )
    fprintf('%s: Error getting nucleus color, reverting to:\n\t%s\n',...
        mfilename, stateYao.CycleIdentification{numCycle,2} )
    colorNucleus_ThisCell = stateYao.CycleIdentification{numCycle,2};
end

I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell);



if isempty( stateYao.applyMask{numCycle}{iImg} )
    stateYao.applyMask{numCycle}{iImg} =...
        zeros( size(stateYao.cellIdx{numCycle}{iImg},1) ,1);
end
stateYao.applyMask{numCycle}{iImg}(idxCell) = 0;

if isempty( stateYao.ellipseParameters{numCycle}{iImg} )
    stateYao.ellipseParameters{numCycle}{iImg} =...
        zeros( size(stateYao.cellIdx{numCycle}{iImg},1) ,5);
end
stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = 0;




%% Run Function
I_nucleus = [];
nucleusCheck1 = [];

if length(idxCell) > 1
    fprintf('%s: Cannot run on this image. Mutliple cells have the same cell ID\n',...
        mfilename)
    fprintf('\tCycle = %d, iImg = %d, Cell ID = %d\n',...
        numCycle,iImg,cellID(iCell))
    
    
    for iIdxCell = 1:length(idxCell)
        idxCell2 = idxCell(iIdxCell);
        
        
        
        stateYao.applyMask{numCycle}{iImg}(idxCell2) = 1;
        
        
        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell2) =...
            zeros( size(I_cell,1),size(I_cell,2) );
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell2) =...
            zeros( size(I_cell,1),size(I_cell,2) );
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell2) =...
            zeros( size(I_cell,1),size(I_cell,2) );
        
        stateYao.ellipseParameters{numCycle}{iImg}(idxCell2,:) = 0;
        
        stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell2} =...
            deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
    end
    
    
else



if strcmp(stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},'None') ||...
        strcmp(stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},'User Input') ||...
        strcmp(stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},'Mask')
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} =...
        stateYao.funcLink.findNucleus_func_default;
end

eval(sprintf('[%s] = %s(%s);',...
    'I_nucleus,nucleusCheck1',...
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},...
    sprintf('%s,%s,%s,%s',...
    'numCycle','iImg','I_cell','colorNucleus_ThisCell') ))



%%
if ~isempty(I_nucleus) && ~all( ~nucleusCheck1{1,1} )

    stateYao.check.type1{numCycle}{iImg}(idxCell,:) = nucleusCheck1;
    
    
    
    [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);

    
    
    eval(sprintf('[%s] = %s(%s);',...
        sprintf('%s,%s,%s',...
        'I_nucleus','I_cytoplasm','I_buffer'),...
        stateYao.funcLink.getZones,...
        sprintf('%s,%s',...
        'I_cell','I_nucleus') ))
%     [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID(I_cell,I_nucleus);
    


    [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
    stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = ellipseParameters;
    


    stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = I_nucleus;
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) = I_cytoplasm;
    stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) = I_buffer;
    
else
    stateYao.applyMask{numCycle}{iImg}(idxCell) = 1;
    
    
    
    stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) =...
        zeros( size(I_cell,1),size(I_cell,2) );
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) =...
        zeros( size(I_cell,1),size(I_cell,2) );
    stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) =...
        zeros( size(I_cell,1),size(I_cell,2) );
    
    stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = 0;
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} =...
        deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
end


end




end


end