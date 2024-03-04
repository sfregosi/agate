function [j,d,y] = julian(month, day, year, baseYear)
%JULIAN         Convert to and from month/day and day-of-the-year.
%
% Converting month/day to year day:
%   yday = julian(month, day)
%   Convert a month and day into a year day (day of the year).
%   The year is assumed to be a non-leap year.  Month and day may be
%   vectors, in which case they should be the same length; the result is
%   a row vector.
%  
%   yday = julian(month, day, year)
%   As above, but a year number is allowed to provide for the possibility of
%   a leap year.  Thinks (incorrectly) that 1900, 1800, etc. were leap years.
%   Does not handle the 1582/1752 gap correctly.
%  
%   yday = julian(month, day, year, baseyear)
%   As above, but computes the number of days since January 0 of the base year.
%   Again, does not handle 1900, 1800, 1752, etc. correctly.
%
% Converting year day to month/day:
%   [month,day] = julian(yday)
%   Convert a day of the year (yday) to month/day.  Assumes it's
%   not a leap year.  yday may be a vector.
%
%   [month,day,year] = julian(yday, baseyear)
%   As above, but allows you to specify a base year.  yday is assumed to
%   be the number of days since Jan 0 of that year.  Returns the date in
%   month/day/year format.  yday and baseyear may be vectors, in which case
%   they should be the same length.
%
%
% Note: The term "Julian Day" for referring to the day of the year
%       is apparently incorrect.  The Julian Day is the number of days
%       since noon (yes, noon) on 1 January 4713 B.C.  (For example,
%       JD 2447770.5 is the beginning of 1 September 1989.)  A better 
%       term for day of the year is "year day"; this is now used in the,
%       comments above, but the name julian.m has not been changed.

monthLength = [31 28 31 30 31 30 31 31 30 31 30 31].';
month = month(:);
if (nargin > 1), day = day(:); end

if (nargout <= 1)
  if (nargin < 3)
    year = 1993;		% any non-leap year will do
  end
  year  =  year(:);

  if (nargin < 4)
    baseYear = year;
  end
  
  % Compute number of days between Jan 1 of this year and Jan 1 of base year.
  j1 = (year     - 1992) * 365 + floor((year     - 1993) / 4) + 1;
  j2 = (baseYear - 1992) * 365 + floor((baseYear - 1993) / 4) + 1;
  
  % Add number of days in this year.
  if (rem(year, 4) == 0)
    monthLength(2) = monthLength(2) + 1;			% leap day
  end
  
  firstday = cumsum([1; monthLength]);
  j = j1 - j2 + firstday(month) - 1 + day;

else
  % Rename args correctly.
  yday = month;
  if (nargin < 2), day = 1; end
  baseyear = day;
  
  % Deal with 4-year blocks.
  x = floor((yday-1) / (365*4 + 1));
  yday = yday - x * (365*4 + 1);
  year = baseyear + x*4;
  
  % Count forward as many years as possible (possibly as many as 3).
  x = 1;
  while (any(x))
    nd = 365 + (rem(year,4) == 0);	% number of days in that year
    x = (nd < yday);			% count one more year?
    yday = yday - x.*nd;
    year = year + x;
  end
  
  % Compute month and day.  This code should be vectorized.
  month = zeros(size(yday));
  day   = zeros(size(yday));
  for i = 1:prod(size(yday))
    ml = monthLength;
    ml(2) = ml(2) + (rem(year(i),4) == 0);
    month(i) = sum(yday(i) > cumsum(ml)) + 1;
    day(i) = yday(i) - sum(ml(1:month(i)-1));
  end

  % Rename args for output.
  j = month;
  d = day;
  y = year;
end
