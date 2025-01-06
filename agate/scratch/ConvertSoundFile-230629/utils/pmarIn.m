function [sams,nChans,sampleSize,sRate,nLeft,dt,hdr] = ...
  pmarIn(filename, start, nframe, chans)
%PMARIN         Read sound from a PMAR (Seaglider acoustic system) file
%
% sams = pmarIn(filename [,start [,n [,chans]]])
%    From a PMAR file, read sound data and return samples. 'start' is
%    the sample number (frame number) to start reading at (the first sample is
%    start=0), and n is the number of samples per channel to read. If n=Inf,
%    read the whole sound. chans is a vector specifying which channels are
%    desired, with channel 0 being the first channel. All of the arguments
%    after 'filename' are optional; if chans is missing, all channels are
%    returned. If the sound is shorter than n samples, then a shortened sams
%    array is returned.
%       The samples are returned in a matrix, with each channel's samples
%    filling one column of the matrix. The matrix has as many columns as the
%    length of chans.
%
% [sams,nChans,sampleSize,sRate,nLeft,dt,hdr] = pmarIn( ... )
%    From the given PMAR file, read the header and return, respectively, the
%    samples (sams), the number of channels (nChans; e.g., 2 for stereo), the
%    bytes per sample (sampleSize; always 2 so far for PMAR files), the sample
%    rate (sRate), the number of samples left in the file after the read
%    (nLeft), the start time of the file in datenum format (dt), and a copy of
%    the lines in the file's header as a cell array of strings (hdr).
%
%    The PMAR file is assumed to have little-endian (PC-style, not
%    Mac/Linux-style) numbers.

if (nargin < 2), start = 0; end
if (nargin < 3), nframe = inf; end
if (nargin < 4), chans = []; end

%% Read header.
% Headers have the format of a bunch of lines, each with '%' and a fieldname and
% a ':' and a space and a value, with the last line having fieldname
% 'headerend'.
fp = fopen(filename, 'r', 'l');     % 'l' means little-endian
if (fp < 0)
  error('Unable to open file %s for reading.', filename);
end

h = struct;         % header line values are deposited here
lineNo = 0;         % for error reporting
hdr = {};           % holds a copy of the header lines as strings
while (1)
  lineNo = lineNo + 1;
  ln = fgetl(fp);
  
  % Sometimes PMAR .dat files are missing part of the header. Try to cope.
  if (ln(1) == 0)   % incomplete headers start with buffering 0's
    % Try to complete the header. Require the header lines samplerate, start.
    if (~isfield(h, 'samplerate') || ~isfield(h, 'start'))
      error([mfilename ':IncompleteHeader'], ...
        'Incomplete header; I can''t cope with the absence of header lines "samplerate" or "start".');
    end
    if (~isfield(h, 'nchannels')),  h.nchannels = 1;     end
    if (~isfield(h, 'dataoffset')), h.dataoffset = 1024; end
    if (~isfield(h, 'samples'))
      % Figure out how many samples are in the file.
      fseek(fp, 0, 'eof');
      pos = ftell(fp);
      fseek(fp, h.dataoffset, 'cof');
      h.samples = (pos - h.dataoffset) / 2;
    end
    break
  end
  
  hdr = [hdr {ln}];                                             %#ok<AGROW>
  if (isnumeric(ln) || ln(1) ~= '%' || ~contains(ln, ':'))
    fclose(fp);
    error('Badly formatted header line in PMAR file %s, line #%d:\n%s', ...
      filename, lineNo, ln);
  elseif (strncmp(ln, '%headerend:', 11))
    break
  end
  
  % Parse the header line. 'fieldname' is the name of this header line.
  tokens = regexp(ln, '%(\w+): (.*)', 'tokens');
  fieldname = tokens{1}{1};             % chars between % and :
  h.(fieldname) = tokens{1}{2};         % add everything after ': ' to struct h
  
  % Handle special cases.
  switch(fieldname)
    case 'start'                        % make time stamp into datenum value
      v = sscanf(h.start, '%d %d %d %d %d %d %d');
      h.date = datenum(v(3)+1900, v(1), v(2), v(4), v(5), v(6) + v(7)/1000);
      
    case {'samplerate' 'nchannels' 'dataoffset' 'samples'}  % make these numeric
      h.(fieldname) = str2double(h.(fieldname));
  end
end           % while (1)

%% Read samples. 
% NB: I assumed h.samples means number of samples per channel (i.e., number of
% sample frames), not total samples across all channels. This matters only for
% files with nchannels > 1, which I haven't seen yet.
sampleSize = 2;             % for now, all PMAR files have 2-byte samples
offset = h.dataoffset + start * sampleSize * h.nchannels;
fseek(fp, offset, 'bof');
framesToRead = min(h.samples - start, nframe);
if (h.nchannels > 1)
  sams = reshape(fread(fp, framesToRead * h.nchannels, 'uint16'), ...
    framesToRead, h.nchannels);
else
  sams = fread(fp, framesToRead * h.nchannels, 'uint16');
end
if (isempty(chans) || isnan(chans))
  chans = 0 : h.nchannels-1;
end
fclose(fp);

%% Construct return values. sampleSize and hdr are set above.
if (~isempty(sams))
  sams = sams(:, chans + 1) - 32768;    % code elsewhere assumes signed int16
end
sRate  = h.samplerate;
nLeft  = h.samples - (start + framesToRead);
nChans = h.nchannels;
dt     = h.date;
