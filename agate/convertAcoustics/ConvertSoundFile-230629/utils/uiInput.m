function ret = uiInput(title,buttonList,callback,siz, n1,i1,n2,i2,n3,i3,n4,i4)   %#ok<INUSD>

%uiInput     Display dialog box with buttons and optionally allow text entry.
%
% ret = uiInput(title, buttonNames, callback)
%    Display the title and buttons and return.  The callback is evaluated
%    when the user clicks a button, with the global variable uiInputButton
%    set to the button number clicked on.  Button numbers start at 1.
%    The names in buttonNames should be separated by | characters.  
%    If any button name begins with ^, a press of the button will
%    execute the callback but NOT make the input window go away. 
%
%    The title string may contain multiple rows; in this case, the first 
%    row is displayed as a title and succeeding rows as ordinary text.  Use
%    a cell array of strings or str2mat to make multiple lines of text.
%
%    The return value is a list of objects: [figure button1 button2 ... txts]
%    where the final txts is the displayed title and text. If there is no
%    title, txts is absent from this vector.
%
%    The callback string may also have multiple rows.  In that case, each
%    row is the callback for each button, respectively.
%
%    For the user, pressing return is like pressing the first button.
%
%    The displayed box is not modal, i.e., it doesn't wait for user input
%    before returning.  For that, do set(ret(1), 'WindowStyle', 'modal'),
%    then call uiwait, then make sure your callback executes uiresume.
%
% ret = uiInput(title, buttonlist, callback, size)
%    As above, but you can specify the size in pixels of the displayed 
%    box as [wide high].  If the size is [] the default size is used.
%    If size is a scalar, it is the width; the default height is used.
%
% ret = uiInput(title, buttonlist, callback, size, 'name', 'init')
%    As above, but also display a text box for the user to edit.
%    'name' is the caption appearing above the edit box, and 'init'
%    is the initial value of the edit box.  Upon callback, the global
%    variable uiInput1 has the edited string.  (It is always a string;
%    use str2num to convert to a number).
%
%    The return value is again a list of objects:
%    [figure button1 button2 ... edit1 edit2 ... txts]
%
% ret=uiInput(title, buttonlist, callback, size, name1,init1, name2,init2, ...)
%    As above, but show two or more edit boxes with captions, with
%    successive values in uiInput2, uiInput3, uiInput4.  Up to four edit
%    boxes can be handled.  If the last init string is omitted, an empty
%    string is used.
%
% Examples:
% uiInput('Replace file?', 'OK|Cancel', 'mycallback')
% uiInput('', 'OK|Cancel', 'mycallback', [], 'New scaling value', num2str(x))
% uiInput('Size', 'OK|Yes|Why not', 'mycallback', [], 'Length','','Height', '')
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 9 May 01

% Internal calls (callback calls) to uiInput are these:
%
% uiInput('XXXkeyXXX')
%    The user typed a key.  Check for it being <RETURN>; if so, choose
%    the first button.
%
% uiInput('XXXclickXXX', n)
%    The user clicked on button number n.  Set up the global variables
%    and execute the user callback.

% Internal details:
% The figure's UserData contains [button1 edit1 edit2 edit3 ...]
% where button1 is the button to execute if the user presses return,
% and edit1 etc. are the edit box objects.
% 
% The button objects' UserData contain [keep callback], where 'keep' is a 
% number saying whether to keep the figure around after pressing this button 
% and 'callback' is the callback string to execute.

global uiInputButton	 % return value -- button number pressed
global uiInput1 uiInput2 % return values -- contents of edit boxes
global uiInput3 uiInput4 %#ok<*NUSED>     ditto

flag = 17.17;		% uiInput figures are marked with this flag value

if ischar(title) && (strcmp(title, 'XXXkeyXXX') || strcmp(title, 'XXXclickXXX'))
  if (version4), fig = gcf; else [~,fig] = eval('gcbo'); end
  figdata = get(fig, 'UserData');
  if strcmp(title, 'XXXkeyXXX')
    c = get(fig, 'CurrentCharacter');
    if (isempty(c))
      return
    end
    if (c ~= 10 && c ~= 13)
      return
    end
    uiInputButton = 1;
    butobj = figdata(1);
    if (isnan(butobj))
      return;
    end
  else
    uiInputButton = buttonList;
    butobj = gco;
  end
  if (length(uiInputButton) ~= 1)
    error('Internal error: Didn''t find exactly one button to match.');
  end
  for i = 2 : length(figdata)
    eval(['uiInput' num2str(i-1) ' = get(figdata(i),''String'');']);
  end
  ud = get(butobj, 'UserData');
  if (~ud(1))			% keep fig after button pressed?
    delete(fig);
  end
  eval(char(ud(2:nCols(ud))));

