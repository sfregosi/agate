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
        case 'figNum'
            figNum = varargin{vIdx+1};
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



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% Configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if nargin < 1
    % This configuration section has example values for each parameter. You'll need
    % to change these for your files and directories.

    %  };

    % % 	% outTemplate is a template (a format string) for the name of the .wav files to
    % % 	% be created. It should include a %s, which becomes a date/time stamp, and it
    % % 	% should end in .wav, .aif, or any other extension known to audiowrite.
    % % 	% outTemplate = 'SoCal_%s.wav';       % must have %s and an extension like .wav
    % % 	outTemplate = '%s.wav';       % must have %s and an extension like .wav



    % % 	% This is for restarting a conversion after it halted. Use '' to start the
    % % 	% conversion from the beginning, or a specific directory name to run the
    % % 	% conversion on that directory and all following ones.
    % % 	restartDir = '';           % start at the beginning and do all the directories
    % % 	%restartDir = 'pm0006a';    % re-start conversion at this directory
    % %
    % % 	% This is for downsampling the data during file conversion. It downsamples by a
    % % 	% factor of 'decim' -- for instance, if decim=5, then the converted .wav files
    % % 	% will have a sample rate 1/5 that of the input PMAR (.dat) files. If you don't
    % % 	% want to downsample, set decim to 0 (or 1). If you do want to downsample, you
    % % 	% need to set the relativeCutoffFreq parameter immediately below. Downsampling
    % % 	% requires the signal processing toolbox (to design the filter). decim must be
    % % 	% an integer, and all the input files must have nearly identical sample rates.
    % % 	%
    % % 	% Note: Sometimes filtering and decimating results in a 'Data clipped when
    % % 	% writing file' warning. My experience is that this happens only when a glider
    % % 	% motor is running, not from environmental sound, so I don't mind it. If you
    % % 	% absolutely don't want it, change the audiowrite statement far below to divide
    % % 	% 'sams' by, say, 10 to lower its amplitude by 20 dB, but beware that this might
    % % 	% result in loss of low-amplitude sound.
    % % 	decim = 0;                      % use this line if you don't want to downsample
    % % 	%decim = 18;                    % use this line to downsample (by this factor)
    % %
    % % 	% relativeCutoffFreq is used only if you're decimating (downsampling) - i.e.,
    % % 	% decim is 2 or more. It specifies the cutoff frequency of the lowpass filter
    % % 	% relative to the Nyquist frequency of the downsampled (decimated) signal. It
    % % 	% must be between 0 and 1. For example, if the downsampled signal has a sample
    % % 	% rate of 10 kHz, and therefore a Nyquist frequency of 5 kHz, a
    % % 	% relativeCutoffFreq of 0.8 would result in a filter cutoff frequency of 4 kHz.
    % % 	% Values around 0.7-0.9 work well; larger numbers in this range preserve more of
    % % 	% the available frequency range in the filtered signal, but result in longer
    % % 	% filters that are slower to run.
    % % 	relativeCutoffFreq = 0.8;      % relative to Nyquist freq of decimated signal
    % %
    % % 	% forceSRate specifies a sample rate to put into the newly-created output
    % % 	% soundfiles. It's useful because PMAR outputs have minor variations in sample
    % % 	% rate from file to file (e.g., 180259 Hz vs. 180261 Hz), but if these different
    % % 	% rates are propagated to the output files, it messes up later software like
    % % 	% Triton that doesn't like variable sample rates. If forceSRate is NaN, it's
    % % 	% ignored and the sample rate from the PMAR soundfile is used in the output
    % % 	% soundfiles.
    % % 	%forceSRate = NaN;              % uncomment to leave sample rates as is
    % % 	forceSRate = 180260;            % uncomment to force a given sample rate

% else % you can specify the configuration with a separate configuration script
    % inDir = CONFIG.ws.inDir;
    % outDir = CONFIG.ws.outDir;
    % % 	outTemplate = CONFIG.pm.outTemplate;
    % showProgress = CONFIG.ws.showProgress;
    % % 	restartDir = CONFIG.pm.restartDir;
    % % 	decim = CONFIG.pm.decim;
    % % 	if isfield(CONFIG.pm, 'relativeCutoffFreq')
    % % 		relativeCutoffFreq = CONFIG.pm.relativeCutoffFreq;
    % % 	end
    % % 	forceSRate = CONFIG.pm.forceSRate;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of configuration %%%%%%%%%%%%%%%%%%%%%%%%%

