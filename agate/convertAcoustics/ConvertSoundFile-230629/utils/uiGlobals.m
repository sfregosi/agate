%uiGlobals   Global variables for uiOpen, uiSlider, uiInput, uiMultiText

% globals for the uiOpen dialog box
global uiOAxes		% axes object for painting in figure
global uiOCallback	% string to eval when user finishes
global uiODir		% current directory (no final /)
global uiODirPopup	% popup menu with directory names
global uiOFiles		% list of files in current directory
global uiOFigure	% figure number of the dialog box
global uiOFontName	% font used for names
global uiOFontSize	% ...and font size
global uiOKeys		% characters typed by user recently
global uiOKeyTime	% time of last keypress, 0 if none
global uiOList		% list of text objects filenames in the patch
global uiOMaxSlider	% max possible slider value
global uiOPatch		% grey rectangle behind list of filenames
global uiOpenValue	% user's choice in the window
global uiOSaveEdit	% edit box for user type-in
global uiOSelFile	% currently selected file number
global uiOSelPatch	% grey patch highlighting selection
global uiOSlider	% slider
global uiOTopFile	% file number appears at top of visible list

% globals for uiSliders
global uiSliderVals	% (handle,lastvalue) pairs
global uiSliderClick	% upsmall, upbig, downsmall, downbig, or drag
global uiSliderPrev	% value of slider before latest user action

% globals for uiMultiText

% globals for uiInput
global uiInputButton	% return value: button number pressed
global uiInputCallback	% the callback
global uiInputEdits	% edit-box objects
global uiInputFig	% the figure
global uiInput1		% return value: edit-box 1 string; also 2, 3, 4
