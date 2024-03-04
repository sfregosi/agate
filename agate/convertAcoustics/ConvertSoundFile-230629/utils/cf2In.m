function [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
                                    cf2In(filename, startFrame, nFrames, chans)
%cf2In   Read data from Haru's CF2-format file (.dat; from NOAA/PMEL lab).
%
% [sams,nChans,sampleSize,sRate,nLeft,dt] = haruIn(filename, start, n, chans)
%    Read Haru Matsumoto's CF2 file format, which is one format of .DAT file.
%    Such files typically have names like 00000318.DAT, though there are other
%    formats of .DAT files (see haruIn.m).
%
%    Input arguments:
%      filename   name of file
%      start      starting sample number; default is 0, meaning the
%                 first sample in the file
%      n          number of samples to read per channel; default is Inf,
%                 meaning read the entire file
%      chans      which channels to read, but since this file format has only
%		  one channel, this should be 1; channel numbering starts
%		  at 1; default is 1
%
%    Output arguments:
%      sams       column vector of samples (or multi-column array, in the 
%                 theoretical case where length(chans) >= 2)
%      nChans     how many channels are in the file (equals 1 for all
%                 extant Haru-format files, but who knows about the future)
%      sampleSize number of bytes per sample, which is 2 for this format
%      sRate      sampling rate, Hz
%      nLeft      number of sample frames remaining in the file after
%                 reading (use cf2In(filename, 0, 0) to get the total number
%                 of samples in the file)
%      dt         date/time (in GMT) that the file starts, encoded as
%                 in datenum
%      endDt      date/time (in GMT) of the first sample after the end of the
%                 file, encoded as in datenum
%
% Note: Reading of .SDAT files is handled by sdatIn.m, which you can call
% directly if you like or do it via this function.
%
% See also haruIn, psmIn, sdatIn.
%
% Dave Mellinger
% Oct. 2015

%formerly: [ept,yr,jd,hr,mn,sc,samprate] = readCF2hdr(filename, datayes) 


%% Documentation from readCF2hdr.m:
%
%[ept,yr,jd,hr,mn,sc,samplerate]=readH3hdr('/dateDir/00000728.DAT',0); %return start time of file.
%[ept,yr,jd,hr,mn,sc,samplerate, t,y]=readH3hdr(''/dateDir/00000728.DAT',1);  % return start time and data.
% 
% OUTPUT 
% file start times from header 
% ept is unix time since 1970 
% yr, jd, hr, min, sc of start time 
% samprate from header (approx) 
% t= dummy time axis for plottting 
% y = time series in counts
%
% Note that t and samprate are approximate. 
% to get real sample rate difference file start times

%% Handle the arguments.

if (nargin < 2), startFrame = 0;   end
if (nargin < 3), nFrames    = inf; end
if (nargin < 4 || isnan(chans)), chans = 1; end

if (length(chans) ~= 1 || chans ~= 1)
  error('%s: I can handle only one-channel files.', mfilename);
end

fd = fopen(filename, 'r', 'b');	% open for reading, little-endian fmt
if (fd < 0)
  error('Unable to open this sound file for reading:\n%s', filename);
end

%% Get header stuff.
st1     = fseek(fd, 90,  'bof');				%#ok<NASGU>
timeStr = fread(fd, 64,  '*char').';	% GMT as a string
st2     = fseek(fd, 196, 'bof'  );				%#ok<NASGU>
sRate   = fread(fd, 1,   'long');	% sample rate

% Decode the GMT string.
yr = str2double(timeStr(1:3)) + 1900; 
jd = str2double(timeStr(5:7));
hr = str2double(timeStr(9:10));
mn = str2double(timeStr(12:13));
sc = str2double(timeStr(15:16)) + str2double(timeStr(18:21)) / 1000;
dt = datenum(yr, 1, jd, hr, mn, sc);

% Other output args.
nChans = 1;		% always 1 (so far anyway) for this file format
sampleSize = 2;		% always 2 bytes (so far anyway) for this file format
nTotal = (flength(fd) - 256) / sampleSize / nChans;% total sample frames in file
nLeft = nTotal - startFrame;
endDt = dt + nTotal/sRate;

%% Get the samples.
sams = [];
if (nFrames > 0 && startFrame < nTotal)
  st3  = fseek(fd, 256 + startFrame*2, 'bof');			%#ok<NASGU>
  sams = fread(fd, nFrames, 'uint16');
end


fclose(fd);

