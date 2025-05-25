function Yao_GUI_Other_builder

global stateYao ghYao


% Panel link
panelName = 'ghYao.MainWindow.Other';
panelHdl = eval(sprintf('%s.hdl',panelName));



% Delete current buttons
fieldList = fieldnames( eval(panelName) );
if size(fieldList,1) > 1
    for iField = 2:size(fieldList,1)
        
        hdl = eval(sprintf('%s.%s.hdl',...
            panelName,...
            fieldList{iField} ));
        
        if ishandle(hdl)
            delete(hdl)
        end
    end
end
ghYao.MainWindow = rmfield(ghYao.MainWindow,'Other');
ghYao.MainWindow.Other.hdl = panelHdl;



if stateYao.ignoreImage(...
            stateYao.Disp.iImg,...
            stateYao.Disp.numCycle ) == 0


% Build new buttons
numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



% Dendrite or nucleus?
if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    % Dendrite
    
    
    
% Build info
panelPosition = get( panelHdl ,'Position');

l_start = 0;
b_top = panelPosition(4);
w_col = 60;
h_row = 40;

w_text = 55;
w_edit = 40;
% w_checkbox = 20;
w_checkbox = 20;


wGapSum = 0;







%   How many defined cells do we have?
nROI = length(stateYao.ROI{numCycle}{iImg});
if nROI ~= 0  
    
    
    
    temp_projects = stateYao.images.origData.projects{numCycle}(:,:,iImg);
    temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle}(:,:,iImg);
    
    for iROI = 1:nROI
        iCell = iROI;
        
        
        
%         idxList = 1:size( stateYao.cellIdx{iCycle}{iImg} ,1);
%         idxList = idxList( stateYao.cellIdx{iCycle}{iImg}(:,1) == iCell );
%         cellID = stateYao.cellIdx{iCycle}{iImg}(idxList,2);
        cellID = iCell; 
        
        
        I_ROI = stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell);
        
        
        [val_Projection] = Yao_calc_Projection(...
            temp_projects,...
            I_ROI);
        [val_LifetimeMap] = Yao_calc_Lifetime(...
            temp_projects,temp_lifetimeMaps,I_ROI);
%         % Projection values
%         val_Projection =...
%             sum(sum( temp_projects.*I_ROI ))/sum(sum( I_ROI ));
%         
%         % Lifetime values
%         nTimesTau = I_ROI .*temp_projects .*temp_lifetimeMaps;
%         
%         val_LifetimeMap =...
%             sum(nTimesTau(:))/...
%             sum( temp_projects(:).*I_ROI(:) );
        
        
        
        stateYao.Results.spc_calculateROIvals.Projection{numCycle}{iImg}(iCell) =...
            val_Projection;
        stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle}{iImg}(iCell) =...
            val_LifetimeMap;
        
        
        % Create GUI objects
        %   0 = text
        %   1 = checkbox (disabled)
        %   2 = edit (disabled)
        styleMatrix = [0 2 2];
        enableMatrix = [0 0 0];
        
        for iObj = 1:3
            
            str = [];
            str_color = [];
            val = [];
            
            l_col = l_start+w_col*(iObj-1) -wGapSum;
            b = b_top - h_row*(iROI+2);
            
            if styleMatrix(iObj) == 0
                % Text
                w = w_text;
                h = h_row *2/3;
                
%                 l = l_col+w_col/2-w/2;
                
                styleObj = 'text';
                
                str = sprintf('Cell %d',iCell);
                
                
                if iCell == stateYao.Disp.cCell
                    str_color = 'm';
                else
                    if cellID <= size( stateYao.colorList ,1)
                        str_color = stateYao.colorList(cellID);
                    else
                        str_color = stateYao.colorList(end);
                    end
                end
                
