function profileT = splitProfiles(gpsSurfT, locCalcT)
% SPLITPROFILES	Create table of dive descent and ascent start/end times
%
%   Syntax:
%       PROFILET = SPLITPROFILES(GPSSURFT, LOCCALCT)
%
%   Description:
%       Creates a table of start and end times and locations for each dive
%       phase (descent and ascent), representing individual profiles.
%       Splitting is based on the maximum dive depth for each dive. It
%       pulls information from gpsSurfT (max depth, dive start/end times
%       and locations) and locCalcT (time max depth is reached) and
%       combines them into a single table with each phase's start/end time
%       and location. Locations at the end of the descent/start of the
%       ascent and midpoint of each profile is calculated used straight
%       line interpolation between the dive start and end locations. Times
%       are given in MATLAB datenum and datetime for easier exporting to
%       csv.
%
%       This function was inspired by spilt_sg_profile.py by J. Marquardt.
%
%   Inputs:
%       gpsSurfT   [table] glider surface locations exported from
%                  extractPositionalData
%       locCalcT   [table] glider fine scale locations exported from
%                  extractPositionalData
%
%	Outputs:
%       profilesT  [table] Start and end times and locations of each
%                       profile
%
%   Examples:
%
%   See also SPLITPROFILESFAST
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2026 January 15
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create output table
nDives = height(gpsSurfT);

% fill in phase labels
phase = strings(2*nDives,1);
phase(1:2:end) = "descent";
phase(2:2:end) = "ascent";

profileT = gpsSurfT(repelem(1:height(gpsSurfT), 2), 1);
profileT.phase = categorical(phase);

% preallocate times and locations
profileT.startTime = NaN(height(profileT), 1);
profileT.startDateTime = NaT(height(profileT), 1);
profileT.endTime = NaN(height(profileT), 1);
profileT.endDateTime = NaT(height(profileT), 1);
profileT.startLatitude = NaN(height(profileT), 1);
profileT.startLongtitude = NaN(height(profileT), 1);
profileT.endLatitude = NaN(height(profileT), 1);
profileT.endLongitude = NaN(height(profileT), 1);

% loop through each row/profile
for f = 1:height(profileT)

    % find max depth time for this dive
    locCalcTmp = locCalcT(locCalcT.dive == profileT.dive(f), :);
    maxIdx = find(locCalcTmp.depth == gpsSurfT.maxDepth_m(profileT.dive(f)), ...
        1, 'last');
    % get straightline interpolation location at time of max depth
    maxLat = interp1([gpsSurfT.startTime(profileT.dive(f)) gpsSurfT.endTime(profileT.dive(f))], ...
        [gpsSurfT.startLatitude(profileT.dive(f)) gpsSurfT.endLatitude(profileT.dive(f))], ...
        locCalcTmp.time(maxIdx));
    maxLon = interp1([gpsSurfT.startTime(profileT.dive(f)) gpsSurfT.endTime(profileT.dive(f))], ...
        [gpsSurfT.startLongitude(profileT.dive(f)) gpsSurfT.endLongitude(profileT.dive(f))], ...
        locCalcTmp.time(maxIdx));

    if ~isempty(maxIdx)
        % fill in values
        if profileT.phase(f) == 'descent'
            profileT.startTime(f) = gpsSurfT.startTime(gpsSurfT.dive == profileT.dive(f));
            profileT.startDateTime(f) = gpsSurfT.startDateTime(gpsSurfT.dive == profileT.dive(f));
            profileT.endTime(f) = locCalcTmp.time(maxIdx);
            profileT.endDateTime(f) = locCalcTmp.dateTime(maxIdx);
            profileT.startLatitude(f) = gpsSurfT.startLatitude(gpsSurfT.dive == profileT.dive(f));
            profileT.startLongitude(f) = gpsSurfT.startLongitude(gpsSurfT.dive == profileT.dive(f));
            profileT.endLatitude(f) = maxLat;
            profileT.endLongitude(f) = maxLon;
        elseif profileT.phase(f) == 'ascent'
            profileT.startTime(f) = locCalcTmp.time(maxIdx);
            profileT.startDateTime(f) = locCalcTmp.dateTime(maxIdx);
            profileT.endTime(f) = gpsSurfT.endTime(gpsSurfT.dive == profileT.dive(f));
            profileT.endDateTime(f) = gpsSurfT.endDateTime(gpsSurfT.dive == profileT.dive(f));
            profileT.startLatitude(f) = maxLat;
            profileT.startLongitude(f) = maxLon;
            profileT.endLatitude(f) = gpsSurfT.endLatitude(gpsSurfT.dive == profileT.dive(f));
            profileT.endLongitude(f) = gpsSurfT.endLongitude(gpsSurfT.dive == profileT.dive(f));
        end

    end

% calculate mid times and mid locations for each phase
profileT.midTime = profileT.startTime  + (profileT.endTime - profileT.startTime)/2;
profileT.midDateTime = profileT.startDateTime + (profileT.endDateTime - profileT.startDateTime)/2;
profileT.midLatitude = profileT.startLatitude  + (profileT.endLatitude - profileT.startLatitude)/2;
profileT.midLongitude = profileT.startLongitude  + (profileT.endLongitude - profileT.startLongitude)/2;

end

end