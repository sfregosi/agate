function plotSoundSpeedProfile(CONFIG, locCalcT)
%PLOTSOUNDSPEEDPROFILE	Plot sound speed profile
%
%   Syntax:
%       PLOTSOUNDSPEEDPROFILE(locCalcT)
%
%   Description:
%       Read in glider locCalcT data variable and create a plot of sound
%       speed with individual sound speed profiles for every dive in grey
%       and the mean and median thicker and in black over the top.
%
%   Inputs:
%       CONFIG      global agate mission configuration variable (for plot
%                   titles)
%       locCalcT    matlab object with table of glider sensor data
%                   extracted with extractPositionalData. Must contain
%                   columns for soundVelocity and depth
%
%   Outputs:
%       no output, creates figure
%
%   Examples:
%
%   See also EXTRACTPOSITIONALDATA
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   12 November 2020 (last known date)
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CONFIG

figure;
plot(locCalcT.soundVelocity, -locCalcT.depth, 'Color', [0.8 0.8 0.8 0.3], ...
    'HandleVisibility', 'off')
hold on
ylim([-1010 10]);
xlabel('sound speed [m/s]')
ylabel('depth [m]')
set(gca,'FontSize',14)
grid on

% get mean for each depth, 'res' meter resolution
res = 5;
meanSSP = zeros(1000/res + 1,2);
medianSSP = zeros(1000/res + 1,2);
b = 0;

for d = 0:res:1000 % to 1000 m
    b = b + 1;
    meanSSP(b,1) = -d;
    medianSSP(b,1) = -d;
    [r, ~] =  find(locCalcT.depth >= d & locCalcT.depth < (d + res));
    meanTmp = mean(locCalcT.soundVelocity(r), 'omitnan');
    medianTmp = median(locCalcT.soundVelocity(r), 'omitnan');
    meanSSP(b,2) = meanTmp;
    medianSSP(b,2) = medianTmp;
end

plot(meanSSP(:,2), meanSSP(:,1), 'k','LineWidth',2)
plot(medianSSP(:,2), medianSSP(:,1), 'k--', 'LineWidth',2)

legend('mean', 'median', 'Location', 'southeast')

title(['Sound Speed Profile: ' CONFIG.glider '_' CONFIG.mission], ...
    'Interpreter','none');

end