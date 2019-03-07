function [ status ] = op_centroidtrack( ratwalk_h, panel_h )
%OP_CENTROIDTRACK track the centroid of the rat and plot its track w.r.t floor centre,
%cumulative distance travelled over time and distribution of its top area
%during test time

status=false;
try
    % -------------------------------------------------
    % parameter definitions
    histbin=100;    % number of bins in area histogram
    
    trackhandle=panel_h.PANEL_RESULT2D;
    disthandle=panel_h.PANEL_RESULT1DRECT;
    areahandle=panel_h.PANEL_RESULT1DSQ;
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [time,pos,area,dist]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [time{1},pos{1},area{1},dist{1}]=calculate(ratwalk_h);
    end
    s=cellfun(@(x)cumsum(x),dist,'UniformOutput',false);% get cumulative distance
    
    % -------------------------------------------------
    % plotting
    % area histogram edge definition
    edgex=linspace(1e-3,1e-2,histbin);
    plotx=diff(edgex)/2+edgex(1:end-1);
    % get object names
    objname=regexp(cellfun(@(x)x.name,ratwalk_h,'UniformOutput',false),'(?<=\\)\w*(?=.rwm)','match');
    for ratidx=1:numel(time)
        % plot distribution of area during this time
        [ploty,~,plotbin]=histcounts(area{ratidx},edgex);
        ploty=accumarray(plotbin+1,time{ratidx},[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        plot(areahandle,plotx,ploty,'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        % plot cumulative distances travelled
        plot(disthandle,time{ratidx}(2:end),s{ratidx},'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        % plot rat walk trajectory for centroid positions
        plot(trackhandle,pos{ratidx}(:,1),pos{ratidx}(:,2),'Marker','.','MarkerSize',5,'LineStyle','none','LineWidth',1,'Tag',char(objname{ratidx}));
    end
    % rat area distribution plot
    areahandle.XLabel.String='Rat Area (m^{3})';
    areahandle.YLabel.String='% Time spent';
    areahandle.XGrid='on';areahandle.XMinorGrid='on';
    areahandle.YGrid='on';areahandle.YMinorGrid='on';
    axis(areahandle,'tight');
    
    % cumulative distance plot
    disthandle.XLabel.String='Time (s)';
    disthandle.YLabel.String='Cumulative Distance (m)';
    disthandle.XGrid='on';disthandle.XMinorGrid='on';
    disthandle.YGrid='on';disthandle.YMinorGrid='on';
    axis(disthandle,'tight');
    
    % track plot
    trackhandle.XLabel.String='distance (m)';
    trackhandle.YLabel.String='distance (m)';
    trackhandle.XGrid='on';trackhandle.XMinorGrid='on';
    trackhandle.YGrid='on';trackhandle.YMinorGrid='on';
    axis(trackhandle,'tight');
    
    %--------------------------------------------------------------------
    % extra group information of estimated distance travelled over 10 minutes
    s_total=cellfun(@(x,y)x(end)/y(end)*600,s,time);
    plot(panel_h.PANEL_RESULTGROUP1DRECT,1:numel(time),s_total,'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',2);
    panel_h.PANEL_RESULTGROUP1DRECT.XLabel.String='object index';
    panel_h.PANEL_RESULTGROUP1DRECT.YLabel.String='Est. Dist. in 10min (m)';
    panel_h.PANEL_RESULTGROUP1DRECT.XGrid='on';panel_h.PANEL_RESULTGROUP1DRECT.XMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DRECT.YGrid='on';panel_h.PANEL_RESULTGROUP1DRECT.YMinorGrid='on';
    axis(panel_h.PANEL_RESULTGROUP1DRECT,'tight');
    
    % group mean plot
    groupid=panel_h.LIST_GROUP.Value;
    errorbar(panel_h.PANEL_RESULTGROUP1DSQ,groupid,mean(s_total),std(s_total),'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',2);
    panel_h.PANEL_RESULTGROUP1DSQ.XLabel.String='group index';
    panel_h.PANEL_RESULTGROUP1DSQ.YLabel.String='Est. Dist. in 10min (m)';
    panel_h.PANEL_RESULTGROUP1DSQ.XGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.XMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DSQ.YGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.YMinorGrid='on';
    axis(panel_h.PANEL_RESULTGROUP1DSQ,'auto');
    %--------------------------------------------------------------------
    
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
% -------------------------------------------------
    function [ time, position, area, distance ] = calculate( ratobj )
        % get time coordinate
        time=ratobj.abstract_av.time;
        % get rat bound time lapse
        ratbound=ratobj.abstract_av.object(3).boundary;
        % calculate rat centroid and area
        [cx,cy,area]=cellfun(@(x)find_centroid(x),ratbound);
        % get floor bound
        floorbound=ratobj.abstract_av.object(1).boundary{1};
        % offset rat centroid by the floor center
        [fx,fy,~]=find_centroid(floorbound);
        cx=cx-fx;cy=cy-fy;
        
        % offsetted position and convert to proper unit
        position=[cx,cy]*ratobj.pixel_res;
        % update position vector to proper units
        ratobj.abstract_av.object(3).position=position;
        % convert area to proper units
        area=area*ratobj.pixel_res^2;
        % calculate and convert distance to proper units
        distance=sqrt((cx(2:end)-cx(1:end-1)).^2+(cy(2:end)-cy(1:end-1)).^2)*ratobj.pixel_res;
    end
end