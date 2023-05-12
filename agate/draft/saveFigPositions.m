function positions = saveFigPositions(CONFIG, saveFileName)
%SAVEFIGPOSITIONS	Save positions of current figures to specifiy in .cnf
%
%	Syntax:
%		POSITIONS = SAVEFIGPOSITIONS(CONFIG, SAVEFILENAME)
%
%	Description:
%		Function to get the positions of all currently open figures and
%		save these in a cell array called 'positions'
%	Inputs:
%		CONFIG 	        Mission/agate global configuration variable
%       saveFileName    Optional input argument as fullfile path and name
%                       to save positions variable. If left empty, will
%                       prompt user to choose path/filename. If path is not
%                       specified, will prompt user to select save location
%
%	Outputs:
%		positions       cell array of figure positions for all currently 
%                       opened agate figures
%
%	Examples:
%       saveFigPositions(CONFIG, 'C:/figPositions.mat');
%	See also
%
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
%
%	FirstVersion: 	03 May 2023
%	Updated:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    saveFileName = [];
end

% % if a filename is specified
% if ~isempty(saveFileName)
%     if ~exist(saveFileName, 'file') % but it doesn't exist...check for path
%         [path, ~, ~] = fileparts(saveFileName);
%         if isempty(path) % if no path specified, prompt to select a file
%             fprintf(1, 'No path specified for saveFileName. Select new file');
%             [name, path] = uigetfile([CONFIG.path.mission '*.mat'], 'Select positions .mat file');
%             saveFileName = fullfile(path, name);
%         end
%     elseif exist(saveFileName, 'file') % and it exists... load it
%         load(saveFileName, 'positions');
%     else
%         fprintf(1, 'No saveFileName to load. Exiting.\n');
%         return
%     end
% end


% find all open figures
openFigs = get(0, 'Children');
% loop through and get positions of each and save
for f = 1:length(openFigs)
    of = openFigs(f);
    ofIdx = of.Number == CONFIG.plots.figNumList;
    positions{ofIdx} = [of.Position];
end

% if name is specified, check for file path and prompt to choose if none
if ~isempty(saveFileName)
    [chkPath, chkName, ~] = fileparts(saveFileName);
    if isempty(chkPath)
        [name, path] = uiputfile([CONFIG.path.mission chkName '.mat'], ...
            'Specify positions .mat file to save');
        if isequal(name, 0) || isequal(path, 0)
            fprintf(1, 'Save file selection canceled. Exiting.\n')
            return
        end
        saveFileName = fullfile(path, name);
    end
else % if no saveFileName specified, prompt to select one
    [name, path] = uiputfile([CONFIG.path.mission 'figPositions.mat'], ...
        'Specify positions .mat file to save');
    if isequal(name, 0) || isequal(path, 0)
        fprintf(1, 'Save file selection canceled. Exiting.\n')
        return
    end
    saveFileName = fullfile(path, name);
end

% save
save(saveFileName , 'positions');

