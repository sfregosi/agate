function [freeSpace, filesDive, filesClimb] = spaceUsed_PMAR(glider, outDir)

% to calculate battery usage during the GoMex 2017 deployment
% updated 07/06/17
% S. Fregosi 2020 02 08 to work with PMAR
% IN PROGRESS!!!!!!!!!!!!!


base_path = outDir;

log_files = dir([base_path 'p*.log']);
numDives = length(log_files)-1; % minus the pre-launch test log files

% set up output table
spaceUsed = table;
spaceUsed.diveNum = [1:numDives]';

for d = 1:numDives

    % Find Target depth
    f = d+1; % because first log file is dive 0/sealaunch
    %         for f = 2:numDives+1; %first log file is dive 0 - sealaunch
    x = fileread([base_path log_files(f).name]);
    idx = strfind(x,'$D_TGT');
    % find edges
    idxc1 = regexp(x(idx:end),',','once') + (idx-1);
    idxc2 = regexp(x(idxc1+1:end),'\n','once') + idxc1;
    % values I want...
    dTgt = str2num(x(idxc1+1:idxc2-1));
    spaceUsed.D_TGT(d) = dTgt;
   
    idxT = strfind(x,'$GPS2');
timeIdxs = [idxT+6:idxT+18];
spaceUsed.diveEnd(d,1) = datenum(x(timeIdxs),'ddmmyy,HHMMSS');
spaceUsed.diveEndTime(d,1) = datetime(spaceUsed.diveEnd(d,1), 'ConvertFrom', 'datenum');
end



% get pam folders
pamFolders = dir([base_path 'pm*']);

% separate A and B files
pam_filesA = dir([base_path 'pa*au.r']);
pam_filesB = dir([base_path 'pa*bu.r']);
pam_filenames = {pam_filesA.name}';

for f = 1:length(pam_filenames);
    pam_dives(f,1) = str2num(pam_filenames{f}(3:6));
    pam_divesStr{f,1} = pam_filenames{f}(3:6);
end


for d=1:numDives
    if any(d == pam_dives) % any pa files for this dive?
        dStr = sprintf('%4.4d',d); % pad some zeros
        pa_fileA = ['pa' dStr 'au.r'];
        pa_fileB = ['pa' dStr 'bu.r'];
        %try to read in A, but then check if empty
        paStats = paRead([base_path pa_fileA]); spaceUsed.notes(d) = {'Au'};
        if isempty(paStats.DiveNum) % if its empty read in b
            paStats = paRead([base_path pa_fileB]); spaceUsed.notes(d) = {'Bu'};end
        if isempty(paStats.DiveNum) % if Bu is also empty...state so
            spaceUsed.notes(d) = {'paEmpt'};
        else % if its not empty, do this! 
        spaceUsed.Free(d) = paStats.Free;
        spaceUsed.TotalTime(d) = paStats.TotalTime;
        spaceUsed.MaxDepth(d) = paStats.MaxDepth;
        spaceUsed.Startups(d) = paStats.Startups;
        %         spaceUsed.Energy(d) = paStats.Energy;
        end
    else
        fprintf(1,'Dive %i pam off\n',d);
        spaceUsed.notes(d) = {'noPa'};
    end
    
    % Find Target depth
    f = d+1; % because first log file is dive 0/sealaunch
    %         for f = 2:numDives+1; %first log file is dive 0 - sealaunch
    x = fileread([base_path log_files(f).name]);
    idx = strfind(x,'$D_TGT');
    % find edges
    idxc1 = regexp(x(idx:end),',','once') + (idx-1);
    idxc2 = regexp(x(idxc1+1:end),'\n','once') + idxc1;
    % values I want...
    dTgt = str2num(x(idxc1+1:idxc2-1));
    spaceUsed.D_TGT(d) = dTgt;
   
    idxT = strfind(x,'$GPS2');
timeIdxs = [idxT+6:idxT+18];
spaceUsed.diveEnd(d,1) = datenum(x(timeIdxs),'ddmmyy,HHMMSS');

    
end

writetable(spaceUsed,'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\spaceUsed.csv')

