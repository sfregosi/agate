function makeKMLContour(CONFIG, depth)
% MAKEKMLCONTOUR	One-line description here, please
%
%   Syntax:
%       OUTPUT = MAKEKMLCONTOUR(INPUT)
%
%   Description:
%       Detailed description here, please
%       REQUIRES NEW FILE EXCHANGE THING!!!!
%
%   Inputs:
%       input   describe, please
%
%	Outputs:
%       output  describe, please
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   01 June 2023
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[fn, path] = uigetfile(fullfile(CONFIG.path.shp, '*.tif;*.tiff'), ...
	'Select etopo raster file');
bathyFile = fullfile(path, fn);

[Z, refvec] = readgeoraster(bathyFile, 'OutputType', 'double', ...
	'CoordinateSystemType', 'geographic');


LAT = refvec.LatitudeLimits(1)+refvec.CellExtentInLatitude/2:refvec.CellExtentInLatitude:refvec.LatitudeLimits(2);
LON = refvec.LongitudeLimits(1)+refvec.CellExtentInLongitude/2:refvec.CellExtentInLongitude:refvec.LongitudeLimits(2);
kml_contour(LON, LAT, flipud(Z), [depth depth]);