%% Reformat configuration parameters and check for errors.

if (~iscell(inDir)),   inDir = { inDir };  end
if (~iscell(outDir)), outDir = { outDir }; end

% % if (decim ~= round(decim))
% % 	error('The decimation factor ''decim'' must be an integer.');
% % end
% % if (decim > 1 && (relativeCutoffFreq <= 0 || relativeCutoffFreq >= 1))
% % 	error('The relative filter cutoff frequency ''relativeCutoffFreq'' must be between 0 and 1.')
% % end
% % if (decim > 1 && ~exist('designfilt', 'file'))
% % 	error('You must have the signal processing toolbox to use downsampling. Please set decim to 0.')
% % end

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
% %
% % % lpFilt is the filter used in downsampling. It can be designed only after we
% % % know the input sample rate.
% % lpFilt = [];
% %
% For finding filenames that have 4 consecutive digits.
dig6 = digitsPattern(6);
% %
% % forceWarned = false;

% get extension length
extLen = length(inExt);	% also strip this many chars from end


%% Process files.

% March through all of inDir.
for di = 1 : length(inDir) % inDir is a cell array
    fprintf(1, 'Source: %s\n', inDir{di});
    fprintf(1, 'Destination:  %s\n', outDir{:});

    % Get all PMAR names (pm*) and weed out ones that aren't valid directories or
    % are before the restart point.
    % pmarDirs = dir(fullfile(inDir{di}, 'pm*'));   % find all PMAR directories
