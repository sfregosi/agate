function wpNames = getWaypointNames(CONFIG, method, nWpts, varargin)
%GETWAYPOINTNAMES Generate waypoint names for Seaglider targets files
%
%   Syntax:
%       OUTPUT = GETWAYPOINTNAMES(INPUT)
%
%   Description:
%       Detailed description here, please
%
%   Inputs:
%       input   describe, please
%
%	Outputs:
%       output  describe, please
%
%   Examples:
%
%   See also
%
%   Authors:
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:   09 February 2026
%
%   Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wpFile = '';

% parse optional args
vIdx = 1;
while vIdx <= length(varargin)
    switch varargin{vIdx}
        case 'wpFile'
            wpFile = varargin{vIdx+1};
            vIdx = vIdx + 2;
        otherwise
            error('Unknown argument.')
    end
end

switch method
    case 'file'
        if isempty(wpFile)
            [f, p] = uigetfile( ...
                fullfile(CONFIG.path.mission, '*.txt'), ...
                'Select waypoint names text file');

            if isequal(f, 0)
                error('Waypoint file selection cancelled.');
            end

            wpFile = fullfile(p, f);
        elseif ~exist(wpFile, 'file')
            error('Waypoint file not found: %s', wpFile);
        end

        fid = fopen(wpFile);
        wpNames = textscan(fid, '%s');
        fclose(fid);
        wpNames = wpNames{:};

    case 'manual'
        wpsRaw = input( ...
            sprintf('Type %d waypoint names, comma-separated: ', nWpts), ...
            's');
        wpNames = strtrim(strsplit(wpsRaw, ','))';

    otherwise
        prefix = method;
        wpNames = cell(nWpts, 1);

        for k = 1:nWpts-1
            wpNames{k} = sprintf('%s%02d', prefix, k);
        end

        % recovery waypoint naming
        switch length(prefix)
            case 1
                wpNames{end} = 'REC';
            case 2
                wpNames{end} = 'RECV';
            case 3
                wpNames{end} = 'RECOV';
            otherwise
                wpNames{end} = 'RECOVERY';
        end
end

% final sanity check
if numel(wpNames) ~= nWpts
    error('Expected %d waypoint names, got %d.', ...
        nWpts, numel(wpNames));
end
end