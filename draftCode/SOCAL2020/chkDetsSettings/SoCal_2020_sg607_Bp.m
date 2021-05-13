%%%%%%%%%%%% Fin whales SoCal 2020 Glider SG607 %%%%%%%%%%%%

% timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1/24;             % check one detection per hour
timeIncr = 10/(24*60);             % check one detection per 10 min
% timeIncr = 1;			% check one detection per day

% Sound files and index:
snddir = 'F:\SoCal2020\sg607_downsampled\sg607-1kHz\';
indexpath = [snddir 'file_dates-sg607_SoCal_Feb20-1kHz.txt'];

% Log files:
% logdir   = 'C:\Users\selene\Box\HDR-SOCAL-2020\largeWhaleAnalysis\blue\'; 	% log file(s) dir
logdir = 'F:\SoCal2020\largeWhaleAnalysis\Bp\Bp_sg607\';
inlogpath  = [logdir 'sg607_Bp_20201022F.log'];
outlogpath = [pathRoot(inlogpath) '-checked_10min.log'];

% Display info:
displayFreq = [0 100];	% freq range to show in Osprey
selectFreq  = [10 40];	% freq range shown in yellow for detection
padTime     = [20 20];	% time shown to either side of detection, s
maxDispSec = 120;
selectTimePad = [0 1];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected