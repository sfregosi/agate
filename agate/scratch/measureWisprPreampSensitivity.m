function [paFreq, paGain] = measureWisprPreampSensitivity(sn, sweep_file, ...
    hydro_sens, amp, dur, attenuator, path_out, out_file_name)
% MEASUREWISPRPREAMPSENSITIVITY	Measure WISPR preamp sensitivity from calibration signal
%
%   Syntax:
%       [PAFREQ, PAGAIN] = MEASUREWISPRPREAMPSENSITIVITY(SN, SWEEP_FILE, HYDRO_SENSE, AMP, DUR,ATTENUATOR, PATH_OUT, OUT_FILE_NAME)
%
%   Description:
%       This function calculates and plots a WISPR preamp sensitivity gain
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
%       frequency bin over the range of interest. The resolution of the
%       sample frequencies will differ slightly based on the sampling rate
%       but is set to approximately be every 50 Hz for all frequencies
%       below 2 kHz and above 89% of the Nyquist (e.g., for 200 kHz sample
%       rate, above 89 kHz) and 500 Hz between 2 kHz and near the Nyquist.
%       These resolutions were selected to balance creating a relatively
%       smooth gain curve that still captures the variability, especially
%       at the very low and very high frequencies. The transition near the
%       Nyquist is not perfectly smooth but the attenuation is very high at
%       those frequencies from the anti-aliasing filter so it is deemed
%       acceptable. These target resolutions and limits could be modified 
%       if desired.
%
%       The output .txt file can be read by wispr or provided as input to
%       agate's generateWisprSystemSensitivity function to be combined with
%       system gain and hydrophone sensitivity to export overall system
%       sensitivity for calibrated sound analysis.
%
%       Additional instructions for generating the calibration sweep signal
%       can be found at <a href="matlab:
%       web('sfregosi.github.io/agate/wispr-calibration.html')">
%       sfregosi.github.io/agate/wispr-calibration.html</a>.
%
%       NOTE. This function is modified from the preamp_cal.m script
%       (c. jones 02/2025) found in <a href="matlab:
%       web('https://github.com/embeddedocean/wispr3')">
%       https://github.com/embeddedocean/wispr3</a>. Modifications
%       functionized the script and made it more customizable for different
%       gliders.
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
%       out_file_name OPTIONAL [char] to specify a specific filename for
%                   the output .mat, .txt, and .png files. If not
%                   specified, will default to
%                   <serialNum>_preamp_gain_mixedResolution_<dateCreated>
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
%   Updated:   2025 August 11
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Check inputs

% will check input argument type or set to empty to prompt
arguments
    sn (1,1) string = ""
    sweep_file (1,1) string = ""
    hydro_sens (1,1) double {mustBeNonpositive} = 0
    amp double {mustBeScalarOrEmpty} = []
    dur double {mustBeScalarOrEmpty} = []
    attenuator logical = 1 % TRUE
    path_out (1,1) string = ""
    out_file_name string = "default"
end

% check serial number (this is used for file name generation)
if sn == ""
    % prompt for SN
    sn = 'XXXX'; % as example
    in = input(sprintf('Enter SN [%s]: ', sn), 's');
    if(~isempty(in))
        sn = in;
    end
end

% pick a data file for the data recorded using the signal generator
if sweep_file == "" || ~exist(sweep_file, 'file')
    [file, path_dat, ~] = uigetfile('*.dat', 'Pick a calibration signal file (.dat)');
    if isequal(file,0)
        error('No sweep file selected.');
    end
    sweep_file = fullfile(path_dat, file);
    fprintf('Selected calibration recording file %s\n', file);
end

% set hydrophone sensitivty - not used in calculation but stored in output
if hydro_sens == 0
    in = input('Enter hydrophone sensitivity (dB re 1V/µPa) [0]: ');
    if (~isempty(in))
        hydro_sens = in;
    end
end

% % define the amplitude of calibration signal sine wave sweep
if isempty(amp)
    amp = 0.010;
    in = input(sprintf('Enter input amplitude in volts [%f]: ', amp));
    if(~isempty(in))
        amp = in;
    end
end

% define the duration of calibration signal sine wave sweep
if isempty(dur)
    dur = 20;
    in = input(sprintf('Enter input sweep duration in seconds [%i]: ', dur));
    if(~isempty(in))
        dur = in;
    end
end

% Define input voltage if a 20db attenuator (20 dB)
% The 2 is because amp half of the differential signal
% Need to check that the attenuator 20db include the rms factor of sqrt(2)/2
if attenuator == true
    vin = 2 * amp / 10;
else
    vin = amp;
end

if path_out == ""
    path_out = uigetdir(pwd, 'Select output directory');
    if path_out == 0
        error('No output directory selected.');
    end
end

% set frequency resolution of output frequency bins
fResLow = 50;   % in Hz
fResHigh = 500; % in Hz
nearNyquist = .89; % percent of Nyquist e.g., .89 kHz for 100 kHz Nyquist

