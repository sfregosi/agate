function [decdeg] = degmin2decdeg(degmin)
%DEGMIN2DECDEG	Convert degree minutes to decimal degrees
%
%   Syntax:
%       decdeg = DEGMIN2DECDEG(degmin)
%
%   Description:
%       Utility to convert latitude and longitude coordinates from degrees 
%       minutes to decimal degreees
%
%   Inputs:
%       degmin  N-by-2 matrix of coordinates in degree minutes
%
%   Outputs:
%       decdeg  N-by-1 vector of coordinates in decimal degrees 
%
%   Examples:
%       degmin = [30 29.2020;-118 58.9980];
%       decdeg = degmin2decdeg(degmin)
%       decdeg =
%                    30.4867
%                   -118.9833
%
%   See also DECDEG2DEGMIN, DECDEG2DEGMINSEC, DEGMINSEC2DECDEG
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   24 July 2016
%   Updated:        12 May 2023
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decdeg=zeros(length(degmin(:,1)),1);

for f=1:length(degmin(:,1))
    dec=degmin(f,2)/60;
    deg=degmin(f,1);
    if deg>0
        decdeg(f,1)=deg+dec;
    else
        decdeg(f,1)=deg-dec;
    end
end
