function pamFilePosits = extractPAMFilePosits(pamFiles, locCalcT, timeBuffer)
%EXTRACTPAMFILEPOSITS Extracts glider location for each acoustic file
%
%	Syntax:
%		PAMFILEPOSITS = EXTRACTPAMFILEPOSITS(CONFIG, PAMFILES, LOCCALCT, TIMEBUFFER)
%
%	Description:
%       Extracts glider positional data (depth, lat, lon, vertical and
%       horizontal velocity, speed, sound speed, PAM status, etc.) for
%       each acoustic file. Each acoustic file is matched to the first 
%       glider sample AT OR AFTER the file's start time. If that matched 
%       sample is more than timeBuffer seconds after the file start, no 
%       position is assigned for that file (all matched columns are 
%       NaN/NaT).
%
%	Inputs:
%       pamFiles   [table] name, start and stop time and duration of all
%                  recorded sound files
%       locCalcT   [table] glider fine scale locations exported from
%                  EXTRACTCALCULATEDPOSITIONS
%       timeBuffer [double] optional argument to specify time (sec) after
%                  around a given file's start you are willing to accept a 
%                  glider position match. Default is 180 sec. Choosing this
%                  value is a balance between glider sampling interval and
%                  file duration -- suggest setting to something close to
%                  the maximum of the two, or there will be many NaNs. 
%
%	Outputs:
%       pamFilePosits  [table] glider positional info at the start of each
%                      acoustic file
%
%	Examples:
%
%   See also EXTRACTCALCULATEDPOSITIONS, EXTRACTPAMSTATUS, CALCPAMEFFORT
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   31 August 2026
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    timeBuffer = 180; % in seconds
end

% get file times as datenum
fileStartNum = datenum(pamFiles.start);

% find the first glider sample AT OR AFTER each file's start time
nextIdx = interp1(locCalcT.time, 1:height(locCalcT), fileStartNum, 'next', 'extrap');

% find cols with valid location data
hasNext = ~isnan(nextIdx);

% get timeDiff column
timeDiff_sec = nan(height(pamFiles), 1);
timeDiff_sec(hasNext) = (locCalcT.time(nextIdx(hasNext)) - ...
    fileStartNum(hasNext))*86400;
% check if its within the buffer
withinBuffer = hasNext & (timeDiff_sec <= timeBuffer);

if any(~hasNext)
	fprintf(1, '%i of %i files start after all available glider positions (no match)\n', ...
		sum(~hasNext), height(pamFiles));
end
if any(hasNext & ~withinBuffer)
	fprintf(1, '%i of %i files'' nearest glider position is > %i sec away\n', ...
		sum(hasNext & ~withinBuffer), height(pamFiles), timeBuffer);
end

% build a template 'no match' row with NaNs/NaTs
noMatch = locCalcT(1,:);
for v = 1:width(noMatch)
	if isdatetime(noMatch{1,v})
		noMatch{1,v} = NaT;
	else
		noMatch{1,v} = NaN;
	end
end

% pull the matched glider rows (placeholder index 1 for no-match rows,
% overwritten below), then null out anything not within the buffer
safeIdx = nextIdx;
safeIdx(~hasNext) = 1;
matchedT = locCalcT(safeIdx,:);
matchedT(~withinBuffer,:) = repmat(noMatch, sum(~withinBuffer), 1);

% assemble output table: file info + matched glider data
pamFilePosits = table();
pamFilePosits.fileName = pamFiles.name;
pamFilePosits.fileStart = pamFiles.start;
pamFilePosits = [pamFilePosits, matchedT];

% drop the redundant raw-datenum time column, rename dateTime for clarity
pamFilePosits.time = [];
pamFilePosits = renamevars(pamFilePosits, 'dateTime', 'sampleDateTime');

end