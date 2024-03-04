function x = secPerDay
%secPerDay	Return the number of seconds in a (normal) day, namely 24*60*60
%
% Note: Occasionally a day in the year (usually Jun. 30 or Dec. 31) has a leap
% second added and is one second longer. This function ignores that possibility.

x = 86400;		% this is 24*60*60
