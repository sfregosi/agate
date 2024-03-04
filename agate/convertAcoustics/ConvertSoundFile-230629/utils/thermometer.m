function thermo = thermometer(x0, x1, varargin)
%THERMOMETER	Print dots as an indication of the progress of a computation.
%
% therm = thermometer(maxval [,ndots [, displayText, args...]])
%    Initialize a thermometer (see below).  ndots, the number of dots to 
%    display on the line, defaults to 70.  The return value is a handle to 
%    pass in subsequent calls.
%
% therm = thermometer(therm, val)
%    Print dots on matlab's typeout screen to indicate that (val/maxval) of
%    the computation is finished.  val should count up starting at (or near)
%    0.  When val >= maxval, a newline is printed.  As a special case, if
%    the (input) value of therm is NaN or [], this function returns 
%    without doing anything at all.
%    =>> Don't forget the "therm =" part of this statement! <<=
%
% -----------------------------------------------------------------------------
%
% Note!  Only one thermometer should be running at a time, since 
% starting up a new one will mess any old one.
%
% Also note!  Don't disp (or printf) anything while a thermometer is running, 
% since of course the display will be corrupted.

% thermo is [ndots maxval prevval]

if (isempty(x0) || any(isnan(x0)))
  thermo = x0;
  return
end

if (numel(x0) == 1)
  % Start a new thermometer.
  if (nargin < 2 || isempty(x1)) x1 = 70; end

  thermo(1) = x1;			% ndots
  thermo(2) = x0;			% maximum value
  thermo(3) = 0;			% previous value

  % Print user text, if any.
  if (~isempty(varargin))
    str = sprintf(varargin{:});
    printf('%-*s|', x1-1, str);
  end
  
else
  thermo = x0;
  if (x1 > thermo(3) && ~isnan(thermo(2)))
    r1 = round(min(       x1 / thermo(2), 1)* thermo(1)); % total dots to show
    r2 = round(min(thermo(3) / thermo(2), 1)* thermo(1)); % dots already shown
    for i = r2 : r1-1
      fprintf(1, '.');
    end
    if (x1 >= thermo(2))
      fprintf('\n');
      thermo(2) = NaN;
    end
    
    thermo(3) = x1;
  end
end
