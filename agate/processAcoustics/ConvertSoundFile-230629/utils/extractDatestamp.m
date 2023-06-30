function dtnum = extractDatestamp(str)
%extractDatestamp	turn a date /time stamp from a string into a datenum
%
% dtnum = extractDatestamp(str)
%   Given a string str, find a string within it that has a date/time stamp and
%   parse it into a datenum value to return. If no such string is found, return
%   NaN. 'str' may also be a cell array of strings, in which case dtnum is an
%   array of the same shape with a datenum for each element.
%
%   The basic date/time stamp has the format yyyymmdd-HHMMSS, with a 4-digit
%   year, 2-digit month, 2-digit day, a dash, 2-digit hour, 2-digit minute, and
%   2-digit second. This string can be embedded in a longer string, so if it's
%   part of a file name, this will still work. An example would be
%   'mysound20190923-145358.wav', which represents 2019-09-23 at 14:53:58.
%
%   You can modify the basic format in these ways:
%	yymmdd-HHMMSS		the year can be 2-digit
%	yyyymmdd-HHMMSS.DDD...	the seconds can be a decimal (of any length)
%	yyyymmdd-HHMMSSpDDD...	the decimal point can be 'p' instead of '.'
%	yyyymmdd_HHMMSS		the center character can be '_'
%	yyyymmddTHHMMSS		the center character can be 'T'	(ISO-8601)
%
%   You can also use the CTBTO format of a 4-digit year and 3-digit year day,
%   like 2019266, which represents midnight on the 266th day of 2019 (i.e.,
%   2019-09-14 at 0:00:00).
%
% Dave Mellinger

% Handle the case where str is a cell array of strings.
if (iscell(str))
  dtnum = zeros(size(str));
  for di = 1 : numel(str)
    dtnum(di) = extractDatestamp(str{di});
  end
  return
end

C = regexp(str, '((\d\d)?\d\d)(\d\d)(\d\d)[-_Tt](\d\d)(\d\d)(\d\d([.p]\d*)?)',...
  'tokens', 'once');
if (length(C) == 6)
  if (length(C{1}) < 4)
    % Fix up 2-digit years: assume 1900's if year>=80, else 2000's.
    if (str2double(C{1}) >= 80), C{1} = ['19' C{1}];
    else                         C{1} = ['20' C{1}];
    end
  end
  dtnum = datenum(str2double(C{1}), str2double(C{2}), ...
    str2double(C{3}), str2double(C{4}), ...
    str2double(C{5}), str2double(strrep(C{6}, 'p','.')));
else
  % Try matching CTBTO's 4-digit year and jday, like snd2019364.wav.
  C = regexp(str, '((\d\d\d\d)(\d\d\d)', 'tokens', 'once');
  if (length(C) == 2)
    dtnum = datenum(str2double(C{1}), 1, str2double(C{2}));
  else
    dtnum = NaN;
  end
end
