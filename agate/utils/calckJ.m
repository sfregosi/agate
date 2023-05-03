function kJ = calckJ(secs, mAmps, V)
% CALCKJ	Calculate kJ from glider reported secs and mAmps and voltage
%
%	Syntax:
%		OUTPUT = CALCKJ(SECS, MAMPS, VS)
%
%	Description:
%		Detailed description here, please
%	Inputs:
%		secs    seconds on
%       mAmps   current draw
%       vs      voltage of glider batteries
%
%	Outputs:
%		kJ      kilojoules consumed 
%
%	Examples:
%       kJ = calckJ(100, 20, 15);
%   kJ =
%                     0.03
%
%	See also
%       calcAh
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	03 May 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% full equation
% kJ = seconds * mAmps * (1 amp/1000 mAmps) * volts * (1 kJ/1000 J)

% simplified
kJ = secs*mAmps*V/1000000;

end
