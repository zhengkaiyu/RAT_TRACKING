function obj = open_ratwalk( obj, filename )
%OPEN_RATWALK Open saved abstract rat walk file

%% function complete
try
    if ischar(filename)
        % concatenate filename
        temp=load(filename,'-mat');
        if isfield(temp,'obj')
            if isa(temp.obj,'RATWALK')
                obj=temp.obj;
                % make output message
                message=sprintf('Rat walk file %s loaded\n',filename);
            else
                message=sprintf('%s is not a RATWALK variable\n',filename);
            end
        else
            message=sprintf('%s is not a RATWALK variable\n',filename);
        end
    else
        message=sprintf('File loading cancelled\n');
    end
    msgbox(message,'Open Rat File Message','modal');
    beep;beep;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end