%             elseif styleMatrix(iObj) == 1
%                 % Checkbox (disabled)
%                 w = w_checkbox;
%                 h = h_row;
%                 
%                 styleObj = 'checkbox';
%                 
%                 val = isMask;
            elseif styleMatrix(iObj) == 2
                % edit (disabled)
                w = w_edit;
                h = h_row;
                
                styleObj = 'edit';
                
                if iObj == 2
                    str =...
                        stateYao.Results.spc_calculateROIvals.Projection{numCycle}{iImg}(iCell);
                elseif iObj == 3
                    str =...
                        stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle}{iImg}(iCell);
                end
                
                if iCell == stateYao.Disp.cCell
                    str_color = 'm';
                else
                    if cellID <= size( stateYao.colorList ,1)
                        str_color = stateYao.colorList(cellID);
                    else
                        str_color = stateYao.colorList(end);
                    end
                end
                
            end
            
            
%             l = l_col;
            l = l_col + (w_col-w)/2;
%             wGapSum = wGapSum+(w_col-w)/2;
            
            
            
            temp_hdl = uicontrol(...
                'Parent',panelHdl,...
                'Style',styleObj,...
                'Units','pixels',...
                'Position',[l b w h]);
            
            if ~isempty(str)
                if ischar(str)
                    set(temp_hdl,'String',str)
                else
                    if str > 1e2
                        set(temp_hdl,'String', sprintf('%2.0f',str) )
                    elseif str > 1e1
                        set(temp_hdl,'String', sprintf('%1.1f',str) )
                    else
                        set(temp_hdl,'String', sprintf('%0.2f',str) )
                    end
                end
                set(temp_hdl,'HorizontalAlignment','left')
                if ~isempty(str_color)
                    set(temp_hdl,'ForegroundColor',str_color)
                end
            end
            if ~isempty(val)
                set(temp_hdl,'Value',val)
            end
            
            if enableMatrix(iObj) == 0;
                set(temp_hdl,'Enable','inactive')
            end
            
            objName = sprintf('ROI%dObj%d',iROI,iObj);
            eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
            
            eval(sprintf('set(%s,''Tag'',''%s'')',...
                sprintf('%s.%s.hdl',panelName,objName),...
                sprintf('%s.%s',panelName,objName) ))
            
            
            
            
            w = w_text;
            if iROI == 1
                % Build labels above
%                 b = b_top - h_row*(iEllipse);
                b = b+h_row*3/2;
                h = h_row/2;
                
                str =[];
                if iObj == 1
                    str = 'Cell ID';
                elseif iObj == 2
                    str = 'Projection';
                    
                    w = w*1.5;
                elseif iObj == 3
                    str = 'LifetimeMap';
                    
                    w = w*1.5;
                end
                
                
                
                if ~isempty(str)
                    temp_hdl = uicontrol(...
                        'Parent',panelHdl,...
                        'Style','text',...
                        'Units','pixels',...
                        'Position',[l b w h]);
                    
                    set(temp_hdl,'String',str,...
                        'HorizontalAlignment','left')
                    
                    objName = sprintf('Label_Obj%d',iROI,iObj);
                    eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
                    
                    eval(sprintf('set(%s,''Tag'',''%s'')',...
                        sprintf('%s.%s.hdl',panelName,objName),...
                        sprintf('%s.%s',panelName,objName) ))
                end
                
                
                
                        
                        
                
                
            end
            
            
        end
        
        
        
        
        
        
    end
end
    
    
    
    
    
    
    
    
    
else
    % Nucleus







% Build info
panelPosition = get( panelHdl ,'Position');

l_start = 0;
b_top = panelPosition(4);
w_col = 60;
h_row = 40;

w_text = 55;
w_edit = 40;
% w_checkbox = 20;
w_checkbox = 20;


wGapSum = 0;


h_nucleusSearch = 20;
w_nucleusSearch = w_col*4;




%   How many defined cells do we have?
if ~isempty( stateYao.cellIdx{numCycle}{iImg} )

