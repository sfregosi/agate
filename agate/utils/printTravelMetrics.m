function tm = printTravelMetrics(CONFIG, pp, targetsFile, printOn)
% PRINTTRAVELMETRICS	One-line description here, please
%
%	Syntax:
%		PRINTTRAVELMETRICS(CONFIG, pp, targetsFile)
%
%	Description:
%		Summarize and print out several metrics about mission distances
%		covered (over ground and along trackline), average speeds (over
%		ground and along trackline), and estimates of remaining days to
%		reach the end of the survey trackline.
%
%       Estimates of distance along trackline covered and remaining are
%       conservative estimates, based on the previous waypoint. 
%
%	Inputs:
%		CONFIG      global config variable from agate mission configuration
%		            file and initlized by agate
%       pp          piloting parameters table created with
%                   extractPilotingParams
%       targetsFile fullfile path to targets file to be used in
%                   calculations for trackline distance covered and
%                   remaining
%       printOn     optional argument to print (1) summary or not print (0)
%                   default is to print
%
%	Outputs:
%		tm      structure of travel metrics includes 
%               distTot     total distance over ground in km
%               distCov     total distance along trackline in km
%               distRem     trackline distance remaining in km
%               missionDur  total mission duration in days
%               avgSpd      average speed over ground in km/day
%               avgTrkSpd   average speed along trackline in km/day
%               daysRem     estimated days remaining to finish trackline
%       also prints out lines of text
%
%	Examples:
%       tm = printTravelMetrics(CONFIG, pp, targetsFile, 1);
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	25 April 2023
%	Updated:
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
tm.distRem = sum(targets.distToNext_km(ctIdx-1:end));
tm.distCov = sum(targets.distToNext_km(1:ctIdx - 1));

% days
tm.missionDur = days(pp.diveEndTime(end) - pp.diveStartTime(1));

% speeds
tm.avgSpd = tm.distTot/tm.missionDur;
tm.avgTrkSpd = tm.distCov/tm.missionDur;

% remaining days
tm.missionRem = tm.distRem/tm.avgTrkSpd;


if printOn == 1
    % print messagess
    fprintf(1, ['SG639 total distance over ground: %.1f km  (~%.f km of trackline) ' ...
        'in %.1f days.\n' ...
        'Avg dist over ground: %.f km/day. Avg dist over trackline: ~%.f km/day.\n' ...
        'Approx. %.f days to complete mission (total ~= %.f days, target = %i days).\n'], ...
        tm.distTot, tm.distCov, tm.missionDur, tm.avgSpd, tm.avgTrkSpd, ...
        tm.missionRem, tm.missionRem + tm.missionDur, CONFIG.tmd);
end

end
