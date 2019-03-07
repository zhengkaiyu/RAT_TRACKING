function [ status, filename ] = save_ratwalk( obj, filename )
%SAVE_RATWALK save processed abstract tracking video

%% function complete
status = false;
% get global variable of rootpaths
global rootpath;
try
    if isempty(filename)
        % get pathname
        if isempty(rootpath);
            % if there is no current rootpath specified uses home path
            pathname='.';
        else
            % get rootpath of objects
            [pathname,~,~]=fileparts(rootpath.object);
        end
        % get filename
        if isempty(obj.name)
            % if not saved as object yet use raw video name as default name
            [~,filename,~]=fileparts(obj.raw_av_obj.Name);
            % construct full filename
            filename=cat(2,pathname,filesep,filename);
        else
            % use object name as filename if this has already been saved before
            filename=obj.name;
            % if the file is still raw video file uses video filename
            if strncmp(filename,'raw video only',14)
                [~,filename,~]=fileparts(obj.raw_av_obj.Name);
                filename=cat(2,pathname,filesep,filename);
            end
        end
        % ask user to save file with automated filename or user specified
        [ filename, pathname, ~ ] = uiputfile({'*.rwm','Rat Walk Matlab File(.rwm)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Save to rat walk MATLAB file', ...
            filename);
        % file save confirmed
        if ischar(filename)
            % update object name to the new filename
            obj.name=cat(2,pathname,filename);
            % save as ver7 mat file
            save(cat(2,pathname,filename),'obj','-mat','-v7');
            % update rootpath for object to the most recent used one
            rootpath.object=obj.name;
            % make output message
            message=sprintf('Rat walk file %s saved\n',filename);
            status=true;
        else
            % make output message
            message=sprintf('File saving cancelled\n');
        end
        % output message
        msgbox(message,'Save Rat File Message','modal');
    else
        % auto batch processing need auto save
        pathname=rootpath.object;
        [~,filename,~]=fileparts(obj.raw_av_obj.Name);
        filename=cat(2,pathname,filename,'.rwm');
        % update object name to the new filename
        obj.name=filename;
        % save as ver7 mat file
        save(filename,'obj','-mat','-v7');
        % update rootpath for object to the most recent used one
        status=true;
    end
    % audio confirmation
    beep;beep;
catch exception
    % error handling
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end