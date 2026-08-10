function decimateDir(fsNew, folder)
% DECIMATEDIR	downsample directory of audio files using DECIMATE
%
%	Syntax:
%		DECIMATEDIR(FSNEW, FOLDER)
%
%	Description:
%		Decimate a directory of audio files to a defined new sampling rate,
%		fsNew, or multiple new sample rates, and write new files in new
%		subdirectory.
%
%       This was designed to work on a folder of subfolders of instruments,
%       e.g., DASBRs following the folder structure on the PIFSC server.
%       This has an outer folder within which there is a subfolder for each
%       recorder/deployment
%
%       Because of variability in folder structures, this really only works
%       with a basic folder/subfolder arrangement where there is a folder
%       such as 'recordings' that contains a subfolder for 'wav' and then
%       the decimated recordings will be saved in a newly created
%       'decimated' subfolder with each new sample rate in the name
%
%       This was originally a script that was modified for each deployment,
%       but this function aims to simplify that script. However, this
%       function can only run on a single folder of sound files. See
%       myUtils/dataProcessing/downsampling for example scripts to deal
%       with more complicated folder strutures and to loop through multiple
%       directories of sound files in one script
%
%       NOTE: previous versions of this function allowed for specifying the
%       file extension as either .wav or .flac. It now defaults to the same
%       extension as the original data. If converting between .wav and
%       .flac is desired see WAV2FLAC or FLAC2WAV, or reach out to discuss
%       a combined function.
%
%	Inputs:
%       fsNew   [double] or [vector] new sample rate or vector of multiple
%               new sample rates (e.g., [1000 9600]) in Hz. Original sample
%               rate must be divisible by new sample rates by an integer
%       folder 	path to audio files to be decimated
%
%	Outputs:
%		creates a folder where newly written audio files are stored
%
%	Examples:
%       decimate([10 9600], 'G:/glider/wav');
%
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:       13 January 2026
%
%	Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set arguments
arguments
    fsNew   (1,:) double {mustBePositive} = []
    folder  (1,:) char   = ''
    % ext     (1,:) char   = '.flac'
end

% prompt for missing args
if isempty(fsNew)
    fsNew = input('Specify new sample rate(s) in Hz (e.g., [1000 9600]): ');
end
fsNew = fsNew(:); % force to column

if isempty(folder) || ~exist(folder, 'dir')
    folder = uigetdir(pwd, 'Select folder containing audio files');
    if folder == 0
        error('No folder selected. Exiting.');
    end
end

% % normalize extension
% if isempty(ext)
%     ext = '.wav';
% end
%
% if ext(1) ~= '.'
%     ext = ['.' ext];
% end


% fileList = dir(folder);
% % skip any subfolders or ., ..
% dirFlags = [fileList.isdir];
% fileList = fileList(~dirFlags,:);

% do the decimation!
fprintf(1, 'Decimating %s\n', folder);
fprintf(1, '   Start time: %s\n',datetime('now'));

% find all the audio files
supportedExt = {'.wav', '.flac'};
audioFiles = [];

for k = 1:numel(supportedExt)
    audioFiles = [audioFiles; dir(fullfile(folder, ['*' supportedExt{k}]))]; %#ok<AGROW>
end

% check for audio files
if isempty(audioFiles)
    error('No supported audio files (.wav or .flac) found in %s.', folder);
end

% check for mix of .wav and .flac
[~, ~, exts] = cellfun(@fileparts, {audioFiles.name}, 'UniformOutput', false);
uExt = unique(lower(exts));
if numel(uExt) > 1
    fprintf(1, 'Found the following audio file types in %s:\n', folder);
    fprintf(1, '  %s\n', uExt{:});
    error('Aborting due to mixed audio file types.');
end

