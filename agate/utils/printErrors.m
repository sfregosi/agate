function printErrors(CONFIG, divenums, pp)
%PRINTERRORS	print the non-zero Seaglider errors for some dive(s)
%
%   Syntax:
%       PRINTERRORS(CONFIG, divenums, pp)
%
%   Description:
%       In the MATLAB Command Window, print the non-zero errors encountered on
%       one or more dives in a user-readable way. If there were no errors on
%       a given dive, nothing is printed.
%
%   Inputs:
%       CONFIG      Mission/agate global configuration variable
%	divenums    Dive numbers to print errors for
%       pp	    Piloting parameters variable for some glider; should have at
%		    least as many rows as max(divenums)
%
%   Outputs:
%       no output; might print information
%
%   Examples:
%	printErrors(CONFIG, 17:19, pp639)         % print errors on dives 17-19
%	printErrors(CONFIG, size(pp639,1), pp639) % print errors on last dive
%
%   See also EXTRACTPILOTINGPARAMS
%
%   Authors:
%       Dave Mellinger <David.Mellinger@oregonstate.edu>
%
%   FirstVersion:   17 May 2023
%   Updated:        17 May 2023
%
%   Created with MATLAB ver.: 9.13.0.2049777 (R2022b)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% These error names are copied out of the 'Seaglider File Formats Manual' for
% each revision of the Seaglider.
RevB_error_names = {
	'Buffer Overruns - The number of times the log file output is longer than the internal buffer length. For each of the buffer overruns, the output is truncated to fit in the buffer, resulting in lost logfile output'
	'Number of spurious interrupts. Spurious interrupts may result from divide by zero or memory de-reference problems. They may also arise from interrupt contention. Occasional isolated spurious interrupts are normal'
	'Number of CF8 errors while opening files'
	'Number of CF8 errors while writing files '
	'Number of CF8 errors while closing files'
	'Number of CF8 retries while opening files'
	'Number of CF8 retries while writing files'
	'Number of CF8 retries while closing the files'
	'Number of pitch errors'
	'Number of roll errors'
	'Number of VBD errors'
	'Number of pitch retries'
	'Number of roll retries'
	'Number of VBD retries'
	'Number of times the GPS did not provide data from $GPRMC (position and time) or $GPGGA (fix data) records within the 2 second timeout'
	'Number of sensor timeouts'
	};

RevE_error_names = {
	'Pitch errors during dive'
	'Roll errors during dive'
	'VBD errors during dive'
	'Pitch retries during dive'
	'Roll retries during dive'
	'VBD retries during dive'
	'GPS timeouts during dive'
	'Compass timeouts during dive'
	'Sensor 1 timeouts during dive'
	'Sensor 2 timeouts during dive'
	'Sensor 3 timeouts during dive'
	'Sensor 4 timeouts during dive'
	'Sensor 5 timeouts during dive'
	'Sensor 6 timeouts during dive'
	'Logger 1 timeouts during dive'
	'Logger 2 timeouts during dive'
	'Logger 3 timeouts during dive'
	'Logger 4 timeouts during dive'
	};

%% Figure out which error names to use.
if (CONFIG.sgVer == 66.12)
	errstrs = RevB_error_names;
elseif (CONFIG.sgVer == 67)
	errstrs = RevE_error_names;
else
	warning(['Version number (%f) in CONFIG.sgVer is unknown; I expected either '
		'66.12 or 67.\nRaw error counts:'], CONFIG.sgVer);
	pp.ERRORS(divenums)					%#ok<NOPRT>
	return
end

%% For each dive, print any errors with non-zero counts.
totalErrors = 0;
for di = 1 : length(divenums)
	errorCountStr = pp.ERRORS{divenums(di)};   % error string like '0,0,1,0,...'
	strs = split(errorCountStr, ',');	     % split into {'0' '0' '1' '0' ...}
	headerDone = false;
	for i = 1 : length(strs)
		errCount = str2double(strs{i});
		totalErrors = totalErrors + errCount;
		if (errCount ~= 0)
			if (~headerDone), fprintf('Errors on dive %d:\n', divenums(di)); end
			headerDone = true;
			fprintf('    Error #%d, count=%d: %s\n', i, errCount, errstrs{i});
		end
	end
end

if (totalErrors ~= 0)
	fprintf("Note: It's normal to get a small handful (< 5) of VBD retries and GPS timeouts.\n");
end

end
