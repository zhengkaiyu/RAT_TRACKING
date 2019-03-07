function [ status ] = op_forcetrack( ratwalk_h, panel_h )
%OP_FORCETRACK calculate the speed, acceleration, force and work done
%   minimum horizontal work done,
%   Fh = mass * horz_acceleration
%   Wh = Force * horz_displacement = mass * horz_acceleration * horz_displacement
%   horz_speed = horz_displacement/delta(time)
%   horz_acceleration = delta(horz_speed)/delta(time)

status=false;
vel_grid=linspace(0,0.5,20);acc_grid=linspace(-5,5,20);
try
    % -------------------------------------------------
    % parameter definitions
    
    corrhandle=panel_h.PANEL_RESULT2D;
    forcehandle=panel_h.PANEL_RESULT1DRECT;
    accelhandle=panel_h.PANEL_RESULT1DSQ;
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [t,v,a,f,~]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [t{1},v{1},a{1},f{1},~]=calculate(ratwalk_h);
    end
    
    % -------------------------------------------------
    % plotting
    % x axis edge boundary for histogram
    edgex=[fliplr(-logspace(-1,1,10)),logspace(-1,1,10)];
    %edgex=acc_grid;
    % calculate plot x axis
    plotx=diff(edgex)/2+edgex(1:end-1);
    % get object names
    objname=regexp(cellfun(@(x)x.name,ratwalk_h,'UniformOutput',false),'(?<=\\)\w*(?=.rwm)','match');
    for ratidx=1:numel(t)
        % calculate histogram
        [ploty,~,plotbin]=histcounts(a{ratidx},edgex);
        ploty=accumarray(plotbin+1,t{ratidx}(2:end),[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        % plot distribution of acceleration during this time
        plot(accelhandle,plotx,ploty,'Marker','o','MarkerSize',3,'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        
        % plot Force over time
        plot(forcehandle,t{ratidx}(2:end),f{ratidx},'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        
        % extra figure for contour of scatter plot below
        sp_num=ceil(sqrt(numel(t)));
        figure(1);
        h=subplot(sp_num,ceil(numel(t)/sp_num),ratidx);
        values = hist3([v{ratidx}(2:end),a{ratidx}],{vel_grid,acc_grid});
        values=log10(values);% change to log scale in z
        values(isinf(values))=0;
        contour(vel_grid,acc_grid,values',[0,0.6,1,1.5,2],'Parent',gca,'ShowText','on');
        h.XLabel.String='speed (m/s)';
        h.YLabel.String='acceleration (m/s^{2})';
        h.XGrid='on';h.XMinorGrid='on';
        h.YGrid='on';h.YMinorGrid='on';
        [~,ratname,~]=fileparts(ratwalk_h{ratidx}.name);
        title(ratname,'Interpreter','none');
        axis(h,[vel_grid(1),vel_grid(end),acc_grid(1),acc_grid(end)]);
        
        % plot speed vs accel
        plot(corrhandle,v{ratidx}(2:end),a{ratidx},'Marker','.','MarkerSize',2,'MarkerFaceColor','none','LineStyle','none','Tag',char(objname{ratidx}));
    end
    
    % plot labelling
    accelhandle.XLabel.String='Acceleration (m/s^{2})';
    accelhandle.YLabel.String='% Time spent';
    set(accelhandle,'YScale','log');
    accelhandle.XGrid='on';accelhandle.XMinorGrid='on';
    accelhandle.YGrid='on';accelhandle.YMinorGrid='on';
    axis(accelhandle,[min(edgex),max(edgex),1e-4,1e2]);
    
    forcehandle.XLabel.String='Time (s)';
    forcehandle.YLabel.String='Force (N)';
    forcehandle.XGrid='on';forcehandle.XMinorGrid='on';
    forcehandle.YGrid='on';forcehandle.YMinorGrid='on';
    axis(forcehandle,'tight');
    
    corrhandle.XLabel.String='speed (m/s)';
    corrhandle.YLabel.String='acceleration (m/s^{2})';
    corrhandle.XGrid='on';corrhandle.XMinorGrid='on';
    corrhandle.YGrid='on';corrhandle.YMinorGrid='on';
    vel_grid=[0,1];acc_grid=[min(edgex),max(edgex)];
    axis(corrhandle,[vel_grid(1),vel_grid(end),acc_grid(1),acc_grid(end)]);
    %---------------------------------------------------------------------
    % extra group information
    plot(panel_h.PANEL_RESULTGROUP1DRECT,1:numel(t),cellfun(@(x)std(x),v),'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',2);
    panel_h.PANEL_RESULTGROUP1DRECT.XLabel.String='plot index';
    panel_h.PANEL_RESULTGROUP1DRECT.YLabel.String='speed std';
    panel_h.PANEL_RESULTGROUP1DRECT.XGrid='on';panel_h.PANEL_RESULTGROUP1DRECT.XMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DRECT.YGrid='on';panel_h.PANEL_RESULTGROUP1DRECT.YMinorGrid='on';
    axis(panel_h.PANEL_RESULTGROUP1DRECT,'tight');
    
    plot(panel_h.PANEL_RESULTGROUP1DSQ,1:numel(t),cellfun(@(x)std(x),a),'Marker','o','MarkerSize',8,'LineStyle','-','LineWidth',2);
    panel_h.PANEL_RESULTGROUP1DSQ.XLabel.String='plot index';
    panel_h.PANEL_RESULTGROUP1DSQ.YLabel.String='acceleration std';
    panel_h.PANEL_RESULTGROUP1DSQ.XGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.XMinorGrid='on';
    panel_h.PANEL_RESULTGROUP1DSQ.YGrid='on';panel_h.PANEL_RESULTGROUP1DSQ.YMinorGrid='on';
    axis(panel_h.PANEL_RESULTGROUP1DSQ,'auto');
    
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end

% -------------------------------------------------
    function [ time, speed, accel, Fh, Wh ] = calculate( ratobj )
        timewindow=1/20; %second
        % get video framerate for smoothing
        framerate = ceil(ratobj.abstract_av.frame_rate*timewindow);
        % get time in seconds
        time = ratobj.abstract_av.time';
        % get rat mass in kilograms
        mass = ratobj.mass/1000;% convert to kg for force calculation (N=kg.m^2/s)
        % get rat position time lapse
        rat_pos = ratobj.abstract_av.object(3).position;
        % calculation delta(position) in meters
        displacement = sqrt(sum(diff(rat_pos).^2,2));
        % average displacement to one second intervals
        %displacement=filter(1/framerate*ones(1,framerate),1,displacement);
        % calculate speed as ds/dt
        speed = displacement./diff(time);
        % cap maximum possible speed
        speed(speed>ratobj.max_speed)=ratobj.max_speed;
        % average speed to one second intervals
        speed=filter(1/framerate*ones(1,framerate),1,speed);
        % adjust time to match speed vector length
        time=time(2:end);
        % calculate acceleration as dv/dt
        accel = diff(speed)./diff(time);
        % calculate force
        Fh = mass*abs(accel);
        % calculate work done
        Wh = Fh.*displacement(2:end);
    end
end