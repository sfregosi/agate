function [hdr, data, time, stamp] = read_wispr_file_quick(name, first, last)
% READ_WISPR_FILE_QUICK	Simplified read of single raw (.dat) WISPR file
%
%   Syntax:
%       [HDR, DATA, TIME, STAMP] = READ_WISPR_FILE_QUICK(NAME, FIRST, LAST)
%
%   Description:
%       Wrapper for EOS/wispr3 read_wispr_file.m that will prompt to select
%       a single file if one is not specified. See READ_WISPR_FILE_AGATE
%       for more detail on the format of a WISPR raw file. 
%
%   Inputs:
%       name    [string] fullpath filename to raw .dat file
%       first   [integer] buffer to start reading at. Set to 0 to just
%               read the header. Set to 1 to start at the beginning.
%       last    [integer] buffer to read to. Set to 0 to read the entire
%               file
%
%   Outputs:
%       hdr     [struct] header information
%       data    [double] sound data, matrix of size
%               [samples_per_buffer, (last-first)]
%       time    [double] count of time from 0, matrix of size
%               [samples_per_buffer, (last-first)]
%       stamp   [double] time in linux epoch time
%
%   Examples:
%
%   See also READ_WISPR_FILE, READ_WISPR_FILE_AGATE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2025 April 08
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check arguments
if nargin == 0
    [name, path] = uigetfile('*.dat', 'Select raw WISPR sound file');
    first = 1; % start at beginning of file
    last = 0; % read whole file
end

if nargin == 3 && isempty(name)
    [name, path] = uigetfile('*.dat', 'Select raw WISPR sound file');
end

% read in file
[hdr, data, time, stamp, ~] = read_wispr_file_agate(fullfile(path, name), ...
    first, last);

end