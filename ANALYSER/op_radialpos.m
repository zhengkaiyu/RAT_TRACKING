function [ status ] = op_radialpos( ratwalk_h, panel_h )
%OP_RADIALPOS Calculate the radial distance from the center of the floor
%and angle distribution in the arena
%location_edge=[0,0.23,0.37,0.6]; define centre,edge,corner as distance from centre

status=false;
location_edge=[0,0.23,0.37,0.6];%define centre,edge,corner as distance from centre
location_id={'Centre','Edge','Corner'};
try
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [time,edgex,rho,theta]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [time{1},edgex{1},rho{1},theta{1}]=calculate(ratwalk_h);
    end
    
    % -------------------------------------------------
    % plotting
    for ratidx=1:numel(rho)
        % plot radial distance histgram
        [ploty,~,plotbin]=histcounts(rho{ratidx},edgex{ratidx});
        plotx=diff(edgex{ratidx})/2+edgex{ratidx}(1:end-1);
        ploty=accumarray(plotbin+1,time{ratidx},[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        plot(panel_h.PANEL_RESULT1DSQ,plotx,ploty,'LineStyle','-','LineWidth',1);
        
        % plot time spent at different location
        [locy,~,locbin]=histcounts(rho{ratidx},location_edge);
        locy=accumarray(locbin+1,time{ratidx},[numel(locy)+1,1],@sum,0);% total time
        locy=100*locy./sum(locy);% normalise sum to 1
        locationp{ratidx}=locy(2:end);
        plot(panel_h.PANEL_RESULT1DRECT,1:numel(location_edge)-1,locationp{ratidx},'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',1);
        
        % plot rat walk angle in 2D to see preferential corners
        [a,b]=rose(theta{ratidx},36);
        b=100*b./numel(theta{ratidx});%percentage frame time
        polar(panel_h.PANEL_RESULT2D,a,b);
    end
    % radial distribution
    panel_h.PANEL_RESULT1DSQ.XLabel.String='Radial Distance (m)';
    panel_h.PANEL_RESULT1DSQ.YLabel.String='% Time spent';
    panel_h.PANEL_RESULT1DSQ.XGrid='on';panel_h.PANEL_RESULT1DSQ.XMinorGrid='on';
    panel_h.PANEL_RESULT1DSQ.YGrid='on';panel_h.PANEL_RESULT1DSQ.YMinorGrid='on';
    panel_h.PANEL_RESULT1DSQ.YScale='Log';
    axis(panel_h.PANEL_RESULT1DSQ,'tight');
    
    % preferred location
    panel_h.PANEL_RESULT1DRECT.XTick=1:1:numel(location_edge);
    panel_h.PANEL_RESULT1DRECT.XTickLabel=location_id;
    panel_h.PANEL_RESULT1DRECT.XLabel.String='Location';
    panel_h.PANEL_RESULT1DRECT.YLabel.String='% Time spent';
    panel_h.PANEL_RESULT1DRECT.YScale='Log';
    panel_h.PANEL_RESULT1DRECT.XGrid='on';panel_h.PANEL_RESULT1DRECT.XMinorGrid='on';
    panel_h.PANEL_RESULT1DRECT.YGrid='on';panel_h.PANEL_RESULT1DRECT.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT1DRECT,[0.5,3.5,1e-1,1e2]);
    
    % Angular distribution
    panel_h.PANEL_RESULT2D.XLabel.String='Angle (Deg)';panel_h.PANEL_RESULT2D.YLabel.String='% Time Spent';
    panel_h.PANEL_RESULT2D.XGrid='on';panel_h.PANEL_RESULT2D.XMinorGrid='on';
    panel_h.PANEL_RESULT2D.YGrid='on';panel_h.PANEL_RESULT2D.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT2D,'tight');
    
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