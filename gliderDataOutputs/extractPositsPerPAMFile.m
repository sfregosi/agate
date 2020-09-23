function filePosits = extractPositsPerPAMFile(gldr, lctn, dplymnt, ...
    pam, locCalcT,secs, path_out)
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

if nargin < 7
    path_out = [];
end

filePosits = table;
if strcmp(gldr,'q003')
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
    save([path_out '\' gldr '_' lctn '_' dplymnt '_pamFilePosits.mat'],'filePosits');
    writetable(filePosits, [path_out '\' gldr '_' lctn '_' dplymnt '_pamFilePosits.csv']);
end

end
