function plot_voltagePackUse(dPARAMS, pp)

figNum = dPARAMS.figNumList(2);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.pkJ, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ, 'LineWidth', 2);
plot(timeDays, pp.vkJ, 'LineWidth', 2);
plot(timeDays, pp.PMAR_kJ, 'LineWidth', 2);
ylim([0 30]); ylabel('energy [kJ]');
xlim([0 max(timeDays)+5]); xlabel('Days in Mission');
grid on;
hold off;

title(['Glider ' dPARAMS.glider ' Usage By Device']);
set(gca, 'FontSize', 14)
set(gcf, 'Position', [600    40    600    400])

legend('pitch motor', 'roll motor', 'vbd motor', 'pmar')
end

