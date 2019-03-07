function [ status ] = export_panel( panel_handle )
%EXPORT_PANEL export different type of plots from matlab
%   export plot type
%   trace,histogram,surface,scatter

% assume worst
status=false;message='';

% default to current path
PathName = './';
try
    if ishandle(panel_handle)
        % if panel current exist
        panel_tag=panel_handle.Tag;
        
        % --- export traces/histogram ---
        trace=findobj(panel_handle,'Type','line');% find trace plot
        if ~isempty(trace)
            % has trace line plot
            % --- Calculate Data ---
            trace_x=get(trace,'XData');% get xdata
            trace_y=get(trace,'YData');% get ydata
            if size(trace_x,1)==1%single line to export
                % turn single trace into cell data for easy processing
                trace_x={trace_x};
            end
            if size(trace_y,1)==1
                trace_y={trace_y};
            end
            % create data cell holder
            data=cell(numel(trace_x)*2,1);
            data(1:2:end)=flipud(trace_x);data(2:2:end)=flipud(trace_y);
            % --- Ask for output ---
            button=questdlg('Where do you want the line plot data exported to?>','Export plots','Clipboard','File','Cancel','Clipboard');
            switch button
                case {'Cancel',''}
                    % if user cancelled action
                    message=sprintf('%s\n','exporting trace cancelled');
                case 'Clipboard'
                    % send data to clipboard
                    data2clip(cellfun(@(x)x',data,'UniformOutput',false));
                    message=sprintf('%g traces exported to %s\n',numel(trace_x),'Clipboard');
                    status=true;
                case 'File'
                    % work out automatic filename
                    tag=cat(2,PathName,'trace_',panel_tag,'_',datestr(now,'yyyymmddHHMMSS'));
                    % ask for save file confirmation
                    [FileName,PathName]=uiputfile('*.dat','Export Traces',tag);
                    if ischar(FileName)
                        % if user happy
                        FileName=cat(2,PathName,FileName);% get filename
                        % open output file for writing
                        fid = fopen(FileName,'w');
                        % output data into file
                        for i=1:1:numel(data)
                            fprintf(fid,'%d ',data{i});
                            fprintf(fid,'\n');
                        end
                        fclose(fid);% close file
                        message=sprintf('%g traces exported to %s\n',numel(trace_x),FileName);
                        status=true;
                    else
                        % if user cancelled action
                        message=sprintf('%s\n','exporting trace cancelled');
                    end
            end
        else
            % no line object found
            message=sprintf('%s%s\n',message,'No traces found');
        end
        
        % --- error bar plot ---
        errorbarplot=findobj(panel_handle,'Type','errorbar');
        if ~isempty(errorbarplot)
            % has trace line plot
            % --- Calculate Data ---
            trace_x=get(errorbarplot,'XData');% get xdata
            trace_y=get(errorbarplot,'YData');% get ydata
            lb_y=get(errorbarplot,'LData');% get lower error data
            %ub_y=get(errorbarplot,'UData');% get upper error data
            if size(trace_x,1)==1%single line to export
                % turn single trace into cell data for easy processing
                trace_x={trace_x};
            end
            if size(trace_y,1)==1
                trace_y={trace_y};
                lb_y={lb_y};
                %ub_y={ub_y};
            end
            % create data cell holder
            data=cell(numel(trace_x)*3,1);
            data(1:3:end)=flipud(trace_x);
            data(2:3:end)=flipud(trace_y);
            data(3:3:end)=flipud(lb_y);
            % --- Ask for output ---
            button=questdlg('Where do you want the error bar plot data exported to?>','Export plots','Clipboard','File','Cancel','Clipboard');
            switch button
                case {'Cancel',''}
                    % if user cancelled action
                    message=sprintf('%s\n','exporting error bar plot cancelled');
                case 'Clipboard'
                    % send data to clipboard
                    data2clip(cellfun(@(x)x',data,'UniformOutput',false));
                    message=sprintf('%s\n%g error bar plot exported to %s\n',message,numel(trace_x),'Clipboard');
                    status=true;
                case 'File'
                    % work out automatic filename
                    tag=cat(2,PathName,'trace_',panel_tag,'_',datestr(now,'yyyymmddHHMMSS'));
                    % ask for save file confirmation
                    [FileName,PathName]=uiputfile('*.dat','Export error bar plot',tag);
                    if ischar(FileName)
                        % if user happy
                        FileName=cat(2,PathName,FileName);% get filename
                        % open output file for writing
                        fid = fopen(FileName,'w');
                        % output data into file
                        for i=1:1:numel(data)
                            fprintf(fid,'%d ',data{i});
                            fprintf(fid,'\n');
                        end
                        fclose(fid);% close file
                        message=sprintf('%s%g error bar plot exported to %s\n',message,numel(trace_x),FileName);
                        status=true;
                    else
                        % if user cancelled action
                        message=sprintf('%s\n','exporting error bar plot cancelled');
                    end
            end
        else
            % no error plot object found
            message=sprintf('%s%s\n',message,'No error data found');
        end
        
        % --- export surfaces ---
        surface=findobj(panel_handle,'Type','surface');% find surface plot
        if ~isempty(surface)
            % has surf plot data
            map=get(surface,'ZData'); %get surface data
            button=questdlg('Where do you want the surface plot data exported to?>','Export plots','Clipboard','File','Cancel','Clipboard');
            switch button
                case {'Cancel',''}
                    % if user cancelled action
                    message=sprintf('%s\nexporting trace cancelled\n',message);
                case 'Clipboard'
                    % send data to clipboard
                    data2clip(map);
                    message=sprintf('%smap data exported to Clipboard\n',message);
                    status=true;
                case 'File'
                    tag=cat(2,PathName,'surface_',panel_tag,'_',datestr(now,'yyyymmddHHMMSS'));
                    choice = questdlg(...
                        sprintf('Please choose the image export format.\nASCII format will output MxN matrix of Z-values.\nTIFF will export a MxNx3 coloured image file.'),...
                        'Choose Export Format','ASCII','TIFF','TIFF');
                    switch choice
                        case 'ASCII'
                            [FileName,PathName,~] = uiputfile('*.asc','Export surface mesh as',tag);
                            if ischar(FileName)
                                FileName=cat(2,PathName,FileName);
                                save(FileName,'map','-ascii');
                                message=sprintf('%s\nmap exported in ascii format to %s\n',message,FileName);
                                status=true;
                            else
                                message=sprintf('%s%s\n',message,'saveing map cancelled');
                            end
                        case 'TIFF'
                            [FileName,PathName,~] = uiputfile('*.tiff','Export surface mesh as',tag);
                            if ischar(FileName)
                                FileName=cat(2,PathName,FileName);
                                databit=8;
                                colours=get(surface,'CData');
                                colours=colours/max(colours(:))*2^databit;
                                % construct tiff file
                                tifobj = Tiff(FileName,'w');
                                tagstruct.ImageLength=size(colours,1);
                                tagstruct.ImageWidth=size(colours,2);
                                tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
                                tagstruct.BitsPerSample = databit;
                                tagstruct.SamplesPerPixel = 1;
                                %tagstruct.RowsPerStrip = 1;
                                tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
                                tagstruct.Software = 'MATLAB';
                                tagstruct.Copyright = 'FIMAS';
                                tifobj.setTag(tagstruct);
                                tifobj.write(uint8(colours));
                                % close tiff file construct
                                tifobj.close();
                                message=sprintf('%s\nmap exported in TIFF format to %s\n',message,FileName);
                                status=true;
                            else
                                message=sprintf('%s\n%s\n',message,'saveing map cancelled');
                            end
                        otherwise
                            % if user cancelled action
                            message=sprintf('%s\n','exporting trace cancelled');
                    end
            end
        else
            % didn't find surf plot data
            message=sprintf('%s%s\n',message,'No surface data found');
        end
        
        % --- export scatter plot ---
        scatter=findobj(panel_handle,'Type','hggroup');% find surface plot
        if ~isempty(scatter)
            trace_x=(get(trace,'XData'));
            trace_y=(get(trace,'YData'));
            button=questdlg('Where do you want the line plot data exported to?>','Export plots','Clipboard','File','Cancel','Clipboard');
            switch button
                case {'Cancel',''}
                    % if user cancelled action
                    message=sprintf('%s\nexporting trace cancelled\n',message);
                case 'Clipboard'
                    % send data to clipboard
                    data2clip({trace_x,trace_y});
                    message=sprintf('%s\nscatter points exported to Clipboard\n',message);
                    status=true;
                case 'File'
                    tag=cat(2,PathName,'scatter_',panel_tag,'_',datestr(now,'yyyymmddHHMMSS'));
                    [FileName,PathName]=uiputfile('*.dat','Export scatter',tag);
                    if ischar(FileName)
                        % get filename
                        FileName=cat(2,PathName,FileName);
                        fid = fopen(FileName,'w');
                        % export data to ascii
                        fprintf(fid,'%d ',trace_x);
                        fprintf(fid,'\n');
                        fprintf(fid,'%d ',trace_y);
                        fprintf(fid,'\n');
                        fclose(fid);%close file
                        message=sprintf('%s\nscatter plot exported in ascii format to %s\n',message,FileName);
                        status=true;
                    else
                        % if user cancelled action
                        message=sprintf('\n%s%s\n',message,'exporting trace cancelled');
                    end
            end
        else
            % didn't find scatter plot data
            message=sprintf('%s%s\n',message,'No scatter data found');
        end
    else
        % couldn't find panel for some reason
        message=sprintf('Panel currently does not exist\n');
    end
    
    % if somehow failed along the way
    if status==false
        errordlg(sprintf('Error Exporting %s',message),'Error Exporting Figure');
    else
        % notify user of success
        helpdlg(message,'Export Figure');
    end
    
catch exception
    % error handling
    message=exception.message;
    errordlg(sprintf('Error Exporting %s',message),'Error Exporting Figure');
end