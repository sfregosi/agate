function plotLandmarks


iColor = [0 0 0];
% label san pedro
h = plotm(33.74, -118.29, 'Marker', 'p', 'MarkerSize', 8, 'MarkerEdgeColor', [1 1 1], ...
    'MarkerFaceColor', [1 1 1], 'Color', [1 1 1], 'DisplayName','');
% turn the legend plotting for san pedro off
set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
textm(33.68, -118.48, 'San Pedro', 'Color', iColor, 'FontSize', 12)

% label islands
% textm(32.9, -118.87, sprintf('       San \n Clemente'), 'Color', iColor, 'FontSize', 12)
textm(33.08, -118.6, sprintf('San \n   Clemente'), 'Color', [0 0 0], 'FontSize', 12)
textm(33.47, -118.5, sprintf('Santa\n       Catalina'), 'Color', iColor, 'FontSize', 12)
textm(33.32, -119.76, sprintf('San Nicolas'), 'Color', iColor, 'FontSize', 12)
% textm(33.58, -119.24, sprintf('  Santa \nBarbara'), 'Color', iColor, 'FontSize', 12)
textm(33.48, -119.32, sprintf('  Santa\nBarbara'), 'Color', iColor, 'FontSize', 12)

bColor = [0.4 0.4 0.4];
% label banks
textm(32.68, -119.2, '\it{Tanner Bank}', 'Color', bColor, 'FontSize', 10)
textm(32.42, -119.25, '\it{Cortes Bank}', 'Color', bColor, 'FontSize', 12)
textm(31.98, -118.27, {'\itSixtymile', '\itBank'}, 'Color', bColor', 'FontSize', 10)
textm(32.92, -119.52, '\it{Cherry Bank}', 'Color', bColor', 'FontSize', 10) 
% % turn legend plotting back on
% set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');

end
