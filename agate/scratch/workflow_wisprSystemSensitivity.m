% WORKFLOW_WISPRSYSTEMSENSITIVITY.M
%	Create a WISPR3 frequency-dependent system sensitivity gain curve
%
%	Description:
%		Example script to produce a WISPR3 system sensitivity gain curve in
%		netCDF and CSV formats from a calibration sweep input signal,
%		known hydrophone sensitivity, and known system gain settings.
%
%       There are two main steps: (1) generating a WISPR3 preamp
%       sensitivity curve (gain curve) from a recording of a known voltage
%       sweep created with a signal generator and (2) combining the output
%       preamp gain curve with the hydrophone sensitivity and any system
%       gain to produce a final system sensitivity gain curve in both a
%       netCDF and CSV format.
%
%       For the first step, a calibration sweep recording file, created
%       with a signal generator input directly to the WISPR3 and preamp
%       board is read in, the user selects the start of a signal
%       calibration sweep and specifies the duration, and the sensitivity
%       is calculated, plotted, and saved as a .mat and .txt file in the
%       desire output location.
%
%       Additional instructions for generating the calibration sweep signal
%       can be found at <a href="matlab:
%       web('sfregosi.github.io/agate/wispr-calibration.html')">
%       sfregosi.github.io/agate/wispr-calibration.html</a>.
%
%       The output of the first step is then provided as one input
%       component and combined with system gain and hydrophone sensitivity
%       to assemble a full system sensitivity curve (frequency dependent
%       calibration curve) to be used in calibrated soundscape and noise
%       analyses.
%
%	Notes
%       Modified from the preamp_cal.m script (c. jones 02/2025) found in
%       https://github.com/embeddedocean/wispr3. Modifications make it more
%       flexible and create an output that can be fed into added steps that
%       calculate the full frequency dependent calibration info.
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   2025 August 13
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% specify path to agate and add to path
% addpath(genpath('C:\Users\User.Name\Documents\MATLAB\agate'))
addpath(genpath('C:\Users\selene.fregosi\Documents\MATLAB\agate'))

%% User modified inputs

% SN of the WISPR preamp/adc board - must be a string less than 16 chars
% used for filename generation
sn = 'WISPR3_no2';

% fullfile path of calibration recording (as raw .dat file)
% see OPTIONAL step below for help converting .dat to .flac/.wav for review
% sweep_file = []; % set to [] to be prompted to select file
sweep_file = "E:\wispr_calibration\wispr_no2\250514\WISPR_250514_213247.dat"; % 100 kHz 20 sec sweep
% sweep_file = "E:\wispr_calibration\wispr_no2\250514\WISPR_250514_214326.dat"; % 200 kHz 60 sec sweep


% define hydrophone sensitivity, not used for the calibration
% but saved in the calibration file for record keeping
hydro_sens = -164.5;

% target frequency resolution of sample points
fRes = 1000;

% define the amplitude of sine wave sweep (in volts) and sweep duration
% typically 10 mV and 20 or 60 seconds
amp = 0.010;
dur = 20; % in seconds

% was a 20 dB attenuator used?
attenuator = true;

% path to save output calibration files
% path_out = 'C:\Users\User.Name\calibration\wispr\preamps';
path_out = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration\wispr\preamps';

% OPTIONAL
% specify an output filename. Default is SN_preamp_gain_mixedResolution_YYYY-MM-DD
% where the timestamp is the date of creation. Do not specify an extension.
% out_file_name = 'testFile';
out_file_name = []; %

%% OPTIONAL - convert to flac for review
% it may be useful to convert the raw .dat files to .flac (or .wav) to
% browse through several recorded files to find a good candidate file with
% a complete sweep

% convert
convertWispr;
% this call with no input arguments will prompt to select raw file location
% and output file location and will default to writing flac. Alternatively,
% specify input arguments to avoid prompts and write to .wav. E.g.,
% convertWispr('inDir', 'E:/wisprFiles', 'outDir', 'E:/wav', 'outExt', '.wav')

%% calculate sensitivity

% this function will plot the waveform of the specified calibration sweep
% file, prompt the user to select the start of one complete sweep,
% calculate the spectrum over the duration of one sweep, save the
% frequency-dependent gain curve as a .mat and .txt and the plot as .png

[paFreq, paGain] = measureWisprPreampSensitivity(sn, sweep_file, ...
    hydro_sens, amp, dur, attenuator, path_out, out_file_name);

