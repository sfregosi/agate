function convertPmar(CONFIG)
%CONVERTPMAR    Convert and downsample PMAR soundfiles to WAVE (.wav) format
%
%   Syntax:
%       CONVERTPMAR(CONFIG)
%
%   Description:
%       Utility to convert raw PMAR-XL DAT (.dat) files to WAV (.wav)
%       files. This is a function-ized version of the convertPmar script
%       and associated function pmarIn written by Dave Mellinger, Oregon 
%       State University and avaiable in the MATLAB File Exchange at:
%       https://www.mathworks.com/matlabcentral/fileexchange/107245-convert-seaglider-pmar-xl-sound-files-to-wav-format
% 
%       The script and function have been modified and combined to work
%       within the agate toolbox. The input CONFIG files are populated from
%       a PMAR-specific configuration (.cnf) file. An example can be found
%       in the agate/settings folder. 
%
%       Given one or more directories, each full of subdirectories with
%       .dat sound files recorded by the PMAR-XL acoustic recording system 
%       on a Seaglider(tm), convert the soundfiles to WAVE (.wav) files. 
%       The resulting .wav files have the start date/time of each PMAR file
%       in the .wav file name. Also create a fileheaders.txt file in each 
%       of these directories with a copy of the header portion of each .dat
%       file, which is text. Optionally, filter and downsample the files to
%       a lower sample rate as they're being converted (downsampling 
%       requires the signal processing toolbox).
%
%   Inputs:
%       CONFIG   [struct] mission/agate configuration variable generated
%                when agate is initialized
%                Required fields: CONFIG.pm.convert, CONFIG.pm.convCnfFile
%                that populates additional required fields CONFIG.pm.inDir,
%                CONFIG.pm.outDir, CONFIG.pm.outTemplate,
%                CONFIG.pm.showProgress, CONFIG.pm.restartDir,
%                CONFIG.pm.decim, CONFIG.pm.relativeCutoffFreq, and
%                CONFIG.pm.forceSRate
%
%	Outputs:
%       None. Generates sound files
%
%   Examples:
%
%   See also 
%
%   Authors:
%       Dave Mellinger, Oregon State University
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   2024 December 11
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% Configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    % This configuration section has example values for each parameter. You'll need
    % to change these for your files and directories.

    % inDir specifies the head input directory or directories, each of which has
    % subdirectories named pmNNNNC (where N is a digit and C is a character like a,
    % b, c...), with each subdirectory having one or more pmNNNN.dat files. inDir
    % can be a string or a cell array of strings; input files will be gathered from
    % all of them.
    %inDir = 'C:\Dave\HDR_Marianas_Hawaii_GoA_SoCal\SoCal\data\';   % example
    inDir = 'C:\Dave\sounds\HI_Apr22_gliders\HI_Apr22_SG639\raw\';
    %inDir = {     % cell array example
    %  'E:\SoCal2020\SG607card1raw\' ...
    %  'E:\SoCal2020\SG607card2raw\'
    %  };

    % outDir specifies the directory to put the .wav files in. It can be a string
    % (one output directory name) or a cell array of strings (multiple output
    % directory names); copies of ALL of the output files will be put in EACH output
    % directory; this allows you to make multiple copies of the data in one pass. If
    % an output directory doesn't exist, it will be created. In each output
    % directory, a file named fileheaders.txt will also get made (or appended to, if
    % it already exists) containing the headers of all the .dat files read and
    % processed. These headers are lines of ASCII text. Two extra lines are added to
    % each header in fileheaders.txt specifying the source (.dat) and destination
    % (e.g., .wav) file names.
    % outDir = 'C:\Dave\HDR_Marianas_Hawaii_GoA_SoCal\SoCal\data\newWAV\'; % example
    outDir = 'C:\Dave\sounds\HI_Apr22_gliders\HI_Apr22_SG639\cooked\';
    %outDir = {           % can be cell array instead
    %  'D:/SoCal2020/sg607wav/' ...
    %  'F:/SoCal2020/sg607wav/'
    %  };

    % outTemplate is a template (a format string) for the name of the .wav files to
    % be created. It should include a %s, which becomes a date/time stamp, and it
    % should end in .wav, .aif, or any other extension known to audiowrite.
    % outTemplate = 'SoCal_%s.wav';       % must have %s and an extension like .wav
    outTemplate = '%s.wav';       % must have %s and an extension like .wav

    % 'showProgress' indicates whether or not to show progress in MATLAB's command
    % window. If true, show filenames are they're processed.
    showProgress = true;        % true or false

    % This is for restarting a conversion after it halted. Use '' to start the
    % conversion from the beginning, or a specific directory name to run the
    % conversion on that directory and all following ones.
    restartDir = '';           % start at the beginning and do all the directories
    %restartDir = 'pm0006a';    % re-start conversion at this directory

    % This is for downsampling the data during file conversion. It downsamples by a
    % factor of 'decim' -- for instance, if decim=5, then the converted .wav files
    % will have a sample rate 1/5 that of the input PMAR (.dat) files. If you don't
    % want to downsample, set decim to 0 (or 1). If you do want to downsample, you
    % need to set the relativeCutoffFreq parameter immediately below. Downsampling
    % requires the signal processing toolbox (to design the filter). decim must be
    % an integer, and all the input files must have nearly identical sample rates.
    %
    % Note: Sometimes filtering and decimating results in a 'Data clipped when
    % writing file' warning. My experience is that this happens only when a glider
    % motor is running, not from environmental sound, so I don't mind it. If you
    % absolutely don't want it, change the audiowrite statement far below to divide
    % 'sams' by, say, 10 to lower its amplitude by 20 dB, but beware that this might
    % result in loss of low-amplitude sound.
    decim = 0;                      % use this line if you don't want to downsample
    %decim = 18;                    % use this line to downsample (by this factor)

    % relativeCutoffFreq is used only if you're decimating (downsampling) - i.e.,
    % decim is 2 or more. It specifies the cutoff frequency of the lowpass filter
    % relative to the Nyquist frequency of the downsampled (decimated) signal. It
    % must be between 0 and 1. For example, if the downsampled signal has a sample
    % rate of 10 kHz, and therefore a Nyquist frequency of 5 kHz, a
    % relativeCutoffFreq of 0.8 would result in a filter cutoff frequency of 4 kHz.
    % Values around 0.7-0.9 work well; larger numbers in this range preserve more of
    % the available frequency range in the filtered signal, but result in longer
    % filters that are slower to run.
    relativeCutoffFreq = 0.8;      % relative to Nyquist freq of decimated signal

    % forceSRate specifies a sample rate to put into the newly-created output
    % soundfiles. It's useful because PMAR outputs have minor variations in sample
    % rate from file to file (e.g., 180259 Hz vs. 180261 Hz), but if these different
    % rates are propagated to the output files, it messes up later software like
    % Triton that doesn't like variable sample rates. If forceSRate is NaN, it's
    % ignored and the sample rate from the PMAR soundfile is used in the output
    % soundfiles.
    %forceSRate = NaN;              % uncomment to leave sample rates as is
    forceSRate = 180260;            % uncomment to force a given sample rate

