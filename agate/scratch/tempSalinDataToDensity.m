% read in temp/salinity stuff from Andy
% calculate density
% sigma has no units...add 1000 to get it in kg/m3
% get min and max for the whole deployment

warning off
path_in = 'C:\Users\selene\Box\HDR-SOCAL-2018\piloting\';

fNames = dir([path_in '*.info']);
headerSpec = '%*s %f %*s %f %*[^\n]';
colNamesSpec = '%s %s %s %s';
dataSpec = '%f %f %f %f';
out = table;
outIdx = 0;

for f = 1:length(fNames)
    fid = fopen([path_in fNames(f).name],'r');
    for ll = 1:5 % 5 lat/lons to check
        outIdx = outIdx + 1;
        c = textscan(fid, headerSpec, 1); % reads to blank line
        [lat lon] = c{:};
        colNames = textscan(fid, colNamesSpec, 1);
        colNames = string(colNames);
        c = textscan(fid, dataSpec, 'CollectOutput',true);
        data = c{:};
        data = array2table(data, 'VariableNames', colNames);
        % this reads to the blank line, then repeat?
        data.density = density(data.Sal, data.Temp);
        data.densityP = densatp(data.Sal, data.Temp, data.Depth(1));
        
        [mi mx] = calcDensityRange(data, lat, lon);
%         fprintf(1,'%s Lat: %f Lon: %f min: %f and max: %f\n', ...
%             fNames(f).name, lat, lon, mi, mx)
        out.month{outIdx,1} = fNames(f).name(1:3);
        out.lat(outIdx,1) = lat;
        out.lon(outIdx,1) = lon;
        out.minSigma(outIdx,1) = mi;
        out.maxSigma(outIdx,1) = mx;
        out.minDens(outIdx,1) = min(data.density(data.Depth <= 1000,1));
        out.maxDens(outIdx,1) = max(data.density(data.Depth <= 1000,1));
        
    end
    fclose(fid);
end

min(out.minSigma)
max(out.maxSigma)

densRange = out;
save([path_in 'densityRanges.mat'],'densRange');


min(out.minDens)
max(out.maxDens)
