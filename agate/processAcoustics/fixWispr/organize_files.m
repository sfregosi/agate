% organize files by dive, phase, etc, etc


% read in dive metadata - pp679
load('F:\sg679_MHI_May2023\piloting\flightStatus\diveTracking_sg679.mat');

% read in reprocessingStatus.xlsx
rs = readtable('D:\sg679_MHI_May2023\reprocessingStatus_original.xlsx', ...
	'Sheet', 'byDive', 'VariableNamesRow', 2);
rs.date = [];
rs.firstFile = num2cell(rs.firstFile);
rs.lastFile = num2cell(rs.lastFile);

% read in file lists (one each for descent and ascent SD cards)
fileListD = readtable('D:\sg679_MHI_May2023\dat\descentFileList.csv', ...
	'Delimiter', ' ', 'ReadVariableNames', false);
fileListD.Properties.VariableNames = {'file'};
fileListA = readtable('D:\sg679_MHI_May2023\dat\ascentFileList.csv', ...
	'Delimiter', ' ', 'ReadVariableNames', false);
fileListA.Properties.VariableNames = {'file'};

% get datetime from file timestamp
fileListD.dt = cellfun(@(x) datetime(x(7:19), 'InputFormat', 'yyMMdd_HHmmss'), ...
	fileListD.file);
fileListA.dt = cellfun(@(x) datetime(x(7:19), 'InputFormat', 'yyMMdd_HHmmss'), ...
	fileListA.file);

% get dive number for each file
for f = 1:height(fileListD)
	dIdx = find(isbetween(fileListD.dt(f), pp679.diveStartTime, pp679.diveEndTime));
	fileListD.dive(f) = pp679.diveNum(dIdx);
end

for f = 1:height(fileListA)
	dIdx = find(isbetween(fileListA.dt(f), pp679.diveStartTime, pp679.diveEndTime));
	fileListA.dive(f) = pp679.diveNum(dIdx);
end

% get first and last file for each dive/phase

dives = unique(rs.dive);
for f = 1:length(dives)
	dNum = dives(f);
	dsIdx = find(rs.dive == dNum & strcmp(rs.phase, 'descent'));
	rs.firstFile{dsIdx} = fileListD.file{find(fileListD.dive == dNum, 1, 'first')};
	rs.lastFile{dsIdx} = fileListD.file{find(fileListD.dive == dNum, 1, 'last')};
	rs.numFiles(dsIdx) = length(find(fileListD.dive == dNum));
	asIdx = find(rs.dive == dNum & strcmp(rs.phase, 'ascent'));
	rs.firstFile{asIdx} = fileListA.file{find(fileListA.dive == dNum, 1, 'first')};
	rs.lastFile{asIdx} = fileListA.file{find(fileListA.dive == dNum, 1, 'last')};
	rs.numFiles(asIdx) = length(find(fileListA.dive == dNum));
end

rs = sortrows(rs, 'dive');
writetable(rs, 'D:\sg679_MHI_May2023\reprocessingStatus_byDive.xlsx', ...
	'Sheet', 'byDive')

