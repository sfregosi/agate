% Convert all of the files in a directory to another file format. inTemplate
% determines what files are converted, and outExt determines the output format.

nOutputBits = 16;	% you can override below
outExt = '.wav';	% determines output format; you can override below
chans = NaN;		% this means read all channels; you can override below
chanStr = '';		% appended to output file name; you can override below
nStrip = 0;		% strip this many chars from old filename; can override
if (1)
	% WISPR files from bench testing in Hawaii.
	%     inDir = 'C:\Dave\Hawaii_gliders\operation\sg679_HI_Apr2023\230502\ascent\';
	inDir = 'E:\sg679_MHI_May2023\raw_acoustic_data\upper_ascent\left';
	%     outDir = fullfile(inDir, 'WAV');	% create this first - not auto created
	outDir = 'F:\sg679_MHI_May2023\wav\';
	inTemplate = '*.dat';
	nOutputBits = 24;
elseif (0)
	% Files from DCLDE 2022 for Pseudorca det/class.
	inDir = 'C:\Dave\sounds\Pseudorca_Hawaii_DCLDE\det\FLAC\cuvier\';
	outDir = inDir;

	% Enable ONE of the lines below. The first one ('*.flac') handles most
	% cases, and the rest of the lines are for handling exceptional cases. Note
	% that 'chans' uses CHANNEL NUMBERING STARTING AT 0, so 'chans=4' will get
	% what is often elsewhere called channel 5. This channel appears best for
	% most 1705 (R/V Lasker) and 1706 (Sette) files.
	chans = 4; inTemplate = '*.flac';			% handles most files
	%chans = 3; inTemplate = '1706_20170913*.flac';
	%chans = 3; inTemplate = '1706_20170918*.flac';
	%chans = 3; inTemplate = '1706_20170919*.flac';
	% A few files have only 3 channels. The first channel appears best.
	%chans = 0; inTemplate = '1706_20170828*.flac';
	%chans = 0; inTemplate = '1706_20170829*.flac';
	%chans = 0; inTemplate = '1706_2017090*.flac';
	%chans = 0; inTemplate = '1706_20170903*.flac';
	%chans = 0; inTemplate = '1706_20170904*.flac';
	%chans = 0; inTemplate = '1706_20170905*.flac';
	%chans = 4; inTemplate = '1706_FLAC_1706_2017091*.flac';%
	chanStr = ['-ch' num2str(chans+1)];
elseif (0)
	inTemplate = '*.flac';
	inDir = 'C:\dave\sounds\GoM2018_HDR\';
	outDir = 'C:\dave\sounds\GoM2018_HDR\';
elseif (0)
	inTemplate = '*.DAT';
	inDir = 'C:\dave\airguns\detectorTest\';
	outDir = 'C:\dave\airguns\detectorTest\';
elseif (0)
	inTemplate = 'wispr_*.flac';
	nOutputBits = 24;
	nStrip = 6;	% for new filename, strip 6 characters from old filename
	inDir = 'C:\dave\LADC-GEMM\data2017\sounds\';
	outDir = 'C:\dave\LADC-GEMM\data2017\sounds\';
end

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
