function [ status ] = op_tortuositytrack( ratwalk_h, panel_h )
%OP_TORTUISITYTRACK Calculate the tortuosity of the rat boundary
%   Tortuosity is defined as
%   tort = perimeter / sqrt(area)
%   histgram of the tortuosity, tortuosity over time will be plotted

status=false;
try
    % -------------------------------------------------
    % calculation
    if iscell(ratwalk_h)
        [time,tort,pos]=cellfun(@(x)calculate(x),ratwalk_h,'UniformOutput',false);
    else
        [time{1},tort{1},pos{1}]=calculate(ratwalk_h);
    end
    % -------------------------------------------------
    % plotting
    plotx=linspace(3,10,100)';
    for ratidx=1:numel(time)
        % display distribution of Tortuosity during this time
        [ploty,~,plotbin]=histcounts(tort{ratidx},plotx);
        ploty=accumarray(plotbin+1,time{ratidx},[numel(ploty)+1,1],@sum,0);% total time
        ploty=100*ploty./sum(ploty);% normalise sum to 1
        ploty=ploty(2:end);% remove the out of bound bin
        plot(panel_h.PANEL_RESULT1DSQ,plotx(2:end),ploty,'LineStyle','-','LineWidth',1);
        % plot tortuosity over time
        plot(panel_h.PANEL_RESULT1DRECT,time{ratidx},tort{ratidx},'LineWidth',1,'LineStyle','-');
        
    end
    % plot labelling
    panel_h.PANEL_RESULT1DSQ.XLabel.String='Tortuosity';
    panel_h.PANEL_RESULT1DSQ.YLabel.String='% Time spent';
    panel_h.PANEL_RESULT1DSQ.XGrid='on';panel_h.PANEL_RESULT1DSQ.XMinorGrid='on';
    panel_h.PANEL_RESULT1DSQ.YGrid='on';panel_h.PANEL_RESULT1DSQ.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT1DSQ,'tight');
    
    panel_h.PANEL_RESULT1DRECT.XLabel.String='Time (s)';
    panel_h.PANEL_RESULT1DRECT.YLabel.String='Tortuosity';
    panel_h.PANEL_RESULT1DRECT.XGrid='on';panel_h.PANEL_RESULT1DRECT.XMinorGrid='on';
    panel_h.PANEL_RESULT1DRECT.YGrid='on';panel_h.PANEL_RESULT1DRECT.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT1DRECT,'tight');
    
    panel_h.PANEL_RESULT2D.XGrid='on';panel_h.PANEL_RESULT2D.XMinorGrid='on';
    panel_h.PANEL_RESULT2D.YGrid='on';panel_h.PANEL_RESULT2D.YMinorGrid='on';
    axis(panel_h.PANEL_RESULT2D,'tight');
    
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