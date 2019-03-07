function text = display_data_analyser( obj, output_handle, index )
%DISPLAY_DATA_ANALYSER output all related data analyser to user specified
%output_handle
%   if index is [] display the list of operators,
%   e.g. obj.display_data_analyser(gui_handle,[])
%   if index is specified display the help content for that operator
%   e.g. obj.display_data_analyser(gui_handle,1)
%   output_handle can be [], e.g. obj.display_data_analyser([],[])

%% function complete
%---------------------------------------
% find all methods mfile associated within the class default analyser_path
allfile = dir(cat(2,obj.analyser_path,'*.m'));
% get the filename list
[~,allmethods,~] = cellfun(@(x)fileparts(x),{allfile.name},'UniformOutput',false);
% find methods mfilename starts with op_
[~,found] = regexp(allmethods,'\<(op)_\w*','match');
found_idx = find(cellfun(@(x)~isempty(x),found));
%---------------------------------------
if ~isempty(found_idx)
    % if found methods
    if isempty(index)
        % if no index was specified display all found operators as list
        text = allmethods(found_idx);
    else
        % index check to force correct values
        index = min(max(1,index),numel(found_idx));
        % display help for selected operator
        text = help(allmethods{found_idx(index)});
    end
    % ---------------------------------
    if ishandle(output_handle)
        % if specified output_handle output to its text field
        output_handle.String=text;
    else
        % if output_handle is [], output to stdout
        if iscell(text)
            % cell text of name list
            text = sprintf('%s\n',text{:});
        else
            % help text
            text = sprintf('%s\n',text);
        end
    end
else
    % if no appropriate methods found
    text = sprintf('no method file op_*.m was found\n');
end