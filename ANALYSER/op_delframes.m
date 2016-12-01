function [ status ] = op_delframes( ratwalk_h, panel_h )
%OP_DELFRAMES delete frames between specified time intervals
%   Input dialogue will ask for start tie and end time in seconds
%   Time points between the two time points (INCLUSIVE) will be found
%   Corresponding frames will be removed
%   Don't forget to save the result again to keep the change
%   Or save to alternative name

status=false;
try
    % -------------------------------------------------
    % ask for time points
    prompt = {'Enter Start Time (sec):','Enter End Time (sec):'};
    dlg_title = 'Delete Frames';
    num_lines = 1;
    def = {'0','1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if ~isempty(answer)
        T_bound=cellfun(@(x)str2double(x),answer);
        % -------------------------------------------------
        % calculation
        if iscell(ratwalk_h)
            cellfun(@(x)calculate(x,T_bound),ratwalk_h,'UniformOutput',false);
        else
            calculate(ratwalk_h,T_bound);
        end
        % -------------------------------------------------
        status=true;
    end
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
% -------------------------------------------------
    function calculate(ratobj,Tbound)
        % find out cut index
        cutidx=(ratobj.abstract_av.time>=Tbound(1)&ratobj.abstract_av.time<=Tbound(2));
        if ~isempty(cutidx)
            Tidx=find(cutidx);
            ratobj.abstract_av.time(Tidx(end):end)=ratobj.abstract_av.time(Tidx(end):end)-ratobj.abstract_av.time(Tidx(end));
            ratobj.abstract_av.time(cutidx)=[];
            ratobj.abstract_av.frame_num=numel(ratobj.abstract_av.time);
            for objidx=1:3
                ratobj.abstract_av.object(objidx).boundary(cutidx)=[];
            end
        end
    end
end