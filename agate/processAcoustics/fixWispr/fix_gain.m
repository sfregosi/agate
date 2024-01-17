%
% matlab script to fix gain jump between data files in a directoy
%
% Loop over a set of file in a directory and compare the data (of length nbufs)
% at the end of the first file with data at the beginning of the second file.
% Determine a gain change by comparing the spectrum of each data segment
% within a range of freqs [f1 f2].
% Change the freq range by entering new values when prompted.
% Enter the new freq range as a vector, for example [50000 60000]
%
% Apply the gain, which should be a factor of 1 (no gain change) or 2
% for a 6 dB change between the base noise levels of the files.
%
% The adjusted data is saved in wav file format, leaving the .dat files unchanged.
%
%
% A .dat data file consists of an ascii file header followed by binary data
% buffers. The ascii header is formatted as matlab expressions.
% The binary data words are formatted as signed 16 or 24 bit integers.
%
% The data file format is:
% - 512 byte ascii header.
% - adc buffer 1
% - adc buffer 2
% ...
% - adc buffer N
% where N is the number of adc buffers per file
%
% The number of adc buffers is defined as
% number_buffers = file_size*512 / buffer_size;
%
% The total data file size is always a multiple of 512 bytes blocks.
% The variable 'file_size' is the number of 512 blocks in the file.
%
% Each adc buffer is of length 'buffer_size' bytes.
% The adc buffer is always a multiple of 512 bytes blocks (32 blocks in most cases).
% Each adc buffer contains a fixed number of sample (samples_per_buffer).
% Each sample is of fixed size in bytes (sample_size).
% The sample size can be 2 or 3.
% If 3 byte samples are used, there will be extra bytes of padded at the end of each adc buffer.
% The number of bytes of padding is defined as:
% padding_per_buffer = buffer_size - (samples_per_buffer * sample_size);
%
% cjones 10/2023
%
% s. fregosi 2023-11-14
warning off
addpath(genpath('C:\Users\Selene.Fregosi\Documents\MATLAB\agate-public\agate'));

%% %%% SET UP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear all;
tic
% verbose = false; % or can be false to print less messages/be more automated
verbose = true;

