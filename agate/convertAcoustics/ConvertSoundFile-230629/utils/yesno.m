function bool = yesno(query, def, labels)
%YESNO		Ask the user a yes-or-no question, return 1 or 0 accordingly.
%
% bool = yesno(query [,def [,buttons]])
%    Prompt the user with 'query' in a dialog box.  Get an answer, and return
%    1 if the answer is 'Y' or 'y' or '1', 0 otherwise.  The query may have
%    multiple rows.  'def' says what to return if the user just presses return;
%    it defaults to 1.  'labels' are the labels for the two buttons; the
%    default is 'Yes|No'.
%
% See also uiInput.

if (nargin < 2), def = 1; end
if (nargin < 3), labels = 'Yes|No'; end

global uiInputButton

if (iscell(query))
  query = [{''}; query(:)];
else
  query(2 : end+1, :) = query;		% first line of query is the title
  query(1, :) = ' ';			% make it blank
end
f = uiInput(query, labels, iff(matlabver >= 7, ' ', 'uiresume'));
set(f(1), 'WindowStyle', 'modal');
uiwait(f(1))
bool = (uiInputButton == 1);
