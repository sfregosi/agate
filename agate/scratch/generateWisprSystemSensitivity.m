function sr = generateWisprSystemSensitivity(metadata, path_out, outType, fRange)
% WISPRSENSITIVITY  Generate overall system sensitivity for WISPR
%
%   Syntax:
%       SR = GENERATEWISPRSYSTEMSENSITIVITY(PATH_CALS, METADATA, PATH_OUT, OUTTYPE, FRANGE)
%
%   Description:
%       Generate netCDF and/or CSV files and summary plots of WISPR system
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
%       It calls several functions from Martin et al. 2021 Erratum: Hybrid
%       millidecade spectra: A practical format for exchange of long-term 
%       ambient sound data, JASA Express Lett 1, 081201 
%       doi: 10.1121/10.0005818. The functions were copied from the
%       supplemental materials and included with agate in the 
%       utils/martin_et_al_2021
%
%   Inputs:
%       path_cals  [char] fullfile path to folder containing input
%                  calibration files (e.g., hydrophone calibration curves,
%                  preamp gain curves)
%       metadata   [char] fullfile path to text file with relevant WISPR
%                  metadata for this mission. Set to blank ([]) to prompt
%                  to select file. See XXXX for example and additional
%                  descriptors/detail
%               wisprVer = 3           % integer either 1, 2, or 3
%               wisprSN = 'WISPR3_no2' % string
%               version = 'v1.3.0'     % string for WISPR firmware version
%               sampling_rate = 200000 % integer, in Hz
%               sample_size = 3        % integer, bits per sample
%               adc_vref = 5           % integer, reference voltage
%               adc_df = 4             % integer, decimation factor 4, 8, 16
%               gain = 0               % integer, e.g., 0, 6, 12, 18
%               hpType = 'HTI92WB'     % string, hydrophone type
%               hpSN = 1211001         % integer, hydrophone serial num
%               hpSens = -164.5        % double, in dB, from manufacturer,
%                                      % set to 'file' to select curve
%               hpFc = 25              % hydrophone high pass filter in Hz
%             **WISPR2 only**
%               paVer = 'WBRev6'       % string, preamp version
%               paSN = '015'           % string, preamp serial number
%
%       path_out   [char] fullfile path to folder to save output
%                  sensitivity netCDF or CSV and plot. Suggest saving
%                  within a folder relevant to this mission or a central
%                  glider folder
%       out_type   [char] to set output file type. Either 'netcdf', 'csv',
%                  or 'both'. Default is 'both'
%       fRange     [1x2 matrix] upper and lower limits of analysis
%                  frequency in Hz (e.g., [0 90000]). Note this is
%                  typically a value below the Nyquist because of the
%                  roll-off location of the anti-aliasing filter
%
%	Outputs:
%       sr         [table] frequency and sensitivity of the system at
%                  hybridmillidecade frequency bands from 1 to fRange
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2025 July 08
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% for testing
% path_cals = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';
% % metadata = []; % WISPR metadata file
% metadata = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration\mission_metadata\sg679_CalCurCEAS_Aug2024_WISPR2_HTI653007.txt';
% path_out = 'C:\Users\selene.fregosi\Documents\GitHub\glider-lab\calibration';
% outType = [];
% fRange = [1 70000]; % in Hz

%% Set defaults/check args

% set up path_cal so uigetfile takes you back to the relevant folder
path_cal = [];

% contains various specs for mission acoustic config that will get eval'd
% if none specified, prompt to locate one
if isempty(metadata) || ~exist(metadata, 'file')
    [name, path_cal] = uigetfile('*.txt', ...
        'Select WISPR metadata file for this mission');
    metadata = fullfile(path_cal, name);
    fprintf(1, 'WISPR metadata file:\n      %s\n', metadata);
end

% check/select output path
if ~exist(path_out, 'dir')
    path_out = uigetdir(path_cal, 'Select output directory');
end

% default to save as netCDF and CSV - if any string other than netcdf or
% csv is entered, will default to both
if isempty(outType)
    outType = 'both';
end
nc = true; csv = true;
if strcmpi(outType, 'netcdf')
    csv = false;
elseif strcmpi(outType, 'csv')
    nc = false;
end

