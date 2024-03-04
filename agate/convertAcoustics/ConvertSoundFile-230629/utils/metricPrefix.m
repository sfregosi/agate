function [value,prefix,div] = metricPrefix(value, cutoff)
%metricPrefix		Choose an appropriate unit prefix.
%
% [newvalue,prefix,div] = metricPrefix(value)
%    Choose an appropriate unit prefix for value, and scale value so that it
%    is expressed in the associated units.  For example, if the value is
%    40100, then the prefix is 'k' and the new value is 40.1.  This is useful
%    for plotting graphs.  The return value div is the amount that value was
%    divided by to get newvalue.
%
%    The prefixes are from "Guide for metric practice", 
%    Physics Today 49(8), part 2, p. 15-16.
%
%    Is value is an array, its maximum element is used to choose the prefix.
%
% [newvalue,prefix] = metricPrefix(value, cutoff)
%    Normally any value between 2 and 2000 will have no prefix, 2000 to 2000000
%    will have prefix 'k', .002 to 2 will have prefix 'm', etc.  The '2' in
%    each of these numbers is the cutoff.  You can choose any cutoff you like;
%    the default is 2, which you also get if you pass in NaN for the cutoff.

if (nargin < 2 || isnan(cutoff))
  cutoff = 2;
end

prefixes = [
    'y'		% yocto  10^-24
    'z'		% zepto  10^-21
    'a'		% atto   10^-18
    'f'		% femto  10^-15
    'p'		% pico   10^-12
    'n'		% nano   10^-9
    'u'		% micro  10^-6         mu is correct, not u
    'm'		% milli  10^-3
    ' '		%        10^0
    'k'		% kilo   10^3          why don't they capitalize this?
    'M'		% mega   10^6
    'G'		% giga   10^9
    'T'		% tera   10^12
    'P'		% peta   10^15
    'E'		% exa    10^18
    'Z'		% zetta  10^21
    'Y'		% yotta  10^24
    ];

zeropoint = find(prefixes == ' ');		% where 10^0 is in the list

index = floor(log10(max(max(value)) / cutoff) / 3) + zeropoint;
index = min(max(index,1), length(prefixes));	% don't fall off end of prefixes
prefix = deblank(prefixes(index));
div = 10^(3 * (index - zeropoint));
value = value / div;
