function convertWisprToFlac(CONFIG, varargin)
%CONVERTWISPRTOFLAC    Convert WISPR .dat soundfiles to FLAC (.flac) format
%
%   Syntax:
%       CONVERTWISPRTOFLAC(CONFIG)
%
%   Description:
%       Given one or more directories, each full of subdirectories with
%       .dat soundfiles recorded by the WISPR acoustic recording system on
%       a Seaglider(tm), convert the .dat soundfiles to FLAC (.flac) files.
%       Also create a fileheaders.txt file in each of these directories
%       with a copy of the header portion of each .dat file, which is text.
%
%       Certain settings can be defined in the agate mission configuration
%       file or defaults will be used.
%       WISPR settings information can be found in the header of a raw .dat
%       file. File duration (in seconds) can be found as
%       file_duration = (file_size*512)/sample_size/sampling_rate
%
% % % Optionally, filter and
% % % downsample the files to a lower sample rate as they're being converted
% % % (downsampling requires the signal processing toolbox).
% % %
% % %
% % % convertPmarFun.m is a functionized version of the convertPmar.m script.
% % % it allows for a CONFIG input argument that is created from the
% % % pmarConvertConfig_template.m, which is meant to keep configuration for
% % % each mission organized in its own file
%
%   Inputs:
%       CONFIG        [struct] mission/agate configuration variable.
%                     Required fields: CONFIG.ws.inDir, CONFIG.ws.outDir,
%                     CONFIG.ws.......
%
%       all varargins are specified using name-value pairs
%                 e.g., 'showProgress', true
%
%
%   Outputs:
%       None. Generates sound files
%
%   Examples:
%
%   See also CONVERTPMARFUN
%
%   Authors:
%       Dave Mellinger Oregon State University
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:        04 December 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% argument checks
narginchk(1, inf)

% set some defaults
% CONFIG.ws.inDir = [];
% CONFIG.ws.outDir = [];
% 'showProgress' indicates whether or not to show progress in MATLAB's
% command window. If true, show filenames as they're processed.
showProgress = true;        % true or false
restartDir = '';            % string for restart subdirectory
inExt = '.dat';             % input extension
outExt = '.flac';           % output extension

% parse arguments
vIdx = 1;
while vIdx <= length(varargin)
    switch varargin{vIdx}
        case 'showProgress' % show progress in commmand window
            showProgress = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'restartDir' % start at a different subdirectory
            restartDir = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'inExt' % input format
            inExt = varargin{vIdx+1};
            vIdx = vIdx+2;
        case 'outExt' % output format
            outExt = varargin{vIdx+1};
            vIdx = vIdx+2;
        otherwise
            error('Incorrect argument. Check inputs.');
    end
end

% check/select in directory
% inDir specifies the input directory or directories. This can be a
% single directory of sound files, or a head directory with
% subdirectories, where subdirectories are named with the date (e.g.,
% 230504 for 4 May 2023) and each directory containing all sound files
% for that day inDir can be a string or a cell array of strings; input
% files will be gathered from all of them.
% inDir = 'E:\sg679_MHI_May2023\raw_acoustic_data\';   % example
% inDir = {     % cell array example
%  'E:\sg679_MHI_May2023\raw_acoustic_data\descent\' ...
%  'E:\sg679_MHI_May2023\raw_acoustic_data\ascent\'
%  };
if isfield(CONFIG.ws, 'inDir') && ~isempty(CONFIG.ws.inDir) && isfolder(CONFIG.ws.inDir)
    inDir = CONFIG.ws.inDir;
else
    inDir = uigetdir(CONFIG.path.mission, 'Select raw data folder');
end

% outDir specifies the directory to put the .wav files in. It can be a
% string (one output directory name) or a cell array of strings
% (multiple output directory names); copies of ALL of the output files
% will be put in EACH output directory; this allows you to make
% multiple copies of the data in one pass. If an output directory does
% not exist it will be created. In each output directory, a file named
% fileheaders.txt will also get made (or appended to, if it already
% exists) containing the headers of all the .dat files read and
% processed. These headers are lines of ASCII text. Two extra lines are
% added to each header in fileheaders.txt specifying the source (.dat)
% and destination (e.g., .wav) file names.
% outDir = 'F:\sg679_MHI_May2023\wav\'; % example
% outDir = {           % can be cell array instead
%  'F:\sg679_MHI_May2023\wav\' ...
%  'G:\sg679_MHI_May2023\wav\'
%  };
% check/select out directory
if isfield(CONFIG.ws, 'outDir') && ~isempty(CONFIG.ws.outDir) && isfolder(CONFIG.ws.outDir)
    outDir = CONFIG.ws.outDir;
else
    outDir = uigetdir(CONFIG.path.mission, 'Select output folder');
end

% check that inDir and outDir are formatted properly (if multiples)
if (~iscell(inDir)),   inDir = { inDir };  end
if (~iscell(outDir)), outDir = { outDir }; end