% define analysis frequency range (may change with mission sample rate)
if isempty(fRange)
    fRange = [1 50000]; % in Hz
end
% sg679 WISPR2 sample rate was 180 kHz but filter has steep drop off at
% around 67 kHz so using 70 kHz
% similar to how Nyquist for NRS is 2500 Hz but only analyze to 2200 Hz

%% read contents of metadata file

% this text file should contain direct arguments to be evaluated. For an
% example see agate/settings/wispr_metadata_example.txt
% must include the following variables: glider, mission, wisprVer,
% sensor_id, version, sampling_rate, adc_vref, adc_df, gain, hpType, hpSN,
% hpSens

fid = fopen(metadata, 'r');
if fid == -1
    error('Invalid file selected. Exiting.\n')
end
al = textscan(fid, '%s', 'delimiter', '\n');
nl = length(al{1});
if nl < 1
    error(['No data in WISPR metadata file. ', ...
        'Did you select the correct file?\n'])
else
    frewind(fid);
    for i = 1:nl
        line = fgets(fid);
        if ~strcmp(line(1), '%')
            eval(line);
        end
    end
end
fclose(fid);

% rename some things for clarity bc WISPR header labels aren't great
sysGain = gain;
sampleRate = sampling_rate;

%% check input curve files
% select correct files where needed (preamp gain, anti-aliasing filter, hydrophone cal)

% WISPR2
if wisprVer == 2

    % set sensor ID string for this mission/configuration
    sensorID = sprintf('WISPR2 %s Preamp Ver: %s, SN: %s, Hydrophone SN: %i', ...
        firmwareVer, paVer, paSN, hpSN);

    % select correct preamp file
    if ~exist('paFile', 'var') || ~exist(paFile, 'file')
        [name, path_cal] = uigetfile({'*.csv; *.xlsx'}, sprintf(['Select correct ', ...
            'preamp calibration file. WISPR2 preamp ver %s, SN %s'], paVer, paSN), ...
            path_cal);
        paFile = fullfile(path_cal, name);
        fprintf(1, 'Selected preamp file:\n      %s\n', paFile);
    end

    % select correct anti-aliasing filter file - IS THIS CORRECT for WISPR2?
    if ~exist('aaFile', 'var') || ~exist(aaFile, 'file')
        [name, path_cal] = uigetfile({'*.csv; *.xlsx'}, sprintf(['Select correct ', ...
            'anti-aliasing filter file. fs %i, df %i'], sampling_rate/1000, adc_df), ...
            path_cal);
        aaFile = fullfile(path_cal, name);
        fprintf(1, 'Selected anti-aliasing filter file:\n      %s\n', aaFile);
    end

    % example from WISPR1
    % antiAliasGain = [zeros(1,length(frqSys)-7) ...
    %     -5 -108 -108 -108 -108 -110 -112];
end

% WISPR3
if wisprVer == 3

    % pause

    % set sensor string for this mission/configuration
    sensorID = sprintf('WISPR3 SN: %s, %s, Hydrophone SN: %i, ', ...
        wisprSN, version, hpSN);


    % select correct sensitivity file
    [name, path_cal] = uigetfile({'*.csv; *.xlsx'}, sprintf(['Select correct ', ...
        'WISPR3 calibration file. WISPR3 SN %s, ver %s'], wisprSN, version), ...
            path_cal);
    paFile = fullfile(path_cal, name);
end


% for either WISPR version...check if hydrophone curve available
if ~isnumeric(hpSens)
    if ~exist('hpFile', 'var') || ~exist(hpFile, 'file')
        % select hydrophone calibration file
        [name, path_cal] = uigetfile({'*.csv; *.xlsx'}, sprintf(['Select hydrophone ', ...
            'calibration file. %s SN %s'], hpType, num2str(hpSN)), ...
            path_cal);
        hpFile = fullfile(path_cal, name);
    end
end

%% read in the gain/calibration/filter curves

% read in preamp gain curve
paCurve = readmatrix(paFile);

% read in anti-aliasing filter curve if exists
if exist('aaFile', 'var')
    aaCurve = readmatrix(aaFile);
else
    aaCurve = [NaN, NaN];
end

% read in hydrophone calibration curve if it exists
if exist('hpFile', 'var')
    hpCal = readmatrix(hpFile);
