function [ status ] = initial_process( obj, image_panel_handle, manual )
%INITIAL_PROCESS manual select floor, box and animal for initialisation
%

%% function complete
status=false;message='';
try
    if isempty(obj.raw_av_obj)
        message=sprintf('You need to load video file first\n');
    else
        % move to the start of the video
        obj.raw_av_obj.CurrentTime = 0;
        % work out frame number
        obj.abstract_av.frame_num=ceil(obj.raw_av_obj.FrameRate*obj.raw_av_obj.Duration);
        obj.abstract_av.object(1).boundary=cell(obj.abstract_av.frame_num,1);
        obj.abstract_av.object(2).boundary=cell(obj.abstract_av.frame_num,1);
        obj.abstract_av.object(3).boundary=cell(obj.abstract_av.frame_num,1);
        obj.abstract_av.object(3).position=zeros(obj.abstract_av.frame_num,2);
        obj.abstract_av.time=linspace(0,obj.raw_av_obj.Duration,obj.abstract_av.frame_num);
        fh=obj.raw_av_obj.height;
        fw=obj.raw_av_obj.width;
        % output this to the image handle, create new figure if not specified
        if isempty(image_panel_handle)
            figure(2357);
            image_panel_handle=gca;
        end
        % set colorscale as gray for output image
        colormap(image_panel_handle,'gray');
        switch manual
            case true
                % semi manual initialisation
                switch obj.raw_av_obj.VideoFormat
                    case 'RGB24'
                        % load the first frame of video footage
                        temp = zeros(obj.raw_av_obj.height,obj.raw_av_obj.width,3);
                    case 'Indexed'
                        
                    case 'Grayscale'
                        temp = zeros(obj.raw_av_obj.height,obj.raw_av_obj.width,1);
                    otherwise
                        
                end
                if hasFrame(obj.raw_av_obj) % if we read it fine
                    temp=readFrame(obj.raw_av_obj); % 1st dim is height/2nd dim is width
                    %temp=0.2989 * temp(:,:,1) - 0.1140 * temp(:,:,3);
                    temp=0.2989 * temp(:,:,1) + 0.5870 * temp(:,:,2) + 0.1140 * temp(:,:,3);% RGB channel as intended
                else
                    message=sprintf('unable to read frame\n');
                end
                cla(image_panel_handle,'reset');
                % display image
                image(temp,'Parent',image_panel_handle,'CDataMapping','scaled');
                msgbox('Select box area by click in on the image','Select Box','modal');
                % ask for impoly box
                % make constrain function to the plot area
                fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                manual_bound=impoly(image_panel_handle,'PositionConstraintFcn',fcn);
                box_bound=fliplr(manual_bound.getPosition);
                delete(manual_bound);
                obj.abstract_av.crop_min=ceil(min(box_bound));
                obj.abstract_av.crop_max=floor(max(box_bound));
                temp=temp(obj.abstract_av.crop_min(1):obj.abstract_av.crop_max(1),obj.abstract_av.crop_min(2):obj.abstract_av.crop_max(2),:);
                obj.abstract_av.frame_width=obj.abstract_av.crop_max(2)-obj.abstract_av.crop_min(2)+1;
                obj.abstract_av.frame_height=obj.abstract_av.crop_max(1)-obj.abstract_av.crop_min(1)+1;
                cla(image_panel_handle);
                % display image
                image(temp,'Parent',image_panel_handle,'CDataMapping','scaled');
                fh=obj.abstract_av.frame_height;
                fw=obj.abstract_av.frame_width;
                view(image_panel_handle,[0 -90]);
                msgbox('Select box floor area by click in on the image','Select Floor','modal');
                % ask for impoly box
                fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                manual_bound=impoly(image_panel_handle,'PositionConstraintFcn',fcn);
                floor_bound=manual_bound.getPosition;
                % assign floor boundary vector
                obj.abstract_av.object(1).boundary{1}=[floor_bound;floor_bound(1,:)];% need to complete the loop
                obj.abstract_av.object(1).name='floor';
                delete(manual_bound);
                % work out corners of the floor
                [val,idx]=min(obj.abstract_av.object(1).boundary{1}*[1 1; -1 -1; 1 -1; -1 1].');
                [~,corner_idx]=sort(val);
                % get floor diagnol length in pixel
                diagnol_pix_dist=sqrt(sum((obj.abstract_av.object(1).boundary{1}(idx(corner_idx(4)),:)-obj.abstract_av.object(1).boundary{1}(idx(corner_idx(1)),:)).^2));
                % work out resolution
                obj.pixel_res=obj.max_floorlength/diagnol_pix_dist;
                % make wall bound polygon from corner vertices
                % need inner in clockwise direction and outer in counterclockwise
                % direction for wall polygon specification
                corner_idx=([corner_idx(4),corner_idx(3),corner_idx(1),corner_idx(2),corner_idx(4)]);%inner square cw
                wallbound=[[[1;1],[fw;1],[fw;fh],[1;fh]],[1;1],[nan;nan],obj.abstract_av.object(1).boundary{1}(idx(corner_idx),:)']';
                obj.abstract_av.object(2).boundary{1}=wallbound;
                obj.abstract_av.object(2).name='wall';
                % ask for impoly rat box
                msgbox('Select rectangular area of the rat by click in on the image','Select Rat','modal');
                % ask for impoly box
                fcn = makeConstrainToRectFcn('impoly',get(image_panel_handle,'XLim'),get(image_panel_handle,'YLim'));
                manual_bound=fliplr(impoly(image_panel_handle,'PositionConstraintFcn',fcn));
                rat_box=manual_bound.getPosition;
                delete(manual_bound);
                [xcoord,ycoord]=meshgrid(1:fw,1:fh);
                inbox=inpolygon(xcoord,ycoord,rat_box(:,1),rat_box(:,2));
                inwall=inpolygon(xcoord,ycoord,wallbound(:,1),wallbound(:,2));
                obj.wall_range=[median(double(temp(inwall))),mean(double(temp(inwall)))];
                obj.floor_range=[median(double(temp(~inwall&~inbox))),mean(double(temp(~inwall&~inbox)))];
                bg_img=temp;
                bg_img(~inbox)=0;
                bg_val=(mean(bg_img(inbox)));
                % revert image back to floor as 0
                bwdata=(bg_img>bg_val);
                % find objects
                [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                % calculate object size
                [objsize]=cellfun(@(x)size(x,1),bound,'UniformOutput',false);
                objsize=cell2mat(objsize);
                % biggest object is the box floor
                [~,objidx]=max(objsize);
                ratbound=fliplr(bound{objidx});
                obj.abstract_av.object(3).boundary{1}=ratbound;
                inrat=inpolygon(xcoord,ycoord,ratbound(:,1),ratbound(:,2));
                obj.rat_range=[median(double(temp(inrat))),mean(double(temp(inrat)))];
                obj.abstract_av.object(3).name='rat';
                status=true;
            case false
                % auto initialisation
                switch obj.raw_av_obj.VideoFormat
                    case 'RGB24'
                        % assume at least one second of video footage
                        temp = zeros(obj.raw_av_obj.height,obj.raw_av_obj.width,3,obj.raw_av_obj.FrameRate);
                    case 'Indexed'
                        
                    case 'Grayscale'
                        temp = zeros(obj.raw_av_obj.height,obj.raw_av_obj.width,1,obj.raw_av_obj.FrameRate);
                    otherwise
                        
                end
                % load first second of the video
                for framecounter=1:size(temp,4)
                    if hasFrame(obj.raw_av_obj) % if we read it fine
                        temp(:,:,:,framecounter)=readFrame(obj.raw_av_obj);
                    else
                        temp(:,:,:,framecounter)=2^16; % assume maximum if empty frame
                    end
                end
                
                % get image size for initial crop
                min_img_size=min(size(temp(:,:,1,1)));
                obj.abstract_av.frame_width=min_img_size;
                obj.abstract_av.frame_height=min_img_size;
                % crop to square of smaller dimension
                temp=temp(1:min_img_size,1:min_img_size,:,:);
                % use minimum in all frames and all channels as the background image for
                % finding floor area
                bg_img=squeeze(mean(min(temp(:,:,:,:),[],4),3));
                image(bg_img,'Parent',image_panel_handle,'CDataMapping','scaled');
                view(image_panel_handle,[0 -90]);
                % erode image to smooth
                kernelsize=ceil(min(size(bg_img))*0.01);% 2% of image size is used as NHOOD
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
                boxbound=bound{objidx(end)};
                % get maximum extent of the floor box
                bound_idx=boundary(boxbound(:,1),boxbound(:,2));
                boxbound=fliplr(boxbound(bound_idx,:));
                % assign floor boundary vector
                obj.abstract_av.object(1).boundary{1}=[boxbound;boxbound(1,:)];% need to complete the loop
                obj.abstract_av.object(1).name='floor';
                % work out corners of the floor
                [val,idx]=min(obj.abstract_av.object(1).boundary{1}*[1 1; -1 -1; 1 -1; -1 1].');
                [~,corner_idx]=sort(val);
                % get floor diagnol length in pixel
                diagnol_pix_dist=sqrt(sum((obj.abstract_av.object(1).boundary{1}(idx(corner_idx(4)),:)-obj.abstract_av.object(1).boundary{1}(idx(corner_idx(1)),:)).^2));
                % work out resolution
                obj.pixel_res=obj.max_floorlength/diagnol_pix_dist;
                % make wall bound polygon from corner vertices
                % need inner in clockwise direction and outer in counterclockwise
                % direction for wall polygon specification
                corner_idx=[corner_idx(4),corner_idx(2),corner_idx(1),corner_idx(3),corner_idx(4)];%inner square cw
                wallbound=[[[1;1],[min_img_size;1],[min_img_size;min_img_size],[1;min_img_size]],[1;1],[nan;nan],obj.abstract_av.object(1).boundary{1}(idx(corner_idx),:)'];
                obj.abstract_av.object(2).boundary{1}=wallbound';
                obj.abstract_av.object(2).name='wall';
                [ycoord,xcoord]=meshgrid(1:min_img_size,1:min_img_size);
                inwall=inpolygon(xcoord,ycoord,wallbound(1,:),wallbound(2,:));
                % try to find rat
                % use last frame of the second in case
                bg_img=squeeze(min(temp(:,:,:,15),[],3));
                bg_val=mean(bg_img(inwall));
                obj.wall_range=[median(bg_img(inwall)),mean(bg_img(inwall))];
                % revert image back to floor as 0
                bwdata=(bg_img>bg_val);
                % find objects
                [bound,~,~,~]= bwboundaries(bwdata,8,'noholes');
                % calculate object size
                [objsize]=cellfun(@(x)prod(max(x)-min(x)),bound,'UniformOutput',false);
                objsize=cell2mat(objsize);
                % find rat object within the box and has certain size
                ratidx=find(objsize<(min_img_size^2/(5*10))&objsize>(min_img_size^2/(3*5*10)));
                % get rat boundary
                ratbound=bound{ratidx};
                obj.abstract_av.object(3).boundary{1}=fliplr(ratbound);
                obj.abstract_av.object(3).name='rat';
                inrat=inpolygon(xcoord,ycoord,ratbound(:,1),ratbound(:,2));
                obj.rat_range=[median(bg_img(inrat)),mean(bg_img(inrat))];
                obj.floor_range=[median(bg_img(~inwall&~inrat)),mean(bg_img(~inwall&~inrat))];
                status=true;
        end
        if status==true
            message=sprintf('Video initialised\n Floor boundary defined with resolution of %f m/pix\n',obj.pixel_res);
        else
            message=sprintf('%sVideo initialisation failed\n',message);
        end
    end
    msgbox(message,'Initialise Video Processing','modal');
    beep;beep;
catch exception
    message=[exception.message,data2clip(exception.stack)];
    errordlg(sprintf('%s\n',message),'analyser error','modal');
end
end