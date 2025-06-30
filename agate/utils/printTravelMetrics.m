function tm = printTravelMetrics(CONFIG, pp, targetsFile, printOn)
%PRINTTRAVELMETRICS	Print out summary of distances/days traveled/remaining
%
%   Syntax:
%     tm = PRINTTRAVELMETRICS(CONFIG, pp, targetsFile)
%
%   Description:
%        Summarize and print out several metrics about mission distances
%        covered (over ground and along trackline), average speeds (over
%        ground and along trackline), and estimates of remaining days to
%        reach the end of the mission trackline.
%
%   Inputs:
%       CONFIG      Global config variable from agate mission configuration
%                   file and initlized by agate
%       pp          Piloting parameters table created with
%                   extractPilotingParams
%       targetsFile Fullfile path to targets file to be used in
%                   calculations for trackline distance covered and
%                   remaining
%       printOn     Optional argument to print (1) summary or not print (0)
%                   default is to print
%
%   Outputs:
%       tm   [struct] of calculated/estimated travel metrics, includes
%               distTot         total distance over ground in km
%               distCov         total distance along trackline in km
%               distRem         trackline distance remaining in km
%               missionElapsed  total mission duration in days
%               avgSpd          average speed over ground in km/day
%               avgTrkSpd       average speed along trackline in km/day
%               daysRem         estimated days remaining to finish trackline
%       also prints out lines of text
%
%   Examples:
%       tm = printTravelMetrics(CONFIG, pp, targetsFile, 1);
%
%   See also PRINTRECOVERYMETRICS
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   25 April 2023
%   Updated:        15 October 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
	printOn = 1;
end

% check that targetsFile specified is valid
if ~exist(targetsFile, 'file')
	fprintf(1, ['Specified targetsFile does not exist. Select' ...
		' targets file to continue.\n']);
	[fn, path] = uigetfile([CONFIG.path.mission, '*.*'], ...
		'Select targets file');
	targetsFile = fullfile(path, fn);
	fprintf('targets file selected: %s\n', fn);
end

tm = struct;

% total dist over ground
tm.distTot = sum(pp.dog_km(~isnan(pp.dog_km)));
% total elapsed days
tm.missionElapsed = days(pp.diveEndTime(end) - pp.diveStartTime(1));

% estimate track distance covered and remaining
% loop through all targets (expect RECV) to get distances between each
[targets, ~] = readTargetsFile(CONFIG, targetsFile);
for f = 1:height(targets) - 1
	[targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
		[targets.lat(f) targets.lon(f)]);
end
% get current waypoint to calculate distance covered and remaining
currTgt = pp.tgtName{end};
ctIdx = find(strcmp(targets.name, currTgt));
% sum dists between all waypoints before current waypoint, then subtract
% remaining distance to currant waypoint to get total trackline covered
dist_covEst = sum(targets.distToNext_km(1:ctIdx-1));
tm.distCov = dist_covEst - pp.distTGT_km(end);
% sum dist between all remaining waypoints + the remaining dist to current
% target to get total trackline remaining
dist_remEst = sum(targets.distToNext_km(ctIdx:end));
tm.distRem = dist_remEst + pp.distTGT_km(end);

% speeds
tm.avgSpd = tm.distTot/tm.missionElapsed;
tm.avgTrkSpd = tm.distCov/tm.missionElapsed;
% last 5 dives only (typically 20-30 hours)
if height(pp) >=5 
tm.avgSpdRec = sum(pp.dog_km(end-4:end))/...
	days(pp.diveEndTime(end) - pp.diveStartTime(end-4));
else % use all dives
    tm.avgSpdRec = sum(pp.dog_km)/...
	days(pp.diveEndTime(end) - pp.diveStartTime(1));
end

% remaining days
tm.missionRem = tm.distRem/tm.avgTrkSpd;
tm.missionRemRec = tm.distRem/tm.avgSpdRec;

% eta to recovery
tm.eta = dateshift(datetime(pp.diveEndTime(end), 'Format', 'uuuu-MMM-dd HH:mm ZZZZ', ...
	'TimeZone', '+0000') + days(tm.missionRem), 'start', 'hour', 'nearest');
tm.etaRec = dateshift(datetime(pp.diveEndTime(end), 'Format', 'uuuu-MMM-dd HH ZZZZ', ...
	'TimeZone', '+0000') + days(tm.missionRemRec), 'start', 'hour', 'nearest');


if printOn == 1
	% print messagess
	fprintf(1, ['%s travel summary through dive %i:\n' ...
		'\tTotal distance over ground: %.1f km (~%.f km of trackline) ' ...
		'in %.1f days\n' ...
		'\tTrackline distance remaining: %.1f km\n' ...
		'\tAvg speed over ground: %.f km/day (last 5 dives only = %.f km/day)\n' ...
		'\tAvg speed over trackline: ~%.f km/day\n' ...
		'\tEstimated mission duration: %.f days (target = %.f days)\n'], ...
		CONFIG.glider, pp.diveNum(end), tm.distTot, tm.distCov, ...
		tm.missionElapsed, tm.distRem, tm.avgSpd, tm.avgSpdRec, tm.avgTrkSpd, ...
		tm.missionRem + tm.missionElapsed, CONFIG.tmd);
end

end
