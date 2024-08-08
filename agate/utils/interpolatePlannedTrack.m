function interpTrack = interpolatePlannedTrack(CONFIG, targetsFile, spacing)
% INTERPOLATEPLANNEDTRACK	Generate lat/lon points at specified spacing between waypoints
%
%   Syntax:
%       INTERPTRACK = INTERPOLATEPLANNEDTRACK(CONFIG, TARGETSFILE, SPACING)
%
%   Description:
%       Detailed description here, please
%   Inputs:
%       CONFIG        [struct] agate configuration settings from .cnf
%       targetsFile   [string] optional argument to targets file. If no file
%                     specified, will prompt to select one, and if no path
%                     specified, will prompt to select path
%                     [table] alternatively can just reference a targets
%                     table that has already been read in to the workspace
%       spacing       [double] optional argument to set spacing between
%                     interpolated points, in km. Default is 5 km. 
%
%	Outputs:
%       interpTrack   [table] lat/lon points interpolated between the
%                     targets at approx the spacing setting
%
%   Examples:
%
%   See also TRACK2, PLOTTRACKBATHYPROFILE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   06 August 2024
%   Updated:        07 August 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
	spacing = 5;
end

% select targetsFile if none specified
if nargin < 2
	[fileName, filePath] = uigetfile([CONFIG.path.mission, '*.*'], ...
		'Select targets file');
	targetsFile = fullfile(filePath, fileName);
	fprintf('targets file selected: %s\n', fileName);
end

% check that targetsFile exists if specified, otherwise prompt to select
if ischar(targetsFile)
	if ~exist(targetsFile, 'file')
		fprintf(1, 'Specified targetsFile does not exist. Select targets file to continue.\n');
		[fileName, filePath] = uigetfile([CONFIG.path.mission, '*.*'], ...
			'Select targets file');
		targetsFile = fullfile(filePath, fileName);
		fprintf('targets file selected: %s\n', fileName);
	end
	% read in targets file
	[targets, ~] = readTargetsFile(CONFIG, targetsFile);
elseif istable(targetsFile)
	targets = targetsFile;
end


% setup output matrix
it = [];

% matlab track function can create track points between a series of
% waypoints but no way to define size, can only specify number of points
% between each pair of waypoints
%
% track2 operates between just one start/end point and you can specify the
% number of points so can divide total length by spacing to get as close as
% possible to the spacing value, then concatenated

% loop through each waypoint to create interpolated points based on length
% of each segment between waypoints
for f = 1:height(targets)-1
	pairDist = distance(targets.lat(f), targets.lon(f), ...
		targets.lat(f+1), targets.lon(f+1), referenceEllipsoid('wgs 84'))/1000;
	npts = round(pairDist/spacing);
	tt = track2(targets.lat(f), targets.lon(f), ...
		targets.lat(f+1), targets.lon(f+1), [1 0], 'degrees', npts);
	it = [it; tt(1:end-1,:)]; % remove the last one so no dupes
end
% add the recv point to the end
it = [it; targets.lat(end) targets.lon(end)];

% turn into a table
interpTrack = array2table(it, 'VariableNames', {'latitude', 'longitude'});
% add in the distance between 
interpTrack.dist_km(2:height(interpTrack),1) = distance( ...
	interpTrack.latitude(1:end-1), interpTrack.longitude(1:end-1),...
	interpTrack.latitude(2:end), interpTrack.longitude(2:end), ...
	referenceEllipsoid('wgs 84'))/1000;

% label actual waypoints (have to round or sometimes misses them)
interpTrack.waypoint(1,1) = targets.name(1);
for f = 1:height(targets)
	wpIdx = find(round(interpTrack.latitude, 8) == round(targets.lat(f), 8) & ...
		round(interpTrack.longitude, 8) == round(targets.lon(f), 8));
	interpTrack.waypoint(wpIdx) = targets.name(f);
end

% % testing
% figure(1)
% scatter(it(:,2), it(:,1), 'gs');
% 
% distancesBetweenPoints = distance(it(1:end-1,1),it(1:end-1,2),...
% 	it(2:end,1),it(2:end,2), referenceEllipsoid('wgs 84'));
% 
% figure(3);
% histogram(distancesBetweenPoints/1000,31)
% xlabel('kilometers between points using track2')
% mean(distancesBetweenPoints/1000)

end