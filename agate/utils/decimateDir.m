function decimateDir(fsNew, folder, path_out)
% DECIMATEDIR	downsample directory of audio files using DECIMATE
%
%	Syntax:
%		DECIMATEDIR(FSNEW, FOLDER)
%		DECIMATEDIR(FSNEW, FOLDER, PATH_OUT)
%
%	Description:
%		Decimate a directory of audio files to a defined new sampling rate,
%		fsNew, or multiple new sample rates, and write new files in new
%		subdirectory.
%
%       The output directory can be specified, or if that argument is left
%       blank, an output directory will be created following the format of
%       [input folder]_decimated_[new sample rate]. Newly decimated files
%       will have the new sample rate appended to the filename (e.g.,
%       WISPR_260810_170505.flac will be WISPR_260810_170505_1kHz.flac).
%
%       This was originally a script that was modified for each deployment.
%       This function simplifies that script but means the function can
%       only be run on a single folder of sound files. See separate repo
%       myUtils/dataProcessing/downsampling for example scripts to deal
%       with more complicated folder strutures and to loop through multiple
%       directories of sound files in one script.
%
%       NOTE: previous versions of this function allowed for specifying the
%       file extension as either .wav or .flac. It now defaults to the same
%       extension as the original data. If converting between .wav and
%       .flac is desired see WAV2FLAC or FLAC2WAV, or reach out to discuss
%       a combined function.
%
%	Inputs:
%       fsNew    [double] or [vector] new sample rate or vector of multiple
%                new sample rates (e.g., [1000 9600]) in Hz. Original
%                sample rate must be divisible by new sample rates by an
%                integer
%       folder 	 path to audio files to be decimated
%       path_out (optional) [char] or [cell array] full path(s) to the
%                folder(s) where decimated files will be written, one per
%                entry in fsNew and in the same order. Folders are created
%                if they do not already exist. If empty or not specified,
%                output folders are created alongside the input folder as
%                [folder]_decimated_[fsNew]
%
%	Outputs:
%		creates a folder where newly written audio files are stored
%
%	Examples:
%       decimateDir([1000 9600], 'G:/glider/wav');
%
%       decimateDir([1000 9600], 'G:/glider/wav', ...
%           {'G:/glider/wav_decimate_1kHz', 'G:/glider/wav_decimate_9p6kHz'});
%
%	See also WAV2FLAC, FLAC2WAV
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	Updated:      2026 August 10
%
%	Created with MATLAB ver.: 9.9.0.1524771 (R2020b) Update 2
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set arguments
arguments
    fsNew   (1,:) double {mustBePositive} = []
    folder  (1,:) char   = ''
    path_out {mustBeText} = {}
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

% check output paths, if specified
if ~isempty(path_out)
    path_out = cellstr(path_out); % standardize char, string, cellstr inputs
    path_out = path_out(:);       % force to column to match fsNew

    % must have one output path per new sample rate
    if numel(path_out) ~= numel(fsNew)
        error(['Number of output paths (%i) must match number of new ' ...
            'sample rates (%i).'], numel(path_out), numel(fsNew));
    end

    % no empties
    if any(cellfun(@isempty, path_out))
        error('One or more specified output paths is empty.');
    end

    % no duplicates - would overwrite/mix decimated files
    if numel(unique(path_out)) ~= numel(path_out)
        error('Specified output paths must be unique.');
    end
end

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
    outDir = cell(length(fsNew), 1);
    fsNewStr = cell(length(fsNew), 1);
    isValid = false(length(fsNew), 1);
    for f = 1:length(fsNew)
        fsN = fsNew(f);
        % calc decimation factor and check that its an integer
        dfN = infoFirst.SampleRate/fsN;
        if rem(dfN, 1) ~= 0
            fprintf(1, ...
                ['Invalid decimation factor:\n  %s\n  fs = %.0f Hz, ', ...
                'fsNew = %.0f Hz (not integer) — skipping\n'], ...
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

        % use specified output path, or build default alongside input
        if isempty(path_out)
            pathParts = regexp(folder, filesep, 'split');
            outDirN = fullfile(pathParts{1:end-1}, ...
                [pathParts{end} '_decimated_' fsNewStr{f}]);
        else
            outDirN = path_out{f};
        end
        if ~exist(outDirN, 'dir')
            mkdir(outDirN);
        end
        outDir{f} = outDirN;
        fprintf(1, '  output folder: %s\n', outDirN);
    end % fsNew

    df        = df(isValid);
    fsNew     = fsNew(isValid);
    fsNewStr  = fsNewStr(isValid);
    outDir    = outDir(isValid);

    if isempty(df)
        error('No valid decimation factors for folder: %s', folder);
    end

    % decimate and write new files
    for af = 1:length(audioFiles)
        try
            [~, afName, fileExt] = fileparts(fullfile(audioFiles(af).folder, ...
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
                    audioFiles(af).name, info.BitsPerSample, ...
                    infoFirst.BitsPerSample);
            end

            for g = 1:length(df)
                dataNew = decimate(double(data), df(g));
                % write data type based on output bits
                if infoFirst.BitsPerSample == 16
                    audiowrite(fullfile(outDir{g}, ...
                        [afName '_' fsNewStr{g} fileExt]), int16(dataNew), ...
                        fsNew(g), 'BitsPerSample', infoFirst.BitsPerSample);
                elseif infoFirst.BitsPerSample == 24 || infoFirst.BitsPerSample == 32
                    audiowrite(fullfile(outDir{g}, ...
                        [afName '_' fsNewStr{g} fileExt]), int32(dataNew), ...
                        fsNew(g), 'BitsPerSample', infoFirst.BitsPerSample);
                else
                    fprintf(1, 'Error: bit size %i not supported.', ...
                        infoFirst.BitsPerSample)
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
                datetime('now'), af, audioFiles(af, 1).name);
        end

    end %loop through audioFiles
end % audioFile check
fprintf(1, '%s DONE. End time: %s\n', folder, datetime('now'))

end
