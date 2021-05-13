%%%%%%%%%%%% Sperm whales SoCal 2020 Glider SG607 %%%%%%%%%%%%

timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1;			% check one detection per day

% Sound files and index:
snddir = 'E:\SoCal2020\sg607_downsampled\sg607-5kHz\';
indexpath = [snddir 'file_dates-sg607_SoCal_Feb20-5kHz.txt'];

% Log files:
% logdir   = 'C:\Users\selene\Box\HDR-SOCAL-2020\largeWhaleAnalysis\sperm\'; 	% log file(s) dir
logdir   = 'E:\SoCal2020\detectorOutputs\sg607_Pm\'; 	% log file(s) dir
inlogpath  = [logdir 'sg607_Pm_20200921.log'];
outlogpath = [pathRoot(inlogpath) '-checked.log'];

% Display info:
displayFreq = [100 2500];	% freq range to show in Osprey
selectFreq  = [1600 2200];	% freq range shown in yellow for detection
padTime     = [30 60];	% time shown to either side of detection, s
maxDispSec = 300;
selectTimePad = [0.5 0.5];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected