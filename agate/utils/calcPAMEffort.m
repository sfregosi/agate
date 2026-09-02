function [pamByMin, pamMinPerHour, pamMinPerDay, pamHrPerDay] = ...
    calcPAMEffort(CONFIG, gpsSurfT, pamFiles, pamByDive, expLimits)
%CALCPAMEFFORT	Calculates acoustic recording effort by minute, hour, day
%
%   Syntax:
%	    [PAMBYMIN, PAMMINPERHOUR, PAMMINPERDAY, PAMHRPERDAY] = ...
%           CALCPAMEFFORT(CONFIG, GPSSURFT, PAMFILES, PAMBYDIVE, EXPLIMITS)
%
%   Description:
%       Summarizes recording effort in several ways by creating tables of
%       all possible recording minutes, hours, and days, and quantifying
%       how many of each of those bins contain recordings. The assessment
%       of minutes is someone imperfect because some minutes only contain
%       partial recordings (if a file ends within that minute) and some
%       minutes are missed (if a recording starts partway through a minute)
%
%       Experiment limits can be defined if multiple instruments were
%       deployed and you want to compare across the maximum deployment time
%       for all of them. Optionally can be left out and the bins will just
%       populate from the first sound file to the end of the last file
%
%       By-minute PAM status and hour/day binning arevectorized (via local
%       functions POINTININTERVALS and BINSUM)rather than looped, for speed
%       on multi-week deployments. Thisrequires pamByDive.diveStart and 
%       pamFiles.start each be sorted ascending with non-overlapping 
%       intervals, which should be true for any deployment, but is worth 
%       checking if any weird behavior is observed. 
%
%       A minute is marked NaN if not in a dive, then 1 if PAM was on,
%       with the PAM-on check applied second (so it can overwrite a NaN).
%       This means that if PAM was on at the surface it would still be
%       marked as 1. **This maybe should be changed!**
%
%   Inputs:
%       CONFIG     agate mission configuration file with relevant mission 
%                  and glider information. Minimum CONFIG fields are 
%                  'glider'
%       gpsSurfT   [table] glider surface locations exported from
%                  EXTRACTSURFACEPOSITIONS
%       pamFiles   [table] name, start and stop time and duration of all
%                  recorded sound files, created with EXTRACTPAMSTATUS
%       pamByDive  [table] summary of recording start and stop, number of
%                  files for each dive. Includes dive start and stop times
%                  and offset of start and stop of pam relative to dive
%                  times, created with EXTRACTPAMSTATUS
%       expLimits  [vector] two datetimes defining the start and end of an
%                  'experiment' to set limits of the maximum possible
%                  recording times
%
%   Outputs:
%       pamByMin      [table] one minute bins with 1 for recordings during
%                     this minute, 0 for no recordings this minute, and
%                     NaNs if the glider was at the surface or not deployed
%       pamMinPerHour [table] one hour bins with the total number of
%                     minutes of that hour with recordings
%       pamMinPerDay  [table] daily bins with total number of minutes with
%                     recordings per day
%       pamHrPerDay   [table] daily bins with total hours with recordings
%                     each day. This is the total minutes/60 so is total
%                     complete hours, not the number of hour bins with any
%                     partial amount of recording
%
%   Examples:
%
%   See also EXTRACTPAMSTATUS, EXTRACTPAMFILEPOSITS,
%   EXTRACTSURFACEPOSITIONS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%    Updated:        2026 August 31
%
%    Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5 % default 'experiment time' is deploy start/end
    expLimits(1) = dateshift(gpsSurfT.startDateTime(1), 'start', 'minute');
    expLimits(2) = dateshift(gpsSurfT.endDateTime(end), 'end', 'minute');
end

% build empty table for whole deployment
dm = (expLimits(1):minutes(1):expLimits(2))';
pamByMin = table;
pamByMin.min = dm;

% build minutes per hour empty table
dh = (dateshift(expLimits(1), 'start', 'hour'):hours(1): ...
    dateshift(expLimits(2), 'start', 'hour'))';
pamMinPerHour = table;
pamMinPerHour.hour = dh;

