function kJ = calckJ(secs, mAmps, V)
%CALCKJ	Calculate kJ from glider reported secs and mAmps and voltage
%
%   Syntax:
%       kJ = CALCKJ(secs, mAmps, V)
%
%   Description:
%      Calculates kJ from seconds, milliamps, and voltage
%
%   Inputs:
%       secs    Seconds on
%       mAmps   Current draw
%       vs      Voltage of glider batteries
%
%   Outputs:
%       kJ      Kilojoules consumed 
%
%	Examples:
%       kJ = calckJ(100, 20, 15)
%          kJ =
%                0.03
%
%	See also CALCAH
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion: 	03 May 2023
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% full equation
% kJ = seconds * mAmps * (1 amp/1000 mAmps) * volts * (1 kJ/1000 J)

% simplified
kJ = secs*mAmps*V/1000000;

end
