function [ status ] = export_abstract_video( obj )
%export_abstract_video write analysed abstract video as a normal video file
%for playback

%% function complete
status = false;
global rootpath;
try
    if isempty(rootpath);
        pathname='./';
    else
        pathname=rootpath.export;
    end
    [ filename, pathname, ~ ] = uiputfile({'*.mp4','Abstract Video File(.mp4)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Export to Abstract Video File', ...
        pathname);
    if ischar(filename)
        % create av file object
        filename=cat(2,pathname,filename);
        rootpath.export=filename;
        avobj = VideoWriter(filename,'MPEG-4');
        % sync frame rate to original video
        avobj.FrameRate=obj.abstract_av.frame_rate;
        avobj.Quality=50;
        % open av object file to write
        open(avobj);
        
        % setup output figure
        figure(11);set(gcf,'Renderer','zbuffer');
        outputpanel=gca;
        axis(outputpanel,'square');
        set(outputpanel,'nextplot','replacechildren');
        
        % loop through all frames and write to av file
        for frame_idx = 1:obj.abstract_av.frame_num
            % display frame
            obj.display_frames(outputpanel,frame_idx,'wire');
            % record frame
            frame = getframe(outputpanel);
            % write frame to av file
            writeVideo(avobj,frame);
        end
        % close av file
        close(avobj);
        % close temporary figure
        close(figure(11));
        % make output message
        message=sprintf('abstract video %s exported\n',filename);
    else
        message=sprintf('abstract video file export cancelled\n');
    end
    msgbox(message,'Export Abstract Video File Message','modal');
    beep;beep;
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end