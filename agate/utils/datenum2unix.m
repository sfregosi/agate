function tu = datenum2unix(tm)
% DATENUM2UNIX	Converts MATLAB datenum to unix time
%
%   Syntax:
%       TU = DATENUM2UNIX(TM)
%
%   Description:
%	    Converts MATLAB datenum (days from 1 Jan 0000) to unix time
%       (epoch time, seconds since 1 Jan 1970). Inverse of UNIX2MATLAB.
%
%   Inputs:
%       tm   [double] MATLAB datenum
%
%   Outputs:
%       tu   [double] unix epoch time in seconds
%
%   Examples:
%       tm = datenum(2025, 1, 24, 12, 0, 0);
%       tu = datenum2unix(tm);
%       disp(tu)
%
%   See also UNIX2DATENUM
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   31 August 2026
%
%   Created with MATLAB ver.: 24.2.0.3212159 (R2024b) Update 9
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tu = (tm - datenum('1970', 'yyyy')) * 86400;
end