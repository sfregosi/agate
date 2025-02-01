function [y,var] = defaultsrate
% defaultsrate   Return the default sampling rate of the machine.
%
% y = defaultsrate
%   Return the default sampling rate available with the current hardware.
%   This may be a vector of several available sampling rates.
%
% [y,variablesrate] = defaultsrate
%   Return the default sampling rate(s) and a flag that says whether the
%   underlying hard/software can play variable sampling rates.  On a Mac,
%   variable sampling rates are implemented with hard/software interpolation.


c = computer;
var = iff(version4, 0, 1);

if     (strcmp(c(1:3), 'SUN')), y = 8000;			% SunOS
elseif (strcmp(c(1:3), 'SOL')), y = 8000; 			% Solaris
elseif (strcmp(c(1:3), 'LNX')), y = 8192; 			% Linux
elseif (strcmp(c(1:3), 'GLNX')),y = 8192; 			% Linux
elseif (strcmp(c(1:3), 'MAC')), y = 22254 + 54/99; var = 1;
elseif (strcmp(c,      'NEXT')),y = 22050;			% or 44100?
elseif (strcmp(c(1:3), 'SGI')), y = 22254 + 54/99; var = 1;
elseif (strcmp(c(1:2), 'HP')),  y = 8192;			% HP UX
elseif (strcmp(c, 'PCWIN64')),  y = 48000; var = 1;		% for all PCs??
elseif (strcmp(c(1:2), 'PC')),  y = 8192; var = 1;		% what's right?

else
  disp(['Don''t know default sampling rate for machine ' c '.  If you know']);
  disp('it, please fix defaultsrate.m and send mail to')
  disp('David.Mellinger@oregonstate.edu .');
  error('Unknown sampling rate for this machine (see defaultsrate.m)');
end
