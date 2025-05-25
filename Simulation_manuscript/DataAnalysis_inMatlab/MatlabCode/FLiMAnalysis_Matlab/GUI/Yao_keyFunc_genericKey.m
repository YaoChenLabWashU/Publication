function Yao_keyFunc_genericKey(src,eventdata)


global stateYao

if ~stateYao.Disp.mode.runningCB
% stateYao.Disp.mode.runningCB = 1;


global ghYao

if src == ghYao.MainWindow.hdl
    cKey = get(src,'CurrentKey');
    
    
    
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    cellID = stateYao.Disp.cCell;
    
    
    if ~isnumeric( stateYao.CycleIdentification{numCycle,2} )
        iCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1);
        iCell = iCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
        iCell = stateYao.cellIdx{numCycle}{iImg}(iCell,1);
    else
        iCell = cellID;
    end
    
    
    
    runZoneID = 0;
    runLoadImage = 0;
    
    new_iCell = [];
    new_iImg = [];
    
    if size(cKey,2) == 1
        % Letter
        if strcmpi(cKey,'e')
            % Erode
            stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) =...
                imerode(...
                stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell),...
                strel('disk',1) );
            
            runZoneID = 1;
            runLoadImage = 1;
            
        elseif strcmpi(cKey,'d')
            % Dilate
            stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) =...
                imdilate(...
                stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell),...
                strel('disk',1) );
            
            runZoneID = 1;
            runLoadImage = 1;
            
            
        elseif strcmpi(cKey,'m')
            Yao_GUI_modifyCell(iCell)
        elseif strcmpi(cKey,'a') %add cell
            Yao_GUI_addCell
        end
        
    else
        if regexp(cKey,'arrow')
            if strcmp(cKey,'uparrow')
                % Change cCell
                new_iCell = iCell-1;
            elseif strcmp(cKey,'downarrow')
                % Change cCell
                new_iCell = iCell+1;
            elseif strcmp(cKey,'rightarrow')
                % Change iImg
                new_iImg = iImg+1;
            elseif strcmp(cKey,'leftarrow')
                % Change iImg
                new_iImg = iImg-1;
            end
        end
    end
    
    
    
    
    
    
    
    if runZoneID
        if ~exist('I_cell','var')
            I_cell = stateYao.images.I_cell_stack{numCycle}{iImg}(:,:,iCell);
        end
        if ~exist('I_nucleus','var')
            I_nucleus = stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell);
        end
        
        eval(sprintf('[%s] = %s(%s);',...
            sprintf('%s,%s,%s',...
            'I_nucleus','I_cytoplasm','I_buffer'),...
            stateYao.funcLink.getZones,...
            sprintf('%s,%s',...
            'I_cell','I_nucleus') ))
%         [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID(I_cell,I_nucleus);
        

        
        [I_nucleus,ellipseParameters] = Yao_generic_convert2Ellipse(I_nucleus);
        stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = ellipseParameters;
    


        stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell) = I_cytoplasm;
        stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell) = I_buffer;
        
        [I_nucleus,ellipseParameters] =...
            Yao_generic_convert2Ellipse(I_nucleus);
        stateYao.ellipseParameters{numCycle}{iImg}(iCell,1:5) =...
            ellipseParameters;
    end
    
    
    
    if ~isempty(new_iCell)
        if ~isempty(stateYao.cellIdx{numCycle}{iImg})
            cellIdList = stateYao.cellIdx{numCycle}{iImg}(:,2);
            
            if size(cellIdList,1) > 1
            if new_iCell < iCell
                if ~any( cellIdList < cellID )
                    stateYao.Disp.cCell = max(cellIdList);
                else
                    cellIdList = cellIdList( cellIdList < cellID );
                    stateYao.Disp.cCell = max(cellIdList);
                end
            else
                if ~any( cellIdList > cellID )
                    stateYao.Disp.cCell = min(cellIdList);
                else
                    cellIdList = cellIdList( cellIdList > cellID );
                    stateYao.Disp.cCell = min(cellIdList);
                end
            end
            runLoadImage = 1;
            end
        end
%         nCell = 1;
%         if ~isempty( stateYao.cellIdx{iCycle} )
%             if length( stateYao.cellIdx{iCycle} ) >= iImg
%             if ~isempty( stateYao.cellIdx{iCycle}{iImg} )
%                 nCell = size( stateYao.cellIdx{iCycle}{iImg} ,1);
%             end
%             end
%         end
%         
%         if nCell == 1
%             % Can't change cell
%         else
%             if new_iCell < 1
%                 new_iCell = nCell;
%             elseif new_iCell > nCell
%                 new_iCell = 1;
%             end
%             
%             stateYao.Disp.cCell = new_iCell;
%             runLoadImage = 1;
%             
%         end
    end
    
    
    
    if ~isempty(new_iImg)
        temp = stateYao.CyclePositions(:,numCycle);
        temp = cat(2,temp,[1:size(stateYao.CyclePositions,1)]');
%         temp = cat(2,temp,stateYao.ignoreImage(:,stateYao.numCycle(iCycle)));
        temp = temp( temp(:,1)~=0 ,:);
%         temp = temp( temp(:,3)==0 ,:);
        

        if ~any( temp(:,2) == new_iImg )


        % Which direction is the user moving?
        if new_iImg > stateYao.Disp.iImg
            % Can we move forward?
            if new_iImg < temp(end,2)
                % Yes
                temp2 = temp(:,2) > new_iImg;
                [max_val max_idx] = max(temp2);
                
                new_iImg = temp(max_idx,2);
            else
                % No
%                 new_iImg = temp(1,2);
                new_iImg = temp(end,2);
            end
        else
            % Can we move back?
            if new_iImg > temp(1,2)
                % Yes
                temp2 = temp(:,2) < new_iImg;
                temp2 = temp2( end:-1:1 );
                [max_val max_idx] = max(temp2);
                max_idx = size(temp2,1) - max_idx +1;
                
                new_iImg = temp(max_idx,2);
            elseif new_iImg == temp(1,2)
                new_iImg = temp(1,2);
            else
%                 new_iImg = temp(end,2);
                new_iImg = temp(1,2);
            end
        end
        
        
        end
        new_numImage = stateYao.CyclePositions(new_iImg,numCycle);
        
        
        
%         stateYao.Disp.cCell = 1;
        
        
        
        stateYao.Disp.iImg = new_iImg;
        
        set( stateYao.Disp.Position.Slider.hdl ,...
            'Value',new_iImg)
        set( stateYao.Disp.Position.Edit.hdl ,...
            'String',num2str( new_numImage ) )
        
        runLoadImage = 1;
        
    end
    
    
    
    if runLoadImage
        Yao_GUI_loadImage
    end
    
end



stateYao.Disp.mode.runningCB = 0;
end