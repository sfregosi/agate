function tm = printTravelMetrics(CONFIG, pp, targetsFile, printOn)
%PRINTTRAVELMETRICS	Print out summary of distances/days traveled/remaining
%
%   Syntax:
%      PRINTTRAVELMETRICS(CONFIG, pp, targetsFile)
%
%   Description:
%        Summarize and print out several metrics about mission distances
%        covered (over ground and along trackline), average speeds (over
%        ground and along trackline), and estimates of remaining days to
%        reach the end of the survey trackline.
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
%       tm          structure of travel metrics includes 
%                   distTot     total distance over ground in km
%                   distCov     total distance along trackline in km
%                   distRem     trackline distance remaining in km
%                   missionDur  total mission duration in days
%                   avgSpd      average speed over ground in km/day
%                   avgTrkSpd   average speed along trackline in km/day
%                   daysRem     estimated days remaining to finish trackline
%       also prints out lines of text
%
%   Examples:
%       tm = printTravelMetrics(CONFIG, pp, targetsFile, 1);
%
%   See also
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   25 April 2023
%   Updated:        25 May 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tm = struct;

% dist over ground
tm.distTot = sum(pp.dog_km(~isnan(pp.dog_km)));

% distance covered and remaining
% get current waypoint and use previous for trackline covered calcs
[targets, ~] = readTargetsFile(CONFIG, targetsFile);
currTgt = pp.tgtName{end};
ctIdx = find(strcmp(targets.name, currTgt));
% loop through all targets (expect RECV) to get distances
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end
% sum
dist_remEst = sum(targets.distToNext_km(ctIdx:end));
tm.distRem = dist_remEst + pp.distTGT_km(end);
dist_covEst = sum(targets.distToNext_km(1:ctIdx-1));
tm.distCov = dist_covEst - pp.distTGT_km(end);

% days
tm.missionDur = days(pp.diveEndTime(end) - pp.diveStartTime(1));

% speeds
tm.avgSpd = tm.distTot/tm.missionDur;
tm.avgTrkSpd = tm.distCov/tm.missionDur;

% remaining days
tm.missionRem = tm.distRem/tm.avgTrkSpd;

% eta
tm.eta = datetime('now', 'Format', 'uuuu-MMM-dd HH:mm:ss ZZZZ', ...
	'TimeZone', '+0000') + days(tm.missionRem);

% avg speed over last 5 dives (which is typically around 24-30 hours
tm.avgSpdRec = sum(pp.dog_km(end-4:end))/...
	days(pp.diveEndTime(end) - pp.diveStartTime(end-4));

if printOn == 1
    % print messagess
    fprintf(1, ['%s travel summary through dive %i:\n' ...
		'\tTotal distance over ground: %.1f km  (~%.f km of trackline) ' ...
        'in %.1f days.\n' ...
        '\tAvg speed over ground: %.f km/day. Avg speed over trackline: ~%.f km/day.\n' ...
		'\tAvg speed over ground last 5 dives: %.f km/day.\n'...
        '\tApprox. %.f days to complete mission (total ~= %.f days, target = %i days).\n'...
		'\t\t***ETA is %s***\n'], ...
		CONFIG.glider, pp.diveNum(end), tm.distTot, tm.distCov, tm.missionDur, ...
		tm.avgSpd, tm.avgTrkSpd, tm.avgSpdRec, tm.missionRem, tm.missionRem + tm.missionDur, ...
		CONFIG.tmd, tm.eta);
end

end