else
    hpCal = [NaN, NaN];
end


%% Calculate general system response

% get sampled frequencies
% freq of multiple curves may not match so standardize to all unique
freq = unique([paCurve(:,1); hpCal(:,1); aaCurve(:,1)]);
% freq = unique([paSens(:,1); aaFilt(:,1)]);
% remove NaNs
freq(isnan(freq)) = [];


% interpolate at all freqs or put in single values
paGain = interp1(paCurve(:,1), paCurve(:,2), freq);
% anti-aliasing filter if needed
if exist('aaFile', 'var')
    aaFilt = interp1(aaCurve(:,1), aaCurve(:,2), freq);
else
    aaFilt = 0;
end
% hydrophone curve if available, or use single value
if exist('hpFile', 'var')
    hpSens = interp1(hpCal(:,1), hpCal(:,2), freq);
else
    % repeat single value
    hpSens = repmat(hpSens, size(freq));
end


% calculate overall system response
sysResp = hpSens + paGain + sysGain + aaFilt;


%% Calculate HMD bands
% Compute HMD bands centers, and interpolate calibration data
%  This uses the revised code from Martin et al., after they corrected an
% and is packaged in agate error.
fftBinSize = 1; %P.fs = 5000;
% [freqTable] = getBandTable(fftBinSize, bin1CenterFrequency, fs, base, ...
%     bandsPerDivision, firstOutputBandCenterFrequency, useFFTResAtBottom);
mDecBands = getBandTable(fftBinSize, 0, sampleRate, 10, 1000, 1, 1);
bcf = mDecBands(:,2);  % band center frequency
% subset to analysis frequency range set at top
bcf = bcf(bcf >= fRange(1) & bcf <= fRange(2));
% interpolate
R = interp1(freq, sysResp, bcf);


%% Plot
% Produce summary plot, to screen and png file

% set colors
hpCol = '#901200'; % NMFS PI Coral red
paCol = '#003087'; % NMFS Oceans blue
aaCol = '#4B8320'; % NMFS SE Seagrass
figure(8);
clf;
set(gcf, 'position', [100 100 900 450], 'color', 'w');
hold on;
plot(freq, hpSens, 'o--', 'Color', hpCol,  'DisplayName', 'Hydrophone Sensitivity');
plot(freq, paGain, 'o--', 'Color', paCol, 'DisplayName', 'Preamp gain');
plot(freq, aaFilt, 'o--', 'Color', aaCol, 'DisplayName', 'Anti-aliasing filter')%
plot(freq, sysResp, 'ks', 'MarkerSize', 10, 'DisplayName', ...
    'System response - original'); % combined/original
plot(bcf, R, 'k', 'LineWidth', 1.5, 'DisplayName', ...
    'System response - interpolated'); % interpolated
