function [xls] = fig2excel(xls, figlist, mouse, channel, TrialData)
%Function which can save plots into excel
%As input the function needs xls.make_excel = 1. Figures have to be active and the figlist should show
% the numbers of the figures. Mouse and channel should be passed as integers. TrialData should contain channel names.
% the files

%change to regulate the information collumn from a given structure
trialdatainfolist = 1:5;

xls.welcome = 1;
%for processing excel file
if isfield(xls,'make_excel')
    if xls.make_excel == 1
        disp(['Processing excel for: mouse ' mouse ' ' channel]) 
    else
        return
    end
end

%for setting first-time parameters
if ~isfield(xls,'firstrun')
    xls.refrow = 15;
    xls.refcollumn = 0;
    xls.space_y = 15;
    xls.space_x = 48; %48
    if exist('figuredir')
        rmdir([pwd '\figuredir'], 's')
    end
    mkdir('figuredir')
end


%sets overwrite parameters, when overwrite is passed, it is saved in xls,
%if not default is xls.overwrite = 0.
if ~isfield(xls, 'overwrite')
    xls.overwrite = 0;
end


%creates local variables from xls
if isfield(xls, 'shapes') 
    shapes = xls.shapes;
    Excel = xls.Excel;
    Workbook = xls.Workbook;
end


%Stops function if figure.xlsx file is already in folder and overwrite is off
if isfile('figure.xlsx')                    
    if xls.overwrite == 0                   
        if ~isfield(xls, 'existmessage')
            xls.existmessage = 1;
            disp('Excelfile already exists and overwrite is set off')
        end
    return
    end
end


%Creates excel file, should only be run in the first run, eiter activated
%by lack of figure.xlsx or by combination of overwrite and firstrun
%parameters
if ~isfile('figure.xlsx') || (xls.overwrite == 1 && ~isfield(xls, 'firstrun')) 
    xls.firstrun = 0;
    % Get handle to Excel COM Server https://nl.mathworks.com/help/matlab/matlab_external/using-a-matlab-application-as-an-automation-client.html
    Excel = actxserver('Excel.Application');
    %Supresses GUI saving message in excel
    Excel.DisplayAlerts = 0; 
    % Set it to visible 
    set(Excel,'Visible',1);
    % Add a Workbook
    Workbooks = Excel.Workbooks;
    Workbook = invoke(Workbooks, 'Add');
    SaveAs(Workbook,[pwd '\figure.xlsx'])
    % Get a handle to Sheets and select Sheet 1
    Sheets = Excel.ActiveWorkBook.Sheets;
    Sheet1 = get(Sheets, 'Item', 1);
    Sheet1.Activate;
    % Get a handle to Shapes for Sheet 1
    shapes = Sheet1.Shapes;
    xls.shapes = shapes;
    xls.Excel = Excel;
    xls.Workbook = Workbook;
    
   
    %Add additional information
    if exist('TrialData')
        %add additional collumns to cell for information
        infocell = { 'Time of analysis: ', datestr(datetime()) ; 'Directory',pwd; 'Script running: ', mfilename};
        defaultcells = size(infocell,1);
        %adds information in structure of collumn names and content into
        %infocell
        collumnnames = fieldnames(TrialData);
        for y = trialdatainfolist
            infocell(y+defaultcells,1) = collumnnames(y);
            infocell(y+defaultcells,2) = {getfield(TrialData(1), char(collumnnames(y)))};
        end
        %placement of infocel into excel
        eActivesheetRange = get(Excel.Activesheet, 'Range', ['A1:B' num2str(y+defaultcells)]);
        eActivesheetRange.Value = infocell;
        clear infocell
        xls.refrow = (y+defaultcells+2) * 15;
    end
end

%if exist('TrialData')
    eActivesheetRange = get(Excel.Activesheet, 'Range', ['A' num2str(round(xls.refrow/15))]);
    eActivesheetRange.Value = [char(mouse) ' ' char(channel)];
%end


%Saves the figures and text in excel file
%Adds txt for mouse+channel in a location
for i = 1:length(figlist)
    figname = [char(mouse) '_' char(channel) '_fig' num2str(i)];
    %saving figure
    saveas(figure(figlist(i)), [pwd '\figuredir\' figname '.png'] )
    saveas(figure(figlist(i)), [pwd '\figuredir\' figname '.m'] )
    %shapes.AddPicture([pwd '\' figname] ,0,1,x pixel position (48 per cell),y pixel (+/-15 per cell),dimensionx,dimensiony)
    shapes.AddPicture([pwd '\figuredir\' figname '.png'] ,0,1, (310*(i-1)+xls.refcollumn) , 30 + xls.refrow , 300,200); %
    delete([pwd '\figuredir\' figname '.png'])
    delete([pwd '\figuredir\' figname '.m'])
end

xls.refrow = xls.space_y*18 + xls.refrow; 
SaveAs(Workbook,[pwd '\figure1.xlsx'])
end