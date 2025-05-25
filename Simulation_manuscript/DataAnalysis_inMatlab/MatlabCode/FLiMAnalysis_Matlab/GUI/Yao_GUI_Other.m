function Yao_GUI_Other(panelHdlName)

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






% w_button = 60;
% 
% styleObj = 'pushbutton';
% 
% str = 'Reset';
% objName = 'Reset';
% 
% l = panelPosition(3)/2-w_button/2;
% b = w_button;
% w = w_button;
% h = w_button/2;
% 
% 
% temp_hdl = uicontrol(...
%     'Parent',panelHdl,...
%     'Style',styleObj,...
%     'Units','pixels',...
%     'Position',[l b w h]);
% 
% set(temp_hdl,'String',str)
% 
% eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
% 
% eval(sprintf('set(%s,''Tag'',''%s'')',...
%     sprintf('%s.%s.hdl',panelName,objName),...
%     sprintf('%s.%s',panelName,objName) ))
% 
% 
% set(temp_hdl,'Callback',@genericCB_Yao )
% 
% 
% 
% 
% 
% 
% 
% styleObj = 'pushbutton';
% 
% str = 'Remove';
% objName = 'Remove';
% 
% l = panelPosition(3)/2-w_button/2;
% b = b+h+w_button/2;
% w = w_button;
% h = w_button/2;
% 
% 
% temp_hdl = uicontrol(...
%     'Parent',panelHdl,...
%     'Style',styleObj,...
%     'Units','pixels',...
%     'Position',[l b w h]);
% 
% set(temp_hdl,'String',str)
% 
% eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
% 
% eval(sprintf('set(%s,''Tag'',''%s'')',...
%     sprintf('%s.%s.hdl',panelName,objName),...
%     sprintf('%s.%s',panelName,objName) ))
% 
% 
% set(temp_hdl,'Callback',@genericCB_Yao )
% 
% 
% 
% 
% 
% styleObj = 'pushbutton';
% 
% str = 'Add';
% objName = 'Add';
% 
% l = panelPosition(3)/2-w_button/2;
% b = b+h+w_button/2;
% w = w_button;
% h = w_button/2;
% 
% 
% temp_hdl = uicontrol(...
%     'Parent',panelHdl,...
%     'Style',styleObj,...
%     'Units','pixels',...
%     'Position',[l b w h]);
% 
% set(temp_hdl,'String',str)
% 
% eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
% 
% eval(sprintf('set(%s,''Tag'',''%s'')',...
%     sprintf('%s.%s.hdl',panelName,objName),...
%     sprintf('%s.%s',panelName,objName) ))
% 
% 
% set(temp_hdl,'Callback',@genericCB_Yao )











% % What controls do we want?
% %   Position Indicator
% %   Slider
% 
% % What sort of sizing do we need?
% w_button = 40;
% w_slider = panelPosition(3) - w_button*7;
% 
% h = 40;
% b = ( 0 + panelPosition(4) - h ) /2;
% 
% 
% 
% 
% 
% for iObj = 1:2
%     
%     if iObj == 1
%         l = w_button+w_button;
%         
%     elseif iObj == 2
%         l = w_button+w_button*3;
%         
% %     elseif iObj < 5
% %         
% %         l = w_button+w_button*2+w_slider+w_button +w_button*(iObj-2);
% %         
% %         if iObj == 4
% %             h = h/2;
% %         end
% %         
% %     else
% %         b = b+h;
% %         
%     end
%     
%     if iObj >2
% %         w = w_button;
% %         if iObj ~= 3
% %             styleObj = 'pushbutton';
% %         else
% %             styleObj = 'togglebutton';
% %         end
%     elseif iObj == 2
%         w = w_slider;
%         styleObj = 'slider';
%     else
%         w = w_button*2;
%         styleObj = 'edit';
%     end
%     
%     
%     
%     temp_hdl = uicontrol(...
%         'Parent',panelHdl,...
%         'Style',styleObj,...
%         'Units','pixels',...
%         'Position',[l b w h]);
%     
%     objName = sprintf('Obj%d',iObj);
%     eval(sprintf('%s = temp_hdl;',sprintf('%s.%s.hdl',panelName,objName)))
%     
%     eval(sprintf('set(%s,''Tag'',''%s'')',...
%         sprintf('%s.%s.hdl',panelName,objName),...
%         sprintf('%s.%s',panelName,objName) ))
%     
%     
%     
%     if strcmp(styleObj,'pushbutton') ||...
%             strcmp(styleObj,'togglebutton')
% %         if iObj == 3
% %             str = '>';
% %             
% %             stateSV.(FigName).Play.hdl = temp_hdl;
% %             
% %         elseif iObj == 4
% %             str = '\/';
% %         elseif iObj == 5
% %             str = '/\';
% %         end
% %         set(temp_hdl,'String',str)
%         
%         
%     elseif strcmp(styleObj,'slider')
%         temp_SliderStep = [...
%             1/stateYao.Disp.nImg ...
%             0.1];
%         
%         set(temp_hdl,...
%             'Max',stateYao.Disp.nImg,...
%             'Min',1,...
%             'Value',1,...
%             'SliderStep',temp_SliderStep)
%        
%         
%         stateYao.Disp.Position.Slider.hdl = temp_hdl;
%         
%         
%     elseif strcmp(styleObj,'edit')
%         set(temp_hdl,'String','1')
%         
%         stateYao.Disp.Position.Edit.hdl = temp_hdl;
%         
%     end
%     
%     
%     
%     set(temp_hdl,'Callback',@genericCB_Yao )
%     
%     
%     
% end

end