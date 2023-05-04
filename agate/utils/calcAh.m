function Ah = calcAh(secs, mAmps)
% CALCAHBYDEVICE	calculate Ah from seconds and mAmps
%	Syntax:
%		OUTPUT = CALCAH(SECS, MAMPS, VS)
%
%	Description:
%		Calculate total amp hours from seconds and milliamps. Useful for
%		getting Ah used by a single device from the $DEVICE_SECS and
%		$DEVICE_MAMPS reported in a Seaglider .log file.
%
%	Inputs:
%		secs    seconds on
%       mAmps   current draw
%
%	Outputs:
%		Ah      amp hours
%
%	Examples:
%       Ah = calcAh(120, 18);
%	See also
%       calckJ
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	26 April 2023
%	Updated:        4 May 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% full equation
% Ah = seconds * mAmps * (1 amp/1000 mAmps) * (1 mAh/3.6 J) * (1 Ah/1000 mAh)

% simplified
Ah = secs.*mAmps/1000/3.6/1000;
end
