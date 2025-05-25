function Yao_GUI_Ctrl(panelHdlName)

global stateYao ghYao

idx = regexp(panelHdlName,'[.]');
panelName = panelHdlName(1:idx(end)-1);
panelHdl = eval(panelHdlName);

set(panelHdl,'Units','pixels')
panelPosition = get(panelHdl,'Position');


l = 0;
w = panelPosition(3);
h = panelPosition(4);
b = 0;



% What controls do we want?
%   Position Indicator
%   Slider
%   Cycle Position

% What sort of sizing do we need?
w_button = 40;
w_slider = panelPosition(3) - w_button*7;

h_orig = 40;
b_orig = ( 0 + panelPosition(4) - h_orig ) /2;





for iObj = 1:4
    
    if iObj == 1 || iObj == 2
        l = w_button*iObj;
        
    elseif iObj == 3
        l = w_button+w_button+w_button*2;
        
    end
    
    if iObj == 1
        w = w_button;
        styleObj = 'popupmenu';
        h = h_orig/2;
        b = b_orig+h_orig/2-h/2;
    elseif iObj == 3
        w = w_slider;
        h = h_orig;
        b = b_orig;
        styleObj = 'slider';
    elseif iObj == 2
        w = w_button*2;
        styleObj = 'edit';
        h = h_orig/2;
        b = b_orig+h_orig/2-h/2;
    else
        styleObj = 'pushbutton';
        w = w_button*2;
        l = panelPosition(3)-w;
        h = h_orig/2;
        b = panelPosition(4)-h;
    end
    
    
    
    temp_hdl = uicontrol(...
        'Parent',panelHdl,...
        'Style',styleObj,...
        'Units','pixels',...
        'Position',[l b w h]);
    
    objName = sprintf('Obj%d',iObj);
    eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
    
    eval(sprintf('set(%s,''Tag'',''%s'')',...
        sprintf('%s.%s.hdl',panelName,objName),...
        sprintf('%s.%s',panelName,objName) ))
    
    
    
    if strcmp(styleObj,'popupmenu')
        set(temp_hdl,'String',{'1'})
        
        stateYao.Disp.Position_Cycle.Popup.hdl = temp_hdl;
        
        
    elseif strcmp(styleObj,'slider')
        
        
%         stateYao.Disp.nImg
%         1/stateYao.Disp.nImg
        
        temp_SliderStep = [...
            1/( size(stateYao.CyclePositions,1) -1) ...
            1/( size(stateYao.CyclePositions,1) -1)];
        
        set(temp_hdl,...
            'Min',1,...
            'Max', size(stateYao.CyclePositions,1) ,...
            'Value',1,...
            'SliderStep',temp_SliderStep)
       
        
        stateYao.Disp.Position.Slider.hdl = temp_hdl;
        
        
    elseif strcmp(styleObj,'edit')
        set(temp_hdl,'String','1')
        
        stateYao.Disp.Position.Edit.hdl = temp_hdl;
        
        
    elseif strcmp(styleObj,'pushbutton')
        set(temp_hdl,'String','Quit & Calc')
        
        stateYao.Disp.Position.Quit.hdl = temp_hdl;
        
    end
    
    
    
    set(temp_hdl,'Callback',@genericCB_Yao )
    
    
    
end

end