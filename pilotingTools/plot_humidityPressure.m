function plot_humidityPressure(glider, pp)

figure(452); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
subplot(211);
plot(timeDays, pp.HUMID, '.');
xlim([0 60]);
ylabel('humidity');
title(['Glider ' glider ' Humidity']);
set(gca, 'FontSize', 14)
grid on;

subplot(212);
plot(timeDays, pp.INTERNAL_PRESSURE, '.');
xlim([0 60]); xlabel('Days in Mission');
ylabel('internal pressure');
title(['Glider ' glider ' Internal Pressure']);
set(gca, 'FontSize', 14)
grid on;

set(gcf, 'Position', [50    700    800    650])

end

