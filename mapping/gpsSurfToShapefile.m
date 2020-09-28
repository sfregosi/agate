function gpsSurfToShapefile(glider, deploymentStr, path_profile)

% import glider surface GPS locations and make a shapefile
% for Navy deliverables/import into ArcGIS

% points are labeled as either start or end of dive so drift at surface can
% be seen. Could just plot starts or ends to not have double points. 

load([path_profile glider '_' deploymentStr '_gpsSurfaceTable_pam.mat']);

% harder to build because cells are annoying....
[pts(1:2*height(gpsSurfT)).Geometry] = deal('Point');

for f = 1:height(gpsSurfT)
    diveNum = f;
    r = f*2 - 1;
    
    % dive start gps location
    pts(r).Lat = gpsSurfT.startLatitude(f);
    pts(r).Lon = gpsSurfT.startLongitude(f);
    pts(r).Time =  cellstr(datestr(gpsSurfT.startDateTime(f)));
    pts(r).Dive = diveNum;
    pts(r).Status = 'start';
    pts(r).PAMDur_hr = hours(gpsSurfT.pamDur(f));

    % dive end gps location
    pts(r+1).Lat = gpsSurfT.endLatitude(f);
    pts(r+1).Lon = gpsSurfT.endLongitude(f);
    pts(r+1).Time =  cellstr(datestr(gpsSurfT.endDateTime(f)));
    pts(r+1).Dive = diveNum;
    pts(r+1).Status = 'end';
    pts(r+1).PAMDur_hr = hours(gpsSurfT.pamDur(f));

end

shpBaseName = [path_profile glider '_' deploymentStr '_gpsSurfacePoints'];
shapewrite(pts, shpBaseName);

end

