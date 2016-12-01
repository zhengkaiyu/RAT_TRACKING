function [ status ] = load_raw_video( obj )
%LOAD_RAW_VIDEO Read in raw open field test video

%% function complete
status=false;
global rootpath;
try
    if isstruct(obj.raw_av_obj)
        pathname=obj.raw_av_obj.Path;
    else
        if isempty(rootpath);
            pathname='./';
        else
            pathname=rootpath.rawvideo;
        end
    end
    
    [ filename, pathname, ~ ] = uigetfile({'*.wmv;*.asf;*.asx','Windows Media® Video (.wmv, .asf, .asx)'; ...
        '*.avi','JPEG-encoded video (.avi)'; ...
        '*.mpg','MPEG-1 (.mpg)'; ...
        '*.mp4;*.m4v','MPEG-4, including H.264 encoded video (.mp4, .m4v)'; ...
        '*.mov','Apple QuickTime Movie (.mov)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a raw video file', ...
        pathname, ...
        'MultiSelect', 'off');
    if ischar(filename)
        filename=cat(2,pathname,filename);
        rootpath.rawvideo=pathname;
        % load video file info video class
        obj.raw_av_obj=VideoReader(filename);
        % get video infomation
        info=data2clip(get(obj.raw_av_obj));
        % make output message
        message=sprintf('Video file loaded\nVideo Information:\n%s',info);
        status=true;
    else
        message=sprintf('video file loading cancelled\n');
    end
    msgbox(message,'Video Loading Message','modal');
    beep;beep;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end