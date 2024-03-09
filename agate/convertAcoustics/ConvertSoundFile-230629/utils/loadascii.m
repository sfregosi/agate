function x = loadascii(filename, commentstr, nanfill)
%LOADASCII   Load an ascii file (w/comments), return its contents as a matrix.
%
% x = loadascii(filename)
%    Return the contents of the file as a numeric array.  This allows
%    you to name the result whatever you like, instead of having to
%    hack around with the name MATLAB chooses with the 'load' command.
%
%    Comments are allowed in files.  As in MATLAB .m files, comments 
%    begin with the '%' character and end at the end of the line.
%
% x = loadascii(filename, commentstr)
%    As above, but comments (which are ignored) begin with the given string
%    instead of '%'.  A typical commentstr is '#'.
%
% x = loadascii(filename, commentstr, nanfill)
%    As above, but when there are two successive commas (',,') in an input line,
%    insert 'NaN' in between them (to produce ',NaN,'). This is helpful for .csv
%    files where some entries are empty. Also, if some lines have fewer entries
%    than others, pad them with NaNs.
%
% See also load, mlFileNameFilter, readBinary, fread, fgetl, fgets.

if (nargin < 2), commentstr = '%'; end
if (nargin < 3), nanfill = false;  end

fd = fopen(filename, 'r');
if (fd < 0)
  error(['Can''t open the file "' filename '".']);
end

x = [];
nr = 0;				% number of rows of good data in x
lineno = 0;

% On some machines, sscanf doesn't deal with 'NaN' or 'Inf'.
% MATLAB doesn't deal with this, so we have to, by using eval instead 
% of sscanf.  sscanf is preferred because it's about twice as fast.
needEval = ...
    strncmp(computer, 'HP', 2) | ...
    strncmp(computer, 'SGI', 3) | ...
    strncmp(computer, 'PC', 2) | ...
    strncmp(computer, 'DEC', 3);

while (1)
  str = fgetl(fd);
  if (~ischar(str))		% EOF?
    x = x(1:nr,:);
    fclose(fd);
    return
  end
  lineno = lineno + 1;
  
  if (nanfill)
    str = strsubst(str, ',,', ',NaN,');
  end
  %y = find(str == commentchar);
  y = strfind(str, commentstr);
  if (isempty(y))
    y = length(str) + 1;
  end
  if (needEval) nums = eval(['[' str(1:y(1)-1) ']']);
  else          nums = sscanf(str(1:y(1)-1), '%g').';
  end

  if (~isempty(nums))
    nr = nr + 1;
    
    if (size(x,2) ~= 0 && length(nums) ~= size(x,2))
      if (nanfill)
        if (size(x,2) > length(nums))
          nums = [nums nan(1, size(x,2) - length(nums))];   % make nums wider
        else
          x = [x nan(size(x,1), length(nums) - size(x,2))]; % make x wider
        end
      else
        fclose(fd);
        error('File %s, line %d: %s.', filename, lineno, ...
          'All lines in file must have same number of elements');
      end
    end

    % If x is too small, add more rows on the bottom.
    if (nr > size(x,1))
      nNewRows = max(5, floor(10000 / length(nums)));
      x = [x; zeros(nNewRows, length(nums))];
    end
    x(nr,:) = nums;
  end
end
