function [gpsSurfT, locCalcT] = extractPAMStatusByFile_QUE(instr, lctn, dplymnt, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT)

% **********THIS NEEDS WORK!!!!!!!!!!!!!!!*******
% 

% PAM ON/OFF information for WISPR board QUEphones
% had to be modified from glider code...messy

% updates locCalcT .mat file (saves new one)
% updates gpsSurfT file (saves new one)
% creates PAMDurs .mat file

% Example inputs:
% instr = 'q003';
% lctn = 'CatBasin';
% dplymnt = 'Jul16';
% fileLength = seconds(120); % in seconds; either 120 or 80 for wispr
% sampleRate = 1000; % in Hz, runs fastest on downsampled 1 kHz data
% dateFormat = 'yyMMdd-HHmmss';
% dateStart = 1; % what part of file name starts the date format



%% initialization
warning off

% get num of samples per file (if max file length)
if fileLength == 120
    numSamples = 119931; % for 2 min file
elseif fileLength == 80
    numSamples = 79954; % for 1 min 20 sec files downsampled to 1000 hz
else
    fprintf('Unknown fileLength...aborting\n')
    return
end

% specify deployment date and time to ignore all files before that
% (sometimes test files recorded in lab are in dataset)
deplDate = gpsSurfT.startDateTime(1);

% select folder with sound files and were to save
% path_in = uigetdir('G:\','Select base folder');
path_acous = uigetdir('C:\', 'Select folder with 1 kHz acoustic data');
path_out = uigetdir(path_acous, 'Select profiles folder to save outputs');

%% Read in files and extract duration information
files=dir([path_acous '\*.wav']);
if isempty(files)
    fprintf('No .wav files found...aborting\n');
    return
    % *****later build in switch to flac??
    % files=dir([path_flac '*.flac']);
    
end

pam=table;
shortfiles=[];
fprintf(1,'%i files:\n',length(files));

% make matrix with start and end times for all PAM files
for f=1:length(files)
    % calc duration in sec using sampling rate..slow but works - more accurate
    try
        wavInfo = audioinfo([path_acous '\' files(f,1).name]); % faster
        y = [1:wavInfo.TotalSamples];
        Fs = wavInfo.SampleRate;
        files(f,1).dur=length(y)./Fs;
        if length(y) ~= numSamples % this is for 2 min files...
            shortfiles=[shortfiles; f length(y)];
            fprintf(1,'%s is short: %i\n',files(f,1).name,length(y));
        end
        % get start timing information from file name
        pam.fileStart(f,1) = datetime(files(f).name(dateStart:length(dateFormat)),'InputFormat',dateFormat);
        pam.fileEnd(f,1) = pam.fileStart(f,1) + seconds(files(f,1).dur);
        
    catch
        fprintf(1, '%s is empty\n',files(f,1).name);
        clear y Fs
    end
    if rem(f,1000)==0; fprintf(1,'%i DONE\n',f);end % counter
end

% remove all before deployment date
[r, ~] = find(pam.fileStart < deplDate,1,'last');
if ~isempty(r)
    pam = pam(r+1:end,:);
end

save([path_out '\' instr '_' lctn '_' dplymnt '_pamByFile.mat'],'pam');

%% Specify 1's and 0s per locCalcT row
% 1 if pam on, 0 if off

locCalcT.pam = zeros(height(locCalcT),1);
fprintf(1,'%s - %d samples:\n', [instr '_' lctn '_' dplymnt], height(locCalcT));
for f = 1:height(locCalcT)
    idx = find(isbetween(locCalcT.dateTime(f),pam.fileStart,pam.fileEnd),1);
    if ~isempty(idx)
        locCalcT.pam(f) = 1;
    end
    clear idx
    
    fprintf(1,'.');
    if (rem(f,80) == 0), fprintf(1,'\n%3d',floor((height(locCalcT)-f)/80)); end
end

save([path_out '\' instr '_' lctn '_' dplymnt '_locCalcT_pam.mat'],'locCalcT');
writetable(locCalcT, [path_out '\' instr '_' lctn '_' dplymnt '_locCalcT_pam.csv']);

% % plotting test
%  plotDiveProfile(locCalcT)

%% Calculate duration of files and Total Duration

pam.dur = pam.fileEnd - pam.fileStart;
totDur = nansum(pam.dur); % as datetime duration format
totDurHrs = hours(totDur);

fprintf('Total PAM duration: %.2f hours\n', totDurHrs);

save([path_out '\' instr '_' lctn '_' dplymnt '_pamByFile.mat'],'pam','totDur','totDurHrs');

%% duration per dive

pamByDive = table;
pamByDive.dive = gpsSurfT.dive;
pamByDive.diveStart = gpsSurfT.startDateTime;
pamByDive.diveEnd = gpsSurfT.endDateTime;

for f = 1:height(pamByDive)
    [r, ~] = find(pam.fileStart > pamByDive.diveStart(f),1,'first');
    pamByDive.pamStart(f,1) = pam.fileStart(r);
    [r, ~] = find(pam.fileEnd < pamByDive.diveEnd(f),1,'last');
    pamByDive.pamEnd(f,1) = pam.fileEnd(r);
end
pamByDive.pamDur = pamByDive.pamEnd - pamByDive.pamStart;
pamByDive.lagStart = pamByDive.pamStart - pamByDive.diveStart;
pamByDive.lagEnd = pamByDive.diveEnd - pamByDive.pamEnd;

save([path_out '\' instr '_' lctn '_' dplymnt '_pamByFile.mat'],'pam','totDur','totDurHrs','pamByDive');

% append to gpsSurfT and save
gpsSurfT.pamStart = pamByDive.pamStart;
gpsSurfT.pamEnd = pamByDive.pamEnd;
gpsSurfT.pamDur = pamByDive.pamDur;

save([path_out '\' instr '_' lctn '_' dplymnt '_gpsSurfaceTable_pam.mat'],'gpsSurfT');
writetable(gpsSurfT, [path_out '\' instr '_' lctn '_' dplymnt '_gpsSurfaceTable_pam.csv']);


