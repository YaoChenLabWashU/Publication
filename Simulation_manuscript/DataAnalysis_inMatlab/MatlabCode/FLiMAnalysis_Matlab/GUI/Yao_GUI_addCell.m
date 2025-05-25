function Yao_GUI_addCell(iImg)

% [mfilename ' 1']

global stateYao gui

numCycle = stateYao.Disp.numCycle;
% numCycle=2
iImg = stateYao.Disp.iImg;

numImage = stateYao.CyclePositions(iImg,numCycle);
eval(sprintf('%s(%s);',...
    stateYao.funcLink.loadImage,...
    sprintf('%s,%s',...
    'numImage','[]') ))

hMsg = msgbox('Delete all ROIs. Add new ROIs (first cell and then nucleus) then click OK');
uiwait(hMsg)

ROICellInput = [];
ROINucleusInput=[];
if size(gui.gy.roiPositions,2)==1
    ROICellInput = round( gui.gy.roiPositions{1,1} );
elseif size(gui.gy.roiPositions,2)==2
    ROICellInput = round( gui.gy.roiPositions{1,1} ); % assume that the first ROI is the cell, the second is the nucleus
    ROINucleusInput = round( gui.gy.roiPositions{1,2} );
    
    %%    checks to make sure cell size is bigger than nucleus size.
    
    size1 = size( stateYao.images.origData.projects{numCycle} ,1);
    size2 = size( stateYao.images.origData.projects{numCycle} ,2);
    
    I_cell = zeros(size1,size2);
    size_cell=0;
    for iInput = 1:size(ROICellInput,1)
        I_cell(ROICellInput(iInput,2),ROICellInput(iInput,1)) = 1;
    end
    I_cell = Yao_generic_fillPts(I_cell);
    size_cell=sum(sum(I_cell));
    
    I_nucleus = zeros(size1,size2);
    size_nucleus=0;
    for iInput = 1:size(ROINucleusInput,1)
        I_nucleus(ROINucleusInput(iInput,2),ROINucleusInput(iInput,1)) = 1;
    end
    I_nucleus = Yao_generic_fillPts(I_nucleus);
    size_nucleus=sum(sum(I_nucleus));
    
    if size_cell<size_nucleus
        a=ROICellInput;
        ROICellInput=ROINucleusInput;
        ROINucleusInput=a;
    end
    
    %%
else
    hMsg = msgbox('Select 1 or 2 ROIs.');
end

if isempty(ROICellInput)
else

size1 = size( stateYao.images.origData.projects{numCycle} ,1);
size2 = size( stateYao.images.origData.projects{numCycle} ,2);

I_cell = zeros(size1,size2);

for iInput = 1:size(ROICellInput,1)
    I_cell(ROICellInput(iInput,2),ROICellInput(iInput,1)) = 1;
end

I_cell = Yao_generic_fillPts(I_cell);



cc = regionprops( I_cell ,'Centroid');

x0 = cc(1).Centroid(1);
y0 = cc(1).Centroid(2);

[theta,rho] = cart2pol(x0,y0);



imageShift = stateYao.shift.second.imageShift{numCycle}(:,:);
idxList = 1:size(imageShift,1);
idxList(iImg) = [];

imageShift2 = [...
    imageShift(idxList,1)-imageShift(iImg,1) ...
    imageShift(idxList,2)-imageShift(iImg,2)];

d = cat(2,idxList',...
    hypot(imageShift2(:,1),imageShift2(:,2)));
d = sortrows(d,2);

size1 = size(I_cell,1);
size2 = size(I_cell,2);
imgTemp  = zeros(size1*3,size2*3);
imgTemp2 = zeros(size1,size2);
I_cell_mask = zeros(size1,size2);
cellID = [];
for iD = 1:size(d,1)
    iImg2 = d(iD,1);
    
    rx = 1+size2 +imageShift( iImg2 ,1):size2*2 +imageShift( iImg2 ,1);
    ry = 1+size1 +imageShift( iImg2 ,2):size1*2 +imageShift( iImg2 ,2);
    
    imgTemp(:,:) = zeros(size1*3,size2*3);
    imgTemp(ry,rx) = I_cell;
    imgTemp2(:,:) = imgTemp(1+size1:size1*2,1+size2:size2*2);
    
    for iCell = 1:size( stateYao.cellIdx{numCycle}{iImg2} ,1)
        
%         iCell
%         
%         iImg
%         iImg2
%         
%         stateYao.cellIdx{numCycle}{iImg}
%         stateYao.cellIdx{numCycle}{iImg2}
        
        if isempty(stateYao.cellIdx{numCycle}{iImg}) ||...
                ~any( stateYao.cellIdx{numCycle}{iImg2}(iCell,2) ==...
                stateYao.cellIdx{numCycle}{iImg}(:,2) )
