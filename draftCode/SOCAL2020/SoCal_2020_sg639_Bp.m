%%%%%%%%%%%% Fin whales SoCal 2020 Glider SG639 %%%%%%%%%%%%

% timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1/24;             % check one detection per hour
timeIncr = 10/(24*60);             % check one detection per 10 min
% timeIncr = 1;			% check one detection per day

% Sound files and index:
snddir = 'E:\SoCal2020\sg639_downsampled\sg639-1kHz\';
indexpath = [snddir 'file_dates-sg639_SoCal_Feb20-1kHz.txt'];

% Log files:
% logdir   = 'C:\Users\selene\Box\HDR-SOCAL-2020\largeWhaleAnalysis\blue\'; 	% log file(s) dir
logdir = 'E:\SoCal2020\largeWhaleAnalysis\Bp\Bp_sg639\';
inlogpath  = [logdir 'sg639_Bp_20201022.log'];
outlogpath = [pathRoot(inlogpath) '-checked_10min.log'];

% Display info:
displayFreq = [0 100];	% freq range to show in Osprey
selectFreq  = [10 40];	% freq range shown in yellow for detection
padTime     = [20 20];	% time shown to either side of detection, s
maxDispSec = 120;
selectTimePad = [0 1];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected