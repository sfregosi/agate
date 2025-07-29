function [paFreq, paGain] = measureWisprSensitivity(sn, sweep_file, ...
    hydro_sens, fRes, amp, dur, attenuator, path_out)
% MEASUREWISPRSENSITIVITY	Measure WISPR sensitivity from calibration signal
%
%   Syntax:
%       [PAFREQ, PAGAIN] = MEASUREWISPRSENSITIVITY(SN, SWEEP_FILE, HYDRO_SENSE, AMP, ATTENUATOR, PATH_OUT)
%
%   Description:
%       This function calculates and plots a WISPR preamp calibration gain
%       curve from a calibration sweep input file.
%
%       The calibration input signal is a constant voltage frequency sweep
%       over the range of interest, typically from 0 to 200 kHz (the upper
%       limit of the sample rate) over at least 10 or 20 seconds. The
%       longer the sweep, the better. This is the input voltage (vin). The
%       recorded signal is the output voltage (vout) and is the output of
%       the preamp and adc; it includes all the preamp gain stages and the
%       filter including the high pass and low pass analog filters and the
%       digital anti-aliasing filters of the adc.
%
%       Gain is calculated as (vout) / (vin) expressed in dB for each
%       frequency bin over the range of interest. The calibrat
%
%       The output .txt file can be read by wispr or provided as input to
%       agate's generateWisprSystemSensitivity function to be combined with
%       system gain and hydrophone sensitivity to export overall system
%       sensitivity for calibrated sound analysis.
%
%       NOTE. This function is modified from the preamp_cal.m script
%       (c. jones 02/2025) found in https://github.com/embeddedocean/wispr3
%       Modifications functionized the script and made it more customizable
%       for different gliders.
%
%   Inputs:
%       sn          [char] serial number of WISPR3 board being measured
%       sweep_file  [char] fullfile path to calibration sweep data file.
%                   Input is raw .dat format
%       hydro_sens  [double] hydrophone sensitivity, single number. It is
%                   not used in the calculation but is written to the
%                   output text file
%       fRes        [integer] target approx frequency resolution of sampled
%                   points, in Hz. e.g., 100. fft_size will be calculated
%                   from sample rate and fRes. Default is 1000 Hz.
%       amp         [integer] voltage of input sweep signal, in volts
%       dur         [integer] duration of input sweep, in seconds
%       attenuator  [logical] true or false if a 20 dB attenuator was used
%                   on the output signal
%       path_out    [char] fullfile path to the folder to save the three
%                   output files (.txt, .mat, .png)
%
%	Outputs:
%       paFreq      [n-by-1 double] frequencies that sensitivity was
%                   measured at
%       paGain      [n-by-1 double] sensitivity gain in dB
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2025 July 28
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

% define the desired frequency resolution of the outut gain curve
if ~exist('fRes', 'var') || isempty(fRes)
    dur = 1000;
    str = sprintf('Enter target frequency resolution in Hz [%f]: ', fRes);
    in =  input(str);
    if(~isempty(in))
        fRes = in;
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

% define the duration of calibration signal sine wave sweep
if ~exist('dur', 'var') || isempty(dur)
    dur = 20;
    str = sprintf('Enter input sweep duration in seconds [%f]: ', dur);
    in =  input(str);
    if(~isempty(in))
        dur = in;
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


%% read in and mark sweep

% Read the calibration data file collected with a signal generator input
% [hdr, vout, time] = read_wispr_file(sweep_file, 2, 1024);

% first read header
[hdr, ~, ~] = read_wispr_file_agate(sweep_file, 0);

% only read up to 120 seconds or full file (to avoid loading giant files)
if hdr.file_duration > 120
    lastBuffer = round(120*hdr.sampling_rate/hdr.samples_per_buffer);
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
hold off;

% define stop based on sweep duration and sample rate
stop = start + dur*hdr.sampling_rate;

% % manually select stop
% bound = ginput(1);
% xline(bound(1));
% hold off;
% stop = floor(d * bound(1)) + 1;

% trim to selection
vout = vout(start:stop);

figure(1); %clf;
plot(vout,'.-');
ylabel('Volts');
xlabel('Sample');
grid on;
%axis([min(min(time)) max(max(time)) -5.1 5.1]);

%% Calc spectrum of vout/vin
% choosing appropriate fft_size is ????
% want good resolution at low frequencies without a lot of 'noise' at the
% higher frequencies where things are flatter (like above 1 kHz)
target_resolution = fRes; % in Hz
fft_size = 2^nextpow2(hdr.sampling_rate/target_resolution);
overlap = fft_size-(fft_size/4);
%window = rectwin(fft_size);
window = hamming(fft_size)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
fs = hdr.sampling_rate;
[spec, f] = cal_spec(vout/vin, fs, window, overlap, time(1));

paGain = 10*log10(spec);
paFreq = f;


%% set up output filenames

% define name of output gain files
mat_file = fullfile(path_out, sprintf('%s_preamp_gain_fftSize%i_%s.mat', ...
    sn, fft_size, datetime('now', 'Format', 'yyyy-MM-dd')));
txt_file = fullfile(path_out, sprintf('%s_preamp_gain_fftSize%i_%s.txt', ...
    sn, fft_size, datetime('now', 'Format', 'yyyy-MM-dd')));
png_file = fullfile(path_out, sprintf('%s_preamp_gain_fftSize%i_%s.png', ...
    sn, fft_size, datetime('now', 'Format', 'yyyy-MM-dd')));

%% save stuff

%save the data as mat file
save(mat_file, 'vout', 'vin', 'fs', 'paFreq', 'paGain');

% plot spectrum
fig2 = figure(2); clf;
set(fig2, 'Position', [50 50 950 450]);
hold on;
plot(paFreq/1000, paGain,'.-'); %normalize the power spec
grid(gca,'minor');
grid on;
xlabel('Frequency [kHz]'),
ylabel('20*log_{10}(V_{out} \\ V_{in}) [dB]');
%axis([0 f(end)/1000 -185 -135]);
title(sn, 'Interpreter', 'none');

% save the plot
print(fig2, '-dpng', png_file);

% write the text file
nbins = length(paFreq);

fp = fopen(txt_file, 'w');
fprintf(fp, 'PREAMP GAIN\r\n');
fprintf(fp, 'SN: %s\r\n', sn);
fprintf(fp, 'sensitivity: %.2f\r\n', hydro_sens);
fprintf(fp, 'nbins: %d\r\n', nbins);
fprintf(fp, 'dfreq: %.3f\r\n', paFreq(3) - paFreq(2));
for n=1:nbins
    fprintf(fp, '%.2f, %.2f\n', paFreq(n), paGain(n));
end
fclose(fp);


end


