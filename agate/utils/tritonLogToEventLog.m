function tls = tritonLogToEventLog(tlIn, prefix)
% TRITONLOGTOEVENTLOG	Reformat Triton log table to a simplified event log
%
%   Syntax:
%       TLS = TRITONLOGTOEVENTLOG(TLIN)
%       TLS = TRITONLOGTOEVENTLOG(TLIN, PREFIX)
%
%   Description:
%       Simplifies and reshapes a Triton log to an event log with the
%       correct formatting for processing with PAMpal into an AcousticStudy
%       object. It appends a unique event ID to each event, that contains
%       the glider's serial (e.g., sg639) and then a sequential number in
%       time. This reorders and renames columns to be just include start,
%       end, sp (species), and id and it standardizes the datetime format.
%
%       TLIN may be:
%         - a collapsed log table (output 'tl' or 'tlm' from
%           COLLAPSETRITONLOG), with or without an existing 'eventID'
%           column
%         - a raw, uncollapsed Triton log table (as read directly from the
%           Triton logger xlsx via readtable)
%         - a string/char fullpath to a raw Triton log xlsx file, which
%           will be read in directly
%
%       When TLIN is raw/uncollapsed, each row is treated as its own event
%       (no merging of duplicate call types or nearby events) - use
%       use COLLAPSETRITONLOG first if needed.
%
%       If TLIN already has an 'eventID' column, it is used as-is and
%       PREFIX is ignored (with a warning). Otherwise eventID is built
%       as '<prefix>_<eventNum>', or just '<eventNum>' if no PREFIX
%       argument is given.
%
%   Inputs:
%       tlIn      table (collapsed or raw Triton log) or fullpath string
%                 to a raw Triton log xlsx
%       prefix    [string] optional prefix for the eventID column, e.g.
%                 'sg680'. If omitted or empty, eventID is just the
%                 zero-padded event number. Ignored if tlIn already has
%                 an eventID column.
%
%	Outputs:
%       tls    table of manually identified cetacean events formatted for
%              further processing with PAMpal with columns start, end,
%              species, and eventID. Time format is MM/dd/uuuu HH:mm:ss.
%
%   Examples:
%       [tl, tlm] = collapseTritonLog('E:\sg639_MHI_log_mw.xlsx', 15);
%       tls = tritonLogToEventLog(tlm, 'sg639');
%
%       % raw log, no collapsing, no prefix
%       tls = tritonLogToEventLog('E:\sg639_MHI_log_mw.xlsx');
%
%   See also COLLAPSETRITONLOG
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2026 August 12
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check arguments
if nargin < 2 || isempty(prefix)
    prefix = '';
end

% read table if input is fullpath string to log file
if ischar(tlIn) || isstring(tlIn)
    tlIn = readtable(char(tlIn));
end

if ~istable(tlIn)
    error('tritonLogToPampal:invalidInput', ...
        'tlIn must be a table, or a fullpath string to a raw Triton log xlsx.');
end

% check variable names of input table
vn = tlIn.Properties.VariableNames;

if all(ismember({'eventNum', 'start', 'stop', 'species'}, vn))
    % already a collapsed log (tl or tlm from collapseTritonLog)
    src = table;
    src.eventNum = tlIn.eventNum;
    src.start = tlIn.start;
    src.stop = tlIn.stop;
    src.species = tlIn.species;

    hasEventID = ismember('eventID', vn);
    if hasEventID
        src.eventID = tlIn.eventID;
    end

elseif all(ismember({'EventNumber', 'SpeciesCode', 'StartTime', 'EndTime'}, vn))
    % raw, uncollapsed Triton log - one output row per input row
    src = table;
    src.eventNum = (1:height(tlIn))';
    src.start = tlIn.StartTime;
    src.stop = tlIn.EndTime;
    src.species = tlIn.SpeciesCode;
    hasEventID = false;

else
    error('tritonLogToPampal:unrecognizedFormat', ...
        ['tlIn does not match a collapsed Triton log (eventNum/start/stop/' ...
        'species) or a raw Triton log (EventNumber/SpeciesCode/StartTime/' ...
        'EndTime).']);
end

% add eventID if needed
if ~hasEventID
    % no eventID column yet, make one
    % pad zeros based on largest event number, minimum 3 digits
    maxNum = max(src.eventNum);

    padWidth = max(3, floor(log10(double(maxNum))) + 1);
    fmt = sprintf('%%0%dd', padWidth);
    % build id strings
    eventStr = arrayfun(@(x) sprintf(fmt, x), src.eventNum, ...
        'UniformOutput', false);
    % eventStr = arrayfun(@(x) sprintf('%02d', x), src.eventNum, ...
    %     'UniformOutput', false);
    src.eventID = eventStr;
end

% add prefix if specified
if ~isempty(prefix)
    src.eventID = cellfun(@(x) [char(prefix) '_' char(x)], ...
        src.eventID, 'UniformOutput', false);
end

% create new output table
tls = src(:, {'start', 'stop', 'species', 'eventID'});
tls.Properties.VariableNames = {'start', 'end', 'sp', 'id'};
tls.start.Format = 'MM/dd/uuuu HH:mm:ss';
tls.end.Format = 'MM/dd/uuuu HH:mm:ss';

end % function end
