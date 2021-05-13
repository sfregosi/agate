plotLegendFinWhales

% DOES NOT WORK!!! 

h = zeros(3,1);


h(2) = plot(sample_points,calc_data_2(1,:),'b-'); 
h(3) = plot(sample_points,calc_data_1(1,:),'ks');
h(4) = plot(sample_points,calc_data_1(2,:),'kd');
h(5) = plot(sample_points,calc_data_1(3,:),'ko');
h(6) = plot(sample_points,calc_data_1(3,:),'ko');

legend(h, 'Location', 'northwest')

% Generate random data
sample_points = 0:0.1:10; 
calc_data_1 = sin(2*pi*[sample_points;sample_points;sample_points]) + ...    
            0.1*randn(3,101);
calc_data_2 = cos(2*pi*[sample_points;sample_points;sample_points]) + ... 
            0.1*randn(3,101);
% Generate dummy info for plot handles "h"
h = zeros(5,1);
h(1) = plot(sample_points,calc_data_1(1,:),'r-'); hold on;
h(2) = plot(sample_points,calc_data_2(1,:),'b-'); 
h(3) = plot(sample_points,calc_data_1(1,:),'ks');
h(4) = plot(sample_points,calc_data_1(2,:),'kd');
h(5) = plot(sample_points,calc_data_1(3,:),'ko');
% Plot things the right way
plot(sample_points,calc_data_1(1,:),'rs-');
plot(sample_points,calc_data_1(2,:),'rd-');
plot(sample_points,calc_data_1(3,:),'ro-');
plot(sample_points,calc_data_2(1,:),'bs-');
plot(sample_points,calc_data_2(2,:),'bd-');
plot(sample_points,calc_data_2(3,:),'bo-'); hold off;
% Define legend according to handles "h"
legend(h,'M elements used','N elements used','P time steps','Q time steps','R time steps')