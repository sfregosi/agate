function extract=basestationFileExtract(glider,outDir,URL)
% To extract glider files from the base station
% S. Fregosi 7/22/2016. Originally for AFFOGATO project/CatBasin deployment
%
% Currently extracts .nc, .log, and pa(WISPR) files basestation web
% Inputs:
% glider    should be something like 'sg607'
% URL       location of files
% outDir    directory of where to save the downloaded files

% Original path used
% outDir=['C:\Users\sfreg_000\SkyDrive\gliders_local\AFFOGATO\'...
%    '2016_07_CatBasin\sg607\extractedFiles\'];

%% check inputs
if (nargin >= 3 && ~isempty(URL))
    URL = URL;
else		% use the default
    URL = ['http://gliderfs2.coas.oregonstate.edu/sgliderweb/seagliders/'...
        glider '/current/basecopy/'];
end

%% List all files available on basestation
files = urlread(URL);
% produces single string of html code of url

%% Getting NC files
% search for locations in files str that are files of interest, here
% something like p6070001.nc
nc_ind = regexp(files,['p' glider(3:end) '.....nc']);
nc_ind = nc_ind(1,1:2:end); % there is always two versions of each file bc of html
ncNameLen = 11; % number of characters of filename

for f = 1:length(nc_ind);
    dive(f).ncFile = [files(nc_ind(f):(nc_ind(f)+ncNameLen-1))];
    if exist([outDir dive(f).ncFile]);
    else
        URL_nc=[URL dive(f).ncFile]; % URL for just that .nc file
        urlwrite(URL_nc,[outDir dive(f).ncFile]); % downlaod the file
        disp([dive(f).ncFile ' saved']);
    end
end
disp('**End of .nc files**');

%% getting pa files
% looking for something like pa0012au.r
pa_ind = regexp(files,'pa.....u.r');
pa_ind = pa_ind(1,1:2:end);
paNameLn = 10;

for f = 1:length(pa_ind);
    dive(f).paFile = [files(pa_ind(f):(pa_ind(f)+paNameLn-1))];
    if exist([outDir dive(f).paFile]);
    else
        URL_pa = [URL dive(f).paFile];
        urlwrite(URL_pa,[outDir dive(f).paFile]);
        disp([dive(f).paFile ' now saved']);
    end
end
disp('**End of .pa files**');

%% getting .log files
% ie p6070002.log
% ** THIS INFORMATION IS EMBEDDED IN THE .NC FILES SO I MIGHT BE ABLE TO
% SKIP THIS IN FUTURE***
log_ind = regexp(files,['p' glider(3:end) '.....log']);
log_ind = log_ind(1,1:2:end);
logNameLn = 12;

for f = 1:length(log_ind);
    dive(f).logFile = [files(log_ind(f):(log_ind(f)+logNameLn-1))];
    if exist([outDir dive(f).logFile]);
    else
        URL_log=[URL dive(f).logFile];
        urlwrite(URL_log,[outDir dive(f).logFile]);
        disp([dive(f).logFile ' now saved']);
    end
end

disp('**End of .log files**');

