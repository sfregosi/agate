function [min_sig mx_sig] = calcDensityRange(data, lat, lon)

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\fileExchange\ocean\'))

% truncate the data to just above 1000 m
data = data(data.Depth <= 1000, :);
t = data.Temp;
s = data.Sal;
d = data.Depth;

% calculate pressure based on depth and latitude
p = z2p80(d,lat);

sig = sigma(p,t,s);
min_sig = min(sig);
mx_sig = max(sig);

% figure;
% plot(sig,-d);
% hold on;
% plot(t,-d)
% plot(s,-d)
% ylim([-1100 0])
% legend('density','temp','salinity')
% title(sprintf('lat: %f lon: %f',lat,lon))
end