else % you can specify the configuration with a separate configuration script
    inDir = CONFIG.pm.inDir;
    outDir = CONFIG.pm.outDir;
    outTemplate = CONFIG.pm.outTemplate;
    showProgress = CONFIG.pm.showProgress;
    restartDir = CONFIG.pm.restartDir;
    decim = CONFIG.pm.decim;
    if isfield(CONFIG.pm, 'relativeCutoffFreq')
        relativeCutoffFreq = CONFIG.pm.relativeCutoffFreq;
    end
    forceSRate = CONFIG.pm.forceSRate;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reformat configuration parameters and check for errors.

if (~iscell(inDir)),   inDir = { inDir };  end
if (~iscell(outDir)), outDir = { outDir }; end

if (decim ~= round(decim))
    error('The decimation factor ''decim'' must be an integer.');
end
if (decim > 1 && (relativeCutoffFreq <= 0 || relativeCutoffFreq >= 1))
    error('The relative filter cutoff frequency ''relativeCutoffFreq'' must be between 0 and 1.')
end
if (decim > 1 && ~exist('designfilt', 'file'))
    error('You must have the signal processing toolbox to use downsampling. Please set decim to 0.')
end

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

% lpFilt is the filter used in downsampling. It can be designed only after we
% know the input sample rate.
lpFilt = [];

% For finding filenames that have 4 consecutive digits.
dig4 = digitsPattern(4);

forceWarned = false;

%% Process files.

