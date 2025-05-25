function Yao_GUI_modifyCell(opt)

global stateYao gui



numCycle = stateYao.Disp.numCycle;
% numCycle=2
iImg = stateYao.Disp.iImg;


numImage = stateYao.CyclePositions(iImg,numCycle );








eval(sprintf('%s(%s);',...
    stateYao.funcLink.loadImage,...
    sprintf('%s,''%s''',...
    'numImage','fast') ))






hMsg = msgbox('Delete all ROIs. Add new ROI then click OK');
uiwait(hMsg)




userInput = round( gui.gy.roiPositions{1,1} );





if any(any(...
        userInput(:,2) < 1 |...
        userInput(:,2) > size(stateYao.images.origData.projects{numCycle},1) |...
        userInput(:,1) < 1 |...
        userInput(:,1) > size(stateYao.images.origData.projects{numCycle},2) ))
    fprintf('\n\n%s: An invalid ROI point was detected. Please try again\n\n',...
        mfilename)
else




size1 = size( stateYao.images.origData.projects{numCycle} ,1);
size2 = size( stateYao.images.origData.projects{numCycle} ,2);

I_cell = zeros(size1,size2);

for iInput = 1:size(userInput)
    I_cell(userInput(iInput,2),userInput(iInput,1)) = 1;
end

I_cell = Yao_generic_fillPts(I_cell);


cc = regionprops( I_cell ,'Centroid');

x0 = cc(1).Centroid(1);
y0 = cc(1).Centroid(2);

[theta,rho] = cart2pol(x0,y0);





% Which cell was modified?
if exist('opt','var') && ~isempty(opt) && isnumeric(opt)
    idxCell = opt;
else
    overlapData = zeros(1,2);
    for i3 = 1:size( stateYao.images.I_cell_stack{numCycle}{iImg} ,3)
        if sum(sum( I_cell.*...
                stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,i3) )) ~= 0
            
            if overlapData(1,1) == 0
                overlapData = [i3 sum(sum( I_cell.*...
                    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,i3) ))];
            else
                overlapData = cat(1,overlapData,...
                    [i3 sum(sum( I_cell.*...
                    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,i3) ))] );
            end
            
        end
    end
    
    
    
    idxCell = [];
    if overlapData(1,1) ~= 0
        if size(overlapData,1) == 1
            idxCell = overlapData(1,1);
        else
            [max_val max_idx] = max( overlapData(:,2) );
            idxCell = overlapData(max_idx,1);
        end
    end
    
    
    
end

% mfilename

if isempty(idxCell)
    % No cell matched
    fprintf('%s: No cell has been identified at this location. Adding..\n',...
        mfilename)
    
    if isempty( stateYao.images.I_cell_stack{numCycle}{iImg} )
        stateYao.images.I_cell_stack{numCycle}{iImg} = I_cell;
        
        stateYao.ellipseParameters{numCycle}{iImg} = zeros(1,5);
        
        stateYao.images.I_nucleus_stack{numCycle}{iImg} = zeros(size1,size2);
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg} = zeros(size1,size2);
        stateYao.images.I_buffer_stack{numCycle}{iImg} = zeros(size1,size2);
        
        stateYao.cellIdx{numCycle}{iImg} = zeros(1,6);
        stateYao.cellIdx{numCycle}{iImg}(end,1) =...
            size(stateYao.images.I_cell_stack{numCycle}{iImg},3);
        stateYao.cellIdx{numCycle}{iImg}(end,3:6) =...
            [rho rad2deg(theta) x0 y0];
        
        stateYao.applyMask{numCycle}{iImg} = 0;
    else
        stateYao.images.I_cell_stack{numCycle}{iImg} = cat(3,...
            stateYao.images.I_cell_stack{numCycle}{iImg},...
            I_cell);
        
