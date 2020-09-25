function trackToShapefile(glider, deploymentStr, path_profile)


% Convert the glider track to a shape file that can be read in ARC
% load in the data from .mat files I already made (from gliderDataOutputs functions)
% build strucutures, and save them as shapefiles


%% IMPORT GLIDER LOCATIONS AND MAKE SHAPEFILE

% cols = min, instr, pam, latitude, longitude, dive, depth, easting,
% northing

% harder to build because cells are annoying....
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
shpBaseName = [path_profile glider '_' deploymentStr '_points'];
shapewrite(pts, shpBaseName);
% could remove nans this way...
% [nanTestx nanTesty] = removeExtraNanSeparators(SG607LocLL(:,1), SG607LocLL(:,2));

% now make SG tracklines shape file (plot faster, get lengths, durations,
% etc)
% first split the bits up
[ty, tx] = polysplit(t.latitude, t.longitude);
t.dateTime(isnan(t.dive)) = NaT;
t.dn = datenum(t.dateTime);
[~, tm] = polysplit(t.dive, t.dn);

% specify as line, length of split bits
[trk(1:length(ty)).Geometry] = deal('Line');
[trk(:).Lat] = ty{:};
[trk(:).Lon] = tx{:};
tmpDive = num2cell(unique(t.dive(~isnan(t.dive))));
[trk(:).Name] = tmpDive{:};
[trk(:).Dive] = tmpDive{:};

for f = 1:length(ty)
    len_km = deg2km(distance(trk(f).Lat(1), trk(f).Lon(1), ...
        trk(f).Lat(end), trk(f).Lon(end)));
    trk(f).Length_km = len_km;
    dur_min = ((tm{f}(end) - tm{f}(1))*86400 + 60)/(60); % in MINUTES
    trk(f).Dur_min = dur_min;
    trk(f).StartTime = datestr(tm{f}(1));
    trk(f).EndTime = datestr(tm{f}(end));
end
shpBaseName = [path_profile glider '_' deploymentStr '_tracks'];
shapewrite(trk, shpBaseName);

% want to save individual minutes for each lat/lon point that makes up each
% track line, but cannot save cells as attributes in geo structures
save([path_profile glider '_' deploymentStr '_trackMinutes.mat'], 'tm')
% so save it on its own