% nEllipse = sum( ~all(stateYao.ellipseParameters{iCycle}{iImg}'==0) );
% if nEllipse ~= 0
    
    cellIdList = stateYao.cellIdx{numCycle}{iImg}(:,2);
    cellIdList = unique(cellIdList);
    if any( cellIdList == 0 )
        cellIdList( cellIdList == 0 ) = [];
    end
    
    
    if ~isempty(cellIdList)
    
    
    for iCellId = size(cellIdList,1):-1:1
        idxCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
        idxCell = idxCell( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellIdList(iCellId) );
        idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
        
%         if all(stateYao.ellipseParameters{iCycle}{iImg}(idxCell,:)==0)
%             cellIdList(iCellId) = [];
%         end
    end
    
    
    
    
    
    temp_projects = stateYao.images.origData.projects{numCycle}(:,:,iImg);
    temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle}(:,:,iImg);
    
    se = strel('disk', stateYao.nucleusOpt.erodeCell_calc(numCycle) );
    
    for iCellID = 1:size(cellIdList,1)
        cellID = cellIdList(iCellID);
        iCell = stateYao.cellIdx{numCycle}{iImg}( stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID ,1);
                
        
        
        % isIgnore
        numCycle
        iImg
        iCell     
        
        isMask = stateYao.applyMask{numCycle}{iImg}(iCell);
        
        I_nucleus = stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell);
        I_cytoplasm = stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell);
%         I_cell = stateYao.I_cell_stack{iCycle}{iImg}(:,:,iCell);
        

        
        
        for iType = 1:2
            if iType == 1
                % Nucleus
                I_mask = I_nucleus;
            else
                % Cytoplasm
                I_mask = I_cytoplasm;
            end
            
            
            
            % Projection values
            val_Projection = Yao_calc_Projection(...
                temp_projects,...
                I_mask);
            
            % Lifetime values
            val_LifetimeMap = Yao_calc_Lifetime(...
                temp_projects,...
                temp_lifetimeMaps,...
                I_mask);
%             % Projection values
%             val_Projection =...
%                 sum(sum( temp_projects.*I_type ))/sum(sum( I_type ));
%             
%             % Lifetime values
%             nTimesTau = I_type .*temp_projects .*temp_lifetimeMaps;
%             
%             val_LifetimeMap =...
%                 sum(nTimesTau(:))/...
%                 sum( temp_projects(:).*I_type(:) );
            
            
            
            stateYao.Results.spc_calculateROIvals.Projection{numCycle}{iImg}(iCell,iType) =...
                val_Projection;
            stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle}{iImg}(iCell,iType) =...
                val_LifetimeMap;
        end
        
        
        
        
        
        
        
        % Create GUI objects
        %   0 = text
        %   1 = checkbox (disabled)
        %   2 = edit (disabled)
        %   3 = pushbutton
        styleMatrix = [0 2 2 2 2 1 3];
        typeMatrix = [0 1 2 1 2 0 0];
        enableMatrix = [0 0 0 0 0 0 1];
        
        for iObj = 1:7
            
            str = [];
            str_color = [];
            val = [];
            
            l_col = l_start+w_col*(iObj-1) -wGapSum;
            b = b_top - h_row*(iCellID+2) -h_nucleusSearch*(iCellID-1);
            
            if styleMatrix(iObj) == 0
                % Text
                w = w_text;
                h = h_row *2/3;
                
