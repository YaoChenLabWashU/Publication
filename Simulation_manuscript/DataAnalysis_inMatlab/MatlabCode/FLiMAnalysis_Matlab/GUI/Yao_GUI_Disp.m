function Yao_GUI_Disp(panelHdlName)

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



subpanelName = sprintf('%s.Disp',panelName);
subpanelHdlName = sprintf('%s.hdl',subpanelName);

temp_hdl = uipanel( 'Parent',panelHdl,...
    'Tag',subpanelName,...
    'Units','pixels',...
    'Position',[l b w h] );

eval(sprintf('%s = temp_hdl;',subpanelHdlName))
stateYao.Disp.panel.hdl = temp_hdl;



% temp_hdl = axes('Parent',eval(subpanelHdlName),'Visible','off');
temp_hdl = axes('Parent',eval(subpanelHdlName),'Visible','on');



set(temp_hdl,'Units','pixels')
set(temp_hdl,'OuterPosition',[l b w h])


set(temp_hdl,'Position', get(temp_hdl,'OuterPosition') )



set(temp_hdl,'XTick',[],'YTick',[])

eval(sprintf('%s.image.hdl = temp_hdl;',subpanelName))
stateYao.Disp.axis.hdl = temp_hdl;





end