%         stateYao.ellipseParameters{numCycle}{iImg} = cat(1,...
%             stateYao.ellipseParameters{numCycle}{iImg},...
%             zeros(1, size(stateYao.ellipseParameters{iCycle}{iImg},2) ) );
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
        stateYao.cellidx{numCycle}{iImg}(end,1) =...
            size(stateYao.images.I_cell_stack{numCycle}{iImg},3);
        stateYao.cellIdx{numCycle}{iImg}(end,3:6) =...
        [rho rad2deg(theta) x0 y0];
        
        stateYao.applyMask{numCycle}{iImg} = cat(1,...
            stateYao.applyMask{numCycle}{iImg},...
            0);
    end
    
    
    
else % if isempty(idxCell)    
    stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,idxCell) = I_cell;
    
    
    
    if all( stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) == 0 )
        % No nucleus
        stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) =...
            zeros(1, size(stateYao.ellipseParameters{numCycle}{iImg},2) );
        
        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) =...
            zeros(size1,size2);
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) =...
            zeros(size1,size2);
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) =...
            zeros(size1,size2);
        
        stateYao.cellIdx{numCycle}{iImg}(idxCell,:) =...
            zeros(1, size(stateYao.cellIdx{numCycle}{iImg},2) );
        stateYao.cellidx{numCycle}{iImg}(idxCell,1) = idxCell;
        stateYao.cellIdx{numCycle}{iImg}(idxCell,3:6) =...
            [rho rad2deg(theta) x0 y0];
    else
        
        stateYao.cellIdx{numCycle}{iImg}(idxCell,3:6) =...
            [rho rad2deg(theta) x0 y0];
        
        
        
        I_nucleus =...
            stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell);
        
        eval(sprintf('[%s] = %s(%s);',...
            sprintf('%s,%s,%s',...
            'I_nucleus','I_cytoplasm','I_buffer'),...
            stateYao.funcLink.getZones,...
            sprintf('%s,%s',...
            'I_cell','I_nucleus') ))
        
        [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
        stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:) = ellipseParameters;
        
        stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,idxCell) = I_nucleus;
        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,idxCell) = I_cytoplasm;
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,idxCell) = I_buffer;
    end
end

% mfilename
Yao_GUI_loadImage

% mfilename

end



