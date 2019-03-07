function [ status ] = op_radialpos( ratwalk_h, panel_h )
%OP_RADIALPOS Calculate the radial distance from the center of the floor
%and angle distribution in the arena
%location_edge=[0,0.23,0.37,0.6]; define centre,edge,corner as distance from centre

status=false;
location_edge=[0,0.23,0.37,0.6];%define centre,edge,corner as distance from centre
location_id={'Centre','Edge','Corner'};
try
    % -------------------------------------------------
    % parameter definitions
    
    angularhandle=panel_h.PANEL_RESULT2D;
    lochandle=panel_h.PANEL_RESULT1DRECT;
    raddisthandle=panel_h.PANEL_RESULT1DSQ;
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [time,edgex,rho,theta]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [time{1},edgex{1},rho{1},theta{1}]=calculate(ratwalk_h);
    end
    
    % -------------------------------------------------
     % get object names
    objname=regexp(cellfun(@(x)x.name,ratwalk_h,'UniformOutput',false),'(?<=\\)\w*(?=.rwm)','match');
    % plotting
    for ratidx=1:numel(rho)
        % plot radial distance histgram
        [ploty,~,plotbin]=histcounts(rho{ratidx},edgex{ratidx});
        plotx=diff(edgex{ratidx})/2+edgex{ratidx}(1:end-1);
        ploty=accumarray(plotbin+1,time{ratidx},[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        plot(raddisthandle,plotx,ploty,'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        
        % plot time spent at different location
        [locy,~,locbin]=histcounts(rho{ratidx},location_edge);
        locy=accumarray(locbin+1,time{ratidx},[numel(locy)+1,1],@sum,0);% total time
        locy=100*locy./sum(locy);% normalise sum to 1
        locationp{ratidx}=locy(2:end);
        plot(lochandle,1:numel(location_edge)-1,locationp{ratidx},'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        
        % plot rat walk angle in 2D to see preferential corners
        [a,b]=rose(theta{ratidx},36);
        b=100*b./numel(theta{ratidx});%percentage frame time
        polar(angularhandle,a,b);
    end

    % radial distribution
    raddisthandle.XLabel.String='Radial Distance from Centre(m)';
    raddisthandle.YLabel.String='% Time spent';
    raddisthandle.XGrid='on';raddisthandle.XMinorGrid='on';
    raddisthandle.YGrid='on';raddisthandle.YMinorGrid='on';
    raddisthandle.YScale='Log';
    axis(raddisthandle,'tight');
    
    % preferred location
    lochandle.XTick=1:1:numel(location_edge);
    lochandle.XTickLabel=location_id;
    lochandle.XLabel.String='Location';
    lochandle.YLabel.String='% Time spent';
    lochandle.YScale='Log';
    lochandle.XGrid='on';lochandle.XMinorGrid='on';
    lochandle.YGrid='on';lochandle.YMinorGrid='on';
    axis(lochandle,[0.5,3.5,1e-1,1e2]);
    
    % Angular distribution
    angularhandle.XLabel.String='Angle (Deg)';angularhandle.YLabel.String='% Time Spent';
    angularhandle.XGrid='on';angularhandle.XMinorGrid='on';
    angularhandle.YGrid='on';angularhandle.YMinorGrid='on';
    axis(angularhandle,'tight');
    %---------------------------------------------------------------------
    % group mean plot
    groupid=repmat(panel_h.LIST_GROUP.Value,[numel(location_id),1]);
    groupid=groupid+[-0.2;0;0.2];
    errorbar(panel_h.PANEL_RESULTGROUP1DSQ,groupid,mean(cell2mat(locationp),2),std(cell2mat(locationp),[],2),'Marker','o','MarkerSize',8,'LineStyle','none','LineWidth',2);
    panel_h.PANEL_RESULTGROUP1DSQ.XLabel.String='Group Index';
    panel_h.PANEL_RESULTGROUP1DSQ.YLabel.String='Group Mean % Time spent';
    panel_h.PANEL_RESULTGROUP1DSQ.XGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.XMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DSQ.YGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.YMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DSQ.YScale='Log';
    axis(panel_h.PANEL_RESULTGROUP1DSQ,'auto');
    panel_h.PANEL_RESULTGROUP1DSQ.XLim=[0.5,panel_h.LIST_GROUP.Value+0.5];
    
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end

% -------------------------------------------------
    function [ time, x, rdist, angle ] = calculate(ratobj)
        % get rat centroid position
        rat_pos=ratobj.abstract_av.object(3).position;
        [angle,rdist]=cart2pol(rat_pos(:,1),rat_pos(:,2));
        x=linspace(0,ratobj.max_floorlength/2,10);% bin number change here
        time=ratobj.abstract_av.time;
    end
end