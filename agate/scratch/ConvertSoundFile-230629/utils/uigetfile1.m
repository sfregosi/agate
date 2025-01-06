function [f,p] = uigetfile1(filterSpec, dialogTitle)
%UIGETFILE1	Display centered dialog box, interactively retrieve a filename
%
% [filename,pathname] = uigetfile1(filterSpec, dialogTitle)
% This is just like uigetfile (q.v.), but the dialog box is approximately
% centered instead of appearing in the upper-left corner.  This doesn't work
% in Windows, since uigetfile doesn't let you specify the location.
%
% See also uigetfile, uiputfile1, uiputfile.

w = 600;		% no way to find out dialog box size; let's guess this
h = 400;
s = get(0, 'ScreenSize');

% The args to uiputfile changed with Matlab version 7, and again sometime
% between 7.3 (R2006b) and 7.6 (R2008a).
[v0,v1] = matlabver;
if (v0 >= 7 && v1 >= 4)
  [f,p] = uigetfile(filterSpec, dialogTitle);
elseif (v0 >= 8)
  [f,p] = uigetfile(filterSpec, dialogTitle);  % no positioning in v8
elseif (v0 >= 7)
  [f,p] = uigetfile(filterSpec, dialogTitle, 'Location', (s([3 4]) - [w h])/2);
else
  [f,p] = uigetfile(filterSpec, dialogTitle, (s(3)-w)/2, (s(4)-h)/2);
end
