function warnbox(message, callback)
%WARNBOX	Display dialog box with warning message.
%
% warnbox(message, callback)
%    Display the message and buttons for 'OK' and 'Cancel'.
% If the user clicks OK, execute the callback.
%
% See also uiInput, warndlg, msgbox, errordlg.

% Internal use:
% warnbox()
%    User clicked something.  Do the callback if appropriate.

global warnboxCallback uiInputButton

if (nargin > 0)
  warnboxCallback = callback;			% save it away for future use
  uiInput(message, 'OK|Cancel', 'warnbox');
  
else
  if (uiInputButton == 1)
    eval(warnboxCallback);
    warnboxCallback = '';
  end

end
