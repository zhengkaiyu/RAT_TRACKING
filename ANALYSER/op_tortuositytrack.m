function [ status ] = op_tortuositytrack( ratwalk_h, panel_h )
%OP_TORTUISITYTRACK Calculate the tortuosity of the rat boundary
%   Tortuosity is defined as
%   tort = perimeter / sqrt(area)
%   histgram of the tortuosity, tortuosity over time will be plotted

status=false;
try
    % -------------------------------------------------
    % parameter definitions
    
    torthandle=panel_h.PANEL_RESULT1DRECT;
    histhandle=panel_h.PANEL_RESULT1DSQ;
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [time,tort,pos]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [time{1},tort{1},pos{1}]=calculate(ratwalk_h);
    end
    % -------------------------------------------------
    % get object names
    objname=regexp(cellfun(@(x)x.name,ratwalk_h,'UniformOutput',false),'(?<=\\)\w*(?=.rwm)','match');
    % plotting
    plotx=linspace(3,10,100)';
    for ratidx=1:numel(time)
        % display distribution of Tortuosity during this time
        [ploty,~,plotbin]=histcounts(tort{ratidx},plotx);
        ploty=accumarray(plotbin+1,time{ratidx},[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        plot(histhandle,plotx(2:end),ploty,'LineStyle','-','LineWidth',1,'Tag',char(objname{ratidx}));
        % plot tortuosity over time
        plot(torthandle,time{ratidx},tort{ratidx},'LineWidth',1,'LineStyle','-','Tag',char(objname{ratidx}));
        
    end
    
    legetext=regexp(cellfun(@(x)x.name,ratwalk_h,'UniformOutput',false),'(?<=\\)\w*(?=.rwm)','match');% get object name
    legend(panel_h.PANEL_RESULT2D,[legetext{:}],'Location','northeast','Interpreter','none','Orientation','Verticle');
    
    % plot labelling
    histhandle.XLabel.String='Tortuosity';
    histhandle.YLabel.String='% Time spent';
    histhandle.XGrid='on';histhandle.XMinorGrid='on';
    histhandle.YGrid='on';histhandle.YMinorGrid='on';
    axis(histhandle,'tight');
    
    torthandle.XLabel.String='Time (s)';
    torthandle.YLabel.String='Tortuosity';
    torthandle.XGrid='on';torthandle.XMinorGrid='on';
    torthandle.YGrid='on';torthandle.YMinorGrid='on';
    axis(torthandle,'tight');
    
    panel_h.PANEL_RESULT2D.XGrid='on';panel_h.PANEL_RESULT2D.XMinorGrid='on';
    panel_h.PANEL_RESULT2D.YGrid='on';panel_h.PANEL_RESULT2D.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT2D,'tight');
    %--------------------------------------------------------------------
    
    %--------------------------------------------------------------------
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end

% -------------------------------------------------
    function [time,tort,position_vec]=calculate(ratobj)
        time=ratobj.abstract_av.time;
        tort=cellfun(@(x)tortuosity(x),ratobj.abstract_av.object(3).boundary);
        position_vec=ratobj.abstract_av.object(3).position;
    end
end