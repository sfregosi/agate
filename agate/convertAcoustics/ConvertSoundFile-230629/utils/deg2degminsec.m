function [deg,min,sec] = deg2degminsec(d)
%deg2degminsec	Convert decimal degrees into degrees, minutes, seconds
%
% [deg,min,sec] = deg2degminsec(degrees)
%    Convert decimal degrees into degrees, minutes, and seconds. Outputs 'deg'
%    and 'min' will be integers, and all three outputs will have the same sign
%    as 'degrees' (or zero). 'degrees' may be an array, in which case the
%    outputs are the same shape array.
%
% [deg,min] = deg2degminsec(degrees)
%    With only two output arguments, convert decimal degrees into degrees and
%    minutes. Output 'deg' will be an integer, and both output arguments will
%    have the same sign as 'degrees' (or zero). 'degrees' may be an array, in
%    which case the outputs are the same shape array.
%
% See also latlong2xyz.

nargoutchk(2,3);

deg = fix(d);
min = (d - deg) * 60;
if (nargout == 3)
  sec = (min - fix(min)) * 60;
  min = fix(min);
end
