function [ status ] = process_frames( obj, image_panel_handle, showav )
%PROCESS_FRAMES Semi-automatic rat tracing and tracking

%% function complete
status=false;
try
    % looop through video frame till the end
    vf=obj.abstract_av.frame_num;
    % move to the start of the video
    obj.raw_av_obj.CurrentTime = 0;
    fw=obj.abstract_av.frame_width;
    fh=obj.abstract_av.frame_height;
    cropmin=obj.abstract_av.crop_min;
    cropmax=obj.abstract_av.crop_max;
    ratsize=(obj.max_ratlength*obj.max_ratwidth)./(obj.pixel_res^2);%maximum rat size in pixel area
    floorbound=obj.abstract_av.object(1).boundary{1}(1:end-1,:);
    [xcoord,ycoord]=meshgrid(1:fw,1:fh);
    inbox=inpolygon(xcoord,ycoord,floorbound(:,1),floorbound(:,2));
    floor_val=uint8(max(obj.floor_range));
    global rootpath; %#ok<TLEV>
    waitbar_handle = waitbar(0,'Please wait...','Progress Bar','Calculating...',...
        'Name',cat(2,'Processing ',obj.raw_av_obj.Name),...
        'CreateCancelBtn',...
        'setappdata(gcbf,''canceling'',1)',...
        'WindowStyle','normal',...
        'Color',[0.2,0.2,0.2]);
    setappdata(waitbar_handle,'canceling',0);
    javaFrame = get(waitbar_handle,'JavaFrame');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(cat(2,rootpath.icon,'Rat_Open_Field.jpg')));
    % get total calculation step
    barstep=0;fc=1;
    while hasFrame(obj.raw_av_obj) % if we read it fine
        temp=readFrame(obj.raw_av_obj);
        %cdata=0.2989 * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),1) - 0.1140 * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),3); %crop size and red - blue channel
        cdata=0.2989 * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),1) + 0.5870 * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),2) + 0.1140 * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),3); %convert rgb to grayscale
        cdata(~inbox)=0;
        if showav
            if fc>1
                set(rawimg_h,'CData',cdata);
            else
                rawimg_h=image(cdata,'Parent',image_panel_handle,'CDataMapping','scaled');
                view(image_panel_handle,[0 -90]);
                hold(image_panel_handle,'on');
            end
        end
        scaling=255/max(cdata(:));
        cdata=cdata*scaling;
        bg_val=floor_val*scaling*0.37+255*0.37;
        % revert image back to floor as 0
        pdata=(cdata>bg_val);
        % find objects
        b = bwboundaries(pdata,8,'noholes');
        % calculate object size and centre
        [cx,cy,area]=cellfun(@(x)find_centroid(fliplr(x)),b);
        % find rat object within the box and has certain size
        ratidx=find(area<ratsize&area>ratsize/10);
        % get rat boundary
        switch numel(ratidx)
            case 0
                % nothing found
                ratidx=find(area>ratsize,1,'first');
                if isempty(ratidx)
                    [~,ratidx]=max(area);
                    %ratidx=find(area<(ratsize/10),1,'last');
                end
            case 1
                
            otherwise
                infloor=find(inpolygon(cx(ratidx),cy(ratidx),floorbound(:,1),floorbound(:,2)));
                if isempty(infloor)
                    ratidx=ratidx(end);
                else
                    ratidx=ratidx(infloor(end));
                end
        end
        if ~isempty(ratidx)
            % lose frame is cannot detect
            obj.abstract_av.time(fc)=obj.raw_av_obj.CurrentTime;
            ratbound=fliplr(b{ratidx});
            obj.abstract_av.object(3).boundary{fc}=ratbound;
            obj.abstract_av.object(3).position(fc,:)=[cx(ratidx),cy(ratidx)];
            if fc>1
                obj.abstract_av.object(2).boundary{fc}=obj.abstract_av.object(2).boundary{fc-1};
                obj.abstract_av.object(1).boundary{fc}=obj.abstract_av.object(1).boundary{fc-1};
            end
        else
            % lost frame assume same as before
            obj.abstract_av.time(fc)=obj.raw_av_obj.CurrentTime;
            if fc>1
                obj.abstract_av.object(3).boundary{fc}=obj.abstract_av.object(3).boundary{fc-1};
                obj.abstract_av.object(3).position(fc,:)=obj.abstract_av.object(3).position(fc-1,:);
                obj.abstract_av.object(2).boundary{fc}=obj.abstract_av.object(2).boundary{fc-1};
                obj.abstract_av.object(1).boundary{fc}=obj.abstract_av.object(1).boundary{fc-1};
            end
        end
        if showav
            if fc>1
                set(ratimg_h,'XData',ratbound(:,1),'YData',ratbound(:,2));
                set(time_h,'String',sprintf('%0.2f sec',obj.abstract_av.time(fc)));
                pause(0.001);
            else
                ratimg_h=plot(image_panel_handle,obj.abstract_av.object(3).boundary{fc}(:,1),obj.abstract_av.object(3).boundary{fc}(:,2),obj.abstract_av.object(3).colour,'LineWidth',2);
                floorimg_h=plot(image_panel_handle,obj.abstract_av.object(1).boundary{fc}(:,1),obj.abstract_av.object(1).boundary{fc}(:,2),obj.abstract_av.object(1).colour,'LineWidth',2);
                time_h=text(0,20,sprintf('%0.1f sec',obj.abstract_av.time(fc)),'Parent',image_panel_handle,'Color','w','FontSize',14,'FontWeight','bold');
                hold(image_panel_handle,'off');
            end
        end
        % waitbar
        done=fc/vf;
        % Report current estimate in the waitbar's message field
        if min(100,floor(100*done))>=barstep
            % update waitbar
            waitbar(done,waitbar_handle,sprintf('%g%%',floor(100*done)));
            barstep=barstep+1;
        end
        % check waitbar
        if getappdata(waitbar_handle,'canceling')
            message=sprintf('Data Import cancelled\n');
            delete(waitbar_handle);       % DELETE the waitbar; don't try to CLOSE it.
            errordlg(sprintf('%s\n',message),'analyser error','modal');
            return;
        end
        fc=fc+1;
    end
    delete(waitbar_handle);       % DELETE the waitbar; don't try to CLOSE it.
    if numel(obj.abstract_av.object(1).boundary)>=fc
        % overestimated frame numbers
        obj.abstract_av.time(fc:end)=[];
        for objidx=1:numel(obj.abstract_av.object)
            obj.abstract_av.object(objidx).boundary(fc:end)=[];
            if ~isempty(obj.abstract_av.object(objidx).position)
                obj.abstract_av.object(objidx).position(fc:end,:)=[];
            end
        end
    end
    obj.abstract_av.frame_num=numel(obj.abstract_av.time);
    obj.abstract_av.frame_rate=obj.raw_av_obj.frameRate;
    if showav
        set(time_h,'String','Fin');
    end
    % reset video time
    obj.raw_av_obj.CurrentTime = 0;
    beep;beep;
    status=true;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end