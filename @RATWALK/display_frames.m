function [ status ] = display_frames( obj, panel, frame, vidtype )
%DISPLAY_FRAMES Display abstract video

%% function patial complete for wired display
status=false;
try
    num_obj=numel(obj.abstract_av.object);
    fh=obj.abstract_av.frame_height;
    fw=obj.abstract_av.frame_width;
    switch vidtype
        case 'solid'
            cdata=zeros(fw,fh);
            [xcoord,ycoord]=meshgrid(1:size(cdata,1),1:size(cdata,2));
            for oc=1:num_obj
                if isempty(obj.abstract_av.object(oc).boundary{frame})
                    
                else
                    inshape=inpolygon(xcoord,ycoord,obj.abstract_av.object(oc).boundary{frame}(:,1),obj.abstract_av.object(oc).boundary{frame}(:,2));
                    switch obj.abstract_av.object(oc).name
                        case 'wall'
                            cdata(inshape)=0.5;
                        case 'floor'
                            cdata(inshape)=0;
                        case 'rat'
                            cdata(inshape)=1;
                    end
                    status=true;
                end
            end
            if ~isempty(panel)
                temp=findobj(panel,'Tag','aav_img_h');
                if isempty(temp)
                    temp=image('CData',cdata,'Parent',panel,'CDataMapping','scaled');
                    temp.Tag='aav_img_h';
                    view([0 -90]);
                else
                    set(temp,'CData',cdata);
                end
                temp=findobj(panel,'Tag','TimeStamp');
                if isempty(temp)
                    time_h=text(0,20,sprintf('%0.1f sec',obj.abstract_av.time(frame)),'Parent',panel,'Color','k','FontSize',14,'FontWeight','bold');
                    time_h.Tag='TimeStamp';
                else
                    temp.String=sprintf('%0.1f sec',obj.abstract_av.time(frame));
                end
            end
        case 'wire'
            if ~isempty(panel)
                num_obj=numel(obj.abstract_av.object);
                for oc=1:num_obj
                    if isempty(obj.abstract_av.object(oc).boundary{frame})
                        
                    else
                        temp=findobj(panel,'Tag',obj.abstract_av.object(oc).name);
                        if isempty(temp)
                            temp=plot(panel,obj.abstract_av.object(oc).boundary{frame}(:,1),obj.abstract_av.object(oc).boundary{frame}(:,2),obj.abstract_av.object(oc).colour,'LineWidth',1);
                            temp.Tag=obj.abstract_av.object(oc).name;
                            hold(panel,'on');
                            view([0 -90]);
                        else
                            set(temp,'XData',obj.abstract_av.object(oc).boundary{frame}(:,1),'YData',obj.abstract_av.object(oc).boundary{frame}(:,2));
                        end
                        temp=findobj(panel,'Tag','TimeStamp');
                        if isempty(temp)
                            time_h=text(0,20,sprintf('%0.1f sec',obj.abstract_av.time(frame)),'Parent',panel,'Color','k','FontSize',14,'FontWeight','bold');
                            time_h.Tag='TimeStamp';
                        else
                            temp.String=sprintf('%0.1f sec',obj.abstract_av.time(frame));
                        end
                        status=true;
                    end
                end
            end
    end
    if ~isempty(obj.abstract_av.object(oc).position)
        if size(obj.abstract_av.object(oc).position,1)==obj.abstract_av.frame_num
            floorbound=obj.abstract_av.object(1).boundary{1};
            % offset rat centroid by the floor center and convert rat position from
            % meters back to pixels
            [fx,fy,~]=find_centroid(floorbound);
            rat_pos=bsxfun(@plus,obj.abstract_av.object(oc).position(frame,:)/obj.pixel_res,[fx,fy]);
            temp=findobj(panel,'Tag',cat(2,obj.abstract_av.object(oc).name,'_c'));
            if isempty(temp)
                temp=plot(panel,rat_pos(1,1),rat_pos(1,2),'Marker','o','MarkerSize',8,'MarkerFaceColor',obj.abstract_av.object(oc).colour,'MarkerEdgeColor','k','LineWidth',2);
                temp.Tag=cat(2,obj.abstract_av.object(3).name,'_c');
            else
                set(temp,'XData',rat_pos(1,1),'YData',rat_pos(1,2));
            end
        else
            
        end
    end
    if ~isempty(panel)
        set(panel,'XTickLabel',[]);
        set(panel,'YTickLabel',[]);
    end
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end