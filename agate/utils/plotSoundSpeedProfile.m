function plotSoundSpeedProfile(locCalcT, savePath)
% read in glider locCalc file and create a plot of sound speed.
% plot mean and median thicker on top of profiles for every individual dive

% inputs:
% locCalcT: .mat file (with full path) with table of glider sensor data
% extracted using positionalDataExtractor - needs to have cols for
% soundVelocity and depth
% if file not specified, will prompt for file
% savePath: path to save .fig and .png. leave empty to not save
% automatically
% If saving, will prompt input for figure title in Command Window

% S. Fregosi updated 2020/11/12

if nargin < 2
    savePath = [];
end

if nargin < 1
    [file_in, path_in] = uigetfile('*.mat', 'Select locCalcT file');
    % path_in = ['G:\score\2015\profiles\' gldr '_' lctn '_' dplymnt '\'];
    % load([file_in gldr '_' lctn '_' dplymnt '_locCalcT_pam.mat']);
    
    load([path_in file_in]);
end

figure;
plot(locCalcT.soundVelocity,-locCalcT.depth,'Color',[0.8 0.8 0.8], 'HandleVisibility', 'off')
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
    meanTmp = nanmean(locCalcT.soundVelocity(r));
    medianTmp = nanmedian(locCalcT.soundVelocity(r));
    meanSSP(b,2) = meanTmp;
    medianSSP(b,2) = medianTmp;
end

plot(meanSSP(:,2), meanSSP(:,1), 'k','LineWidth',2)
plot(medianSSP(:,2), medianSSP(:,1), 'k--', 'LineWidth',2)

legend('mean', 'median', 'Location', 'southeast')
if ~isempty(savePath)
    titleString = input('Figure title string: ','s');
    title(titleString,'Interpreter','none');
    print([savePath titleString '_SSP.png'],'-dpng')
    savefig([savePath titleString '_SSP.fig'])
end

end