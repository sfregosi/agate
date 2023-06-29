function tm = printRecoveryMetrics(CONFIG, pp, targetsFile, recovery, recTZ, printOn)
%PRINTRECOVERYMETRICS	Caclulate travel metrics with recovery focus
%
%   Syntax:
%      rm = PRINTRECOVERYMETRICS(CONFIG, pp, targetsFile, recoveryDT, printOn)
%
%   Description:
%        Builds on PRINTTRAVELMETRICS to summarize and print out several 
%        metrics about estimated mission duration compared to target
%        recovery time. Includes comparing avg speeds for the whole mission
%        to just the last 5 dives, and suggests a range of possible etas
%        based on these avg speeds. 
%
%   Inputs:
%       CONFIG      Global config variable from agate mission configuration
%                   file and initlized by agate
%       pp          Piloting parameters table created with
%                   extractPilotingParams
%       targetsFile Fullfile path to targets file to be used in
%                   calculations for trackline distance covered and
%                   remaining
%       recovery    [string] for target recovery date and time, in UTC
%                   (e.g., '2023-06-05 19:00:00')
%       recTZ       [string] optional argument to adjust printout to 
%                   timezone of recovery location, formatted as '+0000' or
%                   any listed in the 'timezones' function (e.g.,
%                   'Pacific/Honolulu' OR '-1000')
%       printOn     Optional argument to print (1) summary or not print (0)
%                   default is to print
%
%   Outputs:
%       tm          [struct] travel metrics includes 
%                   distTot     total distance over ground in km
%                   distRem     trackline distance remaining in km
%                   distCov     total distance along trackline in km
%                   missionDur  total mission duration in days
%                   avgSpd      average speed over ground in km/day
%                   avgTrkSpd   average speed along trackline in km/day
%                   avgSpdRec   average speed over ground, last 5 dives, km/day
%                   missionRem  estimated days remaining to finish trackline
%                   missionRemRec  estimated days remaining to finish
%                                  trackline, based on speed of last 5 dives
%                   eta         estimated time of arrival at recovery waypoint
%                   etaRec      estimated time of arrival at recovery
%                               waypoint, based on avg speed of last 5 dives
%       also prints out lines of text
%
%   Examples:
%       % use UTC as recovery time zone
%       tm = printRecoveryMetrics(CONFIG, pp, targetsFile, '2023-06-05 19:00:00');
%
%       % use HST as recovery time zone
%       recovery = '2023-06-05 19:00:00';
%       recTZ = 'Pacific/Honolulu';
%       tm = printRecoveryMetrics(CONFIG, pp, targetsFile, recovery, recTZ, 1);
%
%   See also PRINTTRAVELMETRICS
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   27 May 2023
%   Updated:        
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6
	printOn = 1;
end

if nargin < 5 || isempty(recTZ)
	recTZ = '+0000'; % default to UTC
end

tm = printTravelMetrics(CONFIG, pp, targetsFile, 0);

try
tm.recoveryDT = datetime(recovery, 'Format', 'uuuu-MMM-dd HH:mm:ss ZZZZ', 'TimeZone', '+0000');
catch
	fprintf(1, ['recovery should be a string with format yyyy-mm-dd HH:MM:SS'...
		'and in UTC. Check format and try again.\n'])
	return
end

if printOn == 1
    % set up date output format
	dispRecDT = datetime(tm.recoveryDT, 'TimeZone', recTZ, 'Format', ...
		'uuuu-MMM-dd HH:mm z');
	dispEtaDT = datetime(tm.eta, 'TimeZone', recTZ, 'Format', ...
		'uuuu-MMM-dd HH:mm z');
	dispRecEtaDT = datetime(tm.etaRec, 'TimeZone', recTZ, 'Format', ...
		'uuuu-MMM-dd HH:mm z');
	% print message
    fprintf(1, ['%s recovery plan summary at dive %i:\n' ...
		'\t%s - Target recovery\n' ...
		'\t%s - ETA based on mission avg speed\n' ...
        '\t%s - ETA based on recent avg speed (last 5 dives)\n'], ...
		CONFIG.glider, pp.diveNum(end), dispRecDT, dispEtaDT, dispRecEtaDT);
end

end
