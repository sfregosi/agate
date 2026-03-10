function [des, asc] = splitProfilesFast(locCalcT, threshold)
% SPLITPROFILESFAST	Split dive data into descent/ascent phases based on depth change
%
%   Syntax:
%       [DES, ASC] = SPLITPROFILESFAST(CONFIG, GPSSURFT, LOCCALCT, THRESHOLD)
%
%   Description:
%       Split dive data into descent and ascent phases based on a specified
%       depth change rate (threshold). It is very fast and only requires
%       the locCalcT input table but it is imperfect around surfacings. 
% 
%       This function was inspired by spilt_sg_profile.py by J. Marquardt.
%
%   Inputs:
%       threshold  [double] depth change rate (m/s) below which triggers a
%                  profile change. Default is 0.07
%
%	Outputs:
%       des     [table]
%       asc     [table]
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 December 2025
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    threshold = 0.07;
end

% Compute depth change rate
depthChange = gradient(locCalcT.depth)./gradient(locCalcT.time);

% Identify descent and ascent points
idxDes  = depthChange >  threshold;
idxAsc = depthChange < -threshold;

% Separate out
des  = locCalcT(idxDes, :);
asc = locCalcT(idxAsc,: );

% plot test
% figure(26);
% plot(locCalcT.time, -locCalcT.depth, 'k');
% hold on;
% plot(asc.time, -asc.depth, 'm.');
% plot(des.time, -des.depth, 'g.');
end