%                 l = l_col+w_col/2-w/2;
                
                styleObj = 'text';
                
                str = sprintf('Cell %d',cellID);
                
                
                if cellID == stateYao.Disp.cCell
                    str_color = 'm';
                else
                    if cellID <= size( stateYao.colorList ,1)
                        str_color = stateYao.colorList(cellID);
                    else
                        str_color = stateYao.colorList(end);
                    end
                end
                
            elseif styleMatrix(iObj) == 1
                % Checkbox (disabled)
                w = w_checkbox;
                h = h_row;
                
                styleObj = 'checkbox';
                
                val = isMask;
            elseif styleMatrix(iObj) == 2
                % edit (disabled)
                w = w_edit;
                h = h_row;
                
                styleObj = 'edit';
                
                if iObj <= 3
                    str =...
                        stateYao.Results.spc_calculateROIvals.Projection{numCycle}{iImg}(iCell, typeMatrix(iObj) );
                else
                    str =...
                        stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle}{iImg}(iCell, typeMatrix(iObj) );
                end
                
                if cellID == stateYao.Disp.cCell
                    str_color = 'm';
                else
                    if cellID <= size( stateYao.colorList ,1)
                        str_color = stateYao.colorList(cellID);
                    else
                        str_color = stateYao.colorList(end);
                    end
                end
                
                
                
            elseif styleMatrix(iObj) == 3
                % pushbutton - Re-Calc Mask
                
                styleObj = 'pushbutton';
                
                w = w_edit*2;
                h = h_row/2;
                b = b+h/2;
                str = 'Re-Calc Mask';
                
                
            end
            
            
%             l = l_col;
            l = l_col + (w_col-w)/2;
%             wGapSum = wGapSum+(w_col-w)/2;
            
            
            
            temp_hdl = uicontrol(...
                'Parent',panelHdl,...
                'Style',styleObj,...
                'Units','pixels',...
                'Position',[l b w h]);
            
            if ~isempty(str)
                if ischar(str)
                    set(temp_hdl,'String',str)
                else
                    if str > 1e2
                        set(temp_hdl,'String', sprintf('%2.0f',str) )
                    elseif str > 1e1
                        set(temp_hdl,'String', sprintf('%1.1f',str) )
                    else
                        set(temp_hdl,'String', sprintf('%0.2f',str) )
                    end
                end
                set(temp_hdl,'HorizontalAlignment','left')
                if ~isempty(str_color)
                    set(temp_hdl,'ForegroundColor',str_color)
                    set(temp_hdl,'BackgroundColor',[0.5 0.5 0.5])
                end
            end
            if ~isempty(val)
                set(temp_hdl,'Value',val)
            end
            
            if enableMatrix(iObj) == 0;
                set(temp_hdl,'Enable','inactive')
            end
            
            objName = sprintf('Ellipse%dObj%d',iCellID,iObj);
            eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
            
            eval(sprintf('set(%s,''Tag'',''%s'')',...
                sprintf('%s.%s.hdl',panelName,objName),...
                sprintf('%s.%s',panelName,objName) ))
            
            
            
            if styleMatrix(iObj) ~= 0
                set(temp_hdl,'UserData',cellID);
            end
            
            
            
            
            w = w_text;
            if iCellID == 1
                % Build labels above
%                 b = b_top - h_row*(iEllipse);
                b = b+h_row*3/2;
                h = h_row/2;
                
                str =[];
                if iObj == 1
                    str = 'Cell ID';
                elseif iObj == 6
                    str = 'Is Mask?';
                elseif iObj <= 3
                    if iObj == 2
                        str = 'Projection';
                        
                        w = w*1.5;
                    end
                else
                    if iObj == 4
                        str = 'LifetimeMap';
                        
                        w = w*1.5;
                    end
                end
                
                
                
                if ~isempty(str)
                    temp_hdl = uicontrol(...
                        'Parent',panelHdl,...
                        'Style','text',...
                        'Units','pixels',...
                        'Position',[l b w h]);
                    
                    set(temp_hdl,'String',str,...
                        'HorizontalAlignment','left')
                    
                    objName = sprintf('Label_Obj%d',iObj);
                    eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
                    
                    eval(sprintf('set(%s,''Tag'',''%s'')',...
                        sprintf('%s.%s.hdl',panelName,objName),...
                        sprintf('%s.%s',panelName,objName) ))
                end
                
                
                
                str = [];
                if iObj > 1 && iObj < 6
