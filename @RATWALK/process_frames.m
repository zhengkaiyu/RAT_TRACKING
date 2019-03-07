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
    % box area to crop from raw video
    cropmin=obj.abstract_av.crop_min;
    cropmax=obj.abstract_av.crop_max;
    ratsize=(obj.max_ratlength*obj.max_ratwidth)./(obj.pixel_res^2);%maximum rat size in pixel area
    floorbound=obj.abstract_av.object(1).boundary{1}(1:end-1,:);
    [xcoord,ycoord]=meshgrid(1:fw,1:fh);
    % coordinate for floor
    inbox=inpolygon(xcoord,ycoord,floorbound(:,1),floorbound(:,2));
    floor_val=uint8(max(obj.floor_range));
    global rootpath; %#ok<TLEV>
    % make progress window
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
    cla(image_panel_handle,'reset');
    %------------------
    while hasFrame(obj.raw_av_obj)
        % if we read it fine
        temp=readFrame(obj.raw_av_obj);
        % convert rgb to grayscale with only cropped data
        cdata=obj.rgb2gray_ratio(1) * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),1) + obj.rgb2gray_ratio(2) * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),2) + obj.rgb2gray_ratio(3) * temp(cropmin(1):cropmax(1),cropmin(2):cropmax(2),3);
        % ignore data outside the floor
        cdata(~inbox)=0;
        %------------------
        % if show video option selected
        if showav
            if fc>1
                set(rawimg_h,'CData',cdata);
            else
                rawimg_h=image(cdata,'Parent',image_panel_handle,'CDataMapping','scaled');
                view(image_panel_handle,[0 -90]);
                hold(image_panel_handle,'on');
            end
        end
        %------------------
        scaling=255/double(max(cdata(:)));
        % stretch the data
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
                % try to find the first one that is greater than rat area
                if isempty(ratidx)
                    % still not found, assume the maximum sized object
                    % being the rat
                    [~,ratidx]=max(area);
                    %ratidx=find(area<(ratsize/10),1,'last');
                end
            case 1
                % found only one object, great, nothing to do
            otherwise
                % too many object, find ones inside the floor
                infloor=find(inpolygon(cx(ratidx),cy(ratidx),floorbound(:,1),floorbound(:,2)));
                if isempty(infloor)
                    ratidx=ratidx(end);
                else
                    ratidx=ratidx(infloor(end));
                end
        end
        if ~isempty(ratidx)
            % load real time
            obj.abstract_av.time(fc)=obj.raw_av_obj.CurrentTime;
            % detect rat and update
            ratbound=fliplr(b{ratidx});
            obj.abstract_av.object(3).boundary{fc}=ratbound;
            obj.abstract_av.object(3).position(fc,:)=[cx(ratidx),cy(ratidx)];
            if fc>1
                obj.abstract_av.object(2).boundary{fc}=obj.abstract_av.object(2).boundary{fc-1};
                obj.abstract_av.object(1).boundary{fc}=obj.abstract_av.object(1).boundary{fc-1};
            end
        else
            % load real time
            obj.abstract_av.time(fc)=obj.raw_av_obj.CurrentTime;
            % lost frame assume same as before
            if fc>1
                obj.abstract_av.object(3).boundary{fc}=obj.abstract_av.object(3).boundary{fc-1};
                obj.abstract_av.object(3).position(fc,:)=obj.abstract_av.object(3).position(fc-1,:);
                obj.abstract_av.object(2).boundary{fc}=obj.abstract_av.object(2).boundary{fc-1};
                obj.abstract_av.object(1).boundary{fc}=obj.abstract_av.object(1).boundary{fc-1};
            end
        end
        %------------------
        % if display image
        if showav
            if fc>1
                % update existing plot to speed up things
                % update rat object
                set(ratimg_h,'XData',ratbound(:,1),'YData',ratbound(:,2));
                % update time stamp
                set(time_h,'String',sprintf('%0.1f sec (frame %g)',obj.abstract_av.time(fc),fc));
                pause(0.001);
            else
                % plot for the first time
                % floor outline
                plot(image_panel_handle,obj.abstract_av.object(1).boundary{fc}(:,1),obj.abstract_av.object(1).boundary{fc}(:,2),obj.abstract_av.object(1).colour,'LineWidth',2);
                % rat object outline
                ratimg_h=plot(image_panel_handle,obj.abstract_av.object(3).boundary{fc}(:,1),obj.abstract_av.object(3).boundary{fc}(:,2),obj.abstract_av.object(3).colour,'LineWidth',2);
                % time stamp text
                time_h=text(0,20,sprintf('%0.1f sec (frame %g)',obj.abstract_av.time(fc),fc),'Parent',image_panel_handle,'Color','w','FontSize',14,'FontWeight','bold');
                hold(image_panel_handle,'off');
            end
        end
        %------------------
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
            % DELETE the waitbar; don't try to CLOSE it.
            delete(waitbar_handle);
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
    % update actual time and frame rate
    obj.abstract_av.frame_num=numel(obj.abstract_av.time);
    obj.abstract_av.frame_rate=obj.raw_av_obj.frameRate;
    % show finished
    if showav
        set(time_h,'String','Fin');
    end
    % reset video time
    obj.raw_av_obj.CurrentTime = 0;
    % audio notification
    beep;beep;
    status=true;
catch exception
    % error handle
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end