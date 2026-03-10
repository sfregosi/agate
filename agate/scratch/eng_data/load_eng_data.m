clearvars

dir_in='D:\SeaGlider\processing\sg639\Gulf_of_Mexico_2018\2018_05_10_deploymnet\dive_0157';

% load and parse engineering data
eng = read_eng([dir_in '\p6390157.eng']);

% get time stamps
Timeinsec  = eng.elaps_t;
mp = length(Timeinsec);

delta_t =  zeros(mp,1);
delta_t(1:mp-1) = Timeinsec(2:mp) - Timeinsec(1:mp-1);
delta_t(mp) = delta_t(mp-1);

% Motor control variables
pitch_control = eng.pitchCtl;
roll_control  = eng.rollCtl;
vbd           = eng.vbdCC;

%=======================================
% find changes in control signals
%=======================================
% PITCH
pitchdiff = zeros(mp,1);
pitchdiff(2:mp) = diff(pitch_control);

% ROLL
rolldiff = zeros(mp,1);
rolldiff(2:mp)  = diff(roll_control);

% VBD
vbddiff = zeros(mp,1);
vbddiff(2:mp)  = diff(vbd)./delta_t(2:mp);

Depth = eng.depth;

sgtime = Timeinsec/60; % time in minutes
dive_duration = sgtime(end);

% Plot Depth
d=plot(sgtime, Depth, '-r');

hold on
% Mark and plot non-zero VBD motor current
ivb = find( vbddiff > 0.5 );
v=plot(sgtime(ivb), Depth(ivb), '.k', 'markersize', 15);

%
% Mark and plot negative (port) and positive (starboard) roll changes
irn = find( fix(rolldiff) - abs( fix(rolldiff) ) );
irp = find( fix(rolldiff) + abs( fix(rolldiff) ) );
rp=plot(sgtime(irn), Depth(irn), '<b');
rs=plot(sgtime(irp), Depth(irp), '>c');

% Mark and plot negative (downward) and positive (upward) pitch changes
pitchc = fix(10.*pitchdiff);
ipn = find( fix(pitchc) - abs( fix(pitchc) ) );
ipp = find( fix(pitchc) + abs( fix(pitchc) ) );
pd=plot(sgtime(ipn), Depth(ipn), 'vg');
pu=plot(sgtime(ipp), Depth(ipp), '^m');

xlabel('Time (minutes)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Depth (m)', 'FontSize', 12, 'FontWeight', 'bold');
set(gca,'ydir','reverse');

h = legend([d v rp rs pd pu], 'Depth, (m)', ...
  'VBD motor ON', ...
  'Roll motor to Port', ...
  'Roll motor to Starboard', ...
  'Pitch motor downward', ...
  'Pitch motor upward');
set(h,'location','north');
