function processWisprDetFile(CONFIG, filename)
% PROCESSWISPRDETFILE	Unzip WISPR files and make them readable
%
%   Syntax:
%       PROCESSWISPRDETFILE(PATH_BSLOCAL, FILENAME)
%
%   Description:
%       Unzip a WISPR/ERMA detection file, which typically has a name like
%       ws0047az.x00, and remove the extraneous characters that show up in 
%       such files. The result is left in a file of the same name but 
%       without any extension. Assumes path_bsLocal/filename is a valid 
%       file name including an extension, and that it can be unzipped.
%
%       The potential extraneous characters that get removed are extra ^M 
%       characters (ASCII 13) every 64 characters throughout the file - I 
%       don't know how/where these get in there - as well as 'W>' at the 
%       end of the file, which is left over from the WISPR-to-Seaglider 
%       communications protocol.
%
%   Inputs:
%       CONFIG     agate mission configuration file with relevant mission 
%                  and glider information. Minimum needed for this function
%                  are CONFIG.bsLocal
%                  See exaxmple config file and config file help for more
%                  detail on each field: 
%                  https://github.com/sfregosi/agate-public/blob/main/agate/settings/agate_config_example.cnf
%                  https://sfregosi.github.io/agate-public/configuration.html#mission-configuration-file
%       filename   filename of the ws file to be unzipped
%
%	Outputs:
%       writes new files in CONFIG.bsLocal
%
%   Examples:
%
%   See also
%
%   Authors:
%       Dave Mellinger, David.Mellinger@oregonstate.edu
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   FirstVersion:   
%   Updated:        05 September 2024
%
%   Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Unzip the file. gunzip creates an unzipped version without any extension.
[~, name, ext] = fileparts(filename);
gunzip(fullfile(CONFIG.bsLocal, [name, ext]));	% makes unzipped file sans ext

% Remove the stray ^M and ending "W>" characters. Done by reading the whole
% file, removing those characters, and writing back what's left.
fp = fopen(fullfile(CONFIG.bsLocal, name), 'r');
str = fread(fp).';				% read entire file as uint8s
fclose(fp);
str(str == 13) = [];				% remove ^M characters
if (length(str) >= 2 && strcmp(char(str(end-1 : end)), 'W>'))
	str = str(1 : end-2);			% remove trailing "W>"
end
fp = fopen(fullfile(CONFIG.bsLocal, name), 'w');
fwrite(fp, str);				% write str as uint8s
fclose(fp);

end
