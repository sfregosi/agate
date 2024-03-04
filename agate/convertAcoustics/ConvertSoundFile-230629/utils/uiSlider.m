function uiSlider(h, cmd, x0, x1, x2, x3, x4)
%uiSlider    Set up a slider (scrollbar) with better knowledge of mouse clicks
%
% uiSlider(h)
%     To use this function, create a slider the usual way using 
%	h = uicontrol('Style', 'Slider', ...), 
%     then call uiSlider with the handle h of the slider:
%       uiSlider(h);
%     Thereafter, whenever a callback happens, the global variable
%     'uiSliderClick' will have one of these values:
%
%	  upsmall     user clicked in the arrow at the 'max' end of the slider
%	  downsmall   user clicked in the arrow at the 'min' end of the slider
%	  upbig       user clicked in the background space beside the marker
%	  downbig     user clicked in background on the other side
%	  none        user clicked on marker but didn't move it
%	  drag        user grabbed the marker and moved it
%
%     The global variable uiSliderPrev will have the previous value of
%     the slider before the user's action.  (The current value is retrieved
%     with get(h,'value') as usual.)  This is useful for overriding
%     MATLAB's value for the slider in case of a one of the click types above.
%
%     Note: This function is implemented by a change to the Callback 
%     string of the slider.  If you ever change the callback, 
%     call uiSlider(h) again afterwards.
% 
%     Also note: When the marker is near the end of the slider, MATLAB 
%     provides no way to tell between a mouse-click outside the marker
%     and a drag of the marker all the way to the end.  In these cases,
%     upsmall or downsmall is used if it makes sense; if not, upbig or
%     downbig is used.
%
% uiSlider(h, 'Value', x) 
%     To change the value of the slider, use this call instead of 
%     set(h,'Value',x) to ensure that the previous value gets set up 
%     correctly.  Do this 'Value' call after changing Min or Max, too.
%
% Example:
% To make a slider that displays the type of mouse click done, try
%    s = uicontrol('Style','Slider','Position',[20 20 120 20],...
%                  'Callback', 'disp(uiSliderClick)');
%    global uiSliderClick
%    uiSlider(s);
%
% Written by Dave Mellinger, David.Mellinger@oregonstate.edu .  
% This version is 11/4/04.

% Internal routine:
% uiSlider(h, 'go')
%     This is used by uiSlider internally in the callback string.

magic = 992;		% MATLAB always moves sliders in increments of 1/992
small = 10 / magic;	% MATLAB moves 9/992, 10/992, or 11/992 of slider range
big   = 100 / magic;	% ... or 99/992, 100/992, or 101/992
tol   = 1/magic + 1e-6;	% allows for the +/-1 error and some truncation error

global uiSliderVals uiSliderClick uiSliderPrev
if (gexist4('uiSliderVals') ~= 1), uiSliderVals = [-1 -1]; end

if (h == -1), h = gcbo; end
if (nargin == 1)
  set(h, 'Callback', ['uiSlider(-1,''go'');' get(h, 'Callback')]);
  cmd = 'new';
end

hMin = get(h, 'Min');
hMax = get(h, 'Max');

if (lower(cmd(1)) == 'v')		% 'value'
  % round x0 to the nearest 1/magic of the distance from hMin to hMax
  hVal = round((x0-hMin) / (hMax-hMin) * magic) / magic * (hMax-hMin) + hMin;
  set(h, cmd, hVal);
else					% 'go', 'new'
  hVal = get(h, 'Value');		% native units
end
now = (hVal - hMin) / (hMax - hMin);	% normalized units

pos = [];
if (length(uiSliderVals))
  pos = find(uiSliderVals(:,1) == h);
end
if (~length(pos))			% 'new'
  uiSliderVals = [uiSliderVals; h now];

else					% 'go', 'value'
  prev = uiSliderVals(pos(1), 2);
  uiSliderVals(pos, 2) = now;
  uiSliderPrev = prev * (hMax - hMin) + hMin;

  if (strcmp(cmd, 'go'))
    uiSliderClick = 'drag';
    if     (now == prev),                   uiSliderClick = 'none';
    elseif (abs(now - prev - small) < tol), uiSliderClick = 'upsmall';
    elseif (abs(now - prev - big  ) < tol), uiSliderClick = 'upbig';
    elseif (abs(prev - now - small) < tol), uiSliderClick = 'downsmall';
    elseif (abs(prev - now - big  ) < tol), uiSliderClick = 'downbig';
    else					  
      if (hVal == hMax)
	if     (abs(now - prev) < small), uiSliderClick = 'upsmall';
	elseif (abs(now - prev) < big  ), uiSliderClick = 'upbig';
	end
      elseif (hVal == hMin)
	if     (abs(prev - now) < small), uiSliderClick = 'downsmall';
	elseif (abs(prev - now) < big  ), uiSliderClick = 'downbig';
	end
      end
    end
  end
end
