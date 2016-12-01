function [ status ] = save_ratwalk( obj )
%SAVE_RATWALK save processed abstract tracking video

%% function complete
status = false;
global rootpath;
try
    if isempty(rootpath);
        pathname='.';
    else
        [pathname,~,~]=fileparts(rootpath.object);
    end
    if isempty(obj.name)
        [~,filename,~]=fileparts(obj.raw_av_obj.Name);
        filename=cat(2,pathname,filesep,filename);
    else
        filename=obj.name;
        if strncmp(filename,'raw video only',14)
            [~,filename,~]=fileparts(obj.raw_av_obj.Name);
            filename=cat(2,pathname,filesep,filename);
        end
    end
    [ filename, pathname, ~ ] = uiputfile({'*.rwm','Rat Walk Matlab File(.rwm)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Save to rat walk MATLAB file', ...
        filename);
    if ischar(filename)
        obj.name=cat(2,pathname,filename);
        save(cat(2,pathname,filename),'obj','-mat','-v7');
        rootpath.object=obj.name;
        % make output message
        message=sprintf('Rat walk file %s saved\n',filename);
        status=true;
    else
        message=sprintf('File saving cancelled\n');
    end
    msgbox(message,'Save Rat File Message','modal');
    beep;beep;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end