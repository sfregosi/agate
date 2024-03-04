function [f,p] = uiputfile1(initFile, dialogTitle)
%UIPUTFILE1	Display centered dialog box, interactively retrieve a filename
%
% [filename,pathname] = uiputfile1(initFile, dialogTitle)
% This is just like uiputfile (q.v.), but the dialog box is approximately
% centered instead of appearing in the upper-left corner.  This doesn't work
% in Windows, since uiputfile doesn't let you specify the location.
%
% See also uiputfile, uigetfile1, uigetfile.

w = 600;		% no way to find out dialog box size; let's guess this
h = 400;
s = get(0, 'ScreenSize');

% The args to uiputfile changed with Matlab version 7, and again sometime
% between 7.3 and 7.6.
[v0,v1] = matlabver;
if (v0 >= 8)
  % They removed Location in v8 but added FilterSpec.
  [f,p] = uiputfile([pathDir(initFile) filesep '*.' pathExt(initFile)], ...
    dialogTitle, initFile);	
elseif (v0 == 7 && v1 >= 4)
  [f,p] = uiputfile(initFile, dialogTitle);
elseif (v0 >= 7)
  [f,p] = uiputfile(initFile, dialogTitle, 'Location', (s([3 4]) - [w h])/2);
else
  [f,p] = uiputfile(initFile, dialogTitle, (s(3)-w)/2, (s(4)-h)/2);
end
