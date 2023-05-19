function [decdeg] = degminsec2decdeg(degminsec)
%DEGMINSEC2DECDEG	Convert degree minutes seconds to decimal degrees
%
%   Syntax:
%       decdeg = DEGMINSEC2DECDEG(degminsec)
%
%   Description:
%       Utility to convert latitude and longitude coordinates from degrees 
%		minutes seconds to decimal degrees
%
%   Inputs:
%       degminsec   N-by-3 matrix of coordinates in degrees minutes seconds
%                   with degrees in the first column and minutes in the 
%                   second column, and seconds in the third column
%
%   Outputs:
%       decdeg      N-by-1 vector of coordinates in decimal degrees 
%
%   Examples: 
%       degminsec = [30 29 12; -118 58 59];
%       decdeg = degminsec2decdeg(degminsec)
%       decdeg =
%                 30.4867
%                -118.9831
%
%   See also DECDEG2DEGMINSEC, DECDEG2DEGMIN, DEGMIN2DECDEG
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   10 September 2021
%   Updated:        12 May 2023
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decdeg = zeros(length(degminsec(:,1)), 1);

for f = 1:length(degminsec(:,1))
    secDec = degminsec(f,3)/60;
    minDec = (degminsec(f,2) + secDec)/60;
    deg = degminsec(f,1);
    if deg > 0
        decdeg(f,1) = deg + minDec;
    else
        decdeg(f,1) = deg - minDec;
    end
end
