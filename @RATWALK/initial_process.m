function [ status ] = initial_process( obj, image_panel_handle, manual )
%INITIAL_PROCESS manual select floor, box and animal for initialisation or
%automated object selection using first 15 frames
%

%% function complete
status=false;
message='';
try
    if isempty(obj.raw_av_obj)
        % if the raw video object has not been loaded
        message=sprintf('You need to load video file first\n');
        errordlg(sprintf('%s\n',message),'analyser error','modal');
    else
        %-----------------------------------
        % move to the start of the video
        obj.raw_av_obj.CurrentTime = 0;
        % estimate frame number from frame rate
        obj.abstract_av.frame_num=ceil(obj.raw_av_obj.FrameRate*obj.raw_av_obj.Duration);
        % initialise boundary cell vectors
        obj.abstract_av.object(1).boundary=cell(obj.abstract_av.frame_num,1);%floor
        obj.abstract_av.object(2).boundary=cell(obj.abstract_av.frame_num,1);%wall
        obj.abstract_av.object(3).boundary=cell(obj.abstract_av.frame_num,1);%rat
        % initialise rat position cell vectors
        obj.abstract_av.object(3).position=zeros(obj.abstract_av.frame_num,2);
        % initialise time vectors
        obj.abstract_av.time=linspace(0,obj.raw_av_obj.Duration,obj.abstract_av.frame_num);
        % output this to the image handle, create new random figure if not specified
        if isempty(image_panel_handle)
            figure(2357);
            image_panel_handle=gca;
        end
        % clear current display to plot image
        cla(image_panel_handle);
        % set colorscale as gray for output image
        colormap(image_panel_handle,'gray');
        %---------------------------------------
        switch manual
            % semi manual initialisation
            case true
                % get video format
                switch obj.raw_av_obj.VideoFormat
                    % if video is RGB we need to convert it to grayscale
                    case 'RGB24'
                        % if we read it fine
                        if hasFrame(obj.raw_av_obj)
                            % load the first frame of video footage
                            tempimg=readFrame(obj.raw_av_obj); % 1st dim is height/2nd dim is width
                            % RGB channel as intended using rgb2gray_ratio
                            tempimg=obj.rgb2gray_ratio(1) * tempimg(:,:,1) + obj.rgb2gray_ratio(2) * tempimg(:,:,2) + obj.rgb2gray_ratio(3) * tempimg(:,:,3);
                        else
                            % failed to read file
                            message=sprintf('unable to read frame\n');
                            errordlg(sprintf('%s\n',message),'analyser error','modal');
                            return;
                        end
                        % if video is grayscale
                    case 'Grayscale'
                        % if we read it fine
                        if hasFrame(obj.raw_av_obj)
                            % load the first frame of video footage
                            tempimg=readFrame(obj.raw_av_obj); % 1st dim is height/2nd dim is width
                        else
                            % failed to read file
                            message=sprintf('unable to read frame\n');
                            errordlg(sprintf('%s\n',message),'analyser error','modal');
                            return;
                        end
                    otherwise
                        % don't know how to read the video format
                        message=sprintf('unknown video format\n');
                        errordlg(sprintf('%s\n',message),'analyser error','modal');
                        return;
                end
                %---------------------------------------
                % display image
                image(tempimg,'Parent',image_panel_handle,'CDataMapping','scaled');
                % flip it around so we can the boundary plotted
                view(image_panel_handle,[0 -90]);
                %---------------------------------------
                % ask to draw enclosure box outline
                answer=questdlg('Select box area by click in on the image','Select Box','OK','NO','modal');
                switch answer
                    case {'NO',''}
                        % user decided to stop
                        message='Action cancelled';
                        errordlg(sprintf('%s\n',message),'analyser error','modal');
                        return;
                    case 'OK'
                        %----------
                        % make constrain function to the plot area
                        fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                        % get impoly enclosure box
                        manual_bound=impoly(image_panel_handle,'PositionConstraintFcn',fcn);
                        % because displayed image has been fliped, we need
                        % to do it to the boundary too.
                        box_bound=fliplr(manual_bound.getPosition);
                        % remove impoly object
                        delete(manual_bound);
                        %----------
                        % crop image to speed up things and help future
                        % video processing
                        % get maximum image size
                        maximgsize=size(tempimg);
                        % minimum pixel number is 1 and cannot be greater than
                        % image size
                        obj.abstract_av.crop_min=min(max(ceil(min(box_bound)),[1,1]),maximgsize);
                        % maximum pixel number not exceeding image size
                        obj.abstract_av.crop_max=max(min(floor(max(box_bound)),maximgsize),[1,1]);
                        % crop image
                        tempimg=tempimg(obj.abstract_av.crop_min(1):obj.abstract_av.crop_max(1),obj.abstract_av.crop_min(2):obj.abstract_av.crop_max(2),:);
                        % get new cropped image size
                        obj.abstract_av.frame_width=obj.abstract_av.crop_max(2)-obj.abstract_av.crop_min(2)+1;
                        obj.abstract_av.frame_height=obj.abstract_av.crop_max(1)-obj.abstract_av.crop_min(1)+1;
                        %----------
                        % clear panel for display cropped image
                        cla(image_panel_handle);
                        % display image
                        image(tempimg,'Parent',image_panel_handle,'CDataMapping','scaled');
                        % get cropped image height and width
                        fh=obj.abstract_av.frame_height;
                        fw=obj.abstract_av.frame_width;
                        % flip it around so we can the boundary plotted
                        view(image_panel_handle,[0 -90]);
                        %----------
                        % ask to get floor boundary
                        msgbox('Select box floor area by click in on the image','Select Floor','modal');
                        % make contraints for floor selection
                        fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                        % ask for floor impoly
                        manual_bound=impoly(image_panel_handle,'PositionConstraintFcn',fcn);
                        % get floor impoly
                        floor_bound=manual_bound.getPosition;
                        % assign floor boundary vector and name
                        obj.abstract_av.object(1).boundary{1}=[floor_bound;floor_bound(1,:)];% need to complete the loop
                        obj.abstract_av.object(1).name='floor';
                        % remove impoly object
                        delete(manual_bound);
                        % work out corners of the floor
                        [val,idx]=min(obj.abstract_av.object(1).boundary{1}*[1 1; -1 -1; 1 -1; -1 1].');
                        [~,corner_idx]=sort(val);
                        % get floor diagnol length in pixel
                        diagnol_pix_dist=sqrt(sum((obj.abstract_av.object(1).boundary{1}(idx(corner_idx(4)),:)-obj.abstract_av.object(1).boundary{1}(idx(corner_idx(1)),:)).^2));
                        % work out resolution
                        obj.pixel_res=obj.max_floorlength/diagnol_pix_dist;
                        %----------
                        % make wall bound polygon from corner vertices
                        % need inner in clockwise direction and outer in counterclockwise
                        % direction for wall polygon specification
                        corner_idx=([corner_idx(4),corner_idx(3),corner_idx(1),corner_idx(2),corner_idx(4)]);%inner square cw
                        wallbound=[[[1;1],[fw;1],[fw;fh],[1;fh]],[1;1],[nan;nan],obj.abstract_av.object(1).boundary{1}(idx(corner_idx),:)']';
                        % assign wall boundary vector and name
                        obj.abstract_av.object(2).boundary{1}=wallbound;
                        obj.abstract_av.object(2).name='wall';
                        %----------
                        % ask for impoly rat box
                        msgbox('Select rectangular area of the rat by click in on the image','Select Rat','modal');
                        % make constraint for the rat
                        fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                        % ask for impoly rat
                        manual_bound=fliplr(impoly(image_panel_handle,'PositionConstraintFcn',fcn));
                        % get impoly rat
                        rat_box=manual_bound.getPosition;
                        % remove impoly object
                        delete(manual_bound);
                        %----------
                        % make coordinate meshgrid to initialise components
                        % image values (i.e. dark floor, bright rat
                        [xcoord,ycoord]=meshgrid(1:fw,1:fh);
                        % inside rat box
                        inrat=inpolygon(xcoord,ycoord,rat_box(:,1),rat_box(:,2));
                        % enclouse wall only
                        inwall=inpolygon(xcoord,ycoord,wallbound(:,1),wallbound(:,2));
                        % set the range of pixel values in the wall
                        obj.wall_range=[median(double(tempimg(inwall))),mean(double(tempimg(inwall)))];
                        % set the range of pixel values in the floor
                        obj.floor_range=[median(double(tempimg(~inwall&~inrat))),mean(double(tempimg(~inwall&~inrat)))];
                        %----------
                        % get background image
                        bg_img=tempimg;
                        % make everything outside the rat box zero
                        bg_img(~inrat)=0;
                        bg_val=mean(bg_img(inrat));
                        % revert image back to floor as 0
                        bwdata=(bg_img>bg_val);
                        % find objects
                        [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                        % calculate object size
                        [objsize]=cellfun(@(x)size(x,1),bound,'UniformOutput',false);
                        objsize=cell2mat(objsize);
                        % biggest object is the rat
                        [~,objidx]=max(objsize);
                        % flip it around because the img was flipped
                        ratbound=fliplr(bound{objidx});
                        % assign rat boundary vector and name
                        obj.abstract_av.object(3).boundary{1}=ratbound;
                        obj.abstract_av.object(3).name='rat';
                        % refine the inrat coordinate to tighter bound
                        inrat=inpolygon(xcoord,ycoord,ratbound(:,1),ratbound(:,2));
                        % assign average rat pixel intensity
                        obj.rat_range=[median(double(tempimg(inrat))),mean(double(tempimg(inrat)))];
                        status=true;
                end
            case false
                % auto initialisation
                % initialise tempimage to default size
                tempimg=zeros(obj.raw_av_obj.height,obj.raw_av_obj.width,obj.raw_av_obj.FrameRate);
                switch obj.raw_av_obj.VideoFormat
                    % if video is RGB convert it to grayscale
                    case 'RGB24'
                        for framecounter=1:obj.raw_av_obj.FrameRate
                            if hasFrame(obj.raw_av_obj)
                                % if we read it fine
                                temp=readFrame(obj.raw_av_obj);
                                % RGB channel as intended
                                tempimg(:,:,framecounter)=obj.rgb2gray_ratio(1) * temp(:,:,1) + obj.rgb2gray_ratio(2) * temp(:,:,2) + obj.rgb2gray_ratio(3) * temp(:,:,3);
                            else
                                % assume maximum if empty frame
                                tempimg(:,:,framecounter)=2^8;
                            end
                        end
                    case 'Grayscale'
                        % load first second of frame of the video
                        for framecounter=1:obj.raw_av_obj.FrameRate
                            % if we read it fine
                            if hasFrame(obj.raw_av_obj)
                                temp=readFrame(obj.raw_av_obj);
                                tempimg(:,:,framecounter)=temp;
                            else % assume maximum if empty frame
                                tempimg(:,:,framecounter)=2^8;
                            end
                        end
                    otherwise
                        % unknown image format
                        message=sprintf('unknown video format\n');
                        errordlg(sprintf('%s\n',message),'analyser error','modal');
                        return;
                end
                %----------------------
                % use minimum in all frames and all channels as the background image for
                % finding floor area
                bg_img=squeeze(min(tempimg,[],3));
                % display first frame image
                image(tempimg(:,:,1),'Parent',image_panel_handle,'CDataMapping','scaled');
                % flip image so we can see bound
                view(image_panel_handle,[0 -90]);
                % erode image to smooth
                kernelsize=ceil(min(size(bg_img))*0.001);% 2% of image size is used as NHOOD
                kernel = strel('disk',kernelsize);
                bg_img=imerode(bg_img,kernel);
                % calculate mean background
                bg_val=mean(bg_img(:));
                % try to find floor area
                % turn image into binary data with black floor as 1
                bwdata=(bg_img<bg_val);
                % find objects
                [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                % calculate object size
                [objsize]=cellfun(@(x)size(x,1),bound,'UniformOutput',false);
                objsize=cell2mat(objsize);
                % biggest object is the box floor
                [~,objidx]=max(objsize);
                % get box floor boundary
                boxbound=fliplr(bound{objidx(end)});
                % get maximum extent of the floor box
                bound_idx=boundary(boxbound(:,1),boxbound(:,2));
                boxbound=fliplr(boxbound(bound_idx,:));
                % crop to floor area
                cropmax=max(boxbound,[],1);
                cropmin=min(boxbound,[],1);
                % assign crop size for processing
                obj.abstract_av.crop_min=cropmin;
                obj.abstract_av.crop_max=cropmax;
                % crop image
                tempimg=tempimg(cropmin(1):cropmax(1),cropmin(2):cropmax(2),1);
                % get image size for initial crop
                obj.abstract_av.frame_width=size(tempimg,2);
                obj.abstract_av.frame_height=size(tempimg,1);
                cla(image_panel_handle);
                % display image
                image(squeeze(tempimg),'Parent',image_panel_handle,'CDataMapping','scaled');
                fh=obj.abstract_av.frame_height;
                fw=obj.abstract_av.frame_width;
                view(image_panel_handle,[0 -90]);
                %----------------------
                % make new box bound coordinate to match cropped image
                bwdata=(tempimg<bg_val/2);
                [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                [objsize]=cellfun(@(x)size(x,1),bound,'UniformOutput',false);
                objsize=cell2mat(objsize);
                % biggest object is the box floor
                [~,objidx]=max(objsize);
                % get box floor boundary
                boxbound=fliplr(bound{objidx(end)});
                % work out corners of the floor
                [~,idx]=min(boxbound*[1 1; 1 -1; -1 -1; -1 1].');
                corner_coord=boxbound(idx,:);
                % assign floor boundary vector
                obj.abstract_av.object(1).boundary{1}=[corner_coord;corner_coord(1,:)];% need to complete the loop
                obj.abstract_av.object(1).name='floor';
                % get floor diagnol length in pixel
                diagnol_pix_dist=sqrt(sum((obj.abstract_av.object(1).boundary{1}(4,:)-obj.abstract_av.object(1).boundary{1}(2,:)).^2));
                % work out resolution
                obj.pixel_res=obj.max_floorlength/diagnol_pix_dist;
                %----------------------
                % make wall bound polygon from corner vertices
                % need inner in clockwise direction and outer in counterclockwise
                % direction for wall polygon specification
                wallbound=[[[1;1],[fw;1],[fw;fh],[1;fh]],[1;1],[nan;nan],obj.abstract_av.object(1).boundary{1}']';
                obj.abstract_av.object(2).boundary{1}=wallbound;
                obj.abstract_av.object(2).name='wall';
                %----------------------
                % make coordinate grid
                [xcoord,ycoord]=meshgrid(1:fw,1:fh);
                temp=tempimg(:,:,1);
                % get inside wall pixelx
                inwall=inpolygon(xcoord,ycoord,wallbound(1,:),wallbound(2,:));
                % calculate wall intensity
                obj.wall_range=[median(double(temp(inwall))),mean(double(temp(inwall)))];
                % try to find rat
                % use first frame of the second in case
                bg_img=squeeze(min(tempimg(:,:,1),[],3));
                bg_val=mean(bg_img(inwall));
                % revert image back to floor as 0
                bwdata=(bg_img>bg_val);
                % find objects
                [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                % calculate object size
                [objsize]=cellfun(@(x)prod(max(x)-min(x)),bound,'UniformOutput',false);
                objsize=cell2mat(objsize);
                % find rat object within the box and has certain size
                [~,objidx]=max(objsize);
                % get rat boundary
                ratbound=fliplr(bound{objidx});
                % assign rat boundary and name
                obj.abstract_av.object(3).boundary{1}=ratbound;
                obj.abstract_av.object(3).name='rat';
                % calculate refined rat pixel intensity
                inrat=inpolygon(xcoord,ycoord,ratbound(:,1),ratbound(:,2));
                obj.rat_range=[median(double(temp(inrat))),mean(double(temp(inrat)))];
                % calculate refined floor intensity
                obj.floor_range=[median(double(temp(~inwall&~inrat))),mean(double(temp(~inwall&~inrat)))];
                status=true;
        end
        %--------------------
        if status==true
            % if successfully done the boundary detection
            hold(image_panel_handle,'on');
            % plot boundaries
            plot(image_panel_handle,obj.abstract_av.object(3).boundary{1}(:,1),obj.abstract_av.object(3).boundary{1}(:,2),obj.abstract_av.object(3).colour,'LineWidth',2,'Tag','ratimg');
            plot(image_panel_handle,obj.abstract_av.object(1).boundary{1}(:,1),obj.abstract_av.object(1).boundary{1}(:,2),obj.abstract_av.object(1).colour,'LineWidth',2,'Tag','floorimg');
            hold(image_panel_handle,'off');
            % set output message if manual
            if manual
                message=sprintf('%s\nVideo initialised\n Floor boundary defined with resolution of %f m/pix\n',message,obj.pixel_res);
                msgbox(message,'Initialise Video Processing','modal');
            end
        else
            % failed to get initialisation
            message=sprintf('%sVideo initialisation failed\n',message);
            errordlg(sprintf('%s\n',message),'analyser error','modal');
        end
    end
    % audio notification
    beep;beep;
    %----------------
catch exception
    % error handling
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end