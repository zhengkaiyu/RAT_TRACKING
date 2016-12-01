function [ status ] = op_shapetrack( ratwalk_h, panel_h )
%OP_SHAPETRACK use kmean cluster analysis to keep track of head, tail and
%body twist and heading
ratbound=ratwalk_h.abstract_av.object(3).boundary;

floorbound=ratwalk_h.abstract_av.object(1).boundary{1};
% offset rat centroid by the floor center
[fx,fy,~]=find_centroid(floorbound);
ratpos=bsxfun(@plus,ratwalk_h.abstract_av.object(3).position,[fx,fy]);
fw=ratwalk_h.abstract_av.frame_width;
fh=ratwalk_h.abstract_av.frame_height;
[xcoord,ycoord]=meshgrid(1:fw,1:fh);
partnum=3;colourcycle='rgbykw';
perm_vec=(perms(1:1:partnum));
perm_vec=repmat(perm_vec,1,3);
startframe=200;
for fc=startframe:numel(ratbound)
    rat=[];
    %rat=ratbound{fc};
    [rat(:,1),rat(:,2)]=reducem(ratbound{fc}(:,1),ratbound{fc}(:,2));
    inrat=inpolygon(xcoord,ycoord,rat(:,1),rat(:,2));
    
    skel_data=bwmorph(inrat,'thin',inf);
    %skel_data=bwmorph(skel_data,'spur',5);
    centre_data=bwmorph(skel_data,'shrink',inf);
    
    end_data=bwmorph(skel_data,'endpoints');
    
    [xc,yc]=find(skel_data);
    [skelxc,skelyc]=find(centre_data);
    [endxc,endyc]=find(end_data);
    
    skel=[yc,xc];
    skel_center=[skelyc,skelxc];
    skel_center_ref=find(skel(:,1)==skel_center(1)&skel(:,2)==skel_center(2));
    endpt=[endyc,endxc];
    
    
    %{
    % find distance to the nearest skeleton point
    skel_dist=min(sqrt((bsxfun(@minus,rat(:,1),yc')).^2+(bsxfun(@minus,rat(:,2),xc')).^2),[],1)';
    centroid_dist=sqrt(sum(bsxfun(@minus,skel,skel_center).^2,2));
    %[idx,C,sD]=kmeans([[yc,xc],skel_dist,centroid_dist],partnum,'Distance','cityblock','Replicates',3,'Start','plus');
    [idx,C,sD]=kmedoids([[yc,xc],skel_dist,centroid_dist],partnum,'Algorithm','pam','Distance','cityblock','Replicates',2,'Start','plus');
    %}
    [skel_dist,skel_ref]=min(sqrt((bsxfun(@minus,rat(:,1),yc')).^2+(bsxfun(@minus,rat(:,2),xc')).^2),[],2);
    %centroid_dist=skel_dist+sqrt(sum(bsxfun(@minus,skel(skel_ref,:),skel_center).^2,2));% need to work out proper curved length
    centroid_dist=skel_dist+abs(skel_ref-skel_center_ref);% need to work out proper curved length
    [idx,C,sD]=kmeans([rat,skel_dist,centroid_dist],partnum,'Distance','sqeuclidean','Start','uniform');
    %[idx,C,sD]=kmedoids([rat,skel_dist,centroid_dist],partnum,'Algorithm','pam','Distance','sqeuclidean','Replicates',2,'Start','cluster');
    
    if fc==startframe
        % initialisae
        [val,expartidx]=sortrows(C(:,4),-1);
        [~,htorder]=sortrows(C(expartidx(1:2),3),1);
        tailidx=expartidx(htorder(1));
        headidx=expartidx(htorder(2));
        
        %[~,chorder]=sortrows(C(expartidx(3),3),1);
        %chestidx=expartidx(htorder(1)+2);
        chestidx=expartidx(end);
        %hipidx=expartidx(htorder(2)+2);
        partidx=[headidx,chestidx,tailidx];
        
        headc=[C(headidx,1),C(headidx,2)];
        tailc=[C(tailidx,1),C(tailidx,2)];
        chestc=[C(tailidx,1),C(chestidx,2)];
        %hipc=[C(hipidx,1),C(hipidx,2)];
        oldc=C([headidx,chestidx,tailidx],:);
    else
        currentc=C;
        % compare with old centre by minimise trace sum of eigenvalues
        sqMdist=sqrt((bsxfun(@minus,currentc(:,1),oldc(:,1)')).^2+(bsxfun(@minus,currentc(:,2),oldc(:,2)')).^2);
        sqMquant1=(abs(bsxfun(@minus,currentc(:,3),oldc(:,3)')));%skel dist
        sqMquant2=(abs(bsxfun(@minus,currentc(:,4),oldc(:,4)')));%centroid dist
        sqM=[[sqMdist,zeros(3,6)];[zeros(3,3),sqMquant1.^2,zeros(3,3)];[zeros(3,6),sqMquant2.^2]]';
        [~,perm_order]=min(cellfun(@(x)mean(eig(x)),mat2cell(sqM(:,perm_vec'),3*partnum,3*partnum*ones(size(perm_vec,1),1))));
        
        partidx=perm_vec(perm_order,:);
        oldc(:,[1,2])=currentc(partidx(1:3),[1,2]);% only update coordinate matrix not quantifier matrix
    end
    
    if fc==startframe
        figure(1);
        skel_img=image(skel_data*150);
        hold(gca,'on');
        skelcenter=plot(skel_center(1),skel_center(2),'Marker','o','MarkerSize',10,'MarkerFaceColor','w');
        head=scatter(rat(idx==partidx(1),1),rat(idx==partidx(1),2),'Marker','.','MarkerEdgeColor','r');
        headcenter=plot(C(partidx(1),1),C(partidx(1),2),'Marker','o','MarkerEdgeColor','k','MarkerSize',10,'MarkerFaceColor','r');
        
        chest=scatter(rat(idx==partidx(2),1),rat(idx==partidx(2),2),'Marker','.','MarkerEdgeColor','c');
        chestcenter=plot(C(partidx(2),1),C(partidx(2),2),'Marker','o','MarkerEdgeColor','k','MarkerSize',10,'MarkerFaceColor','c');
        
        %hip=scatter(rat(idx==partidx(3),1),rat(idx==partidx(3),2),'Marker','.','MarkerEdgeColor','k');
        %hipcenter=plot(C(partidx(3),1),C(partidx(3),2),'Marker','o','MarkerEdgeColor','k','MarkerSize',10,'MarkerFaceColor','k');
        
        tail=scatter(rat(idx==partidx(3),1),rat(idx==partidx(3),2),'Marker','.','MarkerEdgeColor','y');
        tailcenter=plot(C(partidx(3),1),C(partidx(3),2),'Marker','o','MarkerEdgeColor','k','MarkerSize',10,'MarkerFaceColor','y');
    else
        set(skel_img,'CData',skel_data*150);
        set(skelcenter,'XData',skel_center(1),'YData',skel_center(2));
        set(head,'XData',rat(idx==partidx(1),1),'YData',rat(idx==partidx(1),2));
        set(headcenter,'XData',C(partidx(1),1),'YData',C(partidx(1),2));
        set(chest,'XData',rat(idx==partidx(2),1),'YData',rat(idx==partidx(2),2));
        set(chestcenter,'XData',C(partidx(2),1),'YData',C(partidx(2),2));
        set(tail,'XData',rat(idx==partidx(3),1),'YData',rat(idx==partidx(3),2));
        set(tailcenter,'XData',C(partidx(3),1),'YData',C(partidx(3),2));
    end
    %ratoutline=plot(rat(:,1),rat(:,2),'y-','LineWidth',2);
    
    
    
    %{
    % find the centre of the skeleton
    % find distance to the nearest skeleton point
    skel_dist=min(sqrt((bsxfun(@minus,rat(:,1),endyc')).^2+(bsxfun(@minus,rat(:,2),endxc')).^2),[],1)';
    centroid_dist=sqrt(sum(bsxfun(@minus,endpt,skel_center).^2,2));
    [idx,C,sD]=kmeans([[endyc,endxc],skel_dist,centroid_dist],partnum);
    %[idx,C,sD]=kmedoids([[endyc,endxc],skel_dist,centroid_dist],partnum,'Algorithm','pam','Distance','sqeuclidean','Replicates',2,'Start','plus');
    
    sortq=C(:,3)./C(:,4);
    [~,sDidx]=sort(sortq);
    % waist
    %[~,waistidx]=min(C(:,4));
    % extremety, tail,leg
    [~,dsort]=sort(sortq);
    tailidx=dsort(1);
    %[~,tailidx]=min(C(dsort(1:3),4));
    %tail
    %tailidx=dsort(tailidx);
    %head
    dsort=dsort(dsort~=tailidx);
    [~,headidx]=max(C(dsort,4));
    headidx=dsort(headidx);
    
    
    
    
    partsortidx(1)=tailidx;%tail smallest skeldist/largest centroiddist
    %partsortidx(2)=waistidx;%waist largest skeldisk/smallest centroiddist
    partsortidx(2)=headidx;
    
    figure(1);clf;
    image(skel_data*50);
    hold(gca,'on');
    plot(rat(:,1),rat(:,2),'c');
    
    for partid=1:numel(partsortidx)
        plot(C(partsortidx(partid),1),C(partsortidx(partid),2),'o','MarkerFaceColor',colourcycle(partid),'MarkerSize',30);
    end
    %}
    
    %axis([min(rat(:,1)),max(rat(:,1)),min(rat(:,2)),max(rat(:,2))]);
    %hold(gca,'off');
    pause(0.001);
end
end