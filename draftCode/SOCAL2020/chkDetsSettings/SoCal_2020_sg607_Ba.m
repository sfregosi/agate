%%%%%%%%%%%% Minke Whales SoCal 2020 Glider SG607 %%%%%%%%%%%%

timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1;			% check one detection per day

% Sound files and index:
snddir = 'E:\SoCal2020\sg607_downsampled\sg607-10kHz\';
indexpath = [snddir 'file_dates-sg607_SoCal_Feb20-10kHz.txt'];

% Log files:
logdir   = 'E:\SoCal2020\detectorOutputs\sg607_Ba\'; 	% log file(s) dir
inlogpath  = [logdir 'minke_Det-try1-SG607.log'];
outlogpath = [pathRoot(inlogpath) '-checked.log'];

% Display info:
displayFreq = [0 4000];	% freq range to show in Osprey
selectFreq  = [20 60];	% freq range shown in yellow for detection
padTime     = [4 20];	% time shown to either side of detection, s
maxDispSec = 60;
selectTimePad = [0.5 0.5];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected