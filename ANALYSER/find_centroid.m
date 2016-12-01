function [cx,cy,area]=find_centroid( boundary_vec )
% find the centroid of a closed polygon and its area
% a closed polygon must have the same last and first vertex coordinates

N=size(boundary_vec,1);
area=0.5*sum(boundary_vec(1:N-1,1).*boundary_vec(2:N,2)-(boundary_vec(2:N,1).*boundary_vec(1:N-1,2)));
cx=sum((boundary_vec(1:N-1,1)+boundary_vec(2:N,1)).*(boundary_vec(1:N-1,1).*boundary_vec(2:N,2)-(boundary_vec(2:N,1).*boundary_vec(1:N-1,2))))/(6*area);
cy=sum((boundary_vec(1:N-1,2)+boundary_vec(2:N,2)).*(boundary_vec(1:N-1,1).*boundary_vec(2:N,2)-(boundary_vec(2:N,1).*boundary_vec(1:N-1,2))))/(6*area);
end