function targetsOut = makeTargetsFile(CONFIG, kmlFile, wpMethod)
%MAKETARGETSFILE Create properly formatted targets text file from kml
%
%   Syntax:
%       targetsOut = MAKETARGETSFILE(CONFIG, kmlFile, wpMethod)
%
%   Description:
%       Create a text file properly formatted as a Seaglider targets file,
%       from a saved path created in Google Earth and saved as a .kml. The
%       text file contains relevant header information at the top. Waypoint
%       names can be provided as an additional text document, can be
%       manually input in the Command Window, or a prefix can be specified
%       as the last argument and a sequential alphanumeric waypoint labels
%       will be generated from the prefix
%
%   Inputs:
%       CONFIG     agate mission configuration settings, loaded during
%                  agate initialization. Minimum fields are CONFIG.glider,
%                  CONFIG.mission, CONFIG.path.mission
%       kmlFile    Fullfile path to kml path file to be read in, if left
%                  blank, will prompt to select file
%       wpMethod   Method to define waypoint names, either
%                     'file' = load text file with names, will prompt to
%                            select file
%                     'manual' = manually type in all waypoints in command
%                             window
%                     'prefix' = will automatically generate alpha-numeric
%                             waypoints based on string entered as wpMethod
%                             e.g., 'LW' will generate 'LW01', 'LW02', etc
%                             and will end with RECV
%
%   Outputs:
%       targetsOut Fullpath filename of newly created targets file
%
%   Examples:
%
%   See also MAPPLANNEDTRACK
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   23 April 2023
%   Updated:        04 May 2023
%
%   Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
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
% (2) 'manual', prompted to manually type in command window
% (3) use prefix string specified in function call (e.g., 'WP') and add
% numbers in order after (e.g., WP01, WP02, RECV)

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

% now write it into a targets file
% example header text
% / Targets file for mission sg639_MHI_Apr2023
% / Created on 2023-05-04 10:55:00 UTC
% / Deployment will take place at WW01, recovery at RECV
% / template WWxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=2000 goto=WWzz

targetsOut = fullfile(kmlPath, ['targets_' kmlName]);
fid = fopen(targetsOut, 'w');

fprintf(fid, '%s %s_%s\n', '/ Targets file for mission', CONFIG.glider, ...
    CONFIG.mission);
fprintf(fid, '%s %s %s\n', '/ Created on', string(datetime('now', ...
    'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd HH:mm')), 'UTC');
fprintf(fid, '%s %s%s\n', '/ Deployment will take place at', wpNames{1}, ...
    ', recovery at RECV');
fprintf(fid, '%s\n', '/ template WPxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=XXXX goto=WPzz');

for f = 1:length(wpNames)-1
    fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s\n', ...
        wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f+1});
end
f = length(wpNames);
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f});
fclose(fid);

end