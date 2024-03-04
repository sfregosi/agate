function [x,y,z,t] = matlabver
%matlabver    Return the version number(s) of Matlab as integer(s).
%
% x = matlabver
%   Return the major version number of the Matlab that is running, as
%   an integer.  As of this writing, the latest version number is 6.
%
% [x,y,z,t] = matlabver
%   You can also get the rest of the version numbers -- the minor version
%   number, release number, and sequence number (or whatever it's called).
%   
%
% See also version, ver.

a = sscanf(version, '%d.');

x = a(1);
y = a(2);
z = a(3);
t = a(4);
