% workflow to get a Google Earth created proposed trackline into a targets
% file and then into a 5-km spacing schedule to share with the Navy

% 1 - create track manually in Google Earth, using input from collaborators
% and sponsor. Save as .kml when finalized. 
 
% kmlFile = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\UxS_PIFSC_twoDeployments.kml';
% kmlFile = 'C:\Users\Selene.Fregosi\Desktop\sg680_HI_Apr2022\Leeward Glider_revised_20220503.kml';
% kmlFile = 'C:\Users\Selene.Fregosi\Desktop\sg639_HI_Apr2022\Windward Glider_revised_20220509.kml';
% kmlFile = 'C:\Users\Selene.Fregosi\Desktop\sg680_HI_Apr2022\Leeward Glider_revised_20220524.kml';
% kmlFile = 'C:\Users\Selene.Fregosi\Desktop\sg639_HI_Apr2022\Windward Glider_revised_20220524.kml';
[kmlFileName, kmlPath] = uigetfile('*.kml', 'Select .kml track');
kmlFile = fullfile(kmlPath, kmlFileName);
[~, kmlName, kmlExt] = fileparts(kmlFileName);

% kml saves the vertices of lines as decimal degrees in a code snippet like
% % this: 
% 		<Placemark>
% 			<name>Leeward Glider</name>
% 			<styleUrl>#inline13</styleUrl>
% 			<LineString>
% 				<tessellate>1</tessellate>
% 				<coordinates>
% 					-159.3180977061045,21.93379120241162,0 -159.3915294840902,21.50741673680377,0 -158.8809373915385,21.73528994893612,0 -158.9763412128043,21.27910694076397,0 -158.4324636016379,21.47030430788609,0 -158.5300178504395,20.97351624005566,0 -158.0118868380484,21.04165660408255,0 -157.9015894020643,20.52832280966129,0 -157.3568488495222,20.82859768139042,0 -157.5622783640389,20.30084306318159,0 -157.0340176577208,20.63583528150905,0 -157.2485263069477,20.08415381579547,0 -156.5958158941286,20.38616727824648,0 -156.9019851472443,19.83461456110239,0 -156.1842310583716,20.20053668786948,0 -156.557056073062,19.59525648291685,0 -156.1124900576321,19.74835140750147,0 
% 				</coordinates>
% 			</LineString>
% 		</Placemark>
% FOR NOW
% search for the name of the path you want and find the coordinates line.
% then just copy and paste the coordinates into a text file alone. 
% txtCoordFile = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\kml_leeward_coords.txt';
% txtCoordFile = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\kml_windward_coords.txt';
% txtCoordFile = 'C:\Users\Selene.Fregosi\Desktop\sg680_HI_Apr2022\kml_leeward_revised_20200503.txt';
% txtCoordFile = 'C:\Users\Selene.Fregosi\Desktop\sg639_HI_Apr2022\kml_windward_revised_20200509.txt';
% txtCoordFile = 'C:\Users\Selene.Fregosi\Desktop\sg680_HI_Apr2022\kml_leeward_revised_20200524.txt';
% txtCoordFile = 'C:\Users\Selene.Fregosi\Desktop\sg639_HI_Apr2022\kml_windward_revised_20200524.txt';
[txtCoordFileName, txtCoordPath] = uigetfile([kmlPath '\*.txt'], 'Select .txt coordinate file');
txtCoordFile = fullfile(txtCoordPath, txtCoordFileName);

% read in the coords and rearrange in a readable way
fid = fopen(txtCoordFile, 'r');
decDegCoords = textscan(fid, '%f%f%f', 'delimiter', ',', 'CollectOutput',1);
fclose(fid);
decDegCoords = decDegCoords{1,1}; % convert to array
decDegCoords = decDegCoords(:,1:2); % get rid of the "z" coord which should be 0s
% leeward glider has to be flipped because track order goes from N to S
% decDegCoords = flip(decDegCoords);

