function splitT = splitProfiles(gpsSurfT, locCalcT)
% SPLITPROFILES	Create table of dive descent and ascent start/end times
%
%   Syntax:
%       SPLITT = SPLITPROFILES(CONFIG, GPSSURFT, LOCCALCT, THRESHOLD)
%
%   Description:
%       Creates a table of start and end times for each dive phase (descent
%       and ascent) based on the maximum dive depth for each dive. It
%       pulls information from gpsSurfT (max depth, dive start/end times)
%       and locCalcT (time max depth is reached) and combines them into a
%       single table with each phase's start/end time. Times are provided
%       in MATLAB datenum and datetime for easier exporting to a csv.
% 
%       This also adds a column to the locCalcT
%
%       Times are in MATLAB datenum and datetime.
%
%       This function was inspired by spilt_sg_profile.py by J. Marquardt.
%
%   Inputs:
%       threshold  [double] depth change rate (m/s) below which triggers a
%                  profile change. Default is 0.07
%
%	Outputs:
%       splitProfilesT     [table]
%
%   Examples:
%
%   See also SPLITPROFILESFAST
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 December 2025
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create output table
nDives = height(gpsSurfT);

phase = strings(2*nDives,1);
phase(1:2:end) = "descent";
phase(2:2:end) = "ascent";

splitT = gpsSurfT(repelem(1:height(gpsSurfT), 2), 1);
splitT.phase = categorical(phase);

% splitProfilesT = table('Size', [2*nDives 4], ...
%     'VariableTypes', {'int32', 'categorical', 'double', 'double'}, ...
%     'VariableNames', {'dive', 'phase', 'startTime', 'endTime'});

splitT.startTime = NaN(height(splitT), 1);
splitT.startDateTime = NaT(height(splitT), 1);
splitT.endTime = NaN(height(splitT), 1);
splitT.endDateTime = NaT(height(splitT), 1);

% loop through each row/phase
for f = 1:height(splitT)

    % find max depth time for this dive
    locCalcTmp = locCalcT(locCalcT.dive == splitT.dive(f), :);
    maxIdx = find(locCalcTmp.depth == gpsSurfT.maxDepth_m(splitT.dive(f)), ...
        1, 'last');

    if ~isempty(maxIdx)
        % fill in times
        if splitT.phase(f) == 'descent'
            splitT.startTime(f) = gpsSurfT.startTime(gpsSurfT.dive == splitT.dive(f));
            splitT.startDateTime(f) = gpsSurfT.startDateTime(gpsSurfT.dive == splitT.dive(f));
            splitT.endTime(f) = locCalcTmp.time(maxIdx);
            splitT.endDateTime(f) = locCalcTmp.dateTime(maxIdx);
        elseif splitT.phase(f) == 'ascent'
            splitT.startTime(f) = locCalcTmp.time(maxIdx);
            splitT.startDateTime(f) = locCalcTmp.dateTime(maxIdx);
            splitT.endTime(f) = gpsSurfT.endTime(gpsSurfT.dive == splitT.dive(f));
            splitT.endDateTime(f) = gpsSurfT.endDateTime(gpsSurfT.dive == splitT.dive(f));
        end

    end
end

end