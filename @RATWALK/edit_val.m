function [ status ] = edit_val( obj, fieldname, val )
%EDIT_VAL change ratwalk object field values
%   inputs need fieldname and its new value

%% function complete

status = true;
% check fieldname
switch fieldname
    case 'rgb2gray_ratio'
        % rgb2gray_ratio size must be 1x3 vector for [r,g,b]
        if size(val)==[1,3]
            % if size is correct
            obj.(fieldname) = val;    
        else
            % error message
           errordlg(sprintf('Value [ %s ] is unfit for rgb2gray_ratio.\nIt must have a 1x3 vector value.',num2str(val)),'Wrong Value','modal');
           status = false;
        end
    case 'max_speed'
        % max_speed is limited to <30m/s and >0.001m/s
        obj.(fieldname) = min(max(val,1e-3),30); 
    case 'max_floorlength'
        % max_floorlength limited to <100m and  >0.01m
        obj.(fieldname) = min(max(val,1e-2),100); 
    case 'mass'
        % mass limited to <1000g and >0.01g
        obj.(fieldname) = min(max(val,1e-2),1000); 
    case 'max_ratlength'
        % max_ratlength limited to <0.5m and >0.01m
        obj.(fieldname) = min(max(val,0.01),0.5); 
    case 'max_ratwidth'
        % max_ratwidth limited to <0.1m and >0.001m
        obj.(fieldname) = min(max(val,0.001),0.1); 
    case 'hindlimb_length'
        % hindlimb_length limited to <0.05m and >0.001m
        obj.(fieldname) = min(max(val,0.001),0.05); % limited to 0.05m
    otherwise
        % unknown field name or unauthorised change
        errordlg(sprintf('Field name %s unknown or unauthorised to change.',fieldname),'Unknow Field Name','modal');
        status=false;
end
end