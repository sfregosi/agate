function pamFilePosits = extractPAMFilePosits(pamFiles, locCalcT, timeBuffer)
%EXTRACTPAMFILEPOSITS Extracts glider location for each acoustic file
%
%	Syntax:
%		PAMFILEPOSITS = EXTRACTPAMFILEPOSITS(CONFIG, PAMFILES, LOCCALCT)
%
%	Description:
%		Extract glider positional data for each acoustic file. Includes
%       depth, lat, lon, vertical velocity, horizontal velocity, speed, and
%       sound speed. Uses glider data sample closest to start of sound
%       file, up to an optional buffer time specified as 'timeBuffer'. If
%       not positional data is available within that buffer, no position is
%       provided for that file.
%
%	Inputs:
%       pamFiles   [table] name, start and stop time and duration of all
%                  recorded sound files
%       locCalcT   [table] glider fine scale locations exported from
%                  extractPositionalData
%       timeBuffer [double] optional argument to specify time (sec) around
%                  agiven file you are willing to accept a position.
%                  Default is 180 sec
%
%	Outputs:
%       pamFilePosits  [table] glider positional info at the start of each
%                      acoustic file
%
%	Examples:
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	Updated:        31 December 2024
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    timeBuffer = 180; % in seconds
end

% set up empty output table
pamFilePosits = table;
pamFilePosits.fileName = pamFiles.name;
pamFilePosits.fileStart = pamFiles.start;

% set up a row of nan's for situations with no sample match
noMatch = locCalcT(1,:);
noMatch(1,[1:2 4:end]) = array2table(NaN(1,width(locCalcT)-1));
noMatch.dateTime = NaT;

% fileDate = datetime(fileName(1:end-4),'InputFormat','yyMMdd-HHmmss');
for f = 1:height(pamFilePosits)
    % find the closest positional data after the file start
    % 	[m,i] = min(abs(pamFilePosits.fileStart(f)-locCalcT.dateTime));
    i = find(pamFilePosits.fileStart(f) <= locCalcT.dateTime, 1, 'first');
    if ~isempty(i)
        m = pamFilePosits.fileStart(f) - locCalcT.dateTime(i);
        if abs(m) < seconds(timeBuffer) % within buffer specified by timeBuffer
            pamFilePosits(f,3:width(locCalcT)+2) = locCalcT(i,:);
        elseif abs(m) > seconds(timeBuffer) % outside buffer
            fprintf(1, 'file %s closest time is > %i seconds\n', ...
                pamFilePosits.fileStart(f), timeBuffer)
            pamFilePosits(f, 3:width(locCalcT) + 2) = noMatch;
        else % error??
            fprintf(1, 'file %s error\n', pamFilePosits.fileStart(f))
            pamFilePosits(f, 3:width(locCalcT) + 2) = noMatch;
        end
    else
        fprintf(1, 'file %s starts after all possible glider times. \n', ...
            pamFilePosits.fileStart(f))
        pamFilePosits(f, 3:width(locCalcT) + 2) = noMatch;
    end
end

% add locCalc column names and clean up a bit
pamFilePosits.Properties.VariableNames(3:end) = locCalcT.Properties.VariableNames;
pamFilePosits.time = [];
pamFilePosits.Properties.VariableNames(4) = {'sampleDateTime'};

end
