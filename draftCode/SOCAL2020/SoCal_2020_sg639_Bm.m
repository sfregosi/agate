%%%%%%%%%%%% Blue whales SoCal 2020 Glider SG639 %%%%%%%%%%%%

timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1;			% check one detection per day

% Sound files and index:
snddir = 'E:\SoCal2020\sg639_downsampled\sg639-1kHz\';
indexpath = [snddir 'file_dates-sg639_SoCal_Feb20-1kHz.txt'];

% Log files:
logdir = 'E:\SoCal2020\detectorOutputs\sg639_Bm\';
inlogpath  = [logdir 'sg639_Bm_20201007_run2.log'];
outlogpath = [pathRoot(inlogpath) '-checked.log'];

% Display info:
displayFreq = [0 120];	% freq range to show in Osprey
selectFreq  = [20 60];	% freq range shown in yellow for detection
padTime     = [4 20];	% time shown to either side of detection, s
maxDispSec = 120;
selectTimePad = [0.5 0.5];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected