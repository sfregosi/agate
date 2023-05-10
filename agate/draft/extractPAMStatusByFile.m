function [gpsSurfT, locCalcT, pam] = extractPAMStatusByFile(CONFIG, ...
    fileLength, dateFormat, dateStart, gpsSurfT, locCalcT)
% EXTRACTPAMSTATUSBYFILE	*PLACEHOLDER - NOT YET WORKING*  Extracts glider location data from nc files
%
%	Syntax:
%		[gpsSurfT, locCalcT] = EXTRACTPAMSTATUSBYFILE(CONFIG, SAVEON)
%
%	Description:
%		Extracts 
%
%	Inputs:
%		CONFIG  agate mission configuration file with relevant mission and
%		        glider information. Minimum CONFIG fields are 'glider',
%		        'mission'
%       plotOn  optional argument to plot basic maps of outputs for
%               checking; (1) to plot, (0) to not plot
%
%	Outputs:
%		gpsSurfT    Table with glider surface locations, from GPS, one per
%		            dive, and includes columns for dive start and end
%		            time/lat/lon, dive duration, depth average current,
%                   average speed over ground as northing and easting,
%                   calculated by the hydrodynamic model or the glide slope
%                   model
%       locCalcT    Table with glider calculated locations underwater every
%                   science file sampling interval. This gives more
%                   instantaneous flight details and includes columns
%                   for time, lat, lon from hydrodynamic and glide slope
%                   models, displacement from both models, temperature,
%                   salinity, density, sound speed, glider vertical and
%                   horizontal speed (from both models), pitch, glide
%                   angle, and heading
%
%	Examples:
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	unknown
%	Updated:        23 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PAM ON/OFF information for WISPR board Gliders
% sort of works for QUEphones but is messy

% updates locCalc .mat file (saves new one)
% creates PAMDurs .mat file

% Example inputs:
% gldr = 'sg607';
% lctn = 'CatBasin';
% dplymnt = 'Jul16';
% fileLength = 120; % in seconds; either 120 or 80 for wispr
% sampleRate = 1000; % in Hz, runs fastest on downsampled 1 kHz data
% dateFormat = 'yyMMdd-HHmmss'; 
        % this needs to be in datetime input format sytnax
        % https://www.mathworks.com/help/matlab/ref/datetime.html#d122e273617
% dateStart = 1; % what part of file name starts the date format


global CONFIG
%% initialization
warning off

% get num of samples per file (if max file length)
if fileLength == 120 % wispr
    numSamples = 119931; % for 2 min file
elseif fileLength == 80 % wispr
    numSamples = 79954; % for 1 min 20 sec files downsampled to 1000 hz
elseif fileLength == 600 % PMARXL
    numSamples = 600000;
else
    fprintf('Unknown fileLength...aborting\n')
    return
end

% specify deployment date and time to ignore all files before that
% (sometimes test files recorded in lab are in dataset)
deplDate = gpsSurfT.startDateTime(1);

