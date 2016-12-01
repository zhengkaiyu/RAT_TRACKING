function tortuosity = tortuosity( boundary_vec )
%TORTUOSITY Summary of this function goes here
%   Detailed explanation goes here

perimeter=sum(sqrt(sum(diff(boundary_vec,1).^2,2)));
N=size(boundary_vec,1);
area=0.5*sum(boundary_vec(1:N-1,1).*boundary_vec(2:N,2)-(boundary_vec(2:N,1).*boundary_vec(1:N-1,2)));
tortuosity=perimeter./sqrt(area);
end