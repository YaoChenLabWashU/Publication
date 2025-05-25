function Yao_GUI_build

global stateYao ghYao



% Build Main Figure Window
FigName = 'MainWindow';
ghYao.(FigName).hdl = figure;
set(ghYao.(FigName).hdl,...
    'Units','pixels',...
    'Position',[1 1 850 500] );

set(ghYao.(FigName).hdl,'MenuBar','none')



%% Divide Figure Window into Major Panels
l_Disp = 0;
b_Disp = 100;
w_Disp = 400;
h_Disp = 400;

l_Ctrl = 0;
b_Ctrl = 0;
w_Ctrl = 850;
h_Ctrl = 100;

l_Other = 400;
b_Other = 100;
w_Other = 450;
h_Other = 400;



%% Build Major panel
% Name of the panel and where you want it within it's parent
PanelName = 'Disp';
l = eval(sprintf('l_%s',PanelName));
b = eval(sprintf('b_%s',PanelName));
w = eval(sprintf('w_%s',PanelName));
h = eval(sprintf('h_%s',PanelName));

% gh string pointing to the panel's handle
panelHdlName = sprintf('ghYao.%s.%s.hdl',FigName,PanelName);

% from the gh string, find parent handle
idx = regexp(panelHdlName,'[.]');
parentHdlName = sprintf('%s.hdl',panelHdlName(1:idx(end-1)-1));
parentHdl = eval(parentHdlName);

temp_hdl = uipanel( 'Parent',parentHdl,...
    'Title',PanelName,...
    'Units','Pixels',...
    'Position',[l b w h] );
eval(sprintf('%s = temp_hdl;',panelHdlName))

set(temp_hdl,'Title',[])

% run function that will continue building up the panel contents and
% subpanels
eval(sprintf('Yao_GUI_%s(panelHdlName)',PanelName))



%% Build Major panel
% Name of the panel and where you want it within it's parent
PanelName = 'Ctrl';
l = eval(sprintf('l_%s',PanelName));
b = eval(sprintf('b_%s',PanelName));
w = eval(sprintf('w_%s',PanelName));
h = eval(sprintf('h_%s',PanelName));

% gh string pointing to the panel's handle
panelHdlName = sprintf('ghYao.%s.%s.hdl',FigName,PanelName);

% from the gh string, find parent handle
idx = regexp(panelHdlName,'[.]');
parentHdlName = sprintf('%s.hdl',panelHdlName(1:idx(end-1)-1));
parentHdl = eval(parentHdlName);

temp_hdl = uipanel( 'Parent',parentHdl,...
    'Title',PanelName,...
    'Units','Pixels',...
    'Position',[l b w h] );
eval(sprintf('%s = temp_hdl;',panelHdlName))

set(temp_hdl,'Title',[])

% run function that will continue building up the panel contents and
% subpanels
eval(sprintf('Yao_GUI_%s(panelHdlName)',PanelName))



%% Build Major panel
% Name of the panel and where you want it within it's parent
PanelName = 'Other';
l = eval(sprintf('l_%s',PanelName));
b = eval(sprintf('b_%s',PanelName));
w = eval(sprintf('w_%s',PanelName));
h = eval(sprintf('h_%s',PanelName));

% gh string pointing to the panel's handle
panelHdlName = sprintf('ghYao.%s.%s.hdl',FigName,PanelName);

% from the gh string, find parent handle
idx = regexp(panelHdlName,'[.]');
parentHdlName = sprintf('%s.hdl',panelHdlName(1:idx(end-1)-1));
parentHdl = eval(parentHdlName);

temp_hdl = uipanel( 'Parent',parentHdl,...
    'Title',PanelName,...
    'Units','Pixels',...
    'Position',[l b w h] );
eval(sprintf('%s = temp_hdl;',panelHdlName))

set(temp_hdl,'Title',[])

% run function that will continue building up the panel contents and
% subpanels
eval(sprintf('Yao_GUI_%s(panelHdlName)',PanelName))