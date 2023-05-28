function output = plotPmUsed(CONFIG, pp)
% PLOTPMUSED	Create PMAR diagnostic plots
%
%   Syntax:
%       PLOTPMUSED(CONFIG)
%
%   Description:
%       Creates a two-panel figure with some PMAR outputs for checking
%       PMAR operational status. PMAR space used vs dive duration in
%       the upper panel, and PMAR space used per minute over time in the
%       lower panel.
%
%   Inputs:
%       CONFIG   [struct] agate global mission configuration structure
%       pp       [table] Piloting parameters table created with
%                extractPilotingParams.m
%
%	Outputs:
%       None. Generates figure.
%
%   Examples:
%
%   See also PLOTBATTUSEFREESPACE
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   27 May 2023
%   Updated:        28 May 2023
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if CONFIG.pm.loggers == 0 || ~isfield('pm', CONFIG)
	fprintf(1, 'PMAR logger not available, cannot plot PMAR space used. Exiting...\n')
	return
end

% for now just manually assign...to be worked out later...
figNum = 548;
% figNum = CONFIG.plots.figNumList(6);
% set position
figPosition = [100   100    760    400];
% % overwrite if in config
% if isfield(CONFIG.plots, 'positions')
%     % is a position defined for this figure
%     fnIdx = find(figNum == CONFIG.plots.figNumList);
%     if length(CONFIG.plots.positions) >= fnIdx && ~isempty(CONFIG.plots.positions{fnIdx})
%         figPosition = CONFIG.plots.positions{fnIdx};
%     end
% end

figure(figNum); 
set(gcf, 'Name', 'PMAR Use');
clf;

t = tiledlayout(2,1);

% plot space used vs dive duration
nexttile(1)
plot(pp.diveDur_min, pp.pmUsed_GB, 'k.');
hold on;
% highlight the last 5 dives
plot(pp.diveDur_min(end-4:end), pp.pmUsed_GB(end-4:end), 'co')
grid on;
hold off;
xlabel('dive duration [min]');
ylabel(sprintf('PMAR space\nused [GB]'));
set(gca, 'FontSize', 12)

% space used/dive dur over time
nexttile(2)
plot(pp.diveStartTime, pp.pmUsed_GB./pp.diveDur_min*100, 'k');
hold on;
% add vertical lines for card switches
uac = unique(pp.activeCard);
for u = 1:length(uac)
	acIdx = find(uac(u) == pp.activeCard, 1, 'first');
	xline(pp.diveStartTime(acIdx), '--', 'Color', '#900C3F');
end
grid on;
% xlabel('date');
ylabel(sprintf('PMAR space\nused [MB/min]'));
set(gca, 'FontSize', 12)

% set final plot postions
t.TileSpacing = 'compact';
set(gcf, 'Position', figPosition)

end

