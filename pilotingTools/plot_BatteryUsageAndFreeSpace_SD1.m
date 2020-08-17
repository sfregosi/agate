function plot_BatteryUsageAndFreeSpace_SD1(glider, pp)

figure(450); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
yyaxis left
plot(timeDays, (310 - pp.ampHrConsumed)/310*100, 'LineWidth', 2)
ylim([0 100]);ylabel('Remaining battery %');
xlim([0 50]); xlabel('Days in Mission');
yyaxis right
plot(timeDays, pp.PM_FREEGB + 500, 'LineWidth', 2)
ylim([0 1000]);ylabel('Free Space [GB]');
hline(507, 'k:')

grid on; title(['Glider ' glider ' Battery Usage and Free Space']);
yyaxis left
hline(30, 'k--')
vline(45, 'k-.')
set(gca, 'FontSize', 14)
set(gcf, 'Position', [1650    700    800    650])


end

