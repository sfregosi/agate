function shp = contoursToShapefile(c)

% export contour lines as shapefile for deliverables

% from file exchange - reshape contours into different pieces
[x,y,z] = C2xyz(c);
% save as shp structure
shp = struct('Geometry', 'Line', 'Lon', x, 'Lat', y, 'Z', num2cell(z));






end