else
  % Create a new GUI box.
  nedit = floor((nargin - 3) / 2);
  if (nargin < 4), siz = [0 0]; end
  if (isempty(siz)), siz = [0 0]; elseif (length(siz) == 1), siz = [siz 1]; end
  if (all(siz == [0 0])), siz = [400 1]; end	% MATLAB can't take [400 0]

  if (iscell(title)), nm = title{1};
  else nm = title(1,:);
  end
  fig = figure('Units', 'norm', 'NumberTitle', 'off', 'Name', nm, ...
      'Position', [.4 .4 .3 .3], 'Color', [.7 .7 .7], 'UserData', flag, ...
      'Pointer', 'arrow', 'KeyPressFcn', 'uiInput(''XXXkeyXXX'');');
  set(fig, 'Units', 'pixels');
  axes('Position', [0 0 1 1], 'Visible', 'off');

  bbot	 = 20;
  bhigh	 = 30;
  btop	 = 15;
  ebot	 = 10;
  ehigh	 = 20;
  nbot	 = 10;
  tbot	 = 10;
  top	 = 5;

  bwide  = 100;
  bsep   = 20;
  tleft  = 15;
  eleft  = 25;
  eright = eleft;
  nleft  = eleft;

  % Create buttons.
  nbut = 0;
  if (~isempty(buttonList))
    div = [0, find([buttonList,'|'] == '|')];
    nbut = length(div) - 1;
  end
  if (nRows(callback) > 1 && nbut ~= nRows(callback))
    error('For multiple-row callbacks, number of callback must equal number of buttons.');
  end

  btotw	 = nbut*bwide + (nbut-1)*bsep;
  left	 = (siz(1) - btotw) / 2;
  bot    = bbot;
  buttons= zeros(1,nbut);
  for i = 1:nbut
    butname = buttonList(div(i)+1 : div(i+1)-1);
    keep = (butname(1) == '^');
    butname = butname(keep+1 : length(butname));

    cback = callback;
    if (nRows(cback) ~= 1), cback = cback(i,:); end

    buttons(i) = uicontrol('Style', 'PushB', 'Units', 'pixels', ...
	'Position', [left bot bwide bhigh], 'String', butname, ...
	'Callback', ['uiInput(''XXXclickXXX'', ' num2str(i) ')'], ...
	'UserData', [char(keep+0) cback]);
    left = left + bwide + bsep;
  end
  if (nbut > 0)
    bot = bot + bhigh + btop;
  end

  % Create edit boxes and names.
  ewide = siz(1) - eleft - eright;
  edits = zeros(1,nedit);
  for i = nedit:-1:1
    s = num2str(i);
    bot = bot + ebot;
    initstr = '';
    if (nargin >= 4 + i*2), initstr = eval(['i' s]); end
    if (~ischar(initstr)), initstr = num2str(initstr); end;

    edits(i) = uicontrol('Style', 'edit', 'String', initstr, ...
	'Position', [eleft bot ewide ehigh], 'BackgroundColor', [1 1 1]);
    bot = bot + ehigh + nbot;
    x = eval(['n' s]);
    t = text(nleft, bot, x, 'FontSize', 10, 'Units', 'pixels', ...
	'Color', [0 0 0], 'VerticalAlign', 'bottom');
    bot = bot + sub(get(t, 'Extent'), 4);
  end

  % Create main text, and title if any.
  txts = [];
  if (~isempty(title))
    bot = bot + tbot;
    lines = [];
    if (iscell(title) && length(title) > 1), lines = title(2:end);   end
    if (ischar(title) && nRows(title) > 1),  lines = title(2:end, :); end
    if (~isempty(lines))
      t1 = text(tleft, bot, lines,    'Units', 'pixels', ...
        'Color', [0 0 0], 'VerticalAlign', 'bottom', 'FontSize', 10);
      bot = bot + sub(get(t1, 'Extent'), 4);
    end
    bot = bot + tbot;
    titl = title(1,:);
    if (iscell(titl)), titl = titl{1}; end
    if (~isempty(deblank(titl)))
      tt = text(tleft, bot, deblank(titl), 'FontSize', 12, ...
        'Units', 'pixels', 'Color', [0 0 0], 'VerticalAlign', 'bottom');
      bot = bot + sub(get(tt, 'Extent'), 4);
    else
      tt = [];
    end
    txts = [tt txts];
  end
  bot = bot + top;
  
  % Put figure at correct position.
  set(0, 'Units', 'pixels');  ss = get(0, 'ScreenSize');
  if (siz(2) < 2), siz(2) = bot; end
  set(fig, 'Position', [ss(3:4)/2 - siz/2, siz]);
  if (nbut > 0)
    set(fig, 'UserData', [buttons(1) edits]);
  else
    set(fig, 'UserData', [NaN edits]);
  end

  ret = [fig buttons edits txts];
end
