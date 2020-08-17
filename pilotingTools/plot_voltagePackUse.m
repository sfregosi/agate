function plot_voltagePackUse(glider, pp)

figure(451); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
plot(timeDays, pp.pkJ, 'LineWidth', 2);
hold on;
plot(timeDays, pp.rkJ, 'LineWidth', 2);
plot(timeDays, pp.vkJ, 'LineWidth', 2);
plot(timeDays, pp.PMAR_kJ, 'LineWidth', 2);
ylim([0 30]); ylabel('energy [kJ]');
xlim([0 60]); xlabel('Days in Mission');
hold off;

grid on; title(['Glider ' glider ' Usage By Device']);
set(gca, 'FontSize', 14)
set(gcf, 'Position', [850    700    800    650])

legend('pitch motor', 'roll motor', 'vbd motor', 'pmar')
end

