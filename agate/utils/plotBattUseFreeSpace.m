function plotBattUseFreeSpace(CONFIG, pp, A0_24V, tmd)
% PLOTBATTUSEFREESPACE	Plot battery usage free space (acoustics) remaining 
%
%	Syntax:
%		PLOTBATTUSEFREESPACE(CONFIG, PP, A0_24V, TMD)
%
%	Description:
%		Plot of battery usage (as a percent, left yaxis) and free space
%		remaining on the acoustic SD card (right yaxis) over the course of
%		the deployment. A target mission duration (in days) can be
%		specified as well as horizontal lines for battery and data space
%		margins of error (e.g., 7% capacity left on SD card)
%
%	Inputs:
%		CONFIG      Mission/agate global configuration variable
%       pp          Piloting parameters table created with 
%                   extractPilotingParams.m
%       A0_24V      Value of the $A0_24V parameter with total available amp
%                   hours for this glider (e.g., 310 for 15V system)
%       tmd         target mission duration in days
%
%	Outputs:
%		no output, creates figure
%
%	Examples:
%       plotBattUseFreeSpace(CONFIG, pp639, 310, 60)
%	See also
%       extractPilotingParams
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	13 April 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 3
    tmd = [];
end

figNum = CONFIG.figNumList(1);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
yyaxis left
plot(timeDays, (A0_24V - pp.ampHrConsumed)/A0_24V*100, 'LineWidth', 2)
ylim([0 100]);ylabel('Remaining battery %');
xlim([0 tmd + 10]); xlabel('Days in Mission');

yyaxis right
uniqueCards = unique(pp.activeCard);
lineStyles = {'-', ':', '-', '-.'}; % options for up to 4 cards.
for f = 1:length(uniqueCards)
    ac = uniqueCards(f);
    % this card only
    tmpTimeDays = timeDays(pp.activeCard == ac);
    tmpFreeGB = pp.(['pmFree_' num2str(ac,'0%d') '_GB'])(pp.activeCard == ac);
    plot(tmpTimeDays, tmpFreeGB, lineStyles{f}, 'LineWidth', 2)
    ylim([0 500]);ylabel('Free Space [GB]');
    hline(35, 'k:'); % don't let free space drop below 7%/35 GB or it will stop recording
    hold on;
end
hold off;

grid on; title(['Glider ' dPARAMS.glider ' Battery Usage and Free Space']);
yyaxis left
hline(30, 'k--') % 30% battery safety threshold
if ~isempty(tmd)
    vline(tmd, 'k-.')
end
set(gca, 'FontSize', 14)

set(gcf, 'Position', [0    40    600    400])


end

