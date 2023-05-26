function filePosits = extractPositsPerPAMFile(CONFIG, ...
    pam, locCalcT, secs, path_out)
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
%	FirstVersion: 	26 July 2018
%	Updated:        23 April 2023
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% extract instrument positional data for each PAM file, including depth,
% lat, lon, vertical velocity, horizontal velocity, speed, and sound speed
%
% Inputs:   pam = table of
%fileName = acoustic file (either .wav or .flac) with date in
%               filename in format yyMMdd-HHmmss (*in future could adapt this?)
%           locCalcT = table with location/positional information for
%               instrument of interest
%           secs = buffer around file that you are willing to look for a
%               corresponding position. ~3 mins for glider, up to 10+ for
%               quephone because it samples location less often.
%
% Output:   pFilePosits - a table with instrument positional information at
%           the start of each PAM file
%
% S. Fregosi 2018/07/26
% updated 2019/09/04

global CONFIG
if nargin < 6
    path_out = [];
end

filePosits = table;
if strcmp(glider,'q003')
    noMatch = locCalcT(1,:);
    noMatch.dateTime = NaT;
    noMatch(1,2:end) = array2table(NaN(1,width(locCalcT) - 1));
else % actually a glider
    noMatch = locCalcT(1,:);
    noMatch(1,[1:2 4:end]) = array2table(NaN(1,width(locCalcT)-1));
    noMatch.dateTime = NaT;
    
end


% fileDate = datetime(fileName(1:end-4),'InputFormat','yyMMdd-HHmmss');
for f = 1:height(pam)
    filePosits.date(f,1) = pam.fileStart(f);
    [m,i] = min(abs(pam.fileStart(f)-locCalcT.dateTime)); % find the closest positional data
    if m < seconds(secs) % if the closest position is within buffer specified by secs
        filePosits(f,2:width(locCalcT)+1) = locCalcT(i,:);
    elseif m > seconds(secs) % if closest positional data is greater than buffer
        fprintf(1,'file %s closest time is > %i seconds\n',pam.fileStart(f),secs)
        filePosits(f,2:width(locCalcT)+1) = noMatch;
    else
        fprintf(1,'file %s error\n',pam.fileStart(f))
        filePosits(f,2:width(locCalcT)+1) = noMatch;
    end
end

filePosits.Properties.VariableNames(2:end) = locCalcT.Properties.VariableNames;

if ~isempty(path_out)
    save([path_out '\' glider '_' deploymentStr '_pamFilePosits.mat'],'filePosits');
    writetable(filePosits, [path_out '\' glider '_' deploymentStr '_pamFilePosits.csv']);
end

end