xline(fRange(2), 'k-.', 'DisplayName', 'Upper limit for valid data');
set(gca, 'XScale', 'log', 'FontSize', 12)
grid on;
axis tight;
xlim([0 max(freq)/2]); % xlim([0 max(freq)]; % only plot to nyquist
% ylim([min([paGain; aaFilt; sysResp; sysGain; hSens])-2, ...
%     max([paGain; aaFilt; sysResp; sysGain; hSens])]+2)
ylabel('sensitivity [dB]');
xlabel('frequency [Hz]');
title(sensorID, 'Interpreter', 'none');
legend('Location', 'west');

exportgraphics(gcf, fullfile(path_out, sprintf('%s_%s_sensitivity_%s.png', ...
    glider, mission, datetime('now', 'Format', 'yyyy-MM-dd'))), ...
    'Resolution', 300)



%% save as netCDF

if nc
    ncFilename = fullfile(path_out, sprintf('%s_%s_sensitivity_%s.nc', ...
        glider, mission,  datetime('now', 'Format', 'yyyy-MM-dd')));
    ncid = netcdf.create(ncFilename, 'CLOBBER');

    % global attributes
    varid = netcdf.getConstant('NC_GLOBAL');

    % attribute - title
    ttl = sprintf(['%s WISPR system response interpolated to center ', ...
        'frequencies of hybrid millidecade bands, fs = %i Hz.'], mission, sampleRate);
    netcdf.putAtt(ncid, varid, 'title', ttl);

    % attribute - sensor ID
    netcdf.putAtt(ncid, varid, 'sensor ID', sensorID);

    % attribute - metadata source
    if wisprVer == 2
        % pull just filename
        [~, mdName, mdExt] = fileparts(metadata);
        [~, paName, paExt] = fileparts(paFile);
        [~, aaName, aaExt] = fileparts(paFile);
        ms = sprintf(['Mission metadata: %s. Preamp gain curve: %s ', ...
            'Anti-aliasing filter: %s'], ...
            [mdName, mdExt], [paName, paExt], [aaName, aaExt]);
    end

    % WISPR3 - just have metadata and paFile
    if wisprVer == 3
        % pull filenames from fullfile paths
        [~, mdName, mdExt] = fileparts(metadata);
        [~, paName, paExt] = fileparts(paFile);
        ms = sprintf('Mission metadata: %s. Preamp gain curve: %s', ...
            [mdName, mdExt], [paName, paExt]);
    end

    netcdf.putAtt(ncid, varid, 'metadata source', ms);

    % add data - vectors for frequency dependent sensitivity

    % variable - frequency
    dimidt = netcdf.defDim(ncid, 'frequency', length(bcf));
    varid = netcdf.defVar(ncid, 'frequency', 'NC_DOUBLE', dimidt);
    % netcdf.reDef(ncid); % Re-enter define mode for attributes
    netcdf.putAtt(ncid, varid, 'long_name', 'frequency of hybrid millidecade band center');
    netcdf.putAtt(ncid, varid, 'units', 'Hz');
    netcdf.endDef(ncid) % end define mode for attributes
    netcdf.putVar(ncid, varid, bcf)

    % variable - sensitivity
    netcdf.reDef(ncid); % Re-enter define mode for attributes
    varid = netcdf.defVar(ncid, 'sensitivity', 'NC_DOUBLE', dimidt);
    netcdf.putAtt(ncid, varid, 'long_name', 'hydrophone sensitivity');
    netcdf.putAtt(ncid, varid, 'units', 'dB V re micropascal');
    netcdf.endDef(ncid); % Exit define mode
    netcdf.putVar(ncid, varid, R);

    % variable - raw preamp gain curve
    netcdf.reDef(ncid); % Re-enter define mode for attributes
    dimid_pa_row = netcdf.defDim(ncid, 'preamp_frequency', size(paCurve, 1));
    dimid_pa_col = netcdf.defDim(ncid, 'preamp_sensitivity', 2);
    varid_pa = netcdf.defVar(ncid, 'preamp_gain', 'NC_DOUBLE', [dimid_pa_row, dimid_pa_col]);
    netcdf.putAtt(ncid, varid_pa, 'long_name', 'preamp frequency response');
    netcdf.putAtt(ncid, varid_pa, 'units', 'Hz, dB');
    netcdf.endDef(ncid); % Exit define mode
    netcdf.putVar(ncid, varid_pa, paCurve(:,1:2));

    % variable - raw anti-aliasing filter
    netcdf.reDef(ncid); % Re-enter define mode for attributes
    dimid_aa_row = netcdf.defDim(ncid, 'anti-alias_frequency', size(aaCurve, 1));
    dimid_aa_col = netcdf.defDim(ncid, 'anti-alias_sensitivity', 2);
    varid_aa = netcdf.defVar(ncid, 'anti-alias_filter', 'NC_DOUBLE', [dimid_aa_row, dimid_aa_col]);
    netcdf.putAtt(ncid, varid_aa, 'long_name', 'anti-aliasing filter frequency response');
    netcdf.putAtt(ncid, varid_aa, 'units', 'Hz, dB');
    netcdf.endDef(ncid); % Exit define mode
    netcdf.putVar(ncid, varid_aa, aaCurve(:,1:2));

    % close
    netcdf.close(ncid)

    % display summary of written file
    % ncdisp(ncFilename)
end

%% save as csv

if csv
    csvFilename = fullfile(path_out, sprintf('%s_%s_sensitivity_%s.csv', ...
        glider, mission,  datetime('now', 'Format', 'yyyy-MM-dd')));

    ot = table(bcf, R, 'VariableNames', {'frequency', 'sensitivity'});
    writetable(ot, csvFilename);
end

% clean up output argument
sr = ot;