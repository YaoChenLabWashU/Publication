function varargout = reviewerGUI(varargin)
% REVIEWERGUI M-file for reviewerGUI.fig
%      REVIEWERGUI, by itself, creates a new REVIEWERGUI or raises the existing
%      singleton*.
%
%      H = REVIEWERGUI returns the handle to a new REVIEWERGUI or the handle to
%      the existing singleton*.
%
%      REVIEWERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVIEWERGUI.M with the given input arguments.
%
%      REVIEWERGUI('Property','Value',...) creates a new REVIEWERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before reviewerGUI_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to reviewerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help reviewerGUI

% Last Modified by GUIDE v2.5 03-Feb-2003 14:45:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @reviewerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @reviewerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before reviewerGUI is made visible.
function reviewerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to reviewerGUI (see VARARGIN)

% Choose default command line output for reviewerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes reviewerGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = reviewerGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in reviewPhys.
function generic_Callback(hObject, eventdata, handles)
	genericCallback(hObject);


% --- Executes during object creation, after setting all properties.
function review_CreateFcn(hObject, eventdata, handles)
% hObject    handle to review (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function review_Callback(hObject, eventdata, handles)
	genericCallback(hObject);
	global state
	state.files.lastAcquisition=state.reviewer.review;

	if state.reviewer.reviewPhys
		try
			reviewPhysAcq(state.reviewer.review);
		catch
			disp('error in reviewing phys');
			disp(lasterr);
		end
	end
	if state.reviewer.reviewImages
		try
			readImages(state.reviewer.review);
		catch
			disp('error in reviewing Images ');
			disp(lasterr);
		end
	end

	if state.reviewer.reviewROIScans
		try
			reviewFluorData(state.reviewer.review);
		catch
			disp('error in reviewing ROI Scans phys');
			disp(lasterr);
		end
	end

	if state.reviewer.reviewMaxData
		try
			reviewMaxImages(state.reviewer.review);
		catch
			disp('error in reviewing Max images');
			disp(lasterr);
		end
	end

	
% --- Executes during object creation, after setting all properties.
function fileCounter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileCounter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function fileCounter_Callback(hObject, eventdata, handles)
% hObject    handle to fileCounter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileCounter as text
%        str2double(get(hObject,'String')) returns contents of fileCounter as a double


% --- Executes during object creation, after setting all properties.
function baseName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function baseName_Callback(hObject, eventdata, handles)
% hObject    handle to baseName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baseName as text
%        str2double(get(hObject,'String')) returns contents of baseName as a double


% --- Executes during object creation, after setting all properties.
function reviewSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reviewSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




% --- Executes during object creation, after setting all properties.
function fileCounterSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileCounterSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function fileCounterSlider_Callback(hObject, eventdata, handles)
% hObject    handle to fileCounterSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes on button press in reviewMaxData.
function reviewMaxData_Callback(hObject, eventdata, handles)
% hObject    handle to reviewMaxData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reviewMaxData


