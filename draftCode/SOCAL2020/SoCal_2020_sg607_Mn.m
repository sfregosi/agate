%%%%%%%%%%%% Humpback whales SoCal 2020 Glider SG607 %%%%%%%%%%%%

% timeIncr = 1 / (24*60*60);	% check all detections
% timeIncr = 1;                   % check one detection per day
timeIncr = 1/(24*60);			% check one detection hour


% Sound files and index:
snddir = 'E:\SoCal2020\sg607_downsampled\sg607-5kHz\';
indexpath = [snddir 'file_dates-sg607_SoCal_Feb20-5kHz.txt'];

% Log files:
logdir = 'E:\SoCal2020\largeWhaleAnalysis\Mn\Mn_sg607\';
% inlogpath  = [logdir 'detections_GPL_v2_150_1000_sg607_SOCAL_Feb20_exampleFiles.log'];
inlogpath  = [logdir 'detections_GPL_v2_150_1000_sg607_SOCAL_Feb20_allFiles.log'];
outlogpath = [pathRoot(inlogpath) '-checked.log'];

% Display info:
displayFreq = [100 2500];	% freq range to show in Osprey
selectFreq  = [2200 2400];	% freq range shown in yellow for detection
padTime     = [6 6];	% time shown to either side of detection, s
maxDispSec = 300;
selectTimePad = [0.5 0.5];	% time offset for selection
searchstr = 'Call detected'; % label of each call detected