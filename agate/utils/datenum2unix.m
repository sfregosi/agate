function tu = datenum2unix(tm)
% DATENUM2UNIX	Convert from MATLAB datenum to Unix time (in seconds)
%
%   Syntax:
%       TU = DATENUM2UNIX(TM)
%
%   Description:
%       Conversion between MATLAB datenum to Unix time, in seconds
%
%   Inputs:
%       tm    [double] time as MATLAB datenum (serial days from 1/1/0000)
%
%	Outputs:
%       tu    [double] unix time in seconds from 1/1/1970 00:00:00 
%
%   Examples:
%       tm = 739737; % 30 April 2025
%       tu = datenum2unix(tm);
%
%   See also UNIX2DATENUM
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2026 August 30
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tu = round(86400*(tm - datenum('1970', 'yyyy')));
end