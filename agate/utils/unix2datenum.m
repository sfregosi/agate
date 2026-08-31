function tm = unix2datenum(tu)
%UNIX2MATLAB	Converts unix time to matlab datenum
%
%   Syntax:
%	    TM = UNIX2MATLAB(TU)
%
%   Description:
%	    Converts unix time (epoch time, seconds since 1 Jan 1970) to MATLAB
%       datenum (which is days from 1 Jan 0000)
%	    Built based on this Stack Overflow answer: 
%       https://stackoverflow.com/a/12663377/1890309
%
%   Inputs:
%       tu   [double] unix epoch time in seconds
%
%   Outputs:
%       tm   [double] MATLAB datenum
%
%   Examples:
%       tu = 1737731000;
%       tm = unix2datenum(tu);
%       datestr(tm)
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    Updated:      2026 August 30
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


tm = datenum('1970', 'yyyy') + tu / 86400;

end