% if files present...
if ~isempty(audioFiles)
    % set up decimation factors/output folder structure based on first file
    infoFirst = audioinfo(fullfile(folder, audioFiles(1,1).name));
    fprintf(1, 'Original sample rate: %0.f Hz\n', infoFirst.SampleRate)
    df = zeros(length(fsNew), 1); % decimation factor(s)
    path_out = cell(length(fsNew), 1);
    fsNewStr = cell(length(fsNew), 1);
    isValid = false(length(fsNew), 1);
    for f = 1:length(fsNew)
        fsN = fsNew(f);
        % calc decimation factor and check that its an integer
        dfN = infoFirst.SampleRate/fsN;
        if rem(dfN, 1) ~= 0
            fprintf(1, ...
                'Invalid decimation factor:\n  %s\n  fs = %.0f Hz, fsNew = %.0f Hz (not integer) — skipping\n', ...
                folder, infoFirst.SampleRate, fsN);
            continue
        end
        % if integer, proceed
        fprintf(1,'  decimation factor (%0.f) to %i Hz is good\n', dfN, fsN);
        isValid(f) = true;
        df(f) = dfN;
        % make string for new file names - as Hz or kHz
        if fsN/1000 < 1
            fsNewStr{f} = [num2str(fsN) 'Hz']; % as Hz
        else
            fsNewStr{f} = [num2str(fsN/1000) 'kHz'];
        end

        pathParts = regexp(folder, filesep, 'split');
        path_outN = fullfile(pathParts{1:end-1}, ...
            [pathParts{end} '_decimated_' fsNewStr{f}]);
        mkdir(path_outN);
        path_out{f} = path_outN;
    end % fsNew

    df        = df(isValid);
    fsNew     = fsNew(isValid);
    fsNewStr  = fsNewStr(isValid);
    path_out  = path_out(isValid);

    if isempty(df)
        error('No valid decimation factors for folder: %s', folder);
    end

    % decimate and write new files
    for af = 1:length(audioFiles)
        try
            [~, wfName, fileExt] = fileparts(fullfile(audioFiles(af).folder, ...
                audioFiles(af).name));
            info = audioinfo(fullfile(audioFiles(af).folder, ...
                audioFiles(af).name));
            [data, fs] = audioread(fullfile(audioFiles(af).folder, ...
                audioFiles(af).name), 'native');
            % confirm sample rate matches first file
            if fs ~= infoFirst.SampleRate
                error('Sample rate mismatch in file %s.', audioFiles(af).name);
            end

            if info.BitsPerSample ~= infoFirst.BitsPerSample
                error('Bit depth mismatch in file %s (%d bits ≠ %d bits).', ...
                    audioFiles(af).name, info.BitsPerSample, infoFirst.BitsPerSample);
            end

            for g = 1:length(df)
                dataNew = decimate(double(data), df(g));
                % write data type based on output bits
                if infoFirst.BitsPerSample == 16
                    audiowrite(fullfile(path_out{g}, [wfName '_' fsNewStr{g} fileExt]), ...
                        int16(dataNew), fsNew(g), 'BitsPerSample', infoFirst.BitsPerSample);
                elseif infoFirst.BitsPerSample == 24 || infoFirst.BitsPerSample == 32
                    audiowrite(fullfile(path_out{g}, [wfName '_' fsNewStr{g} fileExt]), ...
                        int32(dataNew), fsNew(g), 'BitsPerSample', infoFirst.BitsPerSample);
                else
                    fprintf(1, 'Error: bit size %i not supported.', infoFirst.BitsPerSample)
                    return
                end

                % old audiowrite - have to be careful with how data are
                % read in ('native') and saved (double vs int16/int32)
                % audiowrite(fullfile(path_out{g}, [wfName '_' fsNewStr{g} ext]), ...
                %     dataNew, fsNew(g), 'BitsPerSample', info.BitsPerSample);
            end
            clear data dataNew
        catch
            fprintf(1, 'ATTENTION: %s - file #%i: %s corrupt\n', ...
                datetime('now'), af, audioFiles(f,1).name);
        end

    end %loop through audioFiles
end % audioFile check
fprintf(1, '%s DONE. End time: %s\n', folder, datetime('now'))

end