% March through all of inDir.
for di = 1 : length(inDir) % inDir is a cell array
    fprintf(1, 'Source: %s\n', inDir{di});
    fprintf(1, 'Dest.:  %s\n', outDir{:});

    % Get all PMAR names (pm*) and weed out ones that aren't valid directories or
    % are before the restart point.
    pmarDirs = dir(fullfile(inDir{di}, 'pm*'));   % find all PMAR directories
    dj = 1;
    while (dj <= length(pmarDirs))
        nm = pmarDirs(dj).name;                     % name of possible subdirectory
        go = go || strcmpi(nm, restartDir);         % gotten to restart point yet?
        if (~go || ~pmarDirs(dj).isdir || length(nm) < 6 || ~contains(nm(3:6),dig4))
            pmarDirs(dj) = [];                        % skip this directory
        else
            dj = dj + 1;                              % keep this directory
        end
    end

    % Process each directory in turn.
    for dj = 1 : length(pmarDirs)                 % ...and process each one

        % Find all .dat files in this directory and process each one.
        pmarFiles = dir(fullfile(pmarDirs(dj).folder, pmarDirs(dj).name, 'pm*.dat'));
        for fi = 1 : length(pmarFiles)

            % Check that pmarFiles(fi) looks like a soundfile name and has 1024-byte
            % header plus >100 bytes of data.
            nm = pmarFiles(fi).name;
            if (~pmarFiles(fi).isdir && length(nm) >= 6 && contains(nm(3:6), dig4) ...
                    && pmarFiles(fi).bytes > 1024+100)

                % Found one. Read in the data.
                inFile = fullfile(pmarFiles(fi).folder, pmarFiles(fi).name);
                [~,inDirLast] = fileparts(pmarFiles(fi).folder);
                sams = [];                              %#ok<NASGU>  saves memory
                [sams,nChan,~,inSRate,nLeft,dt,hdr] = pmarIn(inFile, 0, inf, []);

                % Design the filter if needed and we haven't done so yet.
                if (decim > 1 && isempty(lpFilt))
                    lpFilt = designfilt('lowpassfir', ...   % a low-pass FIR filter
                        'SampleRate',               inSRate, ...
                        'PassbandFrequency',        inSRate/2 / decim * relativeCutoffFreq, ...
                        'StopbandFrequency',        inSRate/2 / decim, ...
                        'PassbandRipple',           0.5, ...               % decibels
                        'StopbandAttenuation',      60, ...                % decibels
                        'DesignMethod',             'kaiserwin');
                    % Display the filter response.
                    fvtool(lpFilt); drawnow
                    fprintf('Filtering and decimation enabled. Filter length: %d samples\n\n', ...
                        length(lpFilt.Coefficients));

                    %[B,A] = designFilter('fir1', 180260, 3500, 300, 1);
                    %[B,A] = fir1(filterLen, cutoffFreq, 'low');  % design lowpass filter
                end

                % Enforce forceSRate if desired.
                outSRate = inSRate;
                if (~isnan(forceSRate))
                    % Check that forced sample rate is within 1% of recorded sample rate.
                    if (~forceWarned && abs(forceSRate / inSRate - 1.0) > 0.01)
                        warning(['!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'...
                            'forceSRate (%g) differs from input file''s sample rate (%g) by\n'...
                            'more than 1%%. This will distort frequencies in the output files.\n'...
                            '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'], ...
                            forceSRate, outSRate)
                        forceWarned = true;
                    end
                    outSRate = forceSRate;
                end

                % Produce an output file in each output directory.
                for dk = 1 : length(outDir)
                    % Construct output file name.
                    fileRoot = sprintf(outTemplate, datestr(dt, 'yymmdd-HHMMSS.FFF'));
                    outFile = fullfile(outDir{dk}, fileRoot);
                    % Copy header, and src/dst filenames, into fileheaders.txt.
                    fprintf(hdrFp(dk), '%%src_filename: %s/%s\n', ...
                        inDirLast, pmarFiles(fi).name);
                    fprintf(hdrFp(dk), '%%dst_filename: %s\n', fileRoot);
                    fprintf(hdrFp(dk), '%s\n', hdr{:});
                    fprintf(hdrFp(dk), '\n');
                    if (dk == 1 && showProgress)
                        [ inPath, inName, inExt] = fileparts(inFile);
                        [outPath,outName,outExt] = fileparts(outFile);
                        [~,inPathLast] = fileparts(inPath);  % last component of dir name
                        fprintf('%2d/%-2d (%2d): %s/%s%s  ==>  %s%s\n', dj, length(pmarDirs), ...
                            fi - 1, inPathLast, inName, inExt, outName, outExt);
                        %pathFile(pathDir(inFile)), pathFile(inFile), pathFile(outFile));
                    end

                    % Filter signal if desired.
                    if (~isempty(lpFilt))
                        sams = filter(lpFilt, sams);
                        if (decim > 1)
                            sams = sams(1 : decim : end);
                            outSRate = outSRate / decim;
                        end
                    end
                    % Write out data. Note that .wav requires an integer sample rate.
                    audiowrite(outFile, sams / 32768, round(outSRate));
                    %soundOut(outFile, sams, sRate);    % older
                end
            end
        end
    end
end
fclose(hdrFp);
end

%% PMARIN function
function [sams,nChans,sampleSize,sRate,nLeft,dt,hdr] = ...
    pmarIn(filename, start, nframe, chans)