% build minutes per day empty table
ddm = (dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2), ...
	'start', 'day'))';
pamMinPerDay = table;
pamMinPerDay.day = ddm;

% build hours per day empty table
ddh = (dateshift(expLimits(1),'start','day'):days(1):dateshift(expLimits(2), ...
	'start', 'day'))';
pamHrPerDay = table;
pamHrPerDay.day = ddh;

fprintf(1,'Calculating PAM status by min: %s\n', CONFIG.glider)

% by Minute -- NaN if not deployed/at surface, 0 if PAM off, 1 if PAM on.
% NOTE: assumes pamByDive.diveStart and pamFiles.start are each sorted
% ascending with non-overlapping intervals
% is start of this min within a dive and is pam on this minute?
inDive = pointInIntervals(dm, pamByDive.diveStart, pamByDive.diveStop);
inPam  = pointInIntervals(dm, pamFiles.start, pamFiles.stop);
% set output all to 0s, then NaN if not in a dive and 1 if not in a file
pam = zeros(height(pamByMin), 1); 
pam(~inDive) = nan;
pam(inPam) = 1;   % overwrites NaN too -- same order-dependence as the original
pamByMin.pam = pam;

fprintf(1, '%s: %i minutes with PAM on\n', CONFIG.glider, ...
	sum(pamByMin.pam, 'omitnan'));
% this is not perfect...not always full minutes (at end of a recording
% and misses some partial minutes (at the start of a recording)

% by Hour
edgesH = [dh; dh(end) + hours(1)];
binH = discretize(pamByMin.min, edgesH);
pamMinPerHour.pam = binSum(pamByMin.pam, binH, height(pamMinPerHour));
pamMinPerHour.pam(pamMinPerHour.pam == 0) = nan; % if all zeros, make nan
fprintf(1, '%s: %i partial hours with PAM on, total %.2f hours\n', ...
	CONFIG.glider, sum(~isnan(pamMinPerHour.pam)), ...
	hours(sum(pamFiles.dur, 'omitnan')));

% by Day
%   Minutes per day
edgesDm = [ddm; ddm(end) + days(1)];
binDm = discretize(pamByMin.min, edgesDm);
pamMinPerDay.pam = binSum(pamByMin.pam, binDm, height(pamMinPerDay));
pamMinPerDay.pam(pamMinPerDay.pam == 0) = nan;

%   Hours per day
edgesDh = [ddh; ddh(end) + days(1)];
binDh = discretize(pamMinPerHour.hour, edgesDh);
pamHrPerDay.pam = round(binSum(pamMinPerHour.pam, binDh, height(pamHrPerDay)) / 60, 2);
pamHrPerDay.pam(pamHrPerDay.pam == 0) = nan;

fprintf(1, '%s: %i partial days with PAM on, total %.2f days\n', ...
	CONFIG.glider, sum(~isnan(pamMinPerDay.pam)), ...
	sum(pamMinPerDay.pam, 'omitnan')/(60*24));

end



function inInterval = pointInIntervals(queryTimes, intervalStart, intervalStop)
% POINTININTERVALS  Vectorized test of whether each queryTime falls
% within any [intervalStart, intervalStop] pair. Requires intervalStart
% sorted ascending with non-overlapping intervals.
idx = interp1(datenum(intervalStart), 1:numel(intervalStart), ...
    datenum(queryTimes), 'previous');
inInterval = false(size(queryTimes));
valid = ~isnan(idx);
inInterval(valid) = queryTimes(valid) <= intervalStop(idx(valid));
end

function binSums = binSum(vals, binIdx, numBins)
% BINSUM  Sum vals (0/1/NaN) into numBins groups defined by binIdx,
% treating NaN as 0 (equivalent to sum(...,'omitnan') per bin -- NaN
% never contributes to a sum either way) and assigning 0 to any bin with
% no data, matching the original loop's behavior before each caller's
% "0 -> NaN" cleanup step.
vals(isnan(vals)) = 0;
valid = ~isnan(binIdx);
binSums = accumarray(binIdx(valid), vals(valid), [numBins, 1]);
end