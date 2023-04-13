function plot_humidityPressure(dPARAMS, pp)

figNum = dPARAMS.figNumList(3);

figure(figNum); clf;
timeDays = datenum(pp.diveEndTime) - datenum(pp.diveStartTime(1));
subplot(211);
plot(timeDays, pp.HUMID, '.');
xlim([0 max(timeDays)+5]);
ylabel('humidity');
title(['Glider ' dPARAMS.glider ' Humidity']);
set(gca, 'FontSize', 14)
grid on;

subplot(212);
plot(timeDays, pp.INTERNAL_PRESSURE, '.');
xlim([0 max(timeDays)+5]); xlabel('Days in Mission');
ylabel('internal pressure');
title(['Glider ' dPARAMS.glider ' Internal Pressure']);
set(gca, 'FontSize', 14)
grid on;

set(gcf, 'Position', [1200    40    600    400])

end

