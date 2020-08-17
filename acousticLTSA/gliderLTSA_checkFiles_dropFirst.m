function ltsaParams = gliderLTSA_checkFiles_dropFirst(ltsaParams,soundFiles)
%
% Function to pull in specified ltsaParams and check them, plus calculate
% some additional parameters based on those defined and based on actual
% file lengths, etc.
%
% slow because it reads in every file

% drop first means it drops the first file of each because naming is off. I
% THINK that all names besides the first should be 7-8 sec later. But for
% now just drop first file and use times as names in files. 

%
%

tic
fprintf(1,'Checking %i files.\n',length(soundFiles)); 
% this is slow because so many files...
% because of speed worth pulling this out as a function and turning it in
% to a "header" of sorts.

% -----------------------------------------------------------------------
% file names and number of files
ltsaParams.fNames       = cellstr(char(soundFiles.name));
ltsaParams.fCount       = size(ltsaParams.fNames,1);
if strcmp(ltsaParams.fType, '.flac')
    ltsaParams.fStartTimes = cellfun(@(x) x(7:end-5), ltsaParams.fNames, 'UniformOutput', false);
    ltsaParams.fStartTimes = datenum(ltsaParams.fStartTimes,'yymmdd_HHMMSS');
elseif strcmp(ltsaParams.fType, '.wav')
    ltsaParams.fStartTimes = cellfun(@(x) x(1:end-4), ltsaParams.fNames, 'UniformOutput', false);
    ltsaParams.fStartTimes = datenum(ltsaParams.fStartTimes,'yymmdd-HHMMSS');
%     disp('fix datenum format');
elseif strcmp(ltsaParams.fType, 'x.wav')
    ltsaParams.fStartTimes = cellfun(@(x) x(16:end-6), ltsaParams.fNames, 'UniformOutput', false);
    ltsaParams.fStartTimes = datenum(ltsaParams.fStartTimes,'yymmdd_HHMMSS');
else
    disp('file type error\n');
end

% ----------------------------------------------------------------------
% define deployment/ltsa sampling rate, nfft and window size/shape
info = audioinfo([soundFiles(1).folder '\' soundFiles(1).name]);
ltsaParams.fs           = info.SampleRate;
% for absolute levels, nfft MUST = fs;
ltsaParams.nfft         = ltsaParams.fs;
% ltsaParams.nfft = ltsaParams.fs/ltsaParams.fBinSize;
ltsaParams.window       = hanning(ltsaParams.nfft);
ltsaParams.noverlap     = round((ltsaParams.overlap/100)*ltsaParams.nfft); % in samples

% compression/averaging number of samples, bins, etc
ltsaParams.cFact        = ltsaParams.tAvg*ltsaParams.fBin;
ltsaParams.sampPerAvg   = ltsaParams.tAvg*ltsaParams.fs;
ltsaParams.nFreq        = floor((ltsaParams.fs/ltsaParams.fBin)/2); %divide by 2 bc one sided; floor deals with 125kHz fs
ltsaParams.fBins        = [1:ltsaParams.fBin:ltsaParams.fs/2]';


% ----------------------------------------------------------------------
% timing between files
% look at timing between files should be 119 sec or greater
% because if there is a gap...name will be much later,
% otherwise it should be 120 sec/file dur
% sometimes it gets rounded down to 119...so use 112 as cut off.
fDiff = diff(ltsaParams.fStartTimes)*86400;
ff = find(fDiff < info.Duration - 5); % should equal number of dives? Wispr system on/off

% remove the files that names are wrong (start of dives)
ltsaParams.fCount = ltsaParams.fCount - length(ff);
ltsaParams.fStartTimes(ff) = [];
ltsaParams.fNames(ff) = [];
% -----------------------------------------------------------------------
% check bits, lengths, sample rates of ALL files + calc # avgs per file
% preallocate for speed
ltsaParams.fNumBits     = zeros(ltsaParams.fCount,1);
ltsaParams.fSampRate    = zeros(ltsaParams.fCount,1);
ltsaParams.fNumSamp     = zeros(ltsaParams.fCount,1);
ltsaParams.fDur         = zeros(ltsaParams.fCount,1);
ltsaParams.fNumAvg      = zeros(ltsaParams.fCount,1);
% ltsaParams.nch = zeros(ltsaParams.nsf,1);

% loop through all files and pull info (SLOW STEP)
corrFiles = [];
for f = 1:ltsaParams.fCount
    try
        info = audioinfo([soundFiles(f).folder '\' ltsaParams.fNames{f,:}]);
        ltsaParams.fNumBits(f)  = info.BitsPerSample;
        ltsaParams.fSampRate(f) = info.SampleRate;
        ltsaParams.fNumSamp(f)  = info.TotalSamples;
        ltsaParams.fDur(f)      = info.TotalSamples/info.SampleRate;
        ltsaParams.fNumAvg(f)   = ceil(info.TotalSamples/(ltsaParams.tAvg*info.SampleRate));
    catch
        fprintf('File error: %s\n', ltsaParams.fNames{f,:});
        corrFiles = [corrFiles; f];
    end
end

% ltsaParams.fullFileNumSamp = max(ltsaParams.fNumSamp);
% ltsaParams.fullFileDurRounded = ceil(ltsaParams.fullFileNumSamp/ltsaParams.fs);

ltsaParams.dropFirst = 'yes';
fprintf(1, 'Dropped %i files for %i dives\n', ...
    length(soundFiles) - ltsaParams.fCount, length(ff)); 

t = toc; % 40 seconds for 13550 LF files
fprintf(1,'Finished checking %i files in %.0f seconds.\n',length(ltsaParams.fNames),t);