figure
plot(spaceUsed.diveEnd,spaceUsed.Free,'.')
grid on
xlabel('Days in Mission')
ylabel('Free Space (%)')
xlim([min(spaceUsed.diveEnd) min(spaceUsed.diveEnd + 50)])
set(gca,'xTick',[min(spaceUsed.diveEnd):5:min(spaceUsed.diveEnd + 50)],...
    'xTickLabel',[0:5:100]);

title(sprintf('SG639 through dive %i',numDives))


print('-dpng', 'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\spaceUsed.png');

fprintf(1,'Free Space Left: %f\n',spaceUsed.Free(end))




% deployment = '2018_05_10_GoMex';
% diveNum = [1:51];
% d = diveNum;
% gliders = {'sg607' 'sg639'}
% deployment = '2017_04_21_Newport';

Ah = table([],[],[],[],[],[],[],{},'VariableNames',{'Dive','diveEnd','pamAh','pamAhCum',...
    'sgAh','freeSpace','recMin','notes'});

% for g = 1:length(gliders);
g = 1;
gldr = gliders{g};
% where to download the files to
base_path = 'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\basestationFiles\';

% extract necessary files
% URL = ['http://gliderfs2.coas.oregonstate.edu/sgliderweb/seagliders/'...
%     gldr '/current/basecopy/'];
% basestationFileExtract(gldr,base_path);

% number of dives
log_files = dir([base_path 'p*.log']);
numDives = length(log_files)-1; % minus the pre-launch test log files

% get pam files
pam_filesA = dir([base_path 'pa*au.r']);
pam_filesB = dir([base_path 'pa*bu.r']);
if length(pam_filesB) > length(pam_filesA)
    pam_filenames = {pam_filesB.name}';
else pam_filenames = {pam_filesA.name}';
end
% get a list of the dives with PAM files at all (dives with PAM ON)
% if statement is in case  just an au or bu file uploaded, but not both
for f = 1:length(pam_filenames)
    pam_dives(f,1) = str2num(pam_filenames{f}(3:6));
    %     pam_divesStr{f,1} = pam_filenames{f}(3:6);
end

%%
% n = 1; % PA file number counter
ampHrRate = [];
for d = 1:numDives;
    % read in log file
    f = d+1; % because first log file is dive 0/sealaunch
    %         for f = 2:numDives+1; %first log file is dive 0 - sealaunch
    x = fileread([base_path log_files(f).name]);
    
    % calculate PAM power usage
    if any(d == pam_dives) % was pam on for this dive?
        dStr = sprintf('%4.4d',d); % pad some zeros
        pa_fileA = ['pa' dStr 'au.r'];
        pa_fileB = ['pa' dStr 'bu.r'];
        try % see if A file even exists, if not, pull B file.
            paStats = paRead([base_path pa_fileA]); Ah.notes(d,1) = {'Au'};
        catch paStats = paRead([base_path pa_fileB]); Ah.notes(d,1) = {'Bu'}; end
        % in case A file exists, but is partially empty, pull stats from B file
        if isempty(paStats.Energy); paStats = paRead([base_path pa_fileB]); Ah.notes(d,1) = {'Bu'}; end
        % there is still a chance both of these are empty.
        try % try and fill in values from paStats
            Ah.Dive(d,1) = d;
            Ah.pamAh(d,1) = ((paStats.Energy*1000)/paStats.TotalTime/paStats.Volt)* ... %amphr rate
                (paStats.TotalTime/3600); % times time on in hours
            ampHrRate = [ampHrRate;(paStats.Energy*1000)/paStats.TotalTime/paStats.Volt];
            Ah.freeSpace(d,1) = paStats.Free;
            Ah.recMin(d,1) = paStats.TotalTime/60;
        catch % if both were empty, fill in estimates.
            if isempty(paStats.Energy) && ~isempty(paStats.TotalTime)
                Ah.notes(d,1) = {'partialEstimate'};
                Ah.Dive(d,1) = d;
                Ah.pamAh(d,1) = 0.08*(paStats.TotalTime/3600); % use conservative estimate 0.08 Amp/hr
                Ah.recMin(d,1) = paStats.TotalTime/60;
                Ah.freeSpace(d,1) = paStats.Free;
            elseif isempty(paStats.Energy) && isempty(paStats.TotalTime)
                Ah.Dive(d,1) = d;
                Ah.notes(d,1) = {'fullEstimate'};
                % find seconds duration of dive
                idxS = strfind(x,'$STATE');
                idxS1 = idxS(1)+7;
                idxS1e = regexp(x(idxS1:end),',','once')+(idxS1-1);
                idxSe = idxS(end)+7;
                idxSee = regexp(x(idxSe:end),',','once')+(idxSe-1);
                dHrs = (str2num(x(idxSe:idxSee))-str2num(x(idxS1:idxS1e)))/3600;                
                Ah.pamAh(d,1) = 0.08*dHrs; % use conservative estimate 0.08 Amp/hr * total dive time
                Ah.recMin(d,1) = dHrs*60; % estimate total dive mins
            end
        end
    else % PAM was off for this dive; fill in zeros.
        fprintf(1,'Dive %f pam off\n',d);
        Ah.notes(d,1) = {'noFiles'};
        Ah.pamAh(d,1) = 0;
        Ah.recMin(d,1) = 0;
        Ah.Dive(d,1) = d;
    end
    
    % calcualte SG power usage
    idx = strfind(x,'$24V_AH');
    % find commas
    idxc1 = regexp(x(idx:end),',','once') + (idx-1);
    idxc2 = regexp(x(idxc1+1:end),',','once') + idxc1;
    % find next line
    idxN = regexp(x(idxc2:end),'\n','once') + (idxc2);
    % values I want...
    voltsH = str2num(x(idxc1+1:idxc2-1));
    ampHrsH = str2num(x(idxc2+1:idxN-2));
    Ah.sgAh(d,1) = ampHrsH;
    Ah.sgV(d,1) = voltsH;
    
    idxT = strfind(x,'$GPS2');
    timeIdxs = [idxT+6:idxT+18];
    Ah.diveEnd(d,1) = datenum(x(timeIdxs),'ddmmyy,HHMMSS');
    
    