%         iImg2
        
        idxCell = stateYao.cellIdx{numCycle}{iImg2}(iCell,1);
        I_cell_mask(:,:) = stateYao.images.I_cell_stack{numCycle}{iImg2}(:,:,idxCell);
        
        if sum(sum( imgTemp2.*I_cell_mask )) ~= 0
            if isempty(cellID)
                cellID = [...
                    stateYao.cellIdx{numCycle}{iImg2}(iCell,2) ...
                    sum(sum( imgTemp2.*I_cell_mask ))];
            else
                cellID = cat(1,cellID,[...
                    stateYao.cellIdx{numCycle}{iImg2}(iCell,2) ...
                    sum(sum( imgTemp2.*I_cell_mask ))] );
            end
        end
        
        end
    end
    
    if ~isempty(cellID)
        cellID = sortrows(cellID,-2);
        cellID = cellID(1,1);
        break
    end
    
end



if isempty(cellID)
    
    cellIDInput = [];
    while isempty(cellIDInput)
        
        cellIDInput = inputdlg('Enter new Cell ID');
        if ~isempty(cellIDInput)
            cellIDInput = str2num( cellIDInput{1} );
            % Non-numeric inputs will cause userInput to be empty
            
            if ~isempty(cellIDInput) && ~isempty(stateYao.cellIdx{numCycle}{iImg})
            if any( cellIDInput == stateYao.cellIdx{numCycle}{iImg}(:,2) )
                fprintf('%s: Cell ID %d is already taken\n',...
                    mfilename,cellIDInput)
                cellIDInput = [];
            end
            end
        end
        
    end
    
    cellID = cellIDInput;
    
end





if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
    stateYao.images.I_cell_stack{numCycle}{iImg} = I_cell;
    
    stateYao.ellipseParameters{numCycle}{iImg} = zeros(1,5);
    
    stateYao.images.I_nucleus_stack{numCycle}{iImg} = zeros(size1,size2);
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg} = zeros(size1,size2);
    stateYao.images.I_buffer_stack{numCycle}{iImg} = zeros(size1,size2);
    
    stateYao.cellIdx{numCycle}{iImg} = zeros(1,6);
    stateYao.cellIdx{numCycle}{iImg}(1,1) =...
        size(stateYao.images.I_cell_stack{numCycle}{iImg},3);    
    stateYao.cellIdx{numCycle}{iImg}(1,3:6) =...
        [rho rad2deg(theta) x0 y0];
    stateYao.cellIdx{numCycle}{iImg}(1,2) = cellID;
    
    
    
    stateYao.applyMask{numCycle}{iImg} = 0;
    
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{1} =...
        deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
    stateYao.colorNucleus{numCycle}{iImg}{1} =...
        stateYao.CycleIdentification{numCycle,2};
else
    stateYao.images.I_cell_stack{numCycle}{iImg} = cat(3,...
        stateYao.images.I_cell_stack{numCycle}{iImg},...
        I_cell);
    
    stateYao.ellipseParameters{numCycle}{iImg} = cat(1,...
        stateYao.ellipseParameters{numCycle}{iImg},...
        zeros(1, size(stateYao.ellipseParameters{numCycle}{iImg},2) ) );
    
    stateYao.images.I_nucleus_stack{numCycle}{iImg} = cat(3,...
        stateYao.images.I_nucleus_stack{numCycle}{iImg},...
        zeros(size1,size2) );
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg} = cat(3,...
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg},...
        zeros(size1,size2) );
    stateYao.images.I_buffer_stack{numCycle}{iImg} = cat(3,...
        stateYao.images.I_buffer_stack{numCycle}{iImg},...
        zeros(size1,size2) );
    
    stateYao.cellIdx{numCycle}{iImg} = cat(1,...
        stateYao.cellIdx{numCycle}{iImg},...
        zeros(1, size(stateYao.cellIdx{numCycle}{iImg},2) ) );
    stateYao.cellIdx{numCycle}{iImg}(end,1) =...
        size(stateYao.images.I_cell_stack{numCycle}{iImg},3);
    stateYao.cellIdx{numCycle}{iImg}(end,3:6) =...
        [rho rad2deg(theta) x0 y0];
    stateYao.cellIdx{numCycle}{iImg}(end,2) = cellID;
    
    
    
    stateYao.applyMask{numCycle}{iImg} = cat(1,...
        stateYao.applyMask{numCycle}{iImg},...
        0);
    
    
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{end+1} =...
        deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
    stateYao.colorNucleus{numCycle}{iImg}{end+1} =...
        stateYao.CycleIdentification{numCycle,2};
end



Yao_GUI_loadImage



%%
% Now ask to add nucleus

if isempty(ROINucleusInput)
    Yao_GUI_addROI;
else
    Yao_GUI_addROI(ROINucleusInput);
end

end
% [mfilename ' 5']