datFiles_all = dir(fullfile(inDir{di}, '**\*.dat')); % recurse through subdirs
% extract just folders (so can restart if interupted)
datDirs = unique({datFiles_all(:).folder}');
    dj = 1;
    while (dj <= length(datDirs))
        [~,inName] = fileparts(datDirs{dj});            % name of possible subdirectory
        go = go || strcmpi(inName, restartDir);         % gotten to restart point yet?
        if (~go || ~isfolder(datDirs{dj}) || length(inName) < 6 || ~contains(inName,dig6))
            datDirs{dj} = [];                        % skip this directory
        else
            dj = dj + 1;                              % keep this directory
        end
    end

    % Process each directory in turn.
    for dj = 1 : length(datDirs)                 % ...and process each one

        % Find all .dat files in this directory and process each one.
        datFiles = dir(fullfile(datDirs{dj}, 'WISPR*.dat'));
        for fi = 1 : length(datFiles)

            % Check that datFiles(fi) looks like a soundfile name and has 1024-byte
            % header plus >100 bytes of data.
            inName = datFiles(fi).name;
            if (~datFiles(fi).isdir && length(inName) >= 6 && ...
                    contains(inName, dig6) && datFiles(fi).bytes > 1024+100)

                % Found one. Read in the data.
                inFile = fullfile(datFiles(fi).folder, datFiles(fi).name);
                [~,inDirLast] = fileparts(datFiles(fi).folder);
                sams = [];                              %#ok<NASGU>  saves memory

% read in using read_wispr_file from C. Jones wispr3 code
% https://github.com/embeddedocean/wispr3
                [hdr, data, time, stamp] = read_wispr_file(inFile, 1, 0);

                % clean up the header - remove empty entries (wispr 2 vs 3)
                fldNames = fieldnames(hdr);
                emp = cellfun(@(C) isempty(hdr.(C)), fldNames);
                hdr = rmfield(hdr, fldNames(emp));

                % [sams,nChan,~,inSRate,nLeft,dt,hdr] = pmarIn(inFile, 0, inf, []);

                % % Design the filter if needed and we haven't done so yet.
                % if (decim > 1 && isempty(lpFilt))
                %     lpFilt = designfilt('lowpassfir', ...   % a low-pass FIR filter
                %         'SampleRate',               inSRate, ...
                %         'PassbandFrequency',        inSRate/2 / decim * relativeCutoffFreq, ...
                %         'StopbandFrequency',        inSRate/2 / decim, ...
                %         'PassbandRipple',           0.5, ...               % decibels
                %         'StopbandAttenuation',      60, ...                % decibels
                %         'DesignMethod',             'kaiserwin');
                %     % Display the filter response.
                %     fvtool(lpFilt); drawnow
                %     fprintf('Filtering and decimation enabled. Filter length: %d samples\n\n', ...
                %         length(lpFilt.Coefficients));
                % 
                %     %[B,A] = designFilter('fir1', 180260, 3500, 300, 1);
                %     %[B,A] = fir1(filterLen, cutoffFreq, 'low');  % design lowpass filter
                % end

                % % Enforce forceSRate if desired.
                % outSRate = inSRate;
                % if (~isnan(forceSRate))
                %     % Check that forced sample rate is within 1% of recorded sample rate.
                %     if (~forceWarned && abs(forceSRate / inSRate - 1.0) > 0.01)
                %         warning(['!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'...
                %             'forceSRate (%g) differs from input file''s sample rate (%g) by\n'...
                %             'more than 1%%. This will distort frequencies in the output files.\n'...
                %             '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'], ...
                %             forceSRate, outSRate)
                %         forceWarned = true;
                %     end
                %     outSRate = forceSRate;
                % end

                % Produce an output file in each output directory.
                for dk = 1 : length(outDir)
                    % Construct output file name.
                    % fileRoot = sprintf(outTemplate, datetime(stamp, ...
                    %     'ConvertFrom', 'epochtime', 'Epoch', '1-Jan-1970', ...
                    %     'TicksPerSeconds', 1000));
                    %     % datestr(dt, 'yymmdd-HHMMSS.FFF'));
                    outName = [inName(1:end-extLen) outExt];
                    outFile = fullfile(outDir{dk}, outName);

                    % Copy header, and src/dst filenames, into fileheaders.txt.
                    fprintf(hdrFp(dk), '%%src_filename: %s/%s\n', ...
                        inDirLast, datFiles(fi).name);
                    fprintf(hdrFp(dk), '%%dst_filename: %s\n', outName);
                    fldNames = fieldnames(hdr);
                    for hk = 1:length(fldNames)
                    fprintf(hdrFp(dk), '%s: %s\n', fldNames{hk}, hdr.(fldNames{hk}));
                    end
                    fprintf(hdrFp(dk), '\n');
                    if (dk == 1 && showProgress)
                        [ inPath, inName, inExt] = fileparts(inFile);
                        [outPath,outName,outExt] = fileparts(outFile);
                        [~,inPathLast] = fileparts(inPath);  % last component of dir name
                        fprintf('%2d/%-2d (%2d): %s/%s%s  ==>  %s%s\n', dj, length(pmarDirs), ...
                            fi - 1, inPathLast, inName, inExt, outName, outExt);
                        %pathFile(pathDir(inFile)), pathFile(inFile), pathFile(outFile));
                    end

                    % % Filter signal if desired.
                    % if (~isempty(lpFilt))
                    %     sams = filter(lpFilt, sams);
                    %     if (decim > 1)
                    %         sams = sams(1 : decim : end);
                    %         outSRate = outSRate / decim;
                    %     end
                    % end
                    % Write out data. Note that .wav requires an integer sample rate.
                    audiowrite(outFile, sams / 32768, round(outSRate));
                    %soundOut(outFile, sams, sRate);    % older
                end
            end
        end
    end
end
fclose(hdrFp);



extLen = length(pathExt(inTemplate));	% also strip this many chars from end
fileList = dir(fullfile(inDir, inTemplate));
for fi = 1 : length(fileList)
	% Figure out names of input and output files.
	inName = fileList(fi).name;
	outName = pathFile([inName(nStrip+1 : end-extLen-1) chanStr outExt]);
	printf('%3d/%-3d  %s', fi, length(fileList), inName)
	inFullName  = fullfile(inDir, inName);
	outFullName = fullfile(outDir, outName);

	% Read old file, write new file.
	[x,r] = soundIn(inFullName, 0, inf, chans);
	if (nOutputBits > 16)
		% audiowrite expects sample values in the range of (-1,1].
		if ~isempty(x)
			audiowrite(outFullName, x / 2^(nOutputBits-1), r, 'BitsPerSample', nOutputBits);
		elseif isempty(x)
			error('File %s is empty. Skipping...\n', inName);
		end
	else
		soundOut(outFullName, x, r);		% only does 16 bits!!!
	end
end