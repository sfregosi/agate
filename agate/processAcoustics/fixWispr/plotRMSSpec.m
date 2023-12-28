function plotRMSSpec(i1, t1, rms1, spec1, freq1, i2, t2, rms2, spec2, freq2)
% PLOTRMSSPEC	Create two-panel plot with RMS and spectra for comparison
%
%   Syntax:
%       PLOTRMSSPEC(I1, T1, RMS1, SPEC1, I2, T2, RMS2, SPEC2)
%
%   Description:
%       Creates a two-panel plot with RMS in the top panel and spectra in
%       the bottom panel. The RMS values are plotted for the 2 seconds at
%       the end of the first file and the first 2 seconds of the second
%       file. The spectra are plotted on the same axes to show any dB
%       offset. 
% 
%   Inputs:
%       i1     [double] indicies of rms values below max_thres, first file
%       t1     [double] time in seconds for first file samples
%       rms1   [double] rms values for each sample, first file
%       spec1  [double] calculated spectrum for last bit of first file
%       freq1  [double] frequency values for spectrum, first file
%       i2     [double] indicies of rms values below max_thres, second file
%       t2     [double] time in seconds for second file samples
%       rms2   [double] rms values for each sample, second file
%       spec2  [double] calculated spectrum for first bit of second file
%       freq2  [double] frequency values for spectrum, second file
%
%	Outputs:
%       none, generates figure
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%		Chris Jones
%
%   FirstVersion:   14 November 2023
%   Updated:
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blue = '#0072BD';
orange = '#D95319';

subplot(2,1,1);
plot(mean(t1(:,i1)), rms1(i1), '.', 'Color', blue)
hold on;
plot(mean(t2(:,i2)), rms2(i2), '.', 'Color', orange);
%semilogx(freq1/1000, 10*log10(spec1), '.-', freq2/1000, 10*log10(spec2), '.-'); %normalize the power spec
%plot(freq1/1000, 10*log10(spec1), '.-', freq2/1000, 10*log10(spec2), '.-'); %normalize the power spec
xlabel('Seconds');
ylabel('RMS');
xlim([min(mean(t1(:,i1))) max(mean(t2(:,i2)))])
hold off;

subplot(2,1,2);
%normalize the power spec
plot(freq1/1000, 10*log10(spec1), '.-', 'Color', blue);
hold on;
plot(freq2/1000, 10*log10(spec2), '.-', 'Color', orange); 
xlabel('Frequency [kHz]');
ylabel('dB');
legend('First file', 'Second file');
hold off;
