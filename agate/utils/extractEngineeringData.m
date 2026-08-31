function engT = extractEngineeringData(CONFIG, plotOn, debugOnError)
% EXTRACTENGINEERINGDATA	Extract glider engineering/flight-controller data
%
%   Syntax:
%       ENGT = EXTRACTENGINEERINGDATA(CONFIG, PLOTON)
%       ENGT = EXTRACTENGINEERINGDATA(CONFIG, PLOTON, DEBUGONERROR)
%
%   Description:
%       Extracts glider flight-controller (engineering) data from
%       basestation-generated .nc files and compiles into a table of
%       pitch, roll, heading, and VBD (variable buoyancy device) position,
%       along with a matching raw depth reading, at the vehicle's native
%       sg_data_point sampling resolution.
%
%       These variables are kept separate from EXTRACTCALCULATEDPOSITIONS
%       because they live on the sg_data_point clock, not the
%       ctd_data_point clock used by RBR Legato-CTD gliders for most
%       other variables (see EXTRACTCALCULATEDPOSITIONS header for
%       details). Unlike that function, no dimension branching is needed
%       here -- eng_pitchAng, eng_head, eng_rollAng, eng_vbdCC, and
%       eng_depth are all on sg_data_point for every glider vintage.
%
%       NOTE on depth: this table uses eng_depth (raw engineering value,
%       converted here from cm to m), NOT the basestation-corrected
%       'depth' or 'ctd_depth' used in EXTRACTCALCULATEDPOSITIONS.
%       eng_depth is uncorrected for average latitude and comes straight
%       from the vehicle's own instrument log rather than basestation
%       post-processing. It's included here so this table's time/depth
%       reference matches its own pitch/roll/heading/vbdCC values exactly
%       (same clock, same source), not to replace the corrected depth
%       columns elsewhere.
%
%   Inputs:
%       CONFIG        agate mission configuration file with relevant mission
%                     and glider information. Minimum CONFIG fields are
%                     'glider', 'mission', 'path.mission'
%       plotOn        optional argument to plot basic time series of outputs
%                     for checking; (1) to plot, (0) to not plot
%       debugOnError  optional argument (logical, default false) -- pauses
%                     at a keyboard prompt when a file fails to load, for
%                     inspecting the error interactively rather than just
%                     logging and skipping.
%
%	Outputs:
%       engT  Table with glider engineering/flight data at native
%             sg_data_point sampling resolution, one row per sample,
%             includes columns for dive, time, dateTime, pitch, roll,
%             heading, vbdCC, and depth (raw, from eng_depth)
%
%   Examples:
%
%   See also EXTRACTCALCULATEDPOSITIONS, EXTRACTSURFACEPOSITIONS
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   30 August 2026
%
%   Created with MATLAB ver.: 24.2.0.3212159 (R2024b) Update 9
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for debugging mode
if nargin < 3
	debugOnError = false;
end

% extracted from individual nc files
files = dir(fullfile(CONFIG.path.mission, 'basestationFiles\p*.nc'));

% Output table columns (for reference):
%   dive, time, dateTime, pitch, roll, heading, vbdCC

% collect one table per file, then vertcat to combine at the end
engTAll = cell(length(files), 1);

% loop through all files
for f = 1:length(files)
	fname = fullfile(CONFIG.path.mission, 'basestationFiles', files(f,1).name);
	[~, fname_name, fname_ext] = fileparts(fname);
	try
		% engineering variables dimension is always sg_data_point
		finfo = ncinfo(fname);
		dimNames = {finfo.Dimensions.Name};
		dimMatch = strcmp(dimNames, 'sg_data_point');
		samples = finfo.Dimensions(dimMatch).Length;

		% build table for this dive/file
		fileT = table();
		fileT.dive     = repmat(f, samples, 1);
		fileT.time     = unix2datenum(ncread(fname, 'time'));
		fileT.pitch    = ncread(fname, 'eng_pitchAng');
		fileT.roll     = ncread(fname, 'eng_rollAng');
		fileT.heading  = ncread(fname, 'eng_head');
		fileT.vbdCC    = ncread(fname, 'eng_vbdCC');

		engTAll{f} = fileT;

	catch ME
		fprintf(1, 'Problem loading %s: %s\n', [fname_name fname_ext], ME.message);
		if debugOnError
			keyboard
		end
	end
end

% combine all files (skip any empty entries from files that errored above)
engT = vertcat(engTAll{~cellfun(@isempty, engTAll)});

% add in dateTime col for readability
engT.dateTime = datetime(engT.time, 'ConvertFrom', 'datenum');
engT = movevars(engT, 'dateTime', 'After', 'time');

% check by plotting
if plotOn
	% pitch/roll/heading time series
	figure;
	ax(1) = subplot(4,1,1); plot(engT.dateTime, engT.pitch); ylabel('pitch (deg)');
	ax(2) = subplot(4,1,2); plot(engT.dateTime, engT.roll); ylabel('roll (deg)');
	ax(3) = subplot(4,1,3); plot(engT.dateTime, engT.heading); ylabel('heading (deg)');
	ax(4) = subplot(4,1,4); plot(engT.dateTime, engT.vbdCC); ylabel('vbdCC');
	xlabel('time');
	linkaxes(ax, 'x');
end

end