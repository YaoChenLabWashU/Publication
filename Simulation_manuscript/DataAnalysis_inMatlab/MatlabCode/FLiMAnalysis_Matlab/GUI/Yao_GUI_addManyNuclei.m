function Yao_GUI_addManyNuclei(numCycle, iImg, ROINucleusInput)

global stateYao



% Get current image information
%  numCycle = stateYao.Disp.numCycle;
% iImg = stateYao.Disp.iImg;



isDendrite = 0;
if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    isDendrite = 1;
end



if isDendrite
    % Should be no ROIs. If there is, remove it
    Yao_GUI_removeROI
    
    
    
    % Add new ROI
    %   Direct user to spc_main
    %   Load appropriate image in spc_main
    %   Have user make ROI
    %   Have user close something to indicate they are done
    %   Load ROI data
    %   Display
%     hMsg = msgbox('Image will be loaded in spc_main. You will select new ROI there. Press ok when ready');
%     uiwait(hMsg)
%     
    
    numImage = stateYao.CyclePositions(iImg,numCycle);
    eval(sprintf('%s(%s)',...
        stateYao.funcLink.loadImage,...
        sprintf('%s,%s',...
        'numImage','[]') ))
%     Yao_generic_loadImage(numImage)
    
    
    
%   hMsg = msgbox('Delete all ROIs. Add new ROI then click OK');
%   uiwait(hMsg)
    
    
    
    iCell = 1;
    
    
    
    global gui
    
    stateYao.ROI{numCycle}{iImg}{iCell} = gui.gy.roiPositions{1,1};
    [stateYao.images.I_ROI_stack{numCycle}{iImg}] = Yao_generic_convertROI2I_ROI(...
        stateYao.ROI{numCycle}{iImg}{iCell},...
        size( stateYao.images.origData.rgbLifetimes{numCycle}(:,:,iImg) ,1),...
        size( stateYao.images.origData.rgbLifetimes{numCycle}(:,:,iImg) ,2) );
    
    
    
%     stateYao.ignoreImage(iImg,iCycle) = 0;
    
%     Yao_GUI_applyROI( stateYao.ROI{iCycle}{iImg} ,1)
    
    
    
else
    % Nucleus
    
%     hMsg = msgbox('Image will be loaded in spc_main. You will select new ROI there. Press ok when ready');
%     uiwait(hMsg)
    
    if ~exist('ROINucleusInput','var') || isempty(ROINucleusInput)
        numImage = stateYao.CyclePositions(iImg,numCycle);
        eval(sprintf('%s(%s)',...
            stateYao.funcLink.loadImage,...
            sprintf('%s,%s',...
            'numImage','[]') ))
        %     Yao_generic_loadImage(numImage)
        
        
        
%         hMsg = msgbox('Delete all ROIs. Add new ROI then click OK');
%         uiwait(hMsg)
        
        
        
        % Get points
        global gui
        
        pts = round( gui.gy.roiPositions{1,1} );
    
    else
        pts = ROINucleusInput;
    end
    
    % If the pts occur in any current cell, replace nucleus
    I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
    
    for iC = 1:size(I_cell_stack,3)
        iCell = iC;
        for iPt = 1:size(pts,1)
            if ~I_cell_stack( pts(iPt,2),pts(iPt,1),iC )
                iCell = [];
                break
            end
        end
        
        if ~isempty(iCell)
            break
        end
        
    end
    
    
    
    [A] = Yao_generic_fitEllipse(pts);
    [x0,y0,semimajor_axis,semiminor_axis,phi] =...
        Yao_generic_convertEllipseEqt_quad2std(A);
    
    phi = Yao_generic_getOrientation(pts,'Rad');
    
    ellipseParameters =...
        [x0 y0 semimajor_axis semiminor_axis rad2deg(phi)];
    
    
    
    if ~isempty(iCell)
        % Replace nucleus
        I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,iCell);
    else