%PMARIN         Read sound from a PMAR (Seaglider acoustic system) file
%
% sams = pmarIn(filename [,start [,n [,chans]]])
%    From a PMAR file, read sound data and return samples. 'start' is
%    the sample number (frame number) to start reading at (the first sample is
%    start=0), and n is the number of samples per channel to read. If n=Inf,
%    read the whole sound. chans is a vector specifying which channels are
%    desired, with channel 0 being the first channel. All of the arguments
%    after 'filename' are optional; if chans is missing, all channels are
%    returned. If the sound is shorter than n samples, then a shortened sams
%    array is returned.
%       The samples are returned in a matrix, with each channel's samples
%    filling one column of the matrix. The matrix has as many columns as the
%    length of chans.
%
% [sams,nChans,sampleSize,sRate,nLeft,dt,hdr] = pmarIn( ... )
%    From the given PMAR file, read the header and return, respectively, the
%    samples (sams), the number of channels (nChans; e.g., 2 for stereo), the
%    bytes per sample (sampleSize; always 2 so far for PMAR files), the sample
%    rate (sRate), the number of samples left in the file after the read
%    (nLeft), the start time of the file in datenum format (dt), and a copy of
%    the lines in the file's header as a cell array of strings (hdr).
%
%    The PMAR file is assumed to have little-endian (PC-style, not
%    Mac/Linux-style) numbers.

if (nargin < 2), start = 0; end
if (nargin < 3), nframe = inf; end
if (nargin < 4), chans = []; end

%% Read header.
% Headers have the format of a bunch of lines, each with '%' and a fieldname and
% a ':' and a space and a value, with the last line having fieldname
% 'headerend'.
fp = fopen(filename, 'r', 'l');     % 'l' means little-endian
if (fp < 0)
    error('Unable to open file %s for reading.', filename);
end

h = struct;         % header line values are deposited here
lineNo = 0;         % for error reporting
hdr = {};           % holds a copy of the header lines as strings
while (1)
    lineNo = lineNo + 1;
    ln = fgetl(fp);

    % Sometimes PMAR .dat files are missing part of the header. Try to cope.
    if (ln(1) == 0)   % incomplete headers start with buffering 0's
        % Try to complete the header. Require the header lines samplerate, start.
        if (~isfield(h, 'samplerate') || ~isfield(h, 'start'))
            error([mfilename ':IncompleteHeader'], ...
                'Incomplete header; I can''t cope with the absence of header lines "samplerate" or "start".');
        end
        if (~isfield(h, 'nchannels')),  h.nchannels = 1;     end
        if (~isfield(h, 'dataoffset')), h.dataoffset = 1024; end
        if (~isfield(h, 'samples'))
            % Figure out how many samples are in the file.
            fseek(fp, 0, 'eof');
            pos = ftell(fp);
            fseek(fp, h.dataoffset, 'cof');
            h.samples = (pos - h.dataoffset) / 2;
        end
        break
    end

    hdr = [hdr {ln}];                                             %#ok<AGROW>
    if (isnumeric(ln) || ln(1) ~= '%' || ~contains(ln, ':'))
        fclose(fp);
        error('Badly formatted header line in PMAR file %s, line #%d:\n%s', ...
            filename, lineNo, ln);
    elseif (strncmp(ln, '%headerend:', 11))
        break
    end

    % Parse the header line. 'fieldname' is the name of this header line.
    tokens = regexp(ln, '%(\w+): (.*)', 'tokens');
    fieldname = tokens{1}{1};             % chars between % and :
    h.(fieldname) = tokens{1}{2};         % add everything after ': ' to struct h

    % Handle special cases.
    switch(fieldname)
        case 'start'                        % make time stamp into datenum value
            v = sscanf(h.start, '%d %d %d %d %d %d %d');
            h.date = datenum(v(3)+1900, v(1), v(2), v(4), v(5), v(6) + v(7)/1000);

        case {'samplerate' 'nchannels' 'dataoffset' 'samples'}  % make these numeric
            h.(fieldname) = str2double(h.(fieldname));
    end
end           % while (1)

%% Read samples.
% NB: I assumed h.samples means number of samples per channel (i.e., number of
% sample frames), not total samples across all channels. This matters only for
% files with nchannels > 1, which I haven't seen yet.
sampleSize = 2;             % for now, all PMAR files have 2-byte samples
offset = h.dataoffset + start * sampleSize * h.nchannels;
fseek(fp, offset, 'bof');
framesToRead = min(h.samples - start, nframe);
if (h.nchannels > 1)
    sams = reshape(fread(fp, framesToRead * h.nchannels, 'uint16'), ...
        framesToRead, h.nchannels);
else
    sams = fread(fp, framesToRead * h.nchannels, 'uint16');
end
if (isempty(chans) || isnan(chans))
    chans = 0 : h.nchannels-1;
end
fclose(fp);

%% Construct return values. sampleSize and hdr are set above.
if (~isempty(sams))
    sams = sams(:, chans + 1) - 32768;    % code elsewhere assumes signed int16
end
sRate  = h.samplerate;
nLeft  = h.samples - (start + framesToRead);
nChans = h.nchannels;
dt     = h.date;
end