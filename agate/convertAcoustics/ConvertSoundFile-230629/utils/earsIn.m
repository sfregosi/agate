function [sams,nChans,sampleSize,sRate,nLeft,dt] = ...
                                      earsIn(filename, start, nframe, chans)
%earsIn   Read data from a EARS-format file (from George Ioup).
%
% [sams,nchan,sampleSize,sRate,nLeft,dt] = earsIn(filename, start, n, chans)
%    Read the EARS file format.
%    
%    Input arguments:
%      start      is the starting sample number; default is 0, meaning the
%                 first sample in the file
%      n          is the number of samples to read per channel; default is Inf,
%                 meaning read the entire file
%      chans      says which channels to read; default is all of them; channel
%                 numbering starts at 1
%
%    Output arguments:
%      sams       is a column vector of samples (or multi-column array, if
%                 chans's length is >= 2)
%      nchan      says how many channels are in the file (equals 1 for all
%                 extant EARS-format files, but who knows about the future)
%      sampleSize is the number of bytes per sample, 1 or 2
%      sRate      is the sampling rate, Hz
%      nLeft      is the number of sample frames remaining in the file after
%                 reading (use earsIn(filename, 0, 0) to get the total number
%                 of samples in the file)
%      dt         is the date/time in GMT that the file starts, encoded as
%                 in datenum
%
% Dave Mellinger
% 7 Feb 2003

persistent warned; if (isempty(warned)), warned = false; end

recSize = 512;				% record size, bytes
sampleSize = 2;
headerSize = 12;			% size of record header, bytes
recNFrames = (recSize - headerSize) / sampleSize;	% samples per record
crystalFreq = 3000000;			% crystal frequency, Hz
sRate = crystalFreq / 256;		% sampling rate, Hz

fd = fopen(filename, 'r', 'b');		% read-only; big-endian byte order
if (fd < 0)
  error(['Can''t open EARS-format file ' filename]);
end

f12 = fread(fd, 12, 'uchar');		% first 12 bytes

%Decode timestamp
if (0)
  if (~warned), warned=1; warning('earsIn:encoding', 'Using legacy date encoding'); end
  dum = bitshift(f12(7),-4);
  dum = bitshift(dum,4);
  dum = bitcmp(dum,'uint8');		% used to be 'dum = bitcmp(dum,8)'
  a = bitand(dum,f12(7));
  
  timecode = f12(11) + f12(10)*2^8 + f12(9)*2^16 + f12(8)*2^24 + a*2^32;
  timecode = timecode*0.008;		%convert from 8ms units to seconds
  
  %Include 25kHz in time!!  (variable "timecode" is in seconds )
  timecode = timecode + f12(12) * .000040;
  
  % timecode is now the number of seconds since 1/1/1990.
  dt = datenum(1990,1,1,0,0,timecode);		% new encoding
  %dt = datevec(datenum(1990,1,1,0,0,timecode));	% old encoding, which was...
  %dt(1) = dt(1) - 1900;				% ...a funky sort of vector
else
  if (~warned), warned=1; warning('earsIn:encoding', 'Using LADC-GEMM date encoding'); end
  dt = EARStimeheader_to_datenumber(f12);
end

fseek(fd, 0, 'eof');
nBytes = ftell(fd);
nFramesTotal = floor(nBytes / recSize) * recNFrames;
nChans = 1;

if (nargin < 2), start = 0;        end
if (nargin < 3), nframe = inf;     end
if (nargin < 4), chans = 1:nChans; end

nframe = min(nframe, nFramesTotal - start);   % prevent reading past EOF
nLeft = nFramesTotal - (start + nframe);

startRec = floor(start / recNFrames);
startSam = start - startRec * recNFrames;
nSamHere = recNFrames - startSam;

fseek(fd, startRec * recSize + startSam * 2 + headerSize, 'bof');
sams = zeros(nframe, 1);
ix = 1;
while (nframe > 0)
  nSamHere = min(nSamHere, nframe);
  sams(ix : ix+nSamHere-1) = fread(fd, nSamHere, 'int16');
  ix = ix + nSamHere;
  nframe = nframe - nSamHere;
  fseek(fd, headerSize, 'cof');
  nSamHere = recNFrames;
end