end


%% Calculate total Amp Hours used during mission
Ah.pamAhCum(1,1) = 0;
Ah.pamAhCum2(1,1) = 0;
pi = 1;
for f = 1:height(Ah)
    Ah.pamAhCum(f,1) = nansum(Ah.pamAh(1:f,1));
    if strcmp(Ah.notes(f),'noFiles')
        pi = f;
    end
    Ah.pamAhCum2(f,1) = nansum(Ah.pamAh(pi:f,1));
end

Ah.totAh = Ah.pamAhCum+Ah.sgAh;
Ah.percRem = 100-(Ah.totAh/310)*100;
TotUsed = max(Ah.totAh)-min(Ah.totAh);
PerRem = min(Ah.percRem);

Ah.totAh2 = Ah.pamAhCum2+Ah.sgAh;
Ah.percRem2 = 100-(Ah.totAh2/310)*100;
TotUsed2 = max(Ah.totAh2)-min(Ah.totAh2);
PerRem2 = min(Ah.percRem2);

fprintf(1,'Battery remaining: %f or %f\n',PerRem,PerRem2);
save('C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\sg639_Energy.mat','Ah')
writetable(Ah,'C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\sg639_Energy.xls')

%% PLOT
figure
hold on
plot(Ah.diveEnd,100-(Ah.sgAh/310)*100,'.-r')
plot(Ah.diveEnd,100-(Ah.totAh2/310)*100,'.-b')
plot(Ah.diveEnd,100-(Ah.totAh/310)*100,'.-k')
grid on
ylim([0 100]);ylabel('Battery Remaining');
xlim([min(Ah.diveEnd) min(Ah.diveEnd + 60)])
set(gca,'xTick',[min(Ah.diveEnd):5:min(Ah.diveEnd + 60)],...
    'xTickLabel',[0:5:100]);
xlabel('Days in Mission')
hline(15,'r--')
vline(datenum(2018,06,22,0,0,0),'r--')
title(sprintf('SG639 through dive %i',numDives))
legend({'sg reported','estimated','estimated + reported'})
hold off

savefig('C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\sg639_Energy.fig')
print('C:\Users\selene\OneDrive\projects\GoMexBOEM\piloting\deployment\sg639_Energy.png','-dpng')
