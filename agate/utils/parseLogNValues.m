function vals = parseLogNValues(x, string, N)
% PARSELOGNVALUES   Parse N comma-separated values from a log entry
%
%   Syntax:
%       VALS = PARSENLOGTOBREAK(X, STRING, N)
%
%   Description:
%       Parse up to N values following a log parameter string, up to the
%       next line break. Works for entries like:
%           $INTERNAL_PRESSURE,8.4,8.9,9.0
%
%   Inputs:
%       x       character string of log
%       string  log parameter to search for (e.g., '$INTERNAL_PRESSURE')
%       N       number of values to parse
%
%   Outputs:
%       vals    1xN numeric array (NaN for missing/unparsable values)
%
%   Example:
%       vals = parseLogNValues(x, '$INTERNAL_PRESSURE', 2);
%
%   See also PARSELOGTOBREAK
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   31 January 2026
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    N = 1; % default to one value (backward-compatible)
end

vals = nan(1,N); % preallocate

% Find parameter in log
idx = strfind(x, [string, ',']);
sl  = length(string);

if isempty(idx)
    return
end

% Find line break
idxBreak = regexp(x(idx+sl+1:end), '\n', 'once');
if isempty(idxBreak)
    idxBreak = length(x) - idx - sl; % if no line break, go to end of string
end
idxBreak = idxBreak + idx + sl;

% Extract value string
valStr = x(idx+sl+1 : idxBreak-1);

% Split by commas
parts = strsplit(valStr, ',');

% Convert first N values to numbers
for k = 1:min(N, numel(parts))
    v = str2double(parts{k});
    if ~isnan(v)
        vals(k) = v;
    end
end

end