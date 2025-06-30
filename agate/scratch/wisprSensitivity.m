% WISPR_CALIBRATION_TO_NETCDF.M
%	Generate netCDF file and  summary plot of WISPR system calibration
%
%	Description:
%       Generate netCDF files and summary plots of WISPR system
%       calibration metadata including hydrophone and preamp sensitivities,
%       user-defined system gain, and anti-aliasing filters. The netCDF
%       files are used by PyPAM Based Processin (PBP) when creating daily
%       files of hybrid millidecade spectra.
%
%	Notes
%       This script is based off the NRS_calibration_to_netcdf.m script
%       written by J. Ryan (MBARI) and S. Haver (NEFSC) available at
%       https://github.com/sahav/NRS
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:   1 May 2025
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set mission and calibration path
% define glider mission
% mission = 'sg679_CalCurCEAS_Aug2024';
mission = 'sg679_MHI_May2023';
% mission = 'sg639_CalCurCEAS_Sep2024';

% set path to calibration data files
path_calibrations = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';

% set path/add path to Samara's NRS repo
path_NRS = 'C:\Users\selene.fregosi\Documents\GitHub\NRS';
addpath(genpath(path_NRS));

% define analysis frequency range (may change with mission sample rate)
fRange = [1 70000]; % in Hz
% sg679 WISPR2 sample rate was 180 kHz but filter has steep drop off at
% around 67 kHz so using 70 kHz
% similar to how Nyquist for NRS is 2500 Hz but only analyze to 2200 Hz

%% Parse correct mission info
% In the future, will either read in a mission record table, or a single
% csv or xlsx for each mission, or something else to parse the relevant
% metadata. For now, hard coding for testing/building an example.
if strcmp(mission, 'sg679_CalCurCEAS_Aug2024') || ...
    strcmp(mission, 'sg679_MHI_May2023')
    % recorder type
    loggerType = 'WISPR2';      % e.g., PMARXL, WISPR2, WISPR3
    loggerVer = '0.2';          % string
    loggerSN = '';              % string

    % recorder settings
    sampleRate = 180000;        % in Hz
    decimationFactor = 4;       % integer like 4, 8, 16
    bitRate = 24;               % bits per sample - 16, 24, etc
    adcVoltRef = 5;             % voltage referece - 5

    % hydrophone info
    hSN = '653007';         % string (or should be numeric?)
    hSens = -162.5;         % in dB, from manufacturer, or could be a curve?
    hydroFc = 25;               % in Hz (high pass filter setting?)

    % system gain
    sysGain = 0;             % integer e.g., 0, 6, 12, 18

    % preamp info
    paVer = 'WBRev6';        % string
    paSN = '015';           % string

    % preampGain = ;              % this should be a matrix
    % preampGain = [-2.9 6.8 13.6 15.7 16.3 16.6 16.8 17.3 19.9 23.9 ...
    %     29.1 36.3 41.2 44.5 45.6 45.5 45.2 44.9 44.6 44.3 ...
    %     44 43.5]; % From gain curve file
    % preampFreq = ;              % this should be a matrix
    paFile = 'preamp_WISPR2_rev6_board15_2023-08-22.csv';

    % anti-aliasing filter info
    % use hand-extracted values from LTC2512 materials
    % select the csv based on input sample rate/decimation factor
    aaFile = 'LTC2512-24_antialiasingFilter_200kHz_df4.csv';
    % antiAliasGain = [zeros(1,length(frqSys)-7) ...
    %     -5 -108 -108 -108 -108 -110 -112];

elseif strcmp(mission, 'sg639_CalCurCEAS_Sep2024')
    % recorder type
    loggerType = 'WISPR3';      % e.g., PMARXL, WISPR2, WISPR3
    loggerVer = '1.3.0';        % string
    loggerSN = 'no4';           % string

    % hydrophone info
    hSN = '635013';         % string (or should be numeric?)
    hSens = -164.5;         % in dB, from manufacturer, or could be a curve?

    % system gain
    sysGain = 0;             % integer e.g., 0, 6, 12, 18

    % anti-aliasing filter info
    % use hand-extracted values from LTC2512 materials
    % select the csv based on input sample rate/decimation factor
    aaFile = 'LTC2512-24_antialiasingFilter_200kHz_df4.csv';
    % antiAliasGain = [zeros(1,length(frqSys)-7) ...
    %     -5 -108 -108 -108 -108 -110 -112];

elseif strcmp(mission, 'sg680_CalCurCEAS_Sep2024')
    % recorder type
    loggerType = 'WISPR3';      % e.g., PMARXL, WISPR2, WISPR3
    loggerVer = '1.3.0';        % string
    loggerSN = 'no2';           % string
    % note DAT FILE HEADERS STATE no3. THIS IS INCORRECT!

    % hydrophone info
    hSN = '635013';         % string (or should be numeric?)
    hSens = -164.5;         % in dB, from manufacturer, or could be a curve?

    % system gain
    sysGain = 0;             % integer e.g., 0, 6, 12, 18

    % anti-aliasing filter info
    % use hand-extracted values from LTC2512 materials
    % select the csv based on input sample rate/decimation factor
    aaFile = 'LTC2512-24_antialiasingFilter_200kHz_df4.csv';
    % antiAliasGain = [zeros(1,length(frqSys)-7) ...
    %     -5 -108 -108 -108 -108 -110 -112];
end

% set hydrophone ID string for this configuration
% hydrophoneID = sprintf('Mission: %s, Hydrophone SN: %s, Preamp SN_Ver: %s_%s', ...
%     mission, hSN, paSN, paVer); % with mission string
hydrophoneID = sprintf('Hydrophone SN: %s, Preamp SN: %s, Preamp Ver: %s', ...
   hSN, paSN, paVer);

