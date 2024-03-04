function flist = getFilesInDateRange(tmplt, startDnum, endDnum)
%getFilesInDateRange	find files in a directory within a given date range
%
% filelist = getFilesInDateRange(tmplt, startDnum, endDnum)
%   Given a path template like C:\foo\bar\*.wav, find all files in it that have
%   a date/time stamp in the filename that's in the range [startDnum,endDnum).
%   The startDnum and endDnum values are numbers encoded as in datenum (q.v.).
%   The return value is a Nx1 file attribute struct array as returned by dir(),
%   which includes a filelist.name field.
%   
%   This uses findDateInString (q.v.) to identify the date/time stamp in the
%   file names.

lst = dir(tmplt);			% list of files matching the template
dtnums = findDateInString({lst.name});	% get date of each one (or NaN)
dtnums(isnan(dtnums)) = inf;		% change NaNs so 'keep' won't include
keep = (startDnum <= dtnums) & (dtnums < endDnum);
flist = lst(keep);
