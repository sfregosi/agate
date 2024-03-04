function [sams,nChans,sampleSize,sRate,nLeft,dt] = ...
                                  indexIn(indexName, startFrame, nFrame, chans)
%indexIn	read sounds via a file_dates file, pretending it's a sound file
%
% sams = indexIn(indexName, startFrame, nFrame)
%   indexName is a file_dates file. This function treats the complete
%   collection of files listed in the file_dates file as a single sound stream,
%   ASSUMING IT HAS NO GAPS, and returns the samples you ask for out of it. The
%   samples start at sample 'startFrame' from the beginning of the first file
%   and extend for 'nFrame' samples.
%
%   N.B.!!!: Be careful to specify a reasonable value for nFrame, as otherwise
%   I will try to assemble ALL of these files into a vector to return. If
%   it's a large dataset, MATLAB will completely choke!
%
% sams = indexIn(indexName, startFrame, nFrame, chans)
%   For files with multiple channels, you can also specify which channels you
%   want. Channel numbering starts at 0 (!).
%
% [sams,nChans,sampleSize,sRate,nLeft,dt] = indexIn( ... )
%   You can also get return arguments specifying the number of channels
%   present in the files, the sample size in bits, the sample rate in Hz, the
%   number of samples remaining across all the files (after startFrame+nFrame),
%   and the date of the beginning of the sample stream.
%
% See also makeHarufileDateIndex for format of an index file (or look at a
% file_dates file).


% A cache is used so we don't have to read the file_dates file every time
% this function is called. file_dates files are re-read any time they are
% modified (i.e., I check the modify date on the file_dates file every
% time), and of course a new cache entry is made if the indexName is
% different from anything currently in the cache.
persistent cache


listing = dir(indexName);		% has a last-modified-date field
cacheKey = [listing.date ' ' indexName];
p = cacheMatch(cache, cacheKey);
if (isempty(p))
  % Haven't read this indexName yet. Read the index, then read the first file
  % to get the sample rate, sample size, and number of channels.
  p = struct('hIndex', [], 'nChans', [], 'sampleSize', [], 'sRate', [], ...
      'modDate', [], 'nSamTotal', [], 'firstSamIx', []);
  p.hIndex = readHarufileDateIndex(indexName); % also reads Bilan/AURAL indices
  fn = fullfile(pathDir(p.hIndex.fname), p.hIndex.hname{1});
  [~,p.sRate,~,p.nChans,~,p.sampleSize] = soundIn(fn, 0, 0);
  p.firstSamIx = [0; cumsum(p.hIndex.nSamples)]; % first sample # of each file
  p.nSamTotal = sum(p.hIndex.nSamples);
  cache = cacheAdd(cache, cacheKey, p);
end

% Set defaults for missing/nan/inf input args.
if (nargin < 2), startFrame = 0; end
if (nargin < 3 || isnan(nFrame) || isinf(nFrame)), nFrame = p.nSamTotal; end
if (nargin < 4 || isnan(chans)), chans = 0 : p.nChans-1; end

%% Read the samples.
fileNo = find(p.firstSamIx <= startFrame, 1, 'last'); % first file to read from
fileStart = startFrame - p.firstSamIx(fileNo);  % where to start read in fileNo
sams = zeros(nFrame, length(chans));
samsIx = 0;			% where in sams[] to put the next samples
while (samsIx < nFrame)
  % nHere is the number of samples to read from this file: the lesser of number
  % of samples left that we need and number of remaining samples in file.
  nHere = min(nFrame - samsIx, p.hIndex.nSamples(fileNo) - fileStart);
  fn = fullfile(pathDir(indexName), p.hIndex.hname{fileNo});
  sams(samsIx+1 : samsIx+nHere) = soundIn(fn, fileStart, nHere, chans);
  samsIx = samsIx + nHere;
  fileNo = fileNo + 1;
  fileStart = 0;
end

%% Set up other return values.
nChans     = p.nChans;
sampleSize = p.sampleSize;
sRate      = p.sRate;
nLeft      = p.firstSamIx(end) - startFrame - nFrame;
dt         = min(p.hIndex.time);

%% This former method reads samples by date. But it didn't work because of
% non-exact dates, variations in sample rate between files, etc. Sample indices
% between files would be off by a handful.
% tStart = dt + startSam / sRate / secPerDay;
% tEnd = tStart + nFrame / sRate / secPerDay;
% sams = haruSoundAtTime([tStart tEnd], p.hIndex, pathDir(indexName));
% sams = sams{1};
% if (isempty(sams)), sams = zeros(0, length(chans));
% else sams = sams(:, chans + 1);
% end
















