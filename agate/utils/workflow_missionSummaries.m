% WORKFLOW_MISSIONSUMMARIES.M
%	Example workflow to create simple mission summary tables
%
%	Description:
%		Generate glider performance/operational summary outputs. This
%		workflow is meant to show how to create a table for multiple
%		simultaneous glider missions but could be used for a single mission
%		too. 
%
%       (1) General Summary. Read in gpsSurfT tables for each glider,
%       extract start/end dates, calculate number of days deployed,
%       distance over ground covered, number of dives, and save as summary
%       table/csv. Requires gpsSurfT table created with the function
%       extractPositionalData (see workflow_processPositionalData.m)
%       (2) Load in PAM effort tables and also summarize total
%       recording duration and the percent of possible hours with
%       recordings. This requires pamMinPerHour created with the function
%       extractPAMStatus (See workflow_acousticEffort.m)
%
%	Notes
%
%	See also
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   3 January 2025
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% *agate is not require for this script but it could be used to define
% mission paths. A config would have to be loaded on each loop iteration.
% Alternatively paths can be manually defined here. 

% path to location where each glider's mission folder lives e.g., if 
% gpsSurfT is in C:\Users\User.Name\Desktop\sgXXX_Mon20XX\profiles, use:
% (loop assumes gpsSurfT is within a profiles folder in a mission folder)
path_missions = fullfile('C:\Users\User.Name\Desktop\');
% path to save .csvs
path_out = fullfile('C:\Users\User.Name\Desktop\', 'project_outputs');

% mission strings to include
missionStrs = {'sgXXX_Loc_Mon20XX';
    'sgXXX_Loc_Mon20XX';
    'sgXXX_Loc_Mon20XX'};

%% (1) General summary

out_vars = [{'glider', 'string'}; ...
    {'startDateTime', 'datetime'}; ...
    {'endDateTime', 'datetime'}; ...
    {'numDives', 'double'}; ...
    {'durDays', 'double'}; ...
    {'dist_km', 'double'}];

out = table('size', [length(missionStrs), size(out_vars,1)], ...
    'VariableNames', out_vars(:,1), 'VariableTypes', out_vars(:,2));

for m = 1:length(missionStrs)
    missionStr = missionStrs{m};
    % pull year from string
    yrStr = missionStr(end-3:end);

    % define path to 'profiles' folder with processed tables
    path_profiles = fullfile(path_missions, missionStr, 'profiles');

    % load gpsSurfT 
    % (created with agate, using workflow_processPositionalData)
    load(fullfile(path_profiles, [missionStr '_gpsSurfaceTable.mat']))

    % calculate mission summary stats
    out.glider{m} = missionStr(1:5);
    out.startDateTime(m) = gpsSurfT.startDateTime(1);
    out.endDateTime(m) = gpsSurfT.endDateTime(end);
    out.numDives(m) = max(gpsSurfT.dive);
    out.durDays(m) = round(days(out.endDateTime(m)-out.startDateTime(m)));
    out.dist_km(m) = round(sum(gpsSurfT.distance_km, 'omitnan'), 1);
end

writetable(out, fullfile(path_out, 'missionSummaryTable.csv'));

%% (2) Include PAM summary

out_vars = [{'recDur_hr', 'double'}; ...
    % 	{'possHrs', 'double'}; ...
    {'recPercent', 'string'}; ...
    % {'recDays', 'string'} ...
    ];

% append to existing table
out_pam = table('size', [length(missionStrs), size(out_vars,1)], ...
    'VariableNames', out_vars(:,1), 'VariableTypes', out_vars(:,2));
out = [out out_pam];

for m = 1:length(missionStrs)
    missionStr = missionStrs{m};

    % define path to 'profiles' folder with processed tables
    path_profiles = fullfile(path_missions, missionStr, 'profiles');
    % load pam effort tables
    load(fullfile(path_profiles, [missionStr '_pamEffort.mat']));

    % pam summary stats
    out.recDur_hr(m) = round(sum(pamMinPerHour.pam, 'omitnan')/60, 1);
    out.recPercent{m} = sprintf('%i%%', ...
        round(out.recDur_hr(m)/ ...
        (hours(out.endDateTime(m) - out.startDateTime(m)))*100));
end

writetable(out, fullfile(path_out, 'missionSummaryTable_PAM.csv'));