%% Calculate general system response

% read in preamp and anti aliasing filter
paGain = readmatrix(fullfile(path_calibrations, paFile));
aaFilt = readmatrix(fullfile(path_calibrations, aaFile));

% sampled frequencies of gain curves may not match - standardize to add
% find all unique frequencies
freq = unique([paGain(:,1); aaFilt(:,1)]);
% interpolate both curves at those frequencies
paGain = interp1(paGain(:,1), paGain(:,2), freq);
aaFilt = interp1(aaFilt(:,1), aaFilt(:,2), freq);

%***May need to add hydrophone sensitivity curves***

% calculate general system response
sysResp = hSens + paGain + sysGain + aaFilt;


%% Calculate HMD bands
% Compute HMD bands centers, and interpolate calibration data
%  This should use the revised code from Martin et al., after they
%  corrected an error.
fftBinSize = 1; %P.fs = 5000;
% [freqTable] = getBandTable(fftBinSize, bin1CenterFrequency, fs, base, ...
%     bandsPerDivision, firstOutputBandCenterFrequency, useFFTResAtBottom);
mDecBands = getBandTable(fftBinSize, 0, sampleRate, 10, 1000, 1, 1);
bcf = mDecBands(:,2);  % band center frequency
% subset to analysis frequency range set at top
k = find(bcf >= fRange(1) & bcf <= fRange(2));
bcf = bcf(k);
% interpolate
R = interp1(freq, sysResp, bcf);


%% Plot
% Produce summary plot, to screen and png file
figure(8);
clf;
set(gcf, 'position', [100 100 900 450], 'color', 'w');
hold on;
plot(freq, repmat(hSens, size(freq)), 'ro--', 'DisplayName', 'Hydrophone Sensitivity');
plot(freq, paGain, 'bo--', 'DisplayName', 'Pre-amp gain');
plot(freq, aaFilt, 'go--', 'DisplayName', 'Anti-aliasing filter')%
plot(freq, sysResp, 'ks', 'MarkerSize', 10, 'DisplayName', ...
    'System response - original'); % combined/original
plot(bcf, R, 'k', 'LineWidth', 1.5, 'DisplayName', ...
    'System response - interpolated'); % interpolated
xline(fRange(2), 'k-.', 'DisplayName', 'Upper limit for valid data');
set(gca, 'XScale', 'log', 'FontSize', 12)
grid on;
axis tight;
xlim([0 max(freq)/2]); % xlim([0 max(freq)];
% ylim([min([paGain; aaFilt; sysResp; sysGain; hSens])-2, ...
%     max([paGain; aaFilt; sysResp; sysGain; hSens])]+2)
ylabel('sensitivity [dB]');
xlabel('frequency [Hz]');
title(hydrophoneID, 'Interpreter', 'none');
legend('Location', 'west');

exportgraphics(gcf, fullfile(path_calibrations, sprintf('%s_sensitivity_%s.png', ...
    mission, datetime('now', 'Format', 'yyyy-MM-dd'))), 'Resolution', 300)

%% save as netCDF

ncFilename = fullfile(path_calibrations, sprintf('%s_sensitivity_%s.nc', ...
    mission,  datetime('now', 'Format', 'yyyy-MM-dd')));
ncid = netcdf.create(ncFilename, 'CLOBBER');

% global attributes
varid = netcdf.getConstant('NC_GLOBAL');

% title
ttl = sprintf(['%s WISPR system response interpolated to center ', ...
    'frequencies of hybrid millidecade bands, fs = %i Hz.'], mission, sampleRate);
netcdf.putAtt(ncid, varid, 'title', ttl);

% Hydrophone ID
netcdf.putAtt(ncid, varid, 'hydrophone ID', hydrophoneID);

% Metadata source
% ms = ("Excel file "+ xlfilename +", sheet name "+ xlsheetname);
ms = sprintf('Preamp CSV %s, filter CSV %s, and script %s', ...
    paFile, aaFile, 'WISPR_calibration_to_netCDF.m');
netcdf.putAtt(ncid, varid, 'metadata source', ms);

% vectors for frequency dependent sensitivity
% frequency
dimidt = netcdf.defDim(ncid, 'frequency', length(bcf));
varid = netcdf.defVar(ncid, 'frequency', 'NC_DOUBLE', dimidt);
netcdf.endDef(ncid) % end define mode for attributes
netcdf.putVar(ncid, varid, bcf)
netcdf.reDef(ncid); % Re-enter define mode for attributes
netcdf.putAtt(ncid, varid, 'long_name', 'frequency of hybrid millidecade band center')
netcdf.putAtt(ncid, varid, 'units', 'Hz')
% sensitivity
varid = netcdf.defVar(ncid, 'sensitivity', 'NC_DOUBLE', dimidt);
netcdf.endDef(ncid)
netcdf.putVar(ncid, varid, R)
netcdf.reDef(ncid); % Re-enter define mode for attributes
netcdf.putAtt(ncid, varid, 'long_name', 'hydrophone sensitivity')
netcdf.putAtt(ncid, varid, 'units', 'dB V re micropascal')

% close
netcdf.close(ncid)

% display summary of written file
ncdisp(ncFilename)

%% save as csv

csvFilename = fullfile(path_calibrations, sprintf('%s_sensitivity_%s.csv', ...
    mission,  datetime('now', 'Format', 'yyyy-MM-dd')));

ot = table(bcf, R, 'VariableNames', {'frequency', 'sensitivity'});
writetable(ot, csvFilename);