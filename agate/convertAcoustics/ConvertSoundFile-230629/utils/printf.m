function printf(fmt, varargin)
%PRINTF		print formatted output in the command window
%
% printf(format, args...)
%    This is simply disp(sprintf(format, args...)), except that there is
%    always a newline, even with a format string that is empty or missing.
%
% See also sprintf, mprintf, disp, num2str, error.

if (nargin < 1 || isempty(fmt))
  disp(' ')
else
  disp(sprintf(fmt, varargin{:}))
end


% OLD CODE (does nice things with arrays, unlike the sprintf version above):
%str = '';
%n = 0;
%while (length(fmt) > 0),
  %p = strindex(fmt, '%');
  %if (~p | p == length(fmt)),
    %str = [str, fmt];
    %fmt = '';
  %elseif (fmt(p+1) == '%')
    %str = [str, fmt(1:p)];
    %fmt = fmt(p+2:length(fmt));
  %else
    %if (n >= 0 & n <= 16)
      %eval(['y = a' int2str(n) ';']);
    %else 
      %error('Something''s wrong.'); 
    %end
    %n = n+1;
    %if (fmt(p+1) == 's')
      %str = [str, fmt(1:p-1), y];
      %fmt = fmt(p+2:length(fmt));
    %else
      %done = 0;
      %for x = p(1) : length(fmt)
        %if (isletter(fmt(x))),
          %str = [str, fmt(1:p(1)-1), sprintf([fmt(p(1):x) ' '], y)];
	  %str(length(str)) = [];		% remove trailing blank
          %fmt = fmt(x+1:length(fmt));
          %done = 1;
          %break
        %end
      %end
      %if (~done),
        %str = [str, fmt];
        %fmt = '';
      %end
    %end
  %end
%end

%if (length(str) == 0), str = ' '; end
%disp(str)
