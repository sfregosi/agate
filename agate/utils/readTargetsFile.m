function targets = readTargetsFile(targetsFile)

%********* FIX THIS TO READ THE FILENAME!!!! *************
% path_out = ['C:\Users\selene\Box\HDR-SOCAL-2018\piloting\' glider '\'];

% if strcmp(glider, 'sg607')
% %     x = fileread([path_out 'targets_' glider '_offshore_20200206']);
% %     x = fileread([path_out 'targets_' glider '_offshore_20200314']);
%         x = fileread([path_out 'targets_' glider '_offshore_20200326']);
% elseif strcmp(glider, 'sg639')
%     x = fileread([path_out 'targets_' glider '_inshore']);
% end
x = fileread(targetsFile);

idx = regexp(x, '\/');
idxBreak = regexp(x(idx(end):end), '\n');
idxBreak = idxBreak + idx(end);

numTargets = length(idxBreak);

targets = table;
warning off

for t = 1:numTargets
    idxPeriod = regexp(x(idxBreak(t):end), '\.');
    idxLat = regexp(x(idxBreak(t):end), 'lat=', 'once');
    idxLon = regexp(x(idxBreak(t):end), 'lon=', 'once');
    idxRad = regexp(x(idxBreak(t):end), 'radius=', 'once');
    
    if ~isempty(idxLat)
        targets.name{t} = deblank(x(idxBreak(t):idxBreak(t) + idxLat - 2));
        targets.lat(t) = str2num(x(idxBreak(t) + idxLat + 3:idxPeriod(1) + idxBreak(t) - 4)) ...
            + str2num(deblank(x(idxPeriod(1) + idxBreak(t) - 3:idxBreak(t) + idxLon - 2)))/60;
        targets.lon(t) = str2num(x(idxLon + idxBreak(t) + 3:idxPeriod(2) + idxBreak(t) - 4)) ...
            - str2num(deblank(x(idxPeriod(2) + idxBreak(t) - 3:idxBreak(t) + idxRad - 2)))/60;
    end
end


end