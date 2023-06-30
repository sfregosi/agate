function [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
                              sdatIn(filename, startFrame, nFrames, chans)
%sdatIn   Read data from an SDAT-format file (.sdat; from NOAA/PMEL lab).
%
% [sams,nchan,sampleSize,sRate,nLeft,dt] = sdatIn(filename, start, n, chans)
%    Read Andy Lau's SDAT file format (the NOAA/PMEL acoustics).  Such files
%    typically have names like 00000318.SDAT.  These are time-corrected .DAT
%    files, with the best-estimate (most accurate) timestamp in each block
%    header every 256 samples.  HOWEVER, the timestamps in the the first 1 s of
%    data in each file might be wrong, so we use later ones.
%    
%    Input arguments:
%      filename   input file to read
%      start      starting sample number; default is 0, meaning the
%                 first sample in the file
%      n          number of samples to read per channel; default is Inf,
%                 meaning read the entire file
%      chans      which channels to read; default is all of them; channel
%                 numbering starts at 1
%
%    Output arguments:
%      sams       column vector of samples (or multi-column array, if
%                 length(chans) >= 2)
%      nChans     how many channels are in the file (equals 1 for all
%                 extant SDAT-format files, but who knows about the future)
%      sampleSize is the number of bytes per sample, 1 or 2
%      sRate      sampling rate, Hz, calculated from best-available timestamps
%      nLeft      number of sample frames remaining in the file after reading;
%                 use sdatIn(filename,0,0) to get total number of sample frames
%                 in file
%      dt         date/time (in GMT) that the file starts, encoded as
%                 in datenum
%      endDt      date/time (in GMT) that the file ends (i.e., the time of the
%                 sample after the last sample), encoded as in datenum
%
% Dave Mellinger
% Aug. 2013

% See "C:\Dave\sounds\fileFormatExamples\Vents_SDAT_Mata09-10_H31\TSFdataFormat.html"
%
% There are multiple time-date strings in SDAT files.  Ignore the ones in the
% file header (first 256 bytes) -- they are the uncorrected ones from the
% original .DAT files.  Also ignore any in the first second of data, since they
% may come before the initial PPS signal and are thus [bad] guesses about the
% time.  Thus, use one after the first 1 s of data.

fd = fopen(filename, 'r', 'b');   % read-only; big-endian byte order
if (fd < 0)
  error(['Can''t open SDAT-format file ' filename]);
end

f12 = char(fread(fd, 12, 'uchar').');      % first 12 bytes
if (~strcmpi(f12(1:3), 'bir'))
  fclose(fd);
  error('Not an SDAT-format file.');
end

% SDAT format.  Get date from first file block.
if (0)
  fseek(fd, 256+32+1, 'bof');          %#ok<UNRCH> % where date string starts
  dt = sdatDateStringToDate(fread(fd, 21, '*char').');
end

% Read rest of long-form SDAT header.
fseek(fd, 222, 'bof');
nChans     = fread(fd, 1, 'short');
sRateEst   = fread(fd, 1, 'short');
sampleType = fread(fd, 1, 'short');
if (sampleType ~= 0 && sampleType ~= 2 && sampleType ~= 3)
  fclose(fd);
  error(['Unknown sample type in SDAT-format file ' filename]);
end
sampleSize  = iff(sampleType==0, 1, 2);  % 0==>1 byte/sam, 2&3==>2 byte/sam
precision   = iff(sampleType==0, 'uchar', iff(sampleType==2,'short','ushort'));
valueOffset = iff(sampleType==0, 128, iff(sampleType==2, 16384-109, 32768));
% -109 is right for Albatross bank phone.

if (nargin < 2), startFrame = 0;   end
if (nargin < 3), nFrames = inf;    end
if (nargin < 4 || isnan(chans)), chans = 1:nChans; end

% Read block-format information.
origHdrSize = 256;                    % bytes; original (DAT) file header
headerSize = origHdrSize+32;          % bytes
blockHdrSize = 32;                    % bytes
fseek(fd, origHdrSize, 'bof');
blockSize = fread(fd, 1, 'uint16');   % bytes
totBlocks = fread(fd, 1, 'uint16');
totSams   = fread(fd, 1, 'uint32');   % sams per chan or sams for all chans??
blockLenSams = (blockSize - blockHdrSize) / sampleSize;
blockLenFrames = blockLenSams / nChans;

% Read start-time from the first block after the first 2 s of data.  Use 2 s,
% not 1 s, because the known sample rate is only nominal and might be off a bit.
blkN = ceil((2.0 * sRateEst + 1) / ((blockSize-blockHdrSize) / sampleSize));
blkN = max(0, min(blkN, totBlocks-1));
frmN = blkN * blockLenFrames;
fseek(fd, headerSize + blockSize*blkN + 1, 'bof');
dt2 = sdatDateStringToDate(fread(fd, 21, '*char').');

% Read end-time from file.
fseek(fd, origHdrSize+8+1, 'bof');          % skip orig header, 3 numbers, '$'
endStr = fread(fd, 21, '*char').';
endDt = sdatDateStringToDate(endStr);

% Calculate sample rate based on time and number of samples from dt2 to endDt.
totFrames = totSams / nChans;
sRate = (totFrames - frmN) / ((endDt - dt2) * 24*60*60);

% Use sample rate to calculate best guess of time of first sample in file.
dt = dt2 - (frmN / sRate / (24*60*60));

nFrames = min(nFrames, totFrames - startFrame);
endFrame = iff(isinf(nFrames), totSams/nChans, startFrame + nFrames);
startBlk = floor(startFrame / blockLenFrames);
endBlk   = floor(endFrame   / blockLenFrames);
startOff = startFrame - startBlk * blockLenFrames;     % in frames
endOff   = endFrame   - endBlk   * blockLenFrames;     % in frames
if (endOff == 0)
  endBlk = endBlk - 1;
  endOff = blockLenFrames;                                        %#ok<NASGU>
end
endBlk = max(endBlk, startBlk);                  % for case where nFrames=0
fseek(fd, headerSize + startBlk * blockSize, 'bof');
sams = fread(fd, [blockSize/sampleSize (endBlk - startBlk + 1)], precision);
fclose(fd);


if (0)
  printf                                                       %#ok<UNRCH>
  for i = 1 : 5              %nCols(sams)-1
    t0str = char([floor(sams(1:16,i  ) / 256)'; mod(sams(1:16,i  ),256)']);
    t1str = char([floor(sams(1:16,i+1) / 256)'; mod(sams(1:16,i+1),256)']);
    t0 = sdatDateStringToDate(t0str(2:22));
    t1 = sdatDateStringToDate(t1str(2:22));
    printf('file block %05d: %.6f %.6f %.6f', i-1, ((t1-t0)*24*60*60))
    pause(0.5)
  end
end


sams(1 : blockHdrSize/sampleSize, :) = [];      % remove block headers
sams = reshape(sams, nChans, numel(sams) / nChans).';
sams = sams(:,chans) - valueOffset;
sams = sams(startOff + 1 : startOff + nFrames, :);
nLeft = totFrames - endFrame;

function dt = sdatDateStringToDate(str)
% Given a 21-character SDAT date string like '2010-105 10:05:09.125',
% return the corresponding date number (datenum format).
dt = datenum([str(1:4) '-01' str(5:end)]);