% % define the desired frequency resolution of the outut gain curve
% if ~exist('fRes', 'var') || isempty(fRes)
%     dur = 1000;
%     str = sprintf('Enter target frequency resolution in Hz [%f]: ', fRes);
%     in =  input(str);
%     if(~isempty(in))
%         fRes = in;
%     end
% end


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
xline(bound(1), 'LineWidth', 2, 'color', 'green');
start = floor(d * bound(1));
% hold off;

% define stop based on sweep duration and sample rate
stop = start + dur*hdr.sampling_rate;
xline(stop/d, 'LineWidth', 2, 'color', 'red');
hold off;

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
% higher frequencies where things are flatter so run process at two
% resolutions and combine them

% low freq (up to 2 kHz and close to Nyquist)
fft_sizeLow = 2^nextpow2(hdr.sampling_rate/fResLow);
overlapLow = fft_sizeLow-(fft_sizeLow/4);
%window = rectwin(fft_size);
windowLow = hamming(fft_sizeLow)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
fs = hdr.sampling_rate;
[specLow, fLow] = cal_spec(vout/vin, fs, windowLow, overlapLow, time(1));

paGainLow = 10*log10(specLow);

% high freq (2 kHz up to 90% of the Nyquist)
fft_sizeHigh = 2^nextpow2(hdr.sampling_rate/fResHigh);
overlapHigh = fft_sizeHigh-(fft_sizeHigh/4);
%window = rectwin(fft_size);
windowHigh = hamming(fft_sizeHigh)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
fs = hdr.sampling_rate;
[specHigh, fHigh] = cal_spec(vout/vin, fs, windowHigh, overlapHigh, time(1));

paGainHigh = 10*log10(specHigh);

% intermediate plot - used during testing
% plot spectrum
fig2 = figure(2); clf;
set(fig2, 'Position', [50 50 950 450]);
hold on;
plot(fLow/1000, paGainLow, '.-', 'Color', [0.5 0.5 0.5]); %normalize the power spec
plot(fHigh/1000, paGainHigh,'k.-'); %normalize the power spec
grid(gca, 'minor');
grid on;
xlabel('Frequency [kHz]'),
ylabel('20*log_{10}(V_{out} \\ V_{in}) [dB]');
%axis([0 f(end)/1000 -185 -135]);
title(sn, 'Interpreter', 'none');
legend('50 Hz resolution', '500 Hz resolution')

% extract the different sections
idxLow = find(fLow <= 2000);
idxNyq = find(fLow >= fs/2*nearNyquist);
idxHigh = find(fHigh > 2000 & fHigh < fs/2*nearNyquist);

paFreq = [fLow(idxLow); fHigh(idxHigh); fLow(idxNyq)];
paGain = [paGainLow(idxLow); paGainHigh(idxHigh); movmean(paGainLow(idxNyq), 10)];
% taking a moving average above 90% Nyquist because still too jagged

plot(paFreq/1000, paGain,'-', 'Color', [0 0 0.5], 'LineWidth', 2);
hold off;

%% set up output filenames

% define file name string for each output
if out_file_name == "default"
    out_file_name = sprintf('%s_preamp_gain_mixedResolution_%s', ...
        sn, datetime('now', 'Format', 'yyyy-MM-dd'));
end

mat_file = fullfile(path_out, sprintf('%s.mat', out_file_name));
txt_file = fullfile(path_out, sprintf('%s.txt', out_file_name));
png_file = fullfile(path_out, sprintf('%s.png', out_file_name));

%% save stuff

%save the data as mat file
save(mat_file, 'vout', 'vin', 'fs', 'paFreq', 'paGain');

% plot spectrum
fig3 = figure(3); clf;
set(fig2, 'Position', [50 50 950 450]);
hold on;
plot(paFreq/1000, paGain, '.-', 'Color', [0 0 0.5], 'LineWidth', 2); %normalize the power spec
grid(gca,'minor');
grid on;
xlabel('Frequency [kHz]'),
ylabel('20*log_{10}(V_{out} \\ V_{in}) [dB]');
%axis([0 f(end)/1000 -185 -135]);
title(sn, 'Interpreter', 'none');

% save the plot
print(fig3, '-dpng', png_file);

% write the text file
nbins = length(paFreq);

fp = fopen(txt_file, 'w');
fprintf(fp, 'PREAMP GAIN\r\n');
fprintf(fp, 'SN: %s\r\n', sn);
fprintf(fp, 'hydrophone sensitivity: %.2f\r\n', hydro_sens);
fprintf(fp, 'nbins: %d\r\n', nbins);
fprintf(fp, 'dfreq: %.3f and %.3f\r\n', fLow(3) - fLow(2), fHigh(3) - fHigh(2));
fprintf(fp, 'sweep_file: %s\r\n', sweep_file);
for n=1:nbins
    fprintf(fp, '%.2f, %.2f\n', paFreq(n), paGain(n));
end
fclose(fp);


end