% % %         % Add new cell
% % %         iCell = size(I_cell_stack,3) +1;
% % %         
% % %         img = stateYao.images.origData.rgbLifetimes{iCycle}(:,:,:,iImg);
% % %         [I_cell,centroid] = Yao_generic_isolateCell_findCell(img,pts);
% % %         
% % %         
% % %         
% % %         I_cell_stack(:,:,iCell) = I_cell;
% % %         stateYao.images.I_cell_stack{iCycle}{iImg} = I_cell_stack;
% % %         
% % %         
% % %         
% % %         x0 = centroid(1);
% % %         y0 = centroid(2);
% % %         
% % %         
% % %         cellDist = zeros(1,2);
% % %         for iImg2 = 1:size(stateYao.cellIdx{iCycle},1)
% % %             if iImg2 ~= iImg
% % %                 for iCell2 = 1:size(stateYao.cellIdx{iCycle}{iImg2},1)
% % %                     d = hypot(...
% % %                         x0-stateYao.cellIdx{iCycle}{iImg2}(iCell2,3),...
% % %                         y0-stateYao.cellIdx{iCycle}{iImg2}(iCell2,4) );
% % %                     
% % %                     if cellDist(1) == 0
% % %                         cellDist(1) = d;
% % %                         cellDist(2) = stateYao.cellIdx{iCycle}{iImg2}(iCell2,1);
% % %                     else
% % %                         if d < cellDist(1)
% % %                             cellDist(1) = d;
% % %                             cellDist(2) = stateYao.cellIdx{iCycle}{iImg2}(iCell2,1);
% % %                         end
% % %                     end
% % %                 end
% % %             end
% % %         end
% % %         
% % %         stateYao.cellIdx{iCycle}{iImg}(iCell,:) =...
% % %             [cellDist(2) hypot(x0,y0) x0 y0];
% % %         
% % %         
% % %         
    end

    
    if ~isempty(I_cell)
    stateYao.ellipseParameters{numCycle}{iImg}(iCell,1:5) = ellipseParameters;
    
    I_search = zeros( size(I_cell,1),size(I_cell,2) );
    
    t = linspace(0,2*pi(), 40 );
    X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
    Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
    
    clear t
    
    X = real(X);
    Y = real(Y);
    
    ellipsePoints = [Y' X'];
    clear X Y
    for iPixel = 1:size(ellipsePoints,1)
        I_search(...
            round(ellipsePoints(iPixel,1)),...
            round(ellipsePoints(iPixel,2)) ) = 1;
    end
%     I_search = Yao_generic_fillPts(I_search);
    I_search = Yao_generic_fillPts(I_search);
    
    eval(sprintf('[%s] = %s(%s);',...
        sprintf('%s,%s,%s',...
        'I_nucleus','I_cytoplasm','I_buffer'),...
        stateYao.funcLink.getZones,...
        sprintf('%s,%s',...
        'I_cell','I_search') ))
    
    
    
    [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
    stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = ellipseParameters;
    
    
    
    stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) = I_nucleus;
    stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell) = I_cytoplasm;
    stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell) = I_buffer;
    
    
    stateYao.applyMask{numCycle}{iImg}(iCell) = 0;
    
    stateYao.funcLink.findNucleus_func{numCycle}{iImg}{iCell} =...
        deblank( stateYao.funcLink.findNucleus_func_List(2,:) );
    stateYao.colorNucleus{numCycle}{iImg}{iCell} =...
        stateYao.CycleIdentification{numCycle,2};
    end
    
    
    
    
    
    
    
% % %     %   How many cells and ellipses should there be?
% % %     nCell = size( stateYao.cellIdx{iCycle}{iImg} ,1);
% % %     nEllipse = size( stateYao.ellipseParameters{iCycle}{iImg} ,1);
% % %     
% % %     if nCell ~= nEllipse
% % %         fprintf('%s: Invalid conditions\n',mfilename)
% % %     else
% % %         iCell = [];
% % %         if nEllipse == 1
% % %             if ~all( stateYao.ellipseParameters{iCycle}{iImg} ==0)
% % %                 % Should be no ellipse. If there is, remove it
% % %                 Yao_GUI_removeROI
% % %             end
% % %             iCell = 1;
% % %         end
% % %         
% % %         
% % %         
% % %         % Add new ROI
% % %         %   Direct user to spc_main
% % %         %   Load appropriate image in spc_main
% % %         %   Have user make ROI
% % %         %   Have user close something to indicate they are done
% % %         %   Load ROI data
% % %         %   Display
% % %         hMsg = msgbox('Image will be loaded in spc_main. You will select new ROI there. Press ok when ready');
% % %         uiwait(hMsg)
% % %         
% % %         
% % %         numImage = stateYao.CyclePositions(iImg, stateYao.numCycle(iCycle) );
% % %         Yao_generic_loadImage(numImage)
% % %         
% % %         
% % %         
% % %         hMsg = msgbox('Delete all ROIs. Add new ROI then click OK');
% % %         uiwait(hMsg)
% % %         
% % %         
% % %         
% % %         % Get points
% % %         global gui
% % %         
% % %         pts = round( gui.gy.roiPositions{1,1} );
% % %         
% % %         
% % %         
% % %         if isempty(iCell)
% % %             % Must have multiple cells, figure out which cell was selected
% % %             I_cell_stack = stateYao.images.I_cell_stack{iCycle}{iImg};
% % %             
% % %             for iC = 1:size(I_cell_stack,3)
% % %                 iCell = iC;
% % %                 for iPt = 1:size(pts,1)
% % %                     if ~I_cell_stack( pts(iPt,2),pts(iPt,1),iC )
% % %                         iCell = [];
% % %                         break
% % %                     end
% % %                 end
% % %                 
% % %                 if ~isempty(iCell)
% % %                     break
% % %                 end
% % %                 
% % %             end
% % %             
% % %         end
% % %         
% % %         
% % %         
% % %         if isempty(iCell)
% % %             fprintf('%s: Error - Some points are outside the cell\n',...
% % %                 mfilename)
% % %         else
% % %         % Convert points to ellipse, then re-build pts
% % %         if ~isempty( stateYao.Disp.ROI.userSelection.data )
% % %             if length(stateYao.Disp.ROI.userSelection.data) >= iCell
% % %                 nPts = size( stateYao.Disp.ROI.userSelection.data{iCell} ,1);
% % %             else
% % %                 nPts = size( stateYao.Disp.ROI.userSelection.data{1} ,1);
% % %             end
% % %         else
% % %             nPts = 6;
% % %         end
% % %         
% % %         [A] = Yao_generic_fitEllipse(pts);
% % %         [x0,y0,semimajor_axis,semiminor_axis,phi] =...
% % %             Yao_generic_convertEllipseEqt_quad2std(A);
% % %         
% % %         phi = Yao_generic_getOrientation(pts,'Rad');
% % %         
% % %         ellipseParameters =...
% % %             [x0 y0 semimajor_axis semiminor_axis rad2deg(phi)];
% % %         
% % %         
% % %         
% % % %         t = linspace(0,2*pi()-2*pi()/nPts, nPts );
% % % %         X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
% % % %         Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
% % % %         
% % % %         clear t
% % % %         
% % % %         X = real(X);
% % % %         Y = real(Y);
% % % %         
% % % %         pts = [X' Y'];
% % % %         clear X Y
% % % %         
% % % %         
% % % %         Yao_GUI_applyROI(pts,iCell)
% % %         
% % %         
% % %         
% % %         % Save
% % %         stateYao.ellipseParameters{iCycle}{iImg}(iCell,1:5) = ellipseParameters;
% % %         
% % %         I_cell = stateYao.images.I_cell_stack{iCycle}{iImg}(:,:,iCell);
% % %         I_search = zeros( size(I_cell,1),size(I_cell,2) );
% % %         
% % %         t = linspace(0,2*pi(), 40 );
% % %         X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
% % %         Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
% % %         
% % %         clear t
% % %         
% % %         X = real(X);
% % %         Y = real(Y);
% % %         
% % %         ellipsePoints = [Y' X'];
% % %         clear X Y
% % %         for iPixel = 1:size(ellipsePoints,1)
% % %             I_search(...
% % %                 round(ellipsePoints(iPixel,1)),...
% % %                 round(ellipsePoints(iPixel,2)) ) = 1;
% % %         end
% % %         I_search = Yao_generic_fillPts(I_search);
% % %         I_search = Yao_generic_fillPts(I_search);
% % %         
% % %         eval(sprintf('[%s] = %s(%s);',...
% % %             sprintf('%s,%s,%s',...
% % %             'I_nucleus','I_cytoplasm','I_buffer'),...
% % %             stateYao.funcLink.getZones,...
% % %             sprintf('%s,%s',...
% % %             'I_cell','I_search') ))
% % % %         [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID(I_cell,I_search);
% % %         
% % %         
% % %         
% % %         [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
% % %         stateYao.ellipseParameters{iCycle}{iImg}(iCell,:) = ellipseParameters;
% % %         
% % %     
% % %         
% % %         stateYao.images.I_nucleus_stack{iCycle}{iImg}(:,:,iCell) = I_nucleus;
% % %         stateYao.images.I_cytoplasm_stack{iCycle}{iImg}(:,:,iCell) = I_cytoplasm;
% % %         stateYao.images.I_buffer_stack{iCycle}{iImg}(:,:,iCell) = I_buffer;
% % %         
% % %         
% % %         stateYao.applyMask{iCycle}{iImg}(iCell) = 0;
% % %         
% % %         
% % %         
% % %         if nCell > 1
% % %             stateYao.Disp.cCell = iCell;
% % %         end
% % %         
% % %         
% % %         end
% % %         
% % %     end
    
end



stateYao.ignoreImage(iImg,numCycle) = 0;



Yao_GUI_loadImage


end