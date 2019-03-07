function [ status ] = load_raw_video( obj, filename )
%LOAD_RAW_VIDEO Read in raw open field test video either with user
%selection of single file or with specified filename
% e.g.  obj.load_raw_video([])
%       obj.load_raw_video('C:\test\test.mpg')

%% function complete
status=false;
% get global rootpath for loading
global rootpath;
%----------------------------------------
try
    if isempty(filename)
        %----------------------------------------
        % auto get path for loading
        % if no filename specified get user input
        if isstruct(obj.raw_av_obj)
            % if raw video field is already filled get the old path
            pathname=obj.raw_av_obj.Path;
        else
            % if raw video field is empty use global rootpath
            if isempty(rootpath);
                % use default current directory
                pathname='./';
            else
                % use previous rawvideo path
                pathname=rootpath.rawvideo;
            end
        end
        %----------------------------------------
        % get user to select single raw video file
        [ filename, pathname, ~ ] = uigetfile({'*.wmv;*.asf;*.asx','Windows Media® Video (.wmv, .asf, .asx)'; ...
            '*.avi','JPEG-encoded video (.avi)'; ...
            '*.mpg','MPEG-1 (.mpg)'; ...
            '*.mp4;*.m4v','MPEG-4, including H.264 encoded video (.mp4, .m4v)'; ...
            '*.mov','Apple QuickTime Movie (.mov)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Pick a raw video file', ...
            pathname, ...
            'MultiSelect', 'off');
        %----------------------------------------
        % if user selected file
        if ischar(filename)
            % combine to get full filename
            filename=cat(2,pathname,filename);
            % update global rawvideo path
            rootpath.rawvideo=pathname;
            % load video file info video class
            obj.raw_av_obj=VideoReader(filename);
            % get video infomation
            info=data2clip(get(obj.raw_av_obj));
            % make output message
            message=sprintf('Video file loaded\nVideo Information:\n%s',info);
            status=true;
        else
            % if user cancelled selection process
            message=sprintf('video file loading cancelled\n');
        end
        msgbox(message,'Video Loading Message','modal');
    else
        %----------------------------------------
        % if filename has been specified, likely auto batch processing
        % get the pathname
        [pathname,~,~]=fileparts(filename);
        % update global rawvideo path
        rootpath.rawvideo=pathname;
        % load video file info video class
        obj.raw_av_obj=VideoReader(filename);
        status=true;
    end
    % audio notification
    beep;beep;
    %----------------------------------------
catch exception
    % error handling
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end