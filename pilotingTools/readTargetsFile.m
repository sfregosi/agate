function targets = readTargetsFile(glider, path_out)

% path_out = ['C:\Users\selene\Box\HDR-SOCAL-2018\piloting\' glider '\'];

if strcmp(glider, 'sg607')
%     x = fileread([path_out 'targets_' glider '_offshore_20200206']);
%     x = fileread([path_out 'targets_' glider '_offshore_20200314']);
        x = fileread([path_out 'targets_' glider '_offshore_20200326']);
elseif strcmp(glider, 'sg639')
    x = fileread([path_out 'targets_' glider '_inshore']);
end
idx = regexp(x, '\/');
idxBreak = regexp(x(idx(end):end), '\n');
idxBreak = idxBreak + idx(end);

numTargets = length(idxBreak);

targets = table;
warning off
for t = 1:numTargets
    idxPeriod = regexp(x(idxBreak(t):end), '\.');
    idxSpace = regexp(x(idxBreak(t):end), '\s');
    targets.name{t} = x(idxBreak(t):idxBreak(t) + idxSpace(1)-2);
    idxLat = regexp(x(idxBreak(t):end), 'lat=', 'once');
    targets.lat(t) = str2num(x(idxLat + idxBreak(t) + 3:idxPeriod(1) + idxBreak(t) - 4)) ...
        + str2num(x(idxPeriod(1) + idxBreak(t) - 3:idxSpace(2) + idxBreak(t) - 2))/60;
    idxLon = regexp(x(idxBreak(t):end), 'lon=', 'once');
    targets.lon(t) = str2num(x(idxLon + idxBreak(t) + 3:idxPeriod(2) + idxBreak(t) - 4)) ...
        - str2num(x(idxPeriod(2) + idxBreak(t) - 3:idxSpace(3) + idxBreak(t) - 2))/60;
end


end