% select folder with sound files and where to save
% path_in = uigetdir('G:\','Select base folder');
path_acous = uigetdir('C:\', 'Select folder with 1 kHz acoustic data');
% pick 1 kHz data because it will run faster...but could change in future. 
path_out = uigetdir(path_acous, 'Select profiles folder to save outputs');

%% Read in files and extract duration information
files = dir([path_acous '\*.wav']);
if isempty(files)
    fprintf('No .wav files found...aborting\n');
    return
    % *****later build in switch to flac??
    % files=dir([path_flac '*.flac']);
    
end

pam = table;
shortfiles = [];
fprintf(1,'%i files:\n',length(files));

% make matrix with start and end times for all PAM files
for f = 1:length(files)
    % calc duration in sec using sampling rate..slow but works - more accurate
    try
        wavInfo = audioinfo([path_acous '\' files(f,1).name]); % faster
        y = [1:wavInfo.TotalSamples];
        Fs = wavInfo.SampleRate;
        files(f,1).dur=length(y)./Fs;
        if length(y) < numSamples % specify this in function inputs. may vary by recording system
            shortfiles=[shortfiles; f length(y)];
            fprintf(1,'%s is short: %i\n',files(f,1).name,length(y));
        end
        % get start timing information from file name
        pam.fileStart(f,1) = datetime(files(f).name(dateStart:length(dateFormat)),'InputFormat',dateFormat);
        pam.fileEnd(f,1) = pam.fileStart(f,1) + seconds(files(f,1).dur);
        
    catch
        fprintf(1, '%s is empty\n',files(f,1).name);
        clear y Fs
    end
    if rem(f,1000)==0; fprintf(1,'%i DONE\n',f);end % counter
end

% remove all before deployment date
[r, ~] = find(pam.fileStart < deplDate,1,'last');
if ~isempty(r)
    pam = pam(r+1:end,:);
end

save([path_out '\' glider '_' deploymentStr '_pamByFile.mat'],'pam');

%% Specify 1's and 0s per locCalcT row
% 1 if pam on, 0 if off

locCalcT.pam = zeros(height(locCalcT),1);
fprintf(1,'%s - %d samples:\n', [glider '_' deploymentStr], height(locCalcT));
for f = 1:height(locCalcT)
    idx = find(isbetween(locCalcT.dateTime(f),pam.fileStart,pam.fileEnd),1);
    if ~isempty(idx)
        locCalcT.pam(f) = 1;
    end
    clear idx
    
    fprintf(1,'.');
    if (rem(f,80) == 0), fprintf(1,'\n%3d',floor((height(locCalcT)-f)/80)); end
end

save([path_out '\' glider '_' deploymentStr '_locCalcT_pam.mat'],'locCalcT');
writetable(locCalcT, [path_out '\' glider '_' deploymentStr '_locCalcT_pam.csv']);

% % plotting test
%  plotDiveProfile(locCalcT)

%% Calculate duration of files and Total Duration

pam.dur = pam.fileEnd - pam.fileStart;
totDur = nansum(pam.dur); % as datetime duration format
totDurHrs = hours(totDur);

fprintf('Total PAM duration: %.2f hours\n', totDurHrs);

save([path_out '\' glider '_' deploymentStr '_pamByFile.mat'],'pam','totDur','totDurHrs');

%% duration per dive

pamByDive = table;
pamByDive.dive = gpsSurfT.dive;
pamByDive.diveStart = gpsSurfT.startDateTime;
pamByDive.diveEnd = gpsSurfT.endDateTime;
pamByDive.numFiles = nan(height(pamByDive),1);

for f = 1:height(pamByDive)
    [r, ~] = find(isbetween(pam.fileStart, pamByDive.diveStart(f), ...
        pamByDive.diveEnd(f)));
    if ~isempty(r)
        pamByDive.numFiles(f,1) = length(r);
        pamByDive.pamDur(f,1) = sum(pam.dur(r));
        pamByDive.pamStart(f,1) = pam.fileStart(r(1));
        pamByDive.pamEnd(f,1) = pam.fileEnd(r(end));
    end
    
end
    
pamByDive.lagStart = pamByDive.pamStart - pamByDive.diveStart;
pamByDive.lagEnd = pamByDive.diveEnd - pamByDive.pamEnd;

save([path_out '\' glider '_' deploymentStr '_pamByFile.mat'],'pam','totDur','totDurHrs','pamByDive');

% append to gpsSurfT and save
gpsSurfT.pamDur = pamByDive.pamDur;
gpsSurfT.pamNumFiles = pamByDive.numFiles;
gpsSurfT.pamStart = pamByDive.pamStart;
gpsSurfT.pamEnd = pamByDive.pamEnd;

save([path_out '\' glider '_' deploymentStr '_gpsSurfaceTable_pam.mat'],'gpsSurfT');
writetable(gpsSurfT, [path_out '\' glider '_' deploymentStr '_gpsSurfaceTable_pam.csv']);


