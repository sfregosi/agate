function interpTrackToShapefile(glider, deploymentStr, path_profile, path_save)

% import glider interpolated locations (1 min) and make a shapefile
% for Navy deliverables/import into ArcGIS

% creates a points shape file
    % with pam status on/off, depth, dive num, and time. 
% and a track shape file
    % with 

    if nargin < 4
        path_save = path_profile;
    end
    
load([path_profile glider '_' deploymentStr '_interpolatedTrack.mat']);

%% points output

% make temporary table to remove nans (need nans for track below)
t = sgInterp;
t = t(~isnan(t.latitude),:);

[pts(1:height(t)).Geometry] = deal('Point');
latTmp = num2cell(t.latitude);
[pts(:).Lat] = latTmp{:};
lonTmp = num2cell(t.longitude);
[pts(:).Lon] = lonTmp{:};
[pts(:).Name] = deal(glider);
% minTmp = num2cell(t.min); % can't use datetimes in geostructures
% [SGPts(:).Min] = minTmp{:};
minStrTmp = cellstr(datestr(t.dateTime));
[pts(:).MinStr] = minStrTmp{:};
diveTmp = num2cell(t.dive);
[pts(:).Dive] = diveTmp{:};
depthTmp = num2cell(t.depth);
[pts(:).Depth] = depthTmp{:};
pamTmp = num2cell(t.pam);
[pts(:).PAM] = pamTmp{:};

clearvars latTmp lonTmp minStrTmp diveTmp depthTmp pamTmp

shpBaseName = [path_profile glider '_' deploymentStr '_interpPoints'];
shapewrite(pts, shpBaseName);

%% track output 
% now make SG tracklines shape file (plot faster, get lengths, durations,
% etc)
% first split the bits up
[ty, tx] = polysplit(sgInterp.latitude, sgInterp.longitude);
sgInterp.dateTime(isnan(sgInterp.dive)) = NaT;
sgInterp.dn = datenum(sgInterp.dateTime);
[~, tm] = polysplit(sgInterp.dive, sgInterp.dn);

% specify as line, length of split bits
[trk(1:length(ty)).Geometry] = deal('Line');
[trk(:).Lat] = ty{:};
[trk(:).Lon] = tx{:};
tmpDive = num2cell(unique(sgInterp.dive(~isnan(sgInterp.dive))));
[trk(:).Name] = tmpDive{:};
[trk(:).Dive] = tmpDive{:};
% [trk(:).Min] = tm{:};

for f = 1:length(ty)
    len_km = deg2km(distance(trk(f).Lat(1), trk(f).Lon(1), ...
        trk(f).Lat(end), trk(f).Lon(end)));
    trk(f).Length_km = len_km;
    dur_min = ((tm{f}(end) - tm{f}(1))*86400 + 60)/(60); % in MINUTES
    trk(f).Dur_min = dur_min;
    trk(f).StartTime = datestr(tm{f}(1));
    trk(f).EndTime = datestr(tm{f}(end));
end

shpBaseName = [path_save glider '_' deploymentStr '_interpTracks'];
shapewrite(trk, shpBaseName);


