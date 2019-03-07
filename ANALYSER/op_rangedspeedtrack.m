function [ status ] = op_rangedspeedtrack( ratwalk_h, panel_h )
%OP_RANGEDSPEEDTRACK calculate the Mean running speed, % time spent running
%and mean acceleration
%   running is defined as speed between 0.05m/s to 3m/s as indicated in op_rangedspeedtrack.m)
%   running speed above max speed is set to max speed

status=false;

try
    % -------------------------------------------------
    % parameter definitions
    speed_bound=[0.05,3];% default lower and upper bound for speed m/s
    accelhandle=panel_h.PANEL_RESULT2D;
    timehandle=panel_h.PANEL_RESULT1DRECT;
    speedhandle=panel_h.PANEL_RESULT1DSQ;
    % -------------------------------------------------
    % calculation returns
    % t = time information [total running time, total video time]
    % v = speed information [mean running speed, std of running speed]
    % a = mean and std information on acceleration(1st row) and
    % deacceleration(2nd row)
    if iscell(ratwalk_h)
        [t,v,a]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [t{1},v{1},a{1}]=calculate(ratwalk_h);
    end
    
    % -------------------------------------------------
    % plotting
    %for ratidx=1:numel(t)
        % plot mean running speed+std
        temp=cell2mat(v');
        errorbar(speedhandle,1:1:numel(t),temp(:,1),temp(:,2),'Marker','o','MarkerSize',3,'LineStyle','-','LineWidth',1);
        
        % plot % time running
        temp=cell2mat(t');
        plot(timehandle,1:1:numel(t),100*temp(:,1)./temp(:,2),'Marker','o','MarkerSize',5,'MarkerFaceColor','none','LineStyle','-','LineWidth',1);
        
        % plot accel/deaccel info
        temp=cell2mat(a');
        acc=temp(1:2:end,:);dacc=temp(2:2:end,:);
        errorbar(panel_h.PANEL_RESULT2D,1:1:numel(t),acc(:,1),acc(:,2),'Marker','o','MarkerSize',5,'MarkerFaceColor','none','LineStyle','-');
        hold all;errorbar(accelhandle,1:1:numel(t),dacc(:,1),dacc(:,2),'Marker','o','MarkerSize',5,'MarkerFaceColor','none','LineStyle','-');
    %end
    % plot labelling
    speedhandle.XLabel.String='plot index';
    speedhandle.YLabel.String='Mean Running Speed (m/s)';
    set(speedhandle,'YScale','linear');
    speedhandle.XGrid='on';speedhandle.XMinorGrid='on';
    speedhandle.YGrid='on';speedhandle.YMinorGrid='on';
    axis(speedhandle,'auto');
    
    timehandle.XLabel.String='plot index';
    timehandle.YLabel.String='% Time Spent Running';
    timehandle.XGrid='on';timehandle.XMinorGrid='on';
    timehandle.YGrid='on';timehandle.YMinorGrid='on';
    axis(timehandle,'auto');
    
    accelhandle.XLabel.String='plot index';
    accelhandle.YLabel.String='mean acceleration (m/s^{2})';
    accelhandle.XGrid='on';accelhandle.XMinorGrid='on';
    accelhandle.YGrid='on';accelhandle.YMinorGrid='on';
    axis(accelhandle,'auto');
   
    %--------------------------------------------------------------------
   
    %--------------------------------------------------------------------
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end

% -------------------------------------------------

    function [ info_time, info_speed, info_accel ] = calculate( ratobj )
        timewindow=1/20; %second
        % get video framerate for smoothing
        framerate = ceil(ratobj.abstract_av.frame_rate*timewindow);
        % get time in seconds
        time = ratobj.abstract_av.time';
        % get rat position time lapse
        rat_pos = ratobj.abstract_av.object(3).position;
        % calculation delta(position) in meters
        displacement = sqrt((rat_pos(2:end,1)-rat_pos(1:end-1,1)).^2+(rat_pos(2:end,2)-rat_pos(1:end-1,2)).^2);
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
        
        running_idx=(speed>=speed_bound(1)&speed<=speed_bound(2));
        info_speed=[mean(speed(running_idx)),std(speed(running_idx))];
        temp=accel(running_idx(1:end-1));%accel has one less element than speed
        info_accel=[mean(temp(temp>0)),std(temp(temp>0));mean(temp(temp<0)),std(temp(temp<0))];
        t_int=diff(time);
        info_time=[sum(t_int(running_idx(1:end-1))),time(end)-time(1)];
    end
end