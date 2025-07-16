function [preamp_freq, preamp_gain] = measureWisprSensitivity(sn, sweep_file, hydro_sens, amp, attenuator, path_out)
% MEASUREWISPRSENSITIVITY	Measure WISPR sensitivity from calibration signal
%
%   Syntax:
%       OUTPUT = MEASUREWISPRSENSITIVITY(INPUT)
%
%   Description:
%       Detailed description here, please
%
%   Inputs:
%       input   describe, please
%
%	Outputs:
%       output  describe, please
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   15 July 2025
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check inputs

% check serial number (this is used for file name generation)
if ~exist('sn', 'var') || isempty(sn)
    % prompt for SN
    sn = 'XXXX'; % as example
    str = sprintf('Enter SN [%s]: ', sn);
    in = input(str, 's');
    if(~isempty(in))
        sn = in;
    end
end

% pick a data file for the data recorded using the signal generator
if ~exist('sweep_file', 'var') || ~exist(sweep_file, 'file')
    [file, dpath, filterindex] = uigetfile('*.dat', 'Pick a calibration signal file (.dat)');
    sweep_file = fullfile(dpath, file);
    fprintf('Selected calibration recording file %s\n', file);
end

% set hydrophone sensitivty - not used in calculation but stored in output
if ~exist('hydro_sens', 'var') || isempty(hydro_sens)
    % prompt for hydrophone sensitivity
    hydro_sens = -165;
    str = sprintf('Enter hydrophone sensitivity [%s]: ', hydro_sens);
    in = input(str, 's');
    if(~isempty(in))
        hydro_sens= in;
    end
end

% define the amplitude of calibration signal sine wave sweep
if ~exist('amp', 'var') || isempty(amp)
    amp = 0.010;
    str = sprintf('Enter input amplitude in volts [%f]: ', amp);
    in =  input(str);
    if(~isempty(in))
        amp = in;
    end
end

% Define input voltage if a 20db attenuator (20 dB)
% The 2 is because amp half of the differenceial signal
% Need to check that the attenuator 20db include the rms factor of sqrt(2)/2
if attenuator == true
    vin = 2 * amp / 10;
else
    vin = amp;
end

%% set up output filenames

% define name of output gain files
mat_file = fullfile(path_out, sprintf('%s_preamp_gain.mat', sn));
txt_file = fullfile(path_out, sprintf('%s_preamp_gain.txt', sn));
png_file = fullfile(path_out, sprintf('%s_preamp_gain.png', sn));


%% do stuff

% Read the calibration data file collected with a signal generator input
% [hdr, vout, time] = read_wispr_file(sweep_file, 2, 1024);

% first read header
[hdr, ~, ~] = read_wispr_file_agate(sweep_file, 0);

% only read up to 90 seconds or full file (to avoid loading giant files)
if hdr.file_duration > 90
    lastBuffer = round(90*hdr.sampling_rate/hdr.samples_per_buffer);
else
    lastBuffer = 0; % read everything
end

[hdr, vout, time] = read_wispr_file_agate(sweep_file, 2, lastBuffer);
% why does chris start on buffer 2?

%vout = sqrt(mean(data(:).^2)); % RMS
vout = vout(:);
% time = time(:);
% secs = time - time(1);

% downsample so plotted waveform fig isn't massive
d = 50;
plot_fs = hdr.sampling_rate/d;
tick_secs = 5;
% plot waveform of input calibration signal 
figure(1); clf;
% plot(secs(1:d:end,:), vout(1:d:end,:),'-');
plot(vout(1:d:end),'-');
xticks(1:(tick_secs*plot_fs):length(vout)/d); % ticks every 10 seconds
xTicks = get(gca, 'XTick');
xticklabels((xTicks-1)/plot_fs);
xlabel('Seconds');
ylabel('Volts');
grid on;
%axis([min(min(time)) max(max(time)) -5.1 5.1]);
title('Pick the start and end of one complete calibration sweep');

% pick a segment of the input data to use for calibration
% This should be at a minimum one complete sweep pulse
fprintf(1, 'Select a single sweep pulse from the input signal to use for calibration.\n');
fprintf(1, 'This should be one complete sweep pulse.\n');

% select start
bound = ginput(1);
hold on;
xline(bound(1));
start = floor(d * bound(1));

% select stop
bound = ginput(1);
xline(bound(1));
hold off;
stop = floor(d * bound(1)) + 1;

% trim to selection
vout = vout(start:stop);

figure(1); %clf;
plot(vout,'.-');
ylabel('Volts');
xlabel('Sample');
grid on;
%axis([min(min(time)) max(max(time)) -5.1 5.1]);

% Calc spectrum of vout/vin
fft_size = 256;
overlap = fft_size-64;
%window = rectwin(fft_size);
window = hamming(fft_size)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
fs = hdr.sampling_rate;
[spec, f] = cal_spec(vout/vin, fs, window, overlap, time(1));

preamp_gain = 10*log10(spec);
preamp_freq = f;

% plot spectrum
fig2 = figure(2); clf;
set(fig2, 'Position', [50 50 950 450]);
hold on;
plot(preamp_freq/1000, preamp_gain,'.-'); %normalize the power spec
grid(gca,'minor');
grid on;
xlabel('Frequency [kHz]'),
ylabel('20*log_{10}(V_{out} \\ V_{in}) [dB]');
%axis([0 f(end)/1000 -185 -135]);
title(sn, 'Interpreter', 'none');

% save the plot
print(fig2, '-dpng', png_file);

%save the data as mat file
save(mat_file, 'vout', 'vin', 'fs', 'preamp_freq', 'preamp_gain');

nbins = length(preamp_freq);

fp = fopen(txt_file, 'w');
fprintf(fp, 'PREAMP GAIN\r\n');
fprintf(fp, 'SN: %s\r\n', sn);
fprintf(fp, 'sensitivity: %.2f\r\n', hydro_sens);
fprintf(fp, 'nbins: %d\r\n', nbins);
fprintf(fp, 'dfreq: %.3f\r\n', preamp_freq(3) - preamp_freq(2));
for n=1:nbins
    fprintf(fp, '%.2f, %.2f\n', preamp_freq(n), preamp_gain(n));
end
fclose(fp);



