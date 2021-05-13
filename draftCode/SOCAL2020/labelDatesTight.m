function labelDatesTight(glider)


% label dates at several waypoints
% BUT DO NOT INCLUDE WAYPOINT LABELS
path_piloting = ['C:\Users\selene\Box\HDR-SOCAL-2020\piloting\' glider '\'];
targetsFile = readTargetsFile(glider, path_piloting);

wpColor = [0.3 0.3 0.3];

if strcmp(glider, 'sg607')
    textm(targetsFile.lat(1), targetsFile.lon(1) + 0.02, ...
        '07 Feb 15:20', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(3) - 0.01, targetsFile.lon(3), ...
        '11 Feb 06:35', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(9)- 0.03, targetsFile.lon(9), ...
        '23 Feb 07:41', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(12), targetsFile.lon(12), ...
        '03 Mar 01:42', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(16)- 0.02, targetsFile.lon(16), ...
        '07 Mar 09:51', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(19), targetsFile.lon(19), ...
        '14 Mar 18:06', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(23), targetsFile.lon(23), ...
        '22 Mar 23:36', 'Color', wpColor, 'FontSize', 10)
    %     textm(targetsFile.lat(25), targetsFile.lon(25) + 0.06, ...
    %         '27 Mar 01:23', 'Color', wpColor, 'FontSize', 10)
    textm(32.46673333, -118.4890667 + 0.03, ...
        '27 Mar 19:18', 'Color', wpColor, 'FontSize', 10)
    textm(32.98, -118.27,  ...
        '31 Mar', 'Color', wpColor, 'FontSize', 10)
    
elseif strcmp(glider, 'sg639')
    
    % label dates at several waypoints
    wpColor = [0.3 0.3 0.3];
    textm(targetsFile.lat(1), targetsFile.lon(1) + 0.02, ...
        '07 Feb 16:55', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(2), targetsFile.lon(2) + 0.02, ...
        '09 Feb 01:39', 'Color', wpColor, 'FontSize', 10)
    textm(targetsFile.lat(3) + 0.04, targetsFile.lon(3) - 0.08, ...
        '10 Feb 22:34', 'Color', wpColor, 'FontSize', 10)
    textm(32.6250, -119.93, ...
        '12 Feb 21:02', 'Color', wpColor, 'FontSize', 10)
    
end


end