%% Initialization.

% Open fileheaders.txt files.
hdrFp = nan(1, length(outDir));
for dk = 1 : length(outDir)
    if (~exist(outDir{dk}, 'dir'))
        mkdir(outDir{dk});
    end
    hdrFp(dk) = fopen(fullfile(outDir{dk}, 'fileheaders.txt'), 'a+'); % append
end

% 'go' says whether we've gotten to restartDir yet. If restartDir is empty, it
% means start from the beginning, so 'go' is true from the start.
go = isempty(restartDir);               % have we gotten to restartDir yet?

% For finding filenames that have 6 consecutive digits (like a date)
dig6 = digitsPattern(6);

% get extension length for building filenames
extLen = length(inExt);


%% Process files.

% March through all of inDir.
for di = 1 : length(inDir) % inDir is a cell array
    fprintf(1, 'Source: %s\n', inDir{di});
    fprintf(1, 'Destination:  %s\n', outDir{:});

    % Get all possible .dat files and directories
    datFiles_all = dir(fullfile(inDir{di}, '**\*.dat')); % recurse through subdirs
    % extract just folders (so can restart if interupted)
    datDirs = unique({datFiles_all(:).folder}');
    dj = 1;
    while (dj <= length(datDirs))
        [~, inName] = fileparts(datDirs{dj});            % name of possible subdirectory
        go = go || strcmpi(inName, restartDir);         % gotten to restart point yet?
        if (~go || ~isfolder(datDirs{dj}) || length(inName) < 6 || ~contains(inName,dig6))
            datDirs{dj} = [];     % skip this directory
        else
            dj = dj + 1;          % keep this directory
        end
    end

    % Process each data directory in turn.
    for dj = 1:length(datDirs)

        % Find all .dat files in this directory and process each one.
        datFiles = dir(fullfile(datDirs{dj}, 'WISPR*.dat'));
        for fi = 1 : length(datFiles)

            % Check that datFiles(fi) looks like a soundfile name and has
            % 512-byte header plus >100 bytes of data.
            inName = datFiles(fi).name;
            if (~datFiles(fi).isdir && length(inName) >= 6 && ...
                    contains(inName, dig6) && datFiles(fi).bytes > 512+100)

                % if looks ok, read it in
                inFile = fullfile(datFiles(fi).folder, datFiles(fi).name);
                [~, inDirLast] = fileparts(datFiles(fi).folder);

                % read in using read_wispr_file from S. Fregosi fork of
                % wispr3 code originally by C. Jones
                % https://github.com/sfregosi/wispr3
                [hdr, raw, time, timestamp, hdrStrs] = read_wispr_file(inFile, 1, 0);

                % Produce an output file in each output directory.
                for dk = 1:length(outDir)
                    % set out file name
                    outName = [inName(1:end-extLen) outExt];
                    outFile = fullfile(outDir{dk}, outName);

                    % Copy header, and src/dst filenames, into fileheaders.txt.
                    fprintf(hdrFp(dk), '%%src_filename: %s/%s\n', ...
                        inDirLast, datFiles(fi).name);
                    fprintf(hdrFp(dk), '%%dst_filename: %s\n', outName);
                    fprintf(hdrFp(dk), '%s\n', hdrStrs{:});
                    % add the first timestamp as a datetime string
                    start_time_stamp = datetime(timestamp(1), ...
                        'ConvertFrom','epochtime', 'Epoch', '1-Jan-1970', ...
                        'Format', 'uuuu-MM-dd HH:mm:ss.SSS');
                    fprintf(hdrFp(dk), 'start_timestamp = ''%s'';\n', start_time_stamp);
                    fprintf(hdrFp(dk), '\n');

                    % if turned on, update progress in console
                    if (dk == 1 && showProgress)
                        fprintf('%2d/%-2d (%2d/%2d): %s/%s  ==>  %s\n', ...
                            dj, length(datDirs), fi, length(datFiles), ...
                            inDirLast, inName, outName);
                    end

                    % get bits
                    nOutputBits = hdr.sample_size*8; % should be 24
                    % reshape the data
                    nchans = hdr.channels;
                    nsamps = length(raw(:)) / nchans;
                    data = reshape(raw(:), nsamps, nchans);

                    % write the file
                    % audiowrite expects sample values in the range of (-1,1].
                    if ~isempty(data)
                        % audiowrite(outFile, data / 2^(nOutputBits-1), hdr.sampling_rate, 'BitsPerSample', nOutputBits);
                        audiowrite(outFile, data, hdr.sampling_rate, ...
                            'BitsPerSample', nOutputBits);

                    elseif isempty(data)
                        fprintf(1, 'File %s is empty. Skipping...\n', inName);
                    end

                end
            end
        end
    end
end
fclose(hdrFp);

end