% % % % Get cell selection
% % % cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
% % % cPos = round( cPos(1,1:2) );
% % % 
% % % iCycle = stateYao.Disp.iCycle;
% % % iImg = stateYao.Disp.iImg;
% % % 
% % % 
% % % 
% % % I_cell_stack = stateYao.images.I_cell_stack{iCycle}{iImg};
% % % 
% % % for iC = 1:size(I_cell_stack,3)
% % %     iCell = iC;
% % %     if ~I_cell_stack( cPos(2),cPos(1),iC )
% % %         iCell = [];
% % %     end
% % %     
% % %     if ~isempty(iCell)
% % %         break
% % %     end
% % % end
% % % 
% % % 
% % % 
% % % if isempty(iCell)
% % %     fprintf('%s: Error - Mouse click was outside any cells\n',...
% % %         mfilename)
% % % else
% % % 
% % % stateYao.Disp.modifyCell.iCell = iCell;
% % % 
% % % 
% % % 
% % % % Prepare to create new window
% % % if isfield( stateYao.Disp.modifyCell ,'fig')
% % % if ~isempty( stateYao.Disp.modifyCell.fig.hdl )
% % % if ishandle( stateYao.Disp.modifyCell.fig.hdl )
% % %     delete( stateYao.Disp.modifyCell.fig.hdl )
% % % end
% % % end
% % % end
% % % stateYao.Disp.modifyCell.fig.hdl = [];
% % % stateYao.Disp.modifyCell.axis.hdl = [];
% % % stateYao.Disp.modifyCell.plot.hdl = [];
% % % stateYao.Disp.modifyCell.menu.hdl = [];
% % % 
% % % 
% % % 
% % % I_cell = I_cell_stack(:,:,iCell);
% % % img = stateYao.images.origData.rgbLifetimes{iCycle}(:,:,:,iImg);
% % % 
% % % stateYao.Disp.modifyCell.origData.I_cell = I_cell;
% % % stateYao.Disp.modifyCell.data.I_cell =...
% % %     stateYao.Disp.modifyCell.origData.I_cell;
% % % stateYao.Disp.modifyCell.origData.rgbLifetimes = img;
% % % 
% % % 
% % % 
% % % [pixelList_perim] = Yao_generic_getPerimeter(I_cell,'PixelList');
% % % for iPt = 1:size(pixelList_perim,1)
% % %     img(...
% % %         pixelList_perim(iPt,1),...
% % %         pixelList_perim(iPt,2), :) = 1;
% % % end
% % % 
% % % stateYao.Disp.modifyCell.origData.img = img;
% % % stateYao.Disp.modifyCell.data.img =...
% % %     stateYao.Disp.modifyCell.origData.img;
% % % 
% % % 
% % % 
% % % stateYao.Disp.modifyCell.menu.optList ={...
% % %     'SAVE','Yao_GUI_modifyCell_save';...
% % %     'Dilate','Yao_GUI_modifyCell_dilate';...
% % %     'Erode','Yao_GUI_modifyCell_erode';...
% % %     'Trim - Curve','Yao_GUI_modifyCell_trim_curve';...
% % %     'Reset','Yao_GUI_modifyCell_reset'};
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % % Create new window
% % % stateYao.Disp.modifyCell.fig.hdl = figure;
% % % set(stateYao.Disp.modifyCell.fig.hdl,'MenuBar','none')
% % % 
% % % % Get previous window position to re-position the new one
% % % global ghYao
% % % 
% % % figPosition = get(ghYao.MainWindow.hdl,'Position');
% % % panelPosition = get(ghYao.MainWindow.Disp.hdl,'Position');
% % % 
% % % l = figPosition(1)+panelPosition(1);
% % % b = figPosition(2)+panelPosition(2);
% % % w = panelPosition(3);
% % % h = panelPosition(4);
% % % 
% % % set(stateYao.Disp.modifyCell.fig.hdl,...
% % %     'Position',[l b w h])
% % % 
% % % 
% % % 
% % % stateYao.Disp.modifyCell.axis.hdl = axes(...
% % %     'Parent',stateYao.Disp.modifyCell.fig.hdl);
% % % 
% % % 
% % % 
% % % stateYao.Disp.modifyCell.plot.hdl =...
% % %     image( img ,...
% % %     'Parent', stateYao.Disp.modifyCell.axis.hdl);
% % % 
% % % set( stateYao.Disp.modifyCell.axis.hdl ,...
% % %     'XTick',[],'YTick',[],...
% % %     'Units','pixels',...
% % %     'Position',[0 0 w h])
% % % 
% % % 
% % % 
% % % 
% % % if ~isempty(stateYao.Disp.modifyCell.menu.hdl)
% % %     delete( stateYao.Disp.modifyCell.menu.hdl )
% % %     set(stateYao.Disp.modifyCell.plot.hdl,'uicontextmenu',[])
% % %     stateYao.Disp.modifyCell.menu.hdl = [];
% % % end
% % % 
% % % stateYao.Disp.modifyCell.menu.hdl = uicontextmenu;
% % % 
% % % for iOpt = 1:size( stateYao.Disp.modifyCell.menu.optList ,1)
% % %     uimenu( stateYao.Disp.modifyCell.menu.hdl ,...
% % %         'Label',...
% % %         stateYao.Disp.modifyCell.menu.optList{iOpt,1},...
% % %         'Callback',...
% % %         stateYao.Disp.modifyCell.menu.optList{iOpt,2} )
% % % end
% % % 
% % % set(stateYao.Disp.modifyCell.plot.hdl,...
% % %     'uicontextmenu',stateYao.Disp.modifyCell.menu.hdl)
% % % 
% % % 
% % % 
% % % 
% % % set( stateYao.Disp.modifyCell.fig.hdl ,...
% % %     'KeyPressFcn',...
% % %     @Yao_mouseFunc_modifyCell_genericKey)
% % % 
% % % 
% % % end