%                     b = b_top - h_row*(iEllipse+1);
                    b = b-h_row/2;
                    h = h_row/2;
                    if typeMatrix(iObj) == 1
                        str = 'Nucleus';
                    else
                        str = 'Cytoplasm';
                    end
                    
                    
                    
                    temp_hdl = uicontrol(...
                        'Parent',panelHdl,...
                        'Style','text',...
                        'Units','pixels',...
                        'Position',[l b w h]);
                    
                    set(temp_hdl,'String',str,...
                        'HorizontalAlignment','left')
                    
                    objName = sprintf('subLabel_Obj%d',iCellID,iObj);
                    eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
                    
                    eval(sprintf('set(%s,''Tag'',''%s'')',...
                        sprintf('%s.%s.hdl',panelName,objName),...
                        sprintf('%s.%s',panelName,objName) ))
                end
                        
                
                
                
            end
            
            
            
            if strcmp(styleObj,'pushbutton')
                set(temp_hdl,'Callback',@genericCB_Yao)
            end
            
            
        end
        
        
        
        
        
        
        
        % Add popup menu showing current nucleus search function being used
        % and what are the other options
        
        h = h_nucleusSearch;
        w = w_nucleusSearch;
        
        b = b_top - h_row*(iCellID+2) -h_nucleusSearch*(iCellID-1) -h;
        l = l_start;
        
        optList = stateYao.funcLink.findNucleus_func_List;
        optSel = stateYao.funcLink.findNucleus_func{numCycle}{iImg}{iCell};
        
        str = cell( size(optList,1) ,2);
        val = 1;
        for iOpt = 1:size(optList,1)
            str{iOpt} = deblank(optList(iOpt,:));
            
            if strcmp( str{iOpt} , optSel )
                val = iOpt;
            end
        end
        
        temp_hdl = uicontrol(...
            'Parent',panelHdl,...
            'Style','popupmenu',...
            'String',str,...
            'Value',val,...
            'Units','pixels',...
            'Position',[l b w h]);
        
        objName = sprintf('nucleusSearch_Cell%d',iCellID);
        eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
        
        eval(sprintf('set(%s,''Tag'',''%s'')',...
            sprintf('%s.%s.hdl',panelName,objName),...
            sprintf('%s.%s',panelName,objName) ))
        
        
        set(temp_hdl,'UserData',cellID);
        
        set(temp_hdl,'Callback',@genericCB_Yao)
        
        
        
        
        
        
        % option list for colorNucleus
        optList = {'blue';'red';'blue/red';'red/blue'};
        optSel = stateYao.colorNucleus{numCycle}{iImg}{iCell};
        
        str = cell( size(optList,1) ,1);
        val = 1;
        for iOpt = 1:size(optList,1)
            str{iOpt} = deblank(optList{iOpt});
            
            if strcmp( str{iOpt} , optSel )
                val = iOpt;
            end
        end
        
        temp_hdl = uicontrol(...
            'Parent',panelHdl,...
            'Style','popupmenu',...
            'String',str,...
            'Value',val,...
            'Units','pixels',...
            'Position',[l+w b w/4 h]);
        
        objName = sprintf('colorNucleus_Cell%d',iCellID);
        eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
        
        eval(sprintf('set(%s,''Tag'',''%s'')',...
            sprintf('%s.%s.hdl',panelName,objName),...
            sprintf('%s.%s',panelName,objName) ))
        
        
        set(temp_hdl,'UserData',cellID);
        
        set(temp_hdl,'Callback',@genericCB_Yao)
        
        
        
        
        
        % Button to apply to all cells with this Cell ID
        temp_hdl = uicontrol(...
            'Parent',panelHdl,...
            'Style','pushbutton',...
            'String','Apply To Others',...
            'Units','pixels',...
            'Position',[l+w+w/4 b 100 h]);
        
        objName = sprintf('ApplyChangeTo_Cell%d',iCellID);
        eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
        
        eval(sprintf('set(%s,''Tag'',''%s'')',...
            sprintf('%s.%s.hdl',panelName,objName),...
            sprintf('%s.%s',panelName,objName) ))
        
        
        set(temp_hdl,'UserData',cellID);
        
        set(temp_hdl,'Callback',@genericCB_Yao)
        
        
        
        
        
    end
    end
% end
end







end


end