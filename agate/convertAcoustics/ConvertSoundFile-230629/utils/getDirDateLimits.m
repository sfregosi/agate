function [start_end,alt_end] = getDirDateLimits(dirpath)
%getDirDateLimits  find the date/time limits of a directory's sound files
%
% start_end = getDirDateLimits(dirpath)
%   Given the path to a bunch of sound files that have date/times encoded in
%   their names, find the start of the first file and end of the last file and
%   return them as [start end] datenum values (i.e., a 1x2 vector of datenums).
%   The 'end' value is actually one sample beyond the last sample in the last
%   file.
%
%   The input argument 'dirpath' can be either a directory name, in which case
%   all files in it are used that have date/time stamps in their names, or a
%   path name with a wildcard, like 'mydir/*.wav', in which case all files that
%   match the wildcard are used. The wildcard is used in a call to dir(), so do
%   'help dir' to see what is allowed. If no files are found or date/time values
%   in the file names aren't found, [NaN NaN] is returned.
%
% [start_end,alt_end] = getDirDateLimits(dirpath)
%   A second return argument alt_end has the time of the last sample rather than
%   one sample beyond it. Beware that at sample rates above around 200 kHz, this
%   'alt_end' value can be the same as the 'end' value because of the limited
%   precision of the double-precision numbers that hold datenum values.
%
% See also extractDatestamp, datenum, dir.
%
% Dave Mellinger

files = dir(dirpath);
dtnums = extractDatestamp({files.name});
start = min(dtnums);
[stop,ix] = max(dtnums);
if (isempty(start) || isnan(start) || isempty(stop) || isnan(stop))
  start_end = [nan nan];
  alt_end = nan;
else
  info = audioinfo(fullfile(files(ix).folder, files(ix).name));
  stop = stop + info.Duration / (24*60*60);             % Duration is in seconds
  alt_end = stop - (1 / info.SampleRate / (24*60*60));	% 1 sample period
  start_end = [start stop];
end
