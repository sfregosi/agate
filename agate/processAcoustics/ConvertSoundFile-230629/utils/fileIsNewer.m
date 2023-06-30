function isNewer = fileIsNewer(f1, f2)
%fileIsNewer	return true if file1 is modified more recently than file2
%
% isNewer = fileIsNewer(file1, file2)
%   Return true if file1 is newer than file2. file1 and file2 are file names,
%   or either (or both) may be a number in datenum format.

d1 = getdate(f1);
d2 = getdate(f2);
isNewer = (d1 > d2);


%% getdate - needed only because the file might be a directory
function dt = getdate(f)
% Return the modify-date of f in datenmum format.
if (isnumeric(f))	% is it a datenum or open file number?
  if (f > 6e5)		% is it a datenum?
    dt = f;
  else
    error('I can''t handle an open file number.')
  end
else			% no, it's a file name
  if (exist(f, 'file') == 7)
    % Directory!
    error('I can''t handle directories yet. You should fix this in fileIsNewer.m!!!');
  end
  dr = dir(f);
  dt = datenum(dr.date);
end
