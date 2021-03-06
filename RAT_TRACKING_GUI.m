function varargout = RAT_TRACKING_GUI(varargin)
% Open Field Rat Tracking Analysis Software Ver 1.5
% Author: Kaiyu Zheng
% Email: k.zheng@ucl.ac.uk
% ------------------------------------------------------------------------
% System Recommendation:
% CPU: Multi-Core System
% RAM: > 1GB depending on image data size
% Operating System: 64bit Matlab 2014b or later on Linux/Mac/Windows
% Global variables: ratobj, ratpt, ratgroup
% ------------------------------------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @RAT_TRACKING_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @RAT_TRACKING_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% ------------------------------------------------------------------------

function RAT_TRACKING_GUI_OpeningFcn(hObject, ~, handles, varargin)
% Choose default command line output for RAT_TRACKING_GUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
initialise(handles);

function varargout = RAT_TRACKING_GUI_OutputFcn(~, ~, handles)
varargout{1} = handles.output;
%#ok<*DEFNU>
%-----------------------------------------------------------------
function BUTTON_LOADVIDEO_Callback(~, ~, handles)
global ratobj ratpt;
% load raw video file
success=ratobj{ratpt(1)}.load_raw_video([]);
if success
    % update window name to the raw video filename
    handles.MAIN_INTERFACE.Name=cat(2,ratobj{ratpt(1)}.raw_av_obj.Path,filesep,ratobj{ratpt(1)}.raw_av_obj.Name);
    % select raw video object
    handles.LIST_OBJ.Value=ratpt(1);
end

function EDIT_RGBRATIO_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2num(get(hObject,'String')); %#ok<ST2NM>
for ratidx=ratpt
    ratobj{ratidx}.edit_val('rgb2gray_ratio',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.rgb2gray_ratio);

function EDIT_MAXSPEED_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('max_speed',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.max_speed);

function EDIT_BOXMAXLEN_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('max_floorlength',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.max_floorlength);

function EDIT_RATMASS_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('mass',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.mass);

function EDIT_RATMAXLEN_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('max_ratlength',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.max_ratlength);

function EDIT_RATMAXWIDTH_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('max_ratwidth',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.max_ratwidth);

function EDIT_RATHINDLIMBLEN_Callback(hObject, ~, ~)
global ratobj ratpt;
val=str2double(get(hObject,'String'));
for ratidx=ratpt
    ratobj{ratidx}.edit_val('hindlimb_length',val);
end
hObject.String=num2str(ratobj{ratpt(1)}.hindlimb_length);

function BUTTON_INIT_VIDEO_Callback(~, ~, handles)
global ratobj ratpt;
ratobj{ratpt(1)}.initial_process(handles.PANEL_RAWVIDEO,true);

function BUTTON_AUTOINIT_Callback(~, ~, handles)
global ratobj ratpt;
ratobj{ratpt(1)}.initial_process(handles.PANEL_RAWVIDEO,false);

function CHECKBOX_SHOWVIDEO_Callback(~, ~, ~)

function BUTTON_PROCESSVIDEO_Callback(~, ~, handles)
global ratobj ratpt;
for ratidx=ratpt
    ratobj{ratidx}.process_frames(handles.PANEL_RAWVIDEO,handles.CHECKBOX_SHOWVIDEO.Value==1);
end

