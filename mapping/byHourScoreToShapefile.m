function byHourScoreToShapefile(glider, deploymentStr, species, byHour, path_save)

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
hrStrTmp = cellstr(datestr(byHour.hour));
[pts(:).Hour] = hrStrTmp{:};
recMinsTmp = num2cell(byHour.recMins);
[pts(:).RecordedMinutes] = recMinsTmp{:};
presenceTmp = num2cell(byHour.presence);
[pts(:).Presence] = presenceTmp{:};
scoreTmp = num2cell(byHour.score);
[pts(:).Detections] = scoreTmp{:};


shpBaseName = [path_save glider '_' deploymentStr '_' species '_byHour'];
shapewrite(pts, shpBaseName);

end
