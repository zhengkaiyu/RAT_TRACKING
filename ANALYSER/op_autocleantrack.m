function [ status ] = op_autocleantrack( ratwalk_h, panel_h )
%OP_DELFRAMES delete frames between specified time intervals
%   Input dialogue will ask for start time and end time in seconds
%   Time points between the two time points (INCLUSIVE) will be found
%   Corresponding frames will be removed
%   Don't forget to save the result again to keep the change
%   Or save to alternative name

status=false;
try
    % -------------------------------------------------
    % parameter definitions
    frame_multiple=5;   % multiplication factor of frame rate perceived as dodgy
    % -------------------------------------------------
    % get time coordinate
    if iscell(ratwalk_h)
        [delidx]=cellfun(@(x)cleantrack(x),ratwalk_h,'UniformOutput',false);
    else
        [delidx{1}]=cleantrack(ratwalk_h);
    end
    
    nframe=cellfun(@(x)numel(x.abstract_av.time),ratwalk_h,'UniformOutput',false);
    todo=cellfun(@(x)~isempty(x),delidx);
    
    % ask for time points
    prompt = {sprintf('%g frames to delete from %g frames\n',[cellfun(@(x)numel(x),delidx);cell2mat(nframe)])};
    dlg_title = 'Auto Delete Frames';
    def = {'Yes'};
    button = questdlg(prompt,dlg_title,'Yes','No',def);
    switch button
        case 'Yes'
            for ratidx=1:numel(ratwalk_h)
                if todo(ratidx)
                    ratwalk_h{ratidx}.abstract_av.time(delidx{ratidx})=[];
                    ratwalk_h{ratidx}.abstract_av.object(1).boundary(delidx{ratidx})=[];
                    ratwalk_h{ratidx}.abstract_av.object(2).boundary(delidx{ratidx})=[];
                    ratwalk_h{ratidx}.abstract_av.object(3).boundary(delidx{ratidx})=[];
                    ratwalk_h{ratidx}.abstract_av.object(3).position(delidx{ratidx},:)=[];
                    ratwalk_h{ratidx}.abstract_av.frame_num=numel(ratwalk_h{ratidx}.abstract_av.time);
                end
            end
            status=true;
        case 'No'
            
    end
    % -------------------------------------------------
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
% -------------------------------------------------
    function [dirtyidx]=cleantrack(ratobj)
        % get rat bound time lapse
        ratbound=ratobj.abstract_av.object(3).boundary;
        % calculate rat centroid and area
        [~,~,area]=cellfun(@(x)find_centroid(x),ratbound);
        % find frame interval that is too close
        dodgytimestamp=find(diff(ratobj.abstract_av.time)<1/(frame_multiple*ratobj.abstract_av.frame_rate))+1;
        % area is zero and timestamp issues
        dirtyidx=union(find(area==0),dodgytimestamp);
    end
end