function Yao_GUI_loadImage

global stateYao ghYao

numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



if any(stateYao.Disp.ROI.userSelection.hdl~=0)
    for iHdl = 1:length(stateYao.Disp.ROI.userSelection.hdl)
        if stateYao.Disp.ROI.userSelection.hdl(iHdl) ~= 0
            delete(stateYao.Disp.ROI.userSelection.hdl(iHdl))
            delete(stateYao.Disp.ROI.userSelectionUnder.hdl(iHdl))
            stateYao.Disp.ROI.userSelection.hdl(iHdl) = 0;
            stateYao.Disp.ROI.userSelectionUnder.hdl(iHdl) = 0;
        end
    end    
end
if any(stateYao.Disp.ROI.ellipse.hdl ~=0)
    for iHdl = 1:length(stateYao.Disp.ROI.ellipse.hdl)
        if stateYao.Disp.ROI.ellipse.hdl(iHdl) ~= 0
            delete(stateYao.Disp.ROI.ellipse.hdl(iHdl))
            delete(stateYao.Disp.ROI.ellipseUnder.hdl(iHdl))
            stateYao.Disp.ROI.ellipse.hdl(iHdl) = 0;
            stateYao.Disp.ROI.ellipseUnder.hdl(iHdl) = 0;
        end
    end    
end
if any(stateYao.Disp.ROI.buffer.hdl ~=0)
    for iHdl = 1:length(stateYao.Disp.ROI.buffer.hdl)
        if stateYao.Disp.ROI.buffer.hdl(iHdl) ~= 0
            delete(stateYao.Disp.ROI.buffer.hdl(iHdl))
            delete(stateYao.Disp.ROI.bufferUnder.hdl(iHdl))
            stateYao.Disp.ROI.buffer.hdl(iHdl) = 0;
            stateYao.Disp.ROI.bufferUnder.hdl(iHdl) = 0;
        end
    end    
end
if any(stateYao.Disp.ROI.cell.hdl ~=0)
    for iHdl = 1:length(stateYao.Disp.ROI.cell.hdl)
        if stateYao.Disp.ROI.cell.hdl(iHdl) ~= 0
            delete(stateYao.Disp.ROI.cell.hdl(iHdl))
            delete(stateYao.Disp.ROI.cellUnder.hdl(iHdl))
            stateYao.Disp.ROI.cell.hdl(iHdl) = 0;
            stateYao.Disp.ROI.cellUnder.hdl(iHdl) = 0;
        end
    end    
end



if ~isempty( stateYao.cellIdx{numCycle} )
    stateYao.Disp.ROI.userSelection.hdl =...
        zeros( size( stateYao.cellIdx{numCycle}{iImg} ,1 ),1);
else
    stateYao.Disp.ROI.userSelection.hdl = 0;
end



if stateYao.CyclePositions(iImg,numCycle) == 0
    fprintf('%s: This image is not meant to be loaded!\n',...
        mfilename)
    
    if stateYao.Disp.iImg ~= 1
        stateYao.Disp.iImg = 1;
        
        Yao_GUI_loadImage
    else
        if any(stateYao.CyclePositions(:,iCycle) ~=0)
            for iPos = 1:size(stateYao.CyclePosition,1)
                if stateYao.CyclePositions(iPos,numCycle) ~=0
                    stateYao.Disp.iImg = iPos;
                    Yao_GUI_loadImage
                    break
                end
            end
        end
    end
    
    
    
else
    
    if isnumeric( stateYao.CycleIdentification{numCycle,2} )
        % Dendrite
%         img = stateYao.imageStack{iCycle}(:,:,iImg);
        img = stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg);
        
        
        if ~isempty( stateYao.Disp.plot.hdl )
            set(stateYao.Disp.plot.hdl,...
                'CData',...
                img )
        else
            stateYao.Disp.plot.hdl =...
                imshow( img ,...
                'Parent', stateYao.Disp.axis.hdl);
        end
        
%         if min(min(img)) ~= max(max(img))
%             set(stateYao.Disp.axis.hdl,...
%                 'CLim',[min(min(img)) max(max(img))])
%         end
        drawnow
        
        
        
        if ~isempty(stateYao.Disp.menu.hdl)
            delete( stateYao.Disp.menu.hdl )
            set(stateYao.Disp.plot.hdl,'uicontextmenu',[])
            stateYao.Disp.menu.hdl = [];
        end
%         figure(ghYao.MainWindow.hdl); stateYao.Disp.menu.hdl = uicontextmenu;
        stateYao.Disp.menu.hdl = uicontextmenu('Parent',ghYao.MainWindow.hdl);
        
        for iOpt = 1:size( stateYao.Disp.menu.dendrite.optList ,1)
            uimenu( stateYao.Disp.menu.hdl ,...
                'Label',...
                stateYao.Disp.menu.dendrite.optList{iOpt,1},...
                'Callback',...
                stateYao.Disp.menu.dendrite.optList{iOpt,2} )
        end
        
        set(stateYao.Disp.plot.hdl,'uicontextmenu',stateYao.Disp.menu.hdl)


        
    else
        % Nucleus
        
        
        if ~isempty( stateYao.cellIdx{numCycle}{iImg} )
            if ~any( stateYao.cellIdx{numCycle}{iImg}(:,2) == stateYao.Disp.cCell )
                stateYao.Disp.cCell = min( stateYao.cellIdx{numCycle}{iImg}(:,2) );
            end
        end
%         temp = stateYao.cellIdx{iCycle}{iImg}(:,2);
%         if stateYao.Disp.cCell > size(temp,1)
%             find_cCell = 1;
%         elseif ~any( temp(:) == stateYao.Disp.cCell )
%             find_cCell = 1;
%         end
%         
%         if find_cCell
%             if ~any( ~all( temp' == 0 ) )
%                 % No ellipses
%                 stateYao.Disp.cCell = 1;
%             else
%                 temp = ~all( temp' == 0 );
%                 temp = cat(2,temp',[1:size(temp,2)]');
%                 temp = temp( temp(:,1)~=0 ,2);
%                 stateYao.Disp.cCell = temp(1);
%             end
%         end

        
        
        
        
        img = stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg);
        
        
        if stateYao.ignoreImage(...
            stateYao.Disp.iImg,...
            stateYao.Disp.numCycle ) == 0
        
        for iCell = 1:size( stateYao.images.I_cell_stack{numCycle}{iImg} ,3)
            I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,iCell);
            if any(any(I_cell))
                [pixelList_perim] = Yao_generic_getPerimeter(I_cell,'PixelList');
                for iPt = 1:size(pixelList_perim,1)
%                     img(...
%                         pixelList_perim(iPt,1),...
%                         pixelList_perim(iPt,2), :) = 1;
                    img(...
                        pixelList_perim(iPt,1),...
                        pixelList_perim(iPt,2), :) = [1 1 1];
                    % Display cell perimeter in [1 1 1] which is white
                end
            end
            
            I_buffer = stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell);
            if any(any(I_buffer))
                [pixelList_perim] = Yao_generic_getPerimeter(I_buffer,'PixelList');
                for iPt = 1:size(pixelList_perim,1)
%                     img(...
%                         pixelList_perim(iPt,1),...
%                         pixelList_perim(iPt,2), :) = 1;
                    img(...
                        pixelList_perim(iPt,1),...
                        pixelList_perim(iPt,2), :) = [0 0 0];
                    % Display nucleus buffer in [0 0 0] which is black
                end
            end
        end
        
        end
        
        
        
        
        
        
        if ~isempty( stateYao.Disp.plot.hdl )
            set(stateYao.Disp.plot.hdl,...
                'CData',...
                img )
        else
            stateYao.Disp.plot.hdl =...
                imshow( img ,...
                'Parent', stateYao.Disp.axis.hdl);
        end
        
        
        
        if ~isempty(stateYao.Disp.menu.hdl)
            delete( stateYao.Disp.menu.hdl )
            stateYao.Disp.menu.hdl = [];
        end
%         figure(ghYao.MainWindow.hdl); stateYao.Disp.menu.hdl = uicontextmenu;
        stateYao.Disp.menu.hdl = uicontextmenu('Parent',ghYao.MainWindow.hdl);
        
        for iOpt = 1:size( stateYao.Disp.menu.nucleus.optList ,1)
            uimenu( stateYao.Disp.menu.hdl ,...
                'Label',...
                stateYao.Disp.menu.nucleus.optList{iOpt,1},...
                'Callback',...
                stateYao.Disp.menu.nucleus.optList{iOpt,2} )
        end
        
        set(stateYao.Disp.plot.hdl,'uicontextmenu',stateYao.Disp.menu.hdl)
        
        
    end
    
    
    
    % So now we have the image loaded, with cell perimeters and nucleus
    % buffers highlighted. We just loaded our right-click context menu.
    % We are ready to display the nuclei
    if stateYao.ignoreImage(...
            stateYao.Disp.iImg,...
            stateYao.Disp.numCycle ) == 0
        
        % Display nucleus
        Yao_GUI_applyROI
    end
    
    
    numImage = stateYao.CyclePositions(stateYao.Disp.iImg,stateYao.Disp.numCycle);
    
    set( stateYao.Disp.Position.Edit.hdl ,'String',num2str( numImage ) )
    set( stateYao.Disp.Position.Slider.hdl ,'Value',stateYao.Disp.iImg )
    
   
    
    
    
    
    Yao_GUI_Other_builder
    
end








end