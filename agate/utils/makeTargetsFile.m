function targetsOut = makeTargetsFile(CONFIG, kmlFile, wpMethod)
% MAKETARGETSFILE	One-line description here, please
%
%	Syntax:
%		OUTPUT = MAKETARGETSFILE(INPUT)
%
%	Description:
%		Detailed description here, please
%	Inputs:
%		CONFIG      agate mission configuration settings, loaded during
%		            agate initialization. Minimum fields are CONFIG.glider,
%		            CONFIG.mission, CONFIG.path.mission,
%       kmlFile     fullfile path to kml path file to be read in, if left
%                   blank, will prompt to select file
%       wpMethod    Method to define waypoint names, either 
%                   'file' = load text file with names, will prompt to
%                           select file
%                   'manual' = manually type in all waypoints in command
%                           window
%                   'prefix' = will automatically generate alpha-numeric
%                           waypoints based on string entered as wpMethod
%                           e.g., 'LW' will generate 'LW01', 'LW02', etc
%                           and will end with RECV
%
%	Outputs:
%		targetsOut  fullpath filename of newly created targets file
%
%	Examples:
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
%
%	FirstVersion: 	23 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CONFIG

% if no .kml specified...
if isempty(kmlFile)
    % Select .kml file
    [kmlFileName, kmlPath] = uigetfile([CONFIG.path.mission '\*.kml'], 'Select .kml track');
    kmlFile = fullfile(kmlPath, kmlFileName);
end

% pull out just  name for naming output targets file
[kmlPath, kmlName, ~] = fileparts(kmlFile);

fid = fopen(kmlFile);
kmlStr = textscan(fid, '%s');
fclose(fid);
kmlStr = kmlStr{:};

% find start and end of coordinates section
scIdx = find(strcmp(kmlStr, '<coordinates>'));
ecIdx = find(strcmp(kmlStr, '</coordinates>'));
coordsOnly = kmlStr(scIdx+1:ecIdx-1);

% set up empty outputs, then loop through and extra each pair
lats = nan(length(coordsOnly), 1);
lons = nan(length(coordsOnly), 1);
for f = 1:length(coordsOnly)
    C = strsplit(coordsOnly{f},',');
    lats(f) = str2double(C{2});
    lons(f) = str2double(C{1});
end

% convert to deg decmins
degMinLats = decdeg2degmin(lats);
degMinLons = decdeg2degmin(lons);

% define waypoint names - 3 options
% (1) 'file', load text file with names
% (2) 'prefix', automatically generate as prefix + numeric
% (3) manually type in command window

switch wpMethod
    case 'file'  % (1) Select .txt file of waypoint names
        [wpFileName, wpPath] = uigetfile([CONFIG.path.mission '\*.txt'], ...
            'Select waypoint names text file');
        wpFile = fullfile(wpPath, wpFileName);

        fid = fopen(wpFile);
        wpNames = textscan(fid, '%s');
        fclose(fid);
        wpNames = wpNames{:};
    case 'manual' % (3) manually type in command window
        wpsRaw = input(['Type in ' num2str(length(degMinLats)) ...
            ' waypoint names, separated by commas, no spaces:'], 's');
        wpNames = strsplit(wpsRaw, ',');
        wpNames = strtrim(wpNames);
        wpNames = wpNames';
    otherwise
        %         case 'prefix'
        %         prefixRaw = input('Specify waypoint alpha prefix:', 's');
        prefixRaw = wpMethod;
        wpNames = cell(length(degMinLats), 1);
        wpSeq = 1:length(degMinLats) - 1; % -1 so last is RECV
        for f = 1:length(wpSeq)
            wpNames(f) = {sprintf('%s%02.f', prefixRaw, wpSeq(f))};
        end
        wpNames{f + 1} = 'RECV';
end

% wpNames = {'WW01', 'WWaa', 'WW02', 'WWab', 'WW03', 'WW04', 'WW05', 'WWac', ...
%     'WW06', 'WWad', 'WW07', 'WWae', 'WW08', 'WWaf', 'WW09', 'WWag', 'WW10', ...
%     'WWah', 'WW11', 'WWai', 'WW12', 'WWaj', 'WW13', 'WWak', 'WW14', 'WWal', ...
%     'WW15', 'WWam', 'WWan', 'WW16', 'WWao', 'WWap', 'WW17', 'WWaq', 'WWar', ...
%     'RECV'}';


% now write it into a targets file
% example header text
% / Targets file for mission sg639_MHI_Apr2023
% / Deployment will take place at WW01
% / template WWxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=2000 goto=WWzz
% / radius set to 2000 m

targetsOut = fullfile(kmlPath, ['targets_' kmlName]);
fid = fopen(targetsOut, 'w');

fprintf(fid, '%s %s_%s\n', '/ Targets file for mission', CONFIG.glider, CONFIG.mission);
fprintf(fid, '%s %s%s\n', '/ Deployment will take place at', wpNames{1}, ', recovery at RECV');
fprintf(fid, '%s\n', '/ template WPxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=2000 goto=WPzz');
fprintf(fid, '%s\n', '/ radius set to 2000 m');

for f = 1:length(wpNames)-1
    fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s\n', ...
        wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f+1});
end
f = length(wpNames);
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f});
fclose(fid);


end