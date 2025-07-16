% WORKFLOW_GENERATEPREAMPGAINCURVE.M
%	Generate a WISPR3 calibration gain curve from a sweep of known voltage
%
%	Description:
%		Example script to calculate and plot a WISPR3 preamplifier
%		calibration gain curve. A calibration recording file created with
%		a signal generator input directly to the WISPR3 and preamp board
%		(SEE DETAILED INSTRUCTIONS HERE)
%       is read in, a user selects a single calibration sweep, and the gain
%       is calculated, plotted, and saved as a .mat and .txt file.
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
%	Notes
%       Modified from the preamp_cal.m script (c. jones 02/2025)found in
%       https://github.com/embeddedocean/wispr3. Modifications make it more
%       customizable and output the results in a format to feed into
%       netCDF/csv creation using agate's generateWisprSystemSensitivity
%       function to provide full system calibration info.
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   2025 July 15
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% User modified inputs

% SN of the preamp/adc board - must be a string less than 16 chars
% used for filename generation
sn = 'WISPR3_no1';

% fullfile path of calibration recording (as raw .dat file)
% set to [] to be prompted to select one
% sweep_file = [];
% sweep_file = "D:\wispr_calibration\wispr_no2\250514\WISPR_250514_213247.dat";
sweep_file = "E:\wispr_calibration\wispr_no1\250714\no1_250714_134457.dat";

% define hydropgone sensitivity, not used for the calibration
% but saved in the calibration file for use later
% hydro_sens = -165;
hydro_sens = 0;

% define the amplitude of sine wave sweep (in volts)
% ideally 10 mV)
amp = 0.010;

% was a 20 dB attenuator used?
attenuator = true;

% path to save output calibration files
path_out = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';

%% calculate sensitivity

 [preamp_freq, preamp_gain]= measureWisprSensitivity(sn, sweep_file, hydro_sens, amp, attenuator, path_out);

% this saves it automatically...pull out saving or leave in function?

