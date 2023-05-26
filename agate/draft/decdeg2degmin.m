function [degmin] = decdeg2degmin(decdeg)
% Convert decimal degrees to degree minutes
%
% Inputs:
%       decdeg should be N-by-1 vector of coordinates in decimal degrees,
%       i.e. decdeg=[30.4867; -118.9833];
% Output: 
%       degmin will be N-by-2 matrix of coordinates in degrees minutes,
%       i.e. degmin =
%               30.0000   29.2020
%               -118.0000   58.9980
%
% Inverse function is degmin2decdeg(degmin)
%
% Created 7/24/2016 by S. Fregosi

degmin=zeros(length(decdeg),1);

for f=1:length(decdeg)
    deg=fix(decdeg(f));
    dec=abs(rem(decdeg(f),1));
    min=dec*60;
    degmin(f,1:2)=[deg min];
end


