function [tl, tlm] = collapseTritonLog(logFile, eventGap)
%COLLAPSETRITONLOG	Collapse a Triton log to have one entry per event
%
%   Syntax:
%       TL = COLLAPSETRITONLOG(FULLFILENAME)
%
%   Description:
%       Collapse/clean up a Triton log so there is just a single line/entry
%       per odontocete event. It merges duplicate lines where multiple
%       sound types are noted (e.g., clicks and whistles in a single UO
%       event) but they are from a single dated 'EventNumber'. Optional
%       argument to combine any events that occur within 'eventGap' mins
%       of one another. This merging by time is an optional argument by
%       setting 'eventGap' to 0 or leave out.
%
%   Inputs:
%       logFile    [string] fullpath filename to log to be processed. If no
%                  file is specified (no arguments) or is empty, or is
%                  incorrect, will prompt to select
%       eventGap   [integer] optional argument to combine events with the 
%                  same species ID code that are separated by less than the
%                  integer specified by eventGap
%
%   Outputs:
%       tl         table as a compressed triton log
%
%   Examples:
%       tl = collapseTritonLog('E:\sg639_MHI_log_mw.xlsx', 15);
% 
%   See also
%
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion:   15 February 2023
%	Updated:        6 June 2023
%
%	Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    eventGap = 0;
end

if nargin < 1
	logFile = [];
end

% agate CONFIG is not required, but if it is present, it will be used in
% file search path if needed
if exist('CONFIG', 'var')
	searchPath = CONIFG.path.mission;
else
	searchPath = cd;
end
% check file exists and if not prompt to select
if ~exist(logFile, 'file')
	[file, path] = uigetfile(fullfile(searchPath, '*.xlsx;*.xls'), 'Select Triton log file');
	logFile = fullfile(path, file);
end

% read in raw triton log xls
t = readtable(logFile);
% make sure sorted by start time
t = sortrows(t, 'StartTime');

% clean up EventNumber dates (these can vary depending on how the xls was
% saved/opened/viewed during the logging process)
t.EventNumber = dateshift(t.EventNumber, 'start', 'second');
% this can still end up with single events listed as 1 sec apart
for f = 1:height(t)-1
    diff = t.EventNumber(f+1) - t.EventNumber(f);
    if diff <= seconds(1) && diff > seconds(0) 
        t.EventNumber(f+1) = t.EventNumber(f);
    end
end

% get unique species codes
uSp = unique(t.SpeciesCode);
% unique call types
uCall = unique(t.Call);
% unique combo of both
spCallOnly = t(:,3:4);
uSpCall = unique(t(:,3:4), 'rows');

% simple collapse based on unique datetime values in EventNumber
[uEN, uIdx, ic] = unique(t.EventNumber, 'stable');
tl = table;
tl.eventNum = [1:length(uEN)]';
tl.start = t.StartTime(uIdx);
tl.stop = t.EndTime(uIdx);
tl.species = t.SpeciesCode(uIdx);
tl.call = cell(height(tl),1);
tl.eventDT = uEN;

for f = 1:height(tl)
    tl.call{f} = t.Call(ic == f);
end

fprintf(1, ['No event merging: %i unqiue species, %i unique call types,' ...
    ' %i unique events\n'], length(uSp), length(uCall), height(tl))

% merge by eventGap if non-zero
tlt = tl; % make a copy to modify in the below loop
tlm = table;
tlmIdx = 1;
if eventGap > 0
    while tlmIdx <= height(tlt)
        % set up extended event start and stop times
        startPlus = tlt.start(tlmIdx) - minutes(eventGap);
        stopPlus = tlt.stop(tlmIdx) + minutes(eventGap);
        % check if any rows overlap with this extended event time
        startYes = find(isbetween(tlt.start, startPlus, stopPlus));
        startYes = startYes(startYes ~= tlmIdx); % ignore actual event
        stopYes = find(isbetween(tlt.stop, startPlus, stopPlus));
        stopYes = stopYes(stopYes ~= tlmIdx); % ignore actual event
        
        % do stuff depending on outcome
        
        % if no overlaps
        if isempty(startYes) && isempty(stopYes)
            % just copy this entry to output
            tlm(tlmIdx,:) = tlt(tlmIdx, :);
            tlmIdx = tlmIdx + 1;
            
            % single overlap entries
        elseif length(startYes) == 1 && length(stopYes) == 1
            % and the single matches are identical meaning whole entry is
            % within buffer
            if startYes == stopYes
                % copy this entry to tlm
                tlm(tlmIdx,:) = tlt(tlmIdx, :);
                % double check that match doesn't start or end within
                % buffer (rather than actual entry)
                if tlt.start(startYes) < tlm.start(tlmIdx)
                    tlm.start(tlmIdx) = tlt.start(startYes);
                end
                if tlt.stop(stopYes) > tlm.stop(tlmIdx)
                    tlm.stop(tlmIdx) = tlt.stop(stopYes);
                end
                % remove the nested entry
                tlt(startYes,:) = [];
                tlmIdx = tlmIdx + 1;
            end
            
            % overlap only on start
        elseif  isempty(stopYes) && ~isempty(startYes)
            % single overlap
            if length(startYes) == 1
                % copy this entry to tlm
                tlm(tlmIdx,:) = tlt(tlmIdx, :);
                % check where the overlap happens
                if tlt.start(startYes) > tlm.stop(tlmIdx)
                    % next entry starts before end of this entry
                    % so replace end time with end time of next entry
                    tlm.stop(tlmIdx) = tlt.stop(startYes);
                    tlm.call{tlmIdx} = unique([tlt.call{tlmIdx}(:);
                        tlt.call{startYes}(:)]);
                end
                % remove the overlapping entry and update tlt to match tlm
                tlt(startYes,:) = [];
                tlt(tlmIdx,:) = tlm(tlmIdx,:);
                tlmIdx = tlmIdx + 1;
            elseif length(startYes) > 1
                fprintf('more than 1 overlap!')
            end
            
            % overlap only on stop
        elseif isempty(startYes) && ~isempty(stopYes)
            % single overlap
            if length(stopYes) == 1
                if stopYes < tlmIdx && tlm.stop(stopYes) < tlt.stop(tlmIdx)
                    % entry before previous entry ends before start or within
                    % buffer of this entry so update previous entry end time
                    tlm.stop(stopYes) = tlt.stop(tlmIdx);
                    tlm.call{stopYes} = unique([tlt.call{stopYes}(:);
                        tlt.call{tlmIdx}(:)]);
                    % remove overlapping entry, update tlt, do NOT advance
                    tlt(tlmIdx,:) = [];
                    tlt(stopYes,:) = tlm(stopYes,:);
                end
            elseif length(stopYes) > 1
                fprintf('more than 1 overlap!')
            end
        elseif length(startYes) > 1 && length(stopYes) > 1
            fprintf('more than 1 overlap!')
        elseif length(startYes) > 1 || length(stopYes) > 1
            fprintf('more than 1 overlap!')
        end
    end
    
    fprintf(1, ['Events merged within %i minutes: %i unqiue species, ' ...
        '%i unique call types, %i unique events\n'], ...
        eventGap, length(uSp), length(uCall), height(tlm))
    
end



end