function BUTTON_BATCHPROCESS_Callback(~, ~, handles)
% Batch auto process all video in selected folder
global ratobj ratpt rootpath;
% get multiple video files
[ filenames, pathname, ~ ] = uigetfile({'*.wmv;*.asf;*.asx','Windows Media� Video (.wmv, .asf, .asx)'; ...
    '*.avi','JPEG-encoded video (.avi)'; ...
    '*.mpg','MPEG-1 (.mpg)'; ...
    '*.mp4;*.m4v','MPEG-4, including H.264 encoded video (.mp4, .m4v)'; ...
    '*.mov','Apple QuickTime Movie (.mov)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Pick a raw video file', ...
    rootpath.rawvideo, ...
    'MultiSelect', 'on');% get all video files in the folder
if ischar(pathname)
    % use raw video only as a placeholder
    oldratpt=ratpt;
    % update rootpath for raw video
    rootpath.rawvideo=pathname;
    % get number of files
    nfile=numel(filenames);
    % loop start
    for fileidx=1:1:nfile
        % load video
        ratobj{ratpt}.load_raw_video(cat(2,pathname,filenames{fileidx}));
        % auto initialise
        ratobj{ratpt}.initial_process(handles.PANEL_RAWVIDEO,false);
        % process
        ratobj{ratpt}.process_frames(handles.PANEL_RAWVIDEO,handles.CHECKBOX_SHOWVIDEO.Value==1);
        % save
        [success,filename]=ratobj{ratpt}.save_ratwalk(1);
        % reset raw video only
        if success
            ratobj{ratpt}=RATWALK;
            ratobj{ratpt}.name='raw video only';
        end
        % load into list
        ratobj{end+1}=RATWALK; %#ok<AGROW>
        ratobj{end}=ratobj{end}.open_ratwalk(filename);
    end% loop end
    % update display list
    handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
    % move the pointer back to original selection
    ratpt=oldratpt;
else
    msgbox('Batch autoprocess cancelled','Action Cancelled','modal');
end

%-----------------------------------------------------------------
function BUTTON_LOADOBJ_Callback(~, ~, handles)
global ratobj ratpt rootpath;
[ filename, pathname, ~ ] = uigetfile({'*.rwm','Rat Walk Matlab File(.rwm)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Open a rat walk MATLAB file', ...
    rootpath.object, ...
    'MultiSelect', 'on');
if ischar(filename)
    filename={filename};
elseif isnumeric(filename)
    return;
end
rootpath.object=pathname; % update rootpath
for fileidx=1:numel(filename)
    ratobj{end+1}=RATWALK; %#ok<AGROW>
    ratobj{end}=ratobj{end}.open_ratwalk(cat(2,pathname,filename{fileidx}));
end
ratpt=numel(ratobj);%point to the last one;
success=ratobj{ratpt(1)}.display_frames(handles.PANEL_RESULTVIDEO,1,'wire');
if success
    handles.SLIDER_FRAME.Min=1;
    handles.SLIDER_FRAME.Value=1;
    handles.SLIDER_FRAME.Max=ratobj{ratpt(1)}.abstract_av.frame_num;
    minstep=1/(handles.SLIDER_FRAME.Max-handles.SLIDER_FRAME.Min);
    handles.SLIDER_FRAME.SliderStep=[minstep,minstep*15];
end
handles.MAIN_INTERFACE.Name=ratobj{ratpt(1)}.name;
handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
handles.LIST_OBJ.Value=ratpt;

function BUTTON_DELOBJ_Callback(~, ~, handles)
global ratpt ratobj ratgroup;
% get selection
button = questdlg('Are you sure you want to delete selected objects','Delete Objects','Yes','No','No');
switch button
    case 'Yes'
        tempidx=1:1:numel(handles.LIST_OBJ.String);
        % remove obj from list excluding 1st raw video object
        ratobj(ratpt(ratpt>1))=[];
        % update group index
        
        % update group
        
        % update list value to the last one
        ratpt=max(ratpt(1)-1,1);
        handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
        handles.LIST_OBJ.Value=ratpt;
    case 'No'
        
end

function LIST_OBJ_Callback(hObject, ~, handles)
global ratobj ratpt;
ratpt=get(hObject,'Value');
if ratpt==1
    if ~isempty(ratobj{ratpt(1)}.raw_av_obj)
        handles.MAIN_INTERFACE.Name=cat(2,ratobj{ratpt(1)}.raw_av_obj.Path,filesep,ratobj{ratpt(1)}.raw_av_obj.Name);
    else
        handles.MAIN_INTERFACE.Name=cat(2,'Rat:',ratobj{ratpt(1)}.name);
    end
else
    handles.MAIN_INTERFACE.Name=cat(2,'Rat:',ratobj{ratpt(1)}.name);
end
% update text box values
handles.EDIT_RGBRATIO.String=num2str(ratobj{ratpt(1)}.rgb2gray_ratio);
handles.EDIT_MAXSPEED.String=num2str(ratobj{ratpt(1)}.max_speed);
handles.EDIT_RATMASS.String=num2str(ratobj{ratpt(1)}.mass);
handles.EDIT_BOXMAXLEN.String=num2str(ratobj{ratpt(1)}.max_floorlength);
handles.EDIT_RATMAXLEN.String=num2str(ratobj{ratpt(1)}.max_ratlength);
handles.EDIT_RATMAXWIDTH.String=num2str(ratobj{ratpt(1)}.max_ratwidth);
handles.EDIT_RATHINDLIMBLEN.String=num2str(ratobj{ratpt(1)}.hindlimb_length);
% update result2d section
success=ratobj{ratpt(1)}.display_frames(handles.PANEL_RESULTVIDEO,1,'wire');
if success
    handles.SLIDER_FRAME.Min=1;
    handles.SLIDER_FRAME.Value=1;
    handles.SLIDER_FRAME.Max=ratobj{ratpt(1)}.abstract_av.frame_num;
    minstep=1/(handles.SLIDER_FRAME.Max-handles.SLIDER_FRAME.Min);
    handles.SLIDER_FRAME.SliderStep=[minstep,minstep*ratobj{ratpt(1)}.abstract_av.frame_rate];
end

function SLIDER_FRAME_Callback(hObject, ~, handles)
global ratobj ratpt;
% get frame value
currentframe=ceil(get(hObject,'Value'));
% update result frame
success=ratobj{ratpt(1)}.display_frames(handles.PANEL_RESULTVIDEO,currentframe,'wire');
if success
    
end

function EDIT_GOTOTIME_Callback(hObject, ~, handles)
global ratobj ratpt;
% restrict time to boundary
timept=min(max(ratobj{ratpt(1)}.abstract_av.time(1),str2double(get(hObject,'String'))),ratobj{ratpt(1)}.abstract_av.time(end));
currentframe=find(ratobj{ratpt(1)}.abstract_av.time>=timept,1,'first');
% update result frame
success=ratobj{ratpt(1)}.display_frames(handles.PANEL_RESULTVIDEO,currentframe,'wire');
if success
    % update slider
    handles.SLIDER_FRAME.Value=currentframe;
end

function BUTTON_EXPORTVIDEO_Callback(~, ~, ~)
global ratobj ratpt;
for ratidx=ratpt
    ratobj{ratidx}.export_abstract_video;
end

function BUTTON_SAVEVIDEO_Callback(~, ~, handles)
global ratobj ratpt;
for ratidx=ratpt
    [success,~]=ratobj{ratidx}.save_ratwalk([]);
    if success
        if (ratidx==1)
            % reset raw video only
            ratobj{ratidx}=RATWALK;
            ratobj{ratpt}.name='raw video only';
        end
        handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
    end
end

% --- Executes on button press in BUTTON_METAINFO.
function BUTTON_METAINFO_Callback(~, ~, ~)
global ratobj ratpt rootpath;
infomess=get(ratobj{ratpt(1)}.raw_av_obj);
if ~isempty(infomess)
    objname=infomess.Name;
    fnames=fieldnames(infomess);
    infomess=cellfun(@(x)num2str(x),struct2cell(infomess),'UniformOutput',false);
    temp = figure(...
        'WindowStyle','normal',...% able to use
        'MenuBar','none',...% no menu
        'Position',[100,100,400,220],...% fixed size
        'Name',cat(2,'Raw AV file meta info: ',objname));% use data name
    javaFrame = get(temp,'JavaFrame');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(cat(2,rootpath.icon,'Rat_Open_Field.jpg')));
    % get new figure position
    pos=get(temp,'Position');
    % create table to display meta information
    uitable(...
        'Parent',temp,...
        'Data',[fnames,infomess],...% output metainfo
        'ColumnName',{'Field','Value'},...
        'Position',[0 0 pos(3)-2 pos(4)-2],...% maximise table
        'ColumnWidth',{floor(pos(3)/3) floor(1*pos(3)/2)},...
        'ColumnEditable',[false false]);% no editing required
end
%-----------------------------------------------------------------
function LIST_ANALYSER_Callback(hObject, ~, ~)
global ratobj ratpt;
funcidx=get(hObject,'Value');
ratobj{ratpt(1)}.display_data_analyser([],funcidx);
%helpdlg(helpmsg,sprintf('function %s help\n',funcstr{funcidx}));

function BUTTON_CALCULATE_Callback(~, ~, handles)
global ratobj ratpt; %#ok<NUSED>
% get function
funcstr=get(handles.LIST_ANALYSER,'String');
funcidx=get(handles.LIST_ANALYSER,'Value');
funcstr=funcstr{funcidx};
% apply function to selected rats
evalc(cat(2,'[ success ] = ',funcstr,'(ratobj(ratpt),handles);'));
beep;beep;

%-----------------------------------------------------------------
function LIST_GROUP_Callback(hObject, ~, handles)
global ratgroup ratpt;
groupid=hObject.Value;
ratpt=ratgroup{groupid}.idx;
handles.LIST_OBJ.Value=ratpt;

function BUTTON_ADDGROUP_Callback(~, ~, handles)
global ratgroup ratpt;
answer = inputdlg('Group Name:','Add Group',1,{'group1'});
if ~isempty(answer)
    % add group
    ratgroup(end+1)=ratgroup(1);
    % fill in details
    ratgroup{end}.name=answer{1};
    ratgroup{end}.idx=ratpt(ratpt>1); % ignore template object
    handles.LIST_GROUP.String=cellfun(@(x)x.name,ratgroup,'UniformOutput',false)';
    handles.LIST_GROUP.Value=numel(ratgroup);
    % update group display in the object list
    ratpt=ratgroup{end}.idx;
    handles.LIST_OBJ.Value=ratpt;
end

function BUTTON_DELGROUP_Callback(~, ~, handles)
global ratgroup;
if handles.LIST_GROUP.Value>1 % don't delete template group
    ratgroup(handles.LIST_GROUP.Value)=[];
    % update group list
    handles.LIST_GROUP.String=cellfun(@(x)x.name,ratgroup,'UniformOutput',false)';
    handles.LIST_GROUP.Value=handles.LIST_GROUP.Value-1; % always has template as 1
else
    errordlg('Template group cannot be deleted','Invalid Action','modal');
end

function BUTTON_ADDOBJ_Callback(~, ~, handles)
global ratpt ratgroup;
groupid=handles.LIST_GROUP.Value;
ratgroup{groupid}.idx=unique([ratgroup{groupid}.idx,ratpt(ratpt>1)]); % ignore template object
% update group display in the object list
ratpt=ratgroup{groupid}.idx;
handles.LIST_OBJ.Value=ratpt;

function BUTTON_REMOVEOBJ_Callback(~, ~, handles)
global ratpt ratgroup;
% get current group id
groupid=handles.LIST_GROUP.Value;
% find intersecting objects
[~,~,removeobjid]=intersect(ratpt,ratgroup{groupid}.idx);
% remove them from current group
ratgroup{groupid}.idx(removeobjid)=[];
% update group display in the object list
ratpt=ratgroup{groupid}.idx;
handles.LIST_OBJ.Value=ratpt;

function BUTTON_LOADGROUP_Callback(~, ~, handles)
global ratobj ratgroup rootpath ratpt;
[ filename, pathname, ~ ] = uigetfile({'*.ogf','Object Group File(.ogf)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Open a Object Group File', ...
    rootpath.group, ...
    'MultiSelect', 'on');
if ischar(filename)
    filename={filename};
elseif isnumeric(filename)
    msgbox('Loading group cancelled','Action Cancelled','modal');
    return;
end
rootpath.group=pathname;
for fileidx=1:numel(filename)
    temp=load(cat(2,pathname,filename{fileidx}),'-mat');
    ratgroup(end+1)=ratgroup(1);
    ratgroup{end}.name=temp.temp.name;
    ratgroup{end}.idx=(1:1:numel(temp.temp.object))+numel(ratobj);
    % add all the objects in the group too
    for objidx=1:1:numel(temp.temp.object)
        ratobj{end+1}=temp.temp.object{objidx};
    end
end
ratpt=ratgroup{end}.idx;
% update group list
handles.LIST_GROUP.String=cellfun(@(x)x.name,ratgroup,'UniformOutput',false)';
handles.LIST_GROUP.Value=numel(ratgroup); % always has template as 1
handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
handles.LIST_OBJ.Value=ratpt;
msgbox('Group loaded','Load Object Group As','modal');

function BUTTON_SAVEGROUP_Callback(~, ~, handles)
global ratobj ratgroup rootpath;
groupid=handles.LIST_GROUP.Value;
% save group under group name
[filename,pathname,~] = uiputfile({'*.ogf','Object Group File (*.ogf)'},'Save Group As',cat(2,rootpath.group,ratgroup{groupid}.name,'.ogf'));
if ischar(filename)
    rootpath.group=pathname;
    % copy over actual object
    temp.name=ratgroup{groupid}.name;
    for objidx=1:1:numel(ratgroup{groupid}.idx)
        temp.object{objidx}=ratobj{ratgroup{groupid}.idx(objidx)};
    end
    save(cat(2,pathname,filename),'temp','-mat');
    clear temp;
    msgbox(sprintf('Group %s saved',ratgroup{groupid}.name),'Save Object Group As','modal');
else
    msgbox('Saving group cancelled','Action Cancelled','modal');
end

%-----------------------------------------------------------------
function BUTTON_HOLD1DSQ_Callback(hObject, ~, handles)
global rootpath;
val=get(hObject,'Value');
if val
    iconimg=imread(cat(2,rootpath.icon,'holdon_icon.png'));
    set(handles.PANEL_RESULT1DSQ,'NextPlot','add');
else
    iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
    set(handles.PANEL_RESULT1DSQ,'NextPlot','replace');
end
set(hObject,'CData',iconimg);

function BUTTON_HOLD1DRECT_Callback(hObject, ~, handles)
global rootpath;
val=get(hObject,'Value');
if val
    iconimg=imread(cat(2,rootpath.icon,'holdon_icon.png'));
    set(handles.PANEL_RESULT1DRECT,'NextPlot','add');
else
    iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
    set(handles.PANEL_RESULT1DRECT,'NextPlot','replace');
end
set(hObject,'CData',iconimg);

function BUTTON_HOLD2D_Callback(hObject, ~, handles)
global rootpath;
val=get(hObject,'Value');
if val
    iconimg=imread(cat(2,rootpath.icon,'holdon_icon.png'));
    set(handles.PANEL_RESULT2D,'NextPlot','add');
else
    iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
    set(handles.PANEL_RESULT2D,'NextPlot','replace');
end
set(hObject,'CData',iconimg);

function BUTTON_HOLDGROUP1DRECT_Callback(hObject, ~, handles)
global rootpath;
val=get(hObject,'Value');
if val
    iconimg=imread(cat(2,rootpath.icon,'holdon_icon.png'));
    set(handles.PANEL_RESULTGROUP1DRECT,'NextPlot','add');
else
    iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
    set(handles.PANEL_RESULTGROUP1DRECT,'NextPlot','replace');
end
set(hObject,'CData',iconimg);

function BUTTON_HOLDGROUP1DSQ_Callback(hObject, ~, handles)
global rootpath;
val=get(hObject,'Value');
if val
    iconimg=imread(cat(2,rootpath.icon,'holdon_icon.png'));
    set(handles.PANEL_RESULTGROUP1DSQ,'NextPlot','add');
else
    iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
    set(handles.PANEL_RESULTGROUP1DSQ,'NextPlot','replace');
end
set(hObject,'CData',iconimg);

function BUTTON_CLEAR1DSQ_Callback(~, ~, handles)
cla(handles.PANEL_RESULT1DSQ);

function BUTTON_CLEAR1DRECT_Callback(~, ~, handles)
cla(handles.PANEL_RESULT1DRECT);

function BUTTON_CLEAR2D_Callback(~, ~, handles)
cla(handles.PANEL_RESULT2D);

function BUTTON_CLEARGROUP1DRECT_Callback(~, ~, handles)
cla(handles.PANEL_RESULTGROUP1DRECT);

function BUTTON_CLEARGROUP1DSQ_Callback(~, ~, handles)
cla(handles.PANEL_RESULTGROUP1DSQ);

function BUTTON_EXPORT1DSQ_Callback(~, ~, handles)
export_panel(handles.PANEL_RESULT1DSQ);

function BUTTON_EXPORT1DRECT_Callback(~, ~, handles)
export_panel(handles.PANEL_RESULT1DRECT);

function BUTTON_EXPORT2D_Callback(~, ~, handles)
export_panel(handles.PANEL_RESULT2D);

function BUTTON_EXPORTGROUP1DRECT_Callback(~, ~, handles)
export_panel(handles.PANEL_RESULTGROUP1DRECT);

function BUTTON_EXPORTGROUP1DSQ_Callback(~, ~, handles)
export_panel(handles.PANEL_RESULTGROUP1DSQ);

% --------------------------------------------------------------------
function Toggle_legend_ClickedCallback(hObject, ~, ~)
global ratobj ratpt;
switch hObject.State
    case 'on'
        % get full name
        [~,legstr,~]=cellfun(@(x)fileparts(x.name),ratobj(ratpt),'UniformOutput',false);
        legend(legstr,'Location','best','Interpreter','none');
    case 'off'
        legend('off');
end

% ------------------------------------------------
function MAIN_INTERFACE_CloseRequestFcn(hObject, ~, ~)
global ratobj ratpt ratgroup rootpath; %#ok<NUSED>
for objidx=1:numel(ratobj)
    delete(ratobj{objidx});
end
clear global ratobj;
clear global ratpt;
clear global ratgroup;

% save updated rootpath
save('./UTILITY/default_path.mat','rootpath','-mat');
clear global rootpath;
% Hint: delete(hObject) closes the figure
delete(hObject);

% ------------------------------------------------
function initialise(handles)
clc;
% ---------------------------------------------------
% set default colour scheme to black background and white font for dark
% room usage
set(0,'DefaultUicontrolBackgroundColor','default');
set(0,'DefaultUicontrolForegroundColor','default');
% ---------------------------------------------------
% add subfolders to path
addpath(genpath('./'));
[ver,date]=version;
release_yr=str2double(datestr(date,'YYYY'));
switch release_yr
    case {2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018}
        feature('accel','on');
    otherwise
        errordlg(sprintf('Incompatible MATLAB Version.\nCurrent Version %s\nRequire >R2008a & <R2018b',ver),'Version Error','modal');
end
% declare ratwalk object
global ratobj ratpt ratgroup rootpath;
% rat pointer to the first rat
ratpt=1;
% temporary rat object for video processing
ratobj{ratpt}=RATWALK;
ratobj{ratpt}.name='raw video only';
% initialise rat group
ratgroup{1}.name='template';
ratgroup{1}.idx=[];
ratgroup{1}.obj=[];

% load root path into programme
try
    temp=load(cat(2,'.',filesep,'UTILITY',filesep,'default_path.mat'),'-mat');% load default paths
    rootpath=temp.rootpath;clear temp;
catch
    rootpath.icon='./icon/';
    rootpath.object='./';
    rootpath.group='./';
    rootpath.rawvideo='./';
    rootpath.export='./';
    fprintf(1,'file not found\n');
end

% initialise edit box
handles.EDIT_RGBRATIO.String=num2str(ratobj{ratpt}.rgb2gray_ratio);
handles.EDIT_MAXSPEED.String=num2str(ratobj{ratpt}.max_speed);
handles.EDIT_RATMASS.String=num2str(ratobj{ratpt}.mass);
handles.EDIT_BOXMAXLEN.String=num2str(ratobj{ratpt}.max_floorlength);
handles.EDIT_RATMAXLEN.String=num2str(ratobj{ratpt}.max_ratlength);
handles.EDIT_RATMAXWIDTH.String=num2str(ratobj{ratpt}.max_ratwidth);
handles.EDIT_RATHINDLIMBLEN.String=num2str(ratobj{ratpt}.hindlimb_length);

% initialise panel
handles.PANEL_RAWVIDEO.Box='on';
handles.PANEL_RAWVIDEO.XTick=[];
handles.PANEL_RAWVIDEO.XTickLabel=[];
handles.PANEL_RAWVIDEO.YTickLabel=[];
handles.PANEL_RAWVIDEO.YTick=[];
handles.PANEL_RESULTVIDEO.Box='on';
handles.PANEL_RESULTVIDEO.XTick=[];
handles.PANEL_RESULTVIDEO.XTickLabel=[];
handles.PANEL_RESULTVIDEO.YTick=[];
handles.PANEL_RESULTVIDEO.YTickLabel=[];
colormap(handles.PANEL_RAWVIDEO,'gray');

% initialise button images
iconimg=imread(cat(2,rootpath.icon,'holdoff_icon.png'));
set(handles.BUTTON_HOLD1DSQ,'CData',iconimg);
set(handles.BUTTON_HOLD1DRECT,'CData',iconimg);
set(handles.BUTTON_HOLD2D,'CData',iconimg);
set(handles.BUTTON_HOLDGROUP1DRECT,'CData',iconimg);
set(handles.BUTTON_HOLDGROUP1DSQ,'CData',iconimg);
iconimg=imread(cat(2,rootpath.icon,'export_icon.jpg'));
set(handles.BUTTON_EXPORT1DSQ,'CData',iconimg);
set(handles.BUTTON_EXPORT1DRECT,'CData',iconimg);
set(handles.BUTTON_EXPORT2D,'CData',iconimg);
set(handles.BUTTON_EXPORTGROUP1DRECT,'CData',iconimg);
set(handles.BUTTON_EXPORTGROUP1DSQ,'CData',iconimg);
iconimg=imread(cat(2,rootpath.icon,'clear_icon.png'));
set(handles.BUTTON_CLEAR1DSQ,'CData',iconimg);
set(handles.BUTTON_CLEAR1DRECT,'CData',iconimg);
set(handles.BUTTON_CLEAR2D,'CData',iconimg);
set(handles.BUTTON_CLEARGROUP1DRECT,'CData',iconimg);
set(handles.BUTTON_CLEARGROUP1DSQ,'CData',iconimg);

% LIST ANALYSER FUNCTIONS
ratobj{ratpt}.display_data_analyser(handles.LIST_ANALYSER,[]);

% initialise list object
handles.LIST_OBJ.String=cellfun(@(x)x.name,ratobj,'UniformOutput',false)';
handles.LIST_OBJ.Value=ratpt;
handles.LIST_GROUP.String=cellfun(@(x)x.name,ratgroup,'UniformOutput',false)';
handles.LIST_GROUP.Value=1;

% change main window icon
warning('off','all');
javaFrame = get(handles.MAIN_INTERFACE,'JavaFrame');
javaFrame.setFigureIcon(javax.swing.ImageIcon(cat(2,rootpath.icon,'Rat_Open_Field.jpg')));
