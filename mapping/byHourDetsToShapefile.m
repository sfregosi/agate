function byHourDetsToShapefile(glider, deploymentStr, species, byHour, path_save)

% take byHour table of baleen whale presence, reshape, and save as
% shapefile for deliverables/import to GIS

% creates a points shape file with:
% 1 glider location per hour (mean of all glider locs in that hour)
% recorded minutes in that hour
% animal presence (1 yes, 0 no)
% number of detections
% number of detections per hour (dets/rec mins in that hour)

[pts(1:height(byHour)).Geometry] = deal('Point');
latTmp = num2cell(byHour.latitude);
[pts(:).Lat] = latTmp{:};
lonTmp = num2cell(byHour.longitude);
[pts(:).Lon] = lonTmp{:};
[pts(:).Name] = deal(glider);
% minTmp = num2cell(t.min); % can't use datetimes in geostructures
% [SGPts(:).Min] = minTmp{:};
hrStrTmp = cellstr(datestr(byHour.hour));
[pts(:).Hour] = hrStrTmp{:};
recMinsTmp = num2cell(byHour.recMins);
[pts(:).RecordedMinutes] = recMinsTmp{:};
presenceTmp = num2cell(byHour.presence);
[pts(:).Presence] = presenceTmp{:};
numDetsTmp = num2cell(byHour.numDets);
[pts(:).Detections] = numDetsTmp{:};
detsPerHrTmp = num2cell(byHour.detsPerHour);
[pts(:).DetectionsPerHour] = detsPerHrTmp{:};


shpBaseName = [path_save glider '_' deploymentStr '_' species '_byHour'];
shapewrite(pts, shpBaseName);

end
