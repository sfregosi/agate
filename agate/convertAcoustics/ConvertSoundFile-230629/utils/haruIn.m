function [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
                              haruIn(filename, startFrame, nFrames, chans)
%haruIn   Read data from a Haru-format file (.dat, .sdat; from NOAA/PMEL lab).
%
% [sams,nchan,sampleSize,sRate,nLeft,dt,endDt] = ...
%                             haruIn(filename, startFrame, nFrames, chans)
%    Read Haru Matsumoto's file format (from NOAA/PMEL's acoustics lab).  Such
%    files typically have names like 00000318.DAT or 00000318.SDAT or
%    DATAFILE.318, or possibly r0125502.28 or r0125502.28m130.
%    
%    Input arguments:
%      filename   the file to read
%      startFrame starting sample number; default is 0, meaning the
%                 first sample in the file
%      nFrames    number of samples to read per channel; default is Inf,
%                 meaning read the entire file
%      chans      which channels to read; default is all of them; channel
%                 numbering starts at 1 (!)
%
%    Output arguments:
%      sams       column vector of samples (or multi-column array, if
%                 chans's length is >= 2)
%      nchan      how many channels are in the file (equals 1 for all
%                 extant Haru-format files, but who knows about the future)
%      sampleSize number of bytes per sample, 1 or 2
%      sRate      sampling rate, Hz
%      nLeft      number of sample frames remaining in the file after
%                 reading (use haruIn(filename, 0, 0) to get the total number
%                 of samples in the file)
%      dt         date/time (in GMT) that the file starts, encoded as
%                 in datenum
%      endDt      date/time (in GMT) of the first sample after the end of the
%                 file; this output arg is available only for SDAT files
%
% Some Haru-files (ETP before Nov. 99, MAR) do not encode their sampling rate,
% so I have to guess.  I'll tell you when I'm guessing.  To override this 
% guess, do something like this:
%          global opHaruSrate; opHaruSrate=112;
%
% Note: Reading of .SDAT files is handled by sdatIn.m, which you can call
% directly if you like or do it via this function. There are also CF2-format
% .DAT files, which are read by cf2In.m.
%
% Dave Mellinger
% 24 Nov 2003

% There are two time-date strings in Haru files.  The first is from the QTech
% clock, which is generally the more accurate, temperature-corrected one.  
% The second is from the Real-Time Clock (RTC), essentially the computer's
% system clock; it's less accurate.
%
% The RTC is set periodically (Matt said maybe once a day) from the QTech
% clock, so the two should never be far apart.  However, upon a reboot, the
% QTech clock doesn't know what time it is, so it gets set from the RTC.  
% So the QTech clock can have a small quantum jump at that point, equal to
% the amount that the RTC was off.  One good way to estimate the jump is
% by looking at the last Haru-file recorded before the reboot, and calculate
% the difference between the two clocks.  A better way would probably be to
% estimate the drift rate between the two clocks, then add the appropriate
% amount of drift to that last-file clock difference.  I've never done the
% latter.

global opHaruSrate opHaruSrateWarned

if (nargin < 2), startFrame = 0;   end
if (nargin < 3), nFrames = inf;    end
if (nargin < 4), chans = NaN;      end

if (strcmpi(pathExt(filename), 'sdat'))
  if (nargin < 4)
    [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
      sdatIn(filename, startFrame, nFrames);
  else
    [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
      sdatIn(filename, startFrame, nFrames, chans);
  end
  return
end

fd = fopen(filename, 'r', 'b');   % read-only; big-endian byte order
if (fd < 0)
  error(['Can''t open Haru-format file ' filename]);
end

f12 = char(fread(fd, 12, 'uchar').');      % first 12 bytes
if (strcmpi(f12(1:3), 'BIR'))
  shortForm = 0;
else 
  % Check for CF2 format of Haru file, as indicated by the string 'CF2' at
  % byte 152 of the file.
  fseek(fd, 152, 'bof');
  cf2str = fread(fd, 2, '*char').';
  if (strcmpi(cf2str, 'cf'))
    % CF2-format file. Let cf2In handle it. Don't want to pass fd because
    % cf2In has a requirement that the file be opened big-endian. Since that's
    % too much to require, cf2In doesn't take fd as an input, just a filename.
    fclose(fd);
    [sams,nChans,sampleSize,sRate,nLeft,dt,endDt] = ...
	cf2In(filename, startFrame, nFrames, chans);
    return
  end
  fseek(fd, 12, 'bof');
  shortForm = 1;
  [~, count] = sscanf(f12, 'H%2d%2d%c%3d%c');
  if (count ~= 5)
    [~, count] = sscanf(f12, 'h%2d%2d%c%3d%c');  % sometimes it's lowercase
    if (count ~= 5)
      fclose(fd);
      error('Not a Haru-format file.');
    end
  end
end

% Get the date string, parse into dt.
fY = fread(fd, 1, 'uchar');
% Short-form or regular (non-SDAT) long-form format.
if (shortForm && (fY == 'y' || fY == 'Y'))
  % Yet another format for Haru-files, let's call it 'Y format'.
  % Example: H0916N043W00Y064:05:26:31:140064:05:26:31:940
  fseek(fd, 13, 'bof');          % where date string starts
  dateStr = [f12(11:12) ' ' fread(fd, 16, '*char').'];
elseif (shortForm)
  % 'short' format
  % example: H1435N043W99 336:17:41:05:530336:17:43:31:920  (at SOF)
  % NO, USE FIRST DATE!  SECOND ONE IS WRONG.  See comment above, or
  %      mar99\NE\disk3\datafile.249 .
  %fscanf(fd, '%d:%d:%d:%d:%3d',5); % skip first date; second is more accurate
  %fseek(fd, 30, 'bof');           % where date string starts
  k = fread(fd, 16, 'char').';
  dateStr = [f12(11:12) ' ' char(k)];
else
  % 'long' format
  fseek(fd, 74, 'bof');          % where date string starts (first one: QTech)
  dateStr = char(fread(fd, 42, 'char').');
end
[dv,count,~,nextIx] = sscanf(dateStr, '%d %d:%d:%d:%d:', 5);
if (count ~= 5)
  fclose(fd);
  error(['The date string in a Haru-format file is bad: ' dateStr]);
end
% Work around MATLAB bug: Sometimes it doesn't read the last ':'.
if (dateStr(nextIx) == ':'), nextIx = nextIx+1; end
% Only 2 digits of the last 3 are valid, so they're centiseconds.
if (dateStr(nextIx) == '*')
  dv(6) = 0;
else
  dv(6) = sscanf(dateStr(nextIx : nextIx + 1), '%d') * 10;  % *10 to make ms
end
if (dv(1) < 90)		% there are no Haru-files from before 1990
  dv(1) = dv(1) + 100;	% short-form dates encode year 2000 as '00'.
end
% Make dt from dv, which is [year-1900  yearday  hour  min  sec  msec].
dt = datenum([dv(1)+1900 1 dv(2) dv(3) dv(4) dv(5)+dv(6)/1000]);
%dt = dv;	% old encoding: dt was an odd sort of vector
  
if (shortForm)
  % Short form of header: only date, other parameters are fixed.
  nChans      = 1;
  if (gexist4('opHaruSrate'))
    sRate = opHaruSrate;
  else
    % Atlantic shortForm files were sampled at 110 Hz, ETP ones at 100 Hz.
    % I used to think (pre-3/26/2004) Atlantic files were sampled at 112 Hz.
    % Examples: 
    % \\Syspc\hdd3\haruphone\MAR\Mar01_Feb02\16n049w\disk4\datafile.000
    % \\Syspc\hdd1\haruphone\EPR\Nov98\EPR\Nov98-May99\00n095w\disk1\datafile.*
    sRate = iff(upper(f12(10)) == 'W' & str2double(f12(7:9)) >= 80, 100, 110);
    if (~gexist4('opHaruSrateWarned')), opHaruSrateWarned = 0; end
    if (sRate ~= opHaruSrateWarned)
      printf(['Warning! Guessing that sample rate of Haru file is %d; ' ...
	  'do "help haruIn" to override'], sRate);
      opHaruSrateWarned = sRate;
    end
  end
  sampleSize  = 1;
  precision   = 'uchar';
  valueOffset = 128;
  headerSize = 46;                      % bytes
else
  % Read rest of long-form (regular or SDAT) header.
  %fseek(fd, 106, 'cof');
  fseek(fd, 222, 'bof');
  sams          = fread(fd, 3, 'short');
  nChans     = sams(1);
  sRate      = sams(2);
  sampleType = sams(3);
  if (sampleType ~= 0 && sampleType ~= 2 && sampleType ~= 3)
    fclose(fd);
    error(['Unknown sample type in Haru-format file ' filename]);
  end
  sampleSize  = iff(sampleType==0, 1, 2);  % 0==>1 byte/sam, 2&3==>2 byte/sam
  precision   = iff(sampleType==0,'uchar',iff(sampleType==2,'short','ushort'));
  valueOffset = iff(sampleType==0, 128, iff(sampleType==2, 16384-109, 32768));
  % -109 is right for Albatross bank phone.
  headerSize = 256;                      % bytes
end

% Determine whether there's a trailing timestamp, and hence length of trailer.
fseek(fd, -17, 'eof');
[~,count] = fscanf(fd, '%3d:%2d:%2d:%2d:%d');
trailerLen = iff(count == 5, 46, 0);

if (nargin < 4), chans = 1:nChans; end

fseek(fd, 0, 'eof');
nFramesTotal = (ftell(fd) - headerSize - trailerLen) / nChans / sampleSize;

% Skip past rest of header.
fseek(fd, headerSize + startFrame * nChans * sampleSize, 'bof');

nFrames = min(nFrames, nFramesTotal - startFrame); % prevent reading past EOF
nLeft = nFramesTotal - nFrames - startFrame;

% Read the data, reshape into sams array.
sams = fread(fd, nFrames * nChans, precision);
fclose(fd);
sams = reshape(sams, nChans, length(sams) / nChans).';
sams = sams(:,chans) - valueOffset;