% %%% SET PATHS %%%
% path_dat = uigetdir('D:\');
% path_dat = 'D:\sg679_MHI_May2023\gainFixTest4\raw';
% path_out = 'D:\sg679_MHI_May2023\gainFixTest4';
% path_wav = fullfile(path_out, 'wav');
% phase = 'lower_descent';
dayStr = 'workingFolder';
dive = 107;
% phase = 'descent';
% phase = 'ascent';
phase = 'fix';
path_dat = fullfile('D:\sg679_MHI_May2023\dat', dayStr);
path_out = 'D:\sg679_MHI_May2023\wav_gain_adjusted';
path_wav = fullfile(path_out, dayStr);
mkdir(path_wav);

% %%% ANALYSIS SETTINGS %%%
%R = input('Enter decimation factor [1]: ');
%if(isempty(R))
%    R = 1;
%end

adc_vref = 5.0;  % reference voltage of the adc (max voltage)
nbufs = 96; % number of data buffer to compare

% don't compare data above this amplitude threshold
max_thresh = 1.0; % set this value to eliminate spikes

% spectrum parameters
fft_size = 128;
win = hamming(fft_size)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
overlap = fft_size/2;

% freq range (Hz) to compare spectra
f1 = 60000;
f2 = 65000;

% set up log file
fid = fopen(fullfile(path_out, ['gainFix_dive', num2str(dive, '%03.f'), '_', ...
	phase, '.log']), 'a');

if fid == -1
	error('Cannot open log file.');
end
fprintf(fid, '\n%s: %s\n', datetime('now', 'format', 'uuuu-MM-dd''T''HH:mm:ss'), ...
	'Beginning gain fix process...');
if verbose
	fprintf(1, '\n%s: %s\n', datetime('now', 'format', 'uuuu-MM-dd''T''HH:mm:ss'), ...
		'Beginning gain fix process...'); %#ok<*UNRCH>
end

% pick a data directory with the .dat file.
% directoryname ='.';
% directoryname = uigetdir(directoryname);
directoryname = path_dat;
files = dir([directoryname '\*.dat']);
nfiles = size(files, 1);
if verbose
	fprintf(1, '%s: %i total .dat files to process\n', directoryname, nfiles);
end
fprintf(fid, '%s: %i total .dat files to process\n', directoryname, nfiles);

% set up output table
gt = table({files(:).name}', nan(nfiles, 1), nan(nfiles, 1), nan(nfiles, 1), ...
	nan(nfiles, 1), 'VariableNames', {'fileName', 'gainSug', 'gainAdj', ...
	'maxThresh', 'firstFile'});

%% %%% READ IN FIRST FILE %%%%%%%%%%%%%%%%%%%%%
first_file = 1;

if verbose; fprintf(1, 'Starting with file %s\n', files(1).name); end
fprintf(fid, 'Starting with file %s\n', files(1).name);

% read the first file in the directory
file1 = files(1).name;
name1 = fullfile(directoryname, files(1).name);
if strcmp(gt.fileName{1}, file1)
	gt.fileName{1} = name1;
	gt.firstFile(1) = 1;
else
	fprintf(1, 'File name does not match expected name. Paused.\n');
	pause; % name does not match expected name
end

% read just to get header info
[nrd1, hdr1, data1, time1] = read_wispr_file(name1, 1, 0);
% get num_bufs
% N = hdr1.file_size * 512 / hdr1.buffer_size;
% read
% [nrd1, hdr1, data1, time1] = read_wispr_file(name1, 1, N);

% remove all zero bufs - only keep everything up to nrd
data1 = data1(:, 1:nrd1);
time1 = time1(:, 1:nrd1);

%% %%% LOOP THROUGH ALL FILES %%%%%%%%%%%%%%%%%
% loop over files in directory
for m = 2:nfiles

	if files(m).isdir
		continue;
	end

	%% %%%%%% READ SECOND FILE %%%%%%%%%%%%%%%%
	file2 = files(m).name;
	name2 = fullfile(directoryname, files(m).name);
	% 	gt.fileName(m) = name2;
	if strcmp(gt.fileName{m}, file2)
		gt.fileName{m} = name2;
	else
		fprintf(1, 'Second file name does not match expected name. Paused.\n');
		pause; % name does not match expected name
	end

	[nrd2, hdr2, data2, time2] = read_wispr_file(name2, 1, 0);
	% remove zeros
	data2 = data2(:, 1:nrd2);
	time2 = time2(:, 1:nrd2);

	if verbose; fprintf(1, 'Comparing file %s and %s\n', file1, file2); end
	fprintf(fid, 'Comparing file %s and %s\n', file1, file2);

	%% %%%%%% PROCESS DATA TO BE COMPARED %%%%%

	% do some data size checks - first file
	if nrd1 < 1917 % size of full duration file
		if verbose
			fprintf(1, 'Looks like %s is truncated: nrd is %d not %d. Continuing...\n', ...
				files(m).name, nrd2, 1917);
		end
	end
	if nrd1 < nbufs
		if verbose
			fprintf(1, 'Not enough data in %s. Reducing nbufs to %i\n', ...
				files(m-1).name, nrd1);
		end
		fprintf(fid, 'Not enough data in %s. Reducing nbufs to %i\n', ...
			files(m-1).name, nrd1);
		nbufs1 = nrd1;
	else
		nbufs1 = nbufs;
	end
	% do some data size checks = second file
	if nrd2 < 1917 % size of full duration file
		if verbose
			fprintf(1, 'Looks like %s is truncated: nrd is %d not %d. Continuing...\n', ...
				files(m).name, nrd2, 1917);
			% 			pause;
		end
	end
	if nrd2 < nbufs
		if verbose
			fprintf(1, 'Not enough data in %s. Reducing nbufs to %i\n', ...
				files(m).name, nrd2);
		end
		fprintf(fid, '**Not enough data in %s. Reducing nbufs to %i\n', ...
			files(m).name, nrd2);
		nbufs2 = nrd2;
	else
		nbufs2 = nbufs;
	end

	% find a section of the data at the end of the first file (sig1)
	% and the start of he second file (sig2)
	sig1 = data1(:,nrd1-nbufs1+1:nrd1); % end of data1
	sig2 = data2(:,1:nbufs2); % beginning of data2

	% make time matrices
	t1 = time1(:,nrd1-nbufs1+1:nrd1) - max(max(time1));
	t2 = time2(:,1:nbufs2) - min(min(time2));

	% find the rms and max of the data segments
	rms1 = sqrt(mean(sig1.^2));
	rms2 = sqrt(mean(sig2.^2));
	max1 = max(abs(sig1));
	max2 = max(abs(sig2));

	%% %%%%%% APPLY THRESHOLDING %%%%%%%%%%%%%%
	% try to ignore the spikes in the data by thresholding
	i1 = find(abs(max1) < max_thresh);
	i2 = find(abs(max2) < max_thresh);

	% while isempty(i1) || isempty(i2) % all sig1 is above threshold
	while (length(i1) < 5 || length(i2) < 5) ... % minimum samples below thresh
			&& max_thresh < 4 % max possible max_thresh
		% try increasing threshold
		max_thresh = max_thresh + 1;
		% try to ignore the spikes in the data
		i1 = find(abs(max1) < max_thresh);
		i2 = find(abs(max2) < max_thresh);
		% 	   break;
	end
	if max_thresh > 1
		if verbose
			fprintf(1, 'Increased max_thresh = %i\n', max_thresh);
		end
		fprintf(fid, 'Increased max_thresh = %i\n', max_thresh);
	end

	if (isempty(i1) || isempty(i2)) && max_thresh == 4 % reached max
		max_thresh = Inf;
		fprintf(1, ['%s ...still not enough data points...', ...
			'gain will be NaN and force manual entry.\n'], files(m).name);
		fprintf(fid, ['...still not enough data points...', ...
			'gain will be NaN and force manual entry.\n']);
	elseif (length(i1) < 5 || length(i2) < 5) && max_thresh == 4 % reached max
		fprintf(1, '%s ...warning...very few data points for comparison.\n', ...
			files(m).name);
		fprintf(fid, '...warning...very few data points for comparison.\n');
	end

	gt.maxThresh(m) = max_thresh;

	% Calc spectrum of data
	fs = hdr1.sampling_rate;
	[spec1, freq1] = my_psd(sig1(:,i1), fs, win, overlap, t1(1));
	[spec2, freq2] = my_psd(sig2(:,i2), fs, win, overlap, t2(1));

	%% %%%%%% PLOT IF VERBOSE %%%%%%%%%%%%%%%%%
	% plot rms and spectrums
	if verbose
		figure(2); clf
		plotRMSSpec(i1, t1, rms1, spec1, freq1, i2, t2, rms2, spec2, freq2);
	end

	% prompt for frequency range (optional)
	if verbose
		commandwindow;
		str = sprintf('Enter freq range to compare [%d %d]: ', f1, f2);
		in = input(str);
		if (~isempty(in))
			f1 = in(1);
			f2 = in(2);
		end

		figure(2); hold on;
		subplot(212);
		xline([f1/1000 f2/1000], 'k:', 'HandleVisibility', 'off');
		hold off;
	end

	%% %%%%%% COMPARE FILE SEGMENTS %%%%%%%%%%%
	% compare the spectrum in the specified freq range to determine gain
	% gain should never be less than 1
	ig = find((freq1 > f1) & (freq2 < f2));
	db_gain = 10*log10(mean(spec2(ig)./spec1(ig)));
	gain = 10^(db_gain/20);
	% 	if gain < 1
	gain = round(gain*2)/2; % if gain < 1 but >= 0.75, call it 1,
	% if gain <0.75 >=0.25, call it 0.5, and < 0.25 = 0
	% 	else
	% 		gain = round(gain);
	% 	end

	%% %%%%%% CHECK FOR VALID GAIN %%%%%%%%%%%%

	% 	if gain == 1 % this is most straightforward occurance - no change
	% 		continue;

	% store suggested gain
	gt.gainSug(m) = gain;

	% 	if gain < 1 || isnan(gain) % this can either happen with first file or is a clipping issue
	% 		if first_file % if it is the first file, it needs to be adjusted down
	% 			% then first file needs adjustment; adjust and resave data1 to wav
	% 			fprintf(1, 'First file requires gain adjustment. Suggested: %.1f\n', ...
	% 				gain);
	% 			fprintf(fid, 'First file requires gain adjustment. Suggested: %.1f\n', ...
	% 				gain);
	% % 			fprintf(1, 'Applying gain adjustment of %.1f to the first file\n', gain);
	%
	% 			pause;
	% 			data1 = gain*data1;
	% 			sig1 = gain*sig1;
	% 			gt.gainAdj(m-1) = gain;
	% 		elseif ~first_file
	% 			fprintf(1, 'Gain is < 1 and not first file...something went wrong\n');
	% 			beep;
	% 			% 			pause;
	% 		end
	% 		% else do nothing by resetting gain to 1
	% 		beep;
	% 		gain = 1;
	% 	end



	% prompt to verify gain
	if verbose || (gain ~= 1 && gain ~= 2) || first_file
		fprintf(1, 'Comparing file %s and %s\n', file1, file2);
		nonstd = ''; % if just printing bc verbose, don't flag in log

		% plot the data segments
		figure(1); clf;
		subplot(2,1,1);
		plot(t1(:), sig1(:), t2(:), sig2(:));
		xlim([min(t1(:)) max(t2(:))]);
		xlabel('Seconds');
		ylabel('Volts');
		title('Original data');

		figure(2); clf
		plotRMSSpec(i1, t1, rms1, spec1, freq1, i2, t2, rms2, spec2, freq2);
		figure(2); hold on;
		subplot(212);
		xline([f1/1000 f2/1000], 'k:', 'HandleVisibility', 'off');
		hold off;

		if first_file
			% check the first file no matter what
			gain1 = gain;
			fprintf(1, 'Double check first file. Suggested: %.1f\n', ...
				gain1);
			fprintf(fid, '**Double check first file. Suggested: %.1f\n', ...
				gain1);

			commandwindow;
			str = sprintf(['Enter gain adjustment to apply to FIRST ', ...
				'file [%.1f]: '], gain1);
			in = input(str);
			if( ~isempty(in))
				gain1 = in;
			end
			fprintf(1, ['Applying gain adjustment of %.1f to the ', ...
				'FIRST file\n'], gain1);
			fprintf(fid, ['**Applying gain adjustment of %.1f to the ', ...
				'FIRST file\n'], gain1);
			data1 = data1/gain1;
			sig1 = sig1/gain1;
			gt.gainAdj(m-1) = gain1;
		end


		if (gain ~= 1 && gain ~= 2)
			beep;
			nonstd = '**NON-STANDARD';
			fprintf(fid, '%s suggested gain is %.1f.\n', nonstd, gain);

			% if first file needs adjustment; adjust and resave data1 to wav
			% 			if first_file
			% 				gain1 = gain;
			% 				fprintf(1, 'First file requires adjustment. Suggested: %.1f\n', ...
			% 					gain1);
			% 				fprintf(fid, '**First file requires adjustment. Suggested: %.1f\n', ...
			% 					gain1);
			%
			% 				commandwindow;
			% 				str = sprintf(['Enter gain adjustment to apply to FIRST ', ...
			% 					'file [%.1f]: '], gain1);
			% 				in = input(str);
			% 				if( ~isempty(in))
			% 					gain1 = in;
			% 				end
			% 				fprintf(1, ['Applying gain adjustment of %.1f to the ', ...
			% 					'FIRST file\n'], gain1);
			% 				fprintf(fid, ['**Applying gain adjustment of %.1f to the ', ...
			% 					'FIRST file\n'], gain1);
			% 				data1 = data1/gain1;
			% 				sig1 = sig1/gain1;
			% 				gt.gainAdj(m-1) = gain1;
			% 			end % first file check

		end

		commandwindow;
		str = sprintf('Enter gain adjustment to apply to second file [%.1f]: ', ...
			gain);
		in = input(str);
		if( ~isempty(in))
			gain = in;
		end

		% plot equalized data to confirm
		figure(1);
		subplot(2,1,2);
		sig2 = sig2/gain;
		plot(t1(:), sig1(:), t2(:), sig2(:));
		xlim([min(t1(:)) max(t2(:))]);
		ylabel('Volts');
		xlabel('Seconds');
		title('Equalized data');

		refresh();
		pause(0.5);
		% 		openvar('gt');

		commandwindow;
		if(input('Look ok? Enter 1 to quit [0]: ') == 1)
			break;
		end
	end

	% state/save final gain adjustment
	if verbose
		fprintf(1, 'Gain adjustment for second file is %.1f\n', gain);
	end
	fprintf(fid, 'Gain adjustment for second file is %.1f\n', gain);
	gt.gainAdj(m) = gain;

	% 	end
	%% %%%%%% ADJUST GAIN AND WRITE WAVS %%%%%%
	% save the first file to wav
	if first_file
		wavfile1 = [file1(1:end-3) 'wav'];
		audiowrite(fullfile(path_wav, wavfile1), data1(:)/(adc_vref), ...
			hdr1.sampling_rate, 'BitsPerSample', 24);
	end

	% adjust the gain on the second file
	if gain == 2
		% 	data2 = data2/gain; % old way with variable gain (not always 2)
		data2 = 0.5*data2;
	end

	% save the second file to wav
	wavfile2 = [file2(1:end-3) 'wav'];
	audiowrite(fullfile(path_wav, wavfile2), data2(:)/(adc_vref), ...
		hdr2.sampling_rate, 'BitsPerSample', 24);

	% save data2 to data1 for comparison with nex file
	data1 = data2;
	time1 = time2;
	name1 = name2;
	file1 = file2;
	nrd1 = nrd2;

	% flag that it's not the first file anymore
	first_file = 0;
	gt.firstFile(m) = first_file;
	% reset the max threshold
	max_thresh = 1;

	if verbose
		commandwindow;
		if(input('Quit? Enter 1 to quit [0]: ') == 1)
			break;
		end
	end

end % end loop through all files in this day

fprintf(fid, 'Processing completed in %i minutes\n\n', round(toc/60));
fprintf(1, 'Processing completed in %i minutes\n\n', round(toc/60));
save(fullfile(path_out, ['gainFix_dive', num2str(dive, '%03.f'), '_', ...
	phase '.mat']), 'gt');

% close log
fclose(fid);

beep; beep;