% convert to deg decmins
degMinLons = decdeg2degmin(decDegCoords(:,1));
degMinLats = decdeg2degmin(decDegCoords(:,2)); 
% define waypoint names
% wpNames = {'LW01', 'LW02', 'LW03', 'LW04', 'LW05', 'LW06', 'LWmA', 'LW07', ...
%     'LWmB', 'LW08', 'LWmC', 'LW09', 'LWmD', 'LW10', 'LWmE', 'LW11', 'LWmF', ...
%     'LW12', 'LWmG', 'LW13', 'LWmH', 'LW14', 'LW15', 'LWmI', 'LWmJ', 'RECV'}';
% wpNames = {'LW01', 'LW02', 'LW03', 'LW04', 'LW05', 'LW06', 'LW07', 'LW08', ...
%      'LW09', 'LW10', 'LW11', 'LW12', 'LW13', 'LW14', 'LW15', 'LW16', 'RECV'}';

% wpNames = {'WW01', 'WW02', 'WW03', 'WW04', 'WW05', 'WW06', 'WW07', 'WW08', ...
%      'WW09', 'WW10', 'WW11', 'WW12', 'WW13', 'WW14', 'WW15', 'WW16', 'RECV'}';
% wpNames = {'WW01', 'WW02', 'WWaa', 'WWab', 'WW03', 'WWm4', 'WW04', 'WWmE', ...
%     'WW05', 'WWmF', 'WW06', 'WWmG', 'WW07', 'WWmH', 'WW08', 'WWmI', 'WW09', ...
%     'WWmJ', 'WW10', 'WWmK', 'WW11', 'WWmL', 'WW12', 'WWmM', 'WW13', 'WWmN', ...
%     'WW14', 'WWmO', 'WW15', 'WWmP', 'WW16', 'WWmQ', 'WW17', 'WWmR', 'WWmS', ...
%     'WWmT', 'RECV'}';
wpNames = {'WW01', 'WW02', 'WW03', 'WW04', 'WW05', 'WW06', 'WW07', 'WW08', ...
    'WW09', 'WW10', 'WW11', 'WW12', 'WW13', 'WW14', 'WW15', 'WW16', ...
    'WW17', 'RECV'}';

% now write it into a targets file
% example header text
% / Glider survey plan for UxS HI March 2022
% / Deployment will take place at WPo1
% / template WPo lat= lon= radius=2000 goto=WPo
% / radius set to 2000 m

% targetsOut =  'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_leeward_20220121_auto';
% targetsOut =  'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_windward_20220121_auto';
% targetsOut = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_leeward_revised_20220503_auto';
% targetsOut = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_windward_revised_20220509_auto';
% targetsOut = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_leeward_revised_20220524_auto';
% targetsOut = 'C:\Users\Selene.Fregosi\Documents\UxS_HI_Glider\piloting\targets_windward_revised_20220524_auto';

targetsOut = fullfile(kmlPath, ['targets_' kmlName]);
fid = fopen(targetsOut, 'w');
% write the header text 
% fprintf(fid, '%s\n', '/ Glider survey plan for UxS HI April 2022 - Leeward Glider');
% fprintf(fid, '%s\n', '/ Deployment will take place at LW01, recovery at RECV');
fprintf(fid, '%s\n', '/ Glider survey plan for UxS MHI April 2023 - SG639 - Windward Glider');
fprintf(fid, '%s\n', '/ Deployment will take place at WW01, recovery at RECV');

fprintf(fid, '%s\n', '/ template WPxx lat=DDMM.MMMM lon=DDDMM.MMMM radius=2000 goto=WPo');
fprintf(fid, '%s\n', '/ radius set to 2000 m');

for f = 1:length(wpNames)-1
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s\n', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f+1});
end
f = length(wpNames);
fprintf(fid, '%s lat=%d%07.4f lon=%d%07.4f radius=2000 goto=%s', ...
    wpNames{f}, degMinLats(f,1), degMinLats(f,2), degMinLons(f,1), degMinLons(f,2), wpNames{f});
fclose(fid);

%% plot
glider = ['sg639']; % leeward
% glider = 'sg680'; % windward
latLim = [17 22];
lonLim = [-157 -152];
path_shp = 'C:\Users\Selene.Fregosi\Documents\GIS\';

plotGliderPath_etopo(glider, latLim, lonLim, pp, path_out, path_shp, figNum)


