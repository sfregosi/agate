%% Flac for passive packer
%Katrina Johnson

%% old version
cd('J:\') % Modify this to be the source drive to read files from.
dirList = dir;
fullPathFlac = '"C:\flac-1.3.2-win\win64\flac"'; % Location of FLAC programs.
myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
outDir = 'D:\ListenGoMex_DT_15\data\acoustic_files\';% Modify this to be the output drive where the files read to. VERY IMPORTANT TO HAVE FINAL SLASH \
if ~isdir(outDir)
    mkdir(outDir)
end
%
for iDir = 1:length(dirList)
    thisList = dir(fullfile(dirList(iDir).folder,dirList(iDir).name,'*.x.wav'));
    if isempty(thisList)
        continue
    end
    cd(fullfile(dirList(iDir).folder,dirList(iDir).name))
    nFiles = length(thisList);
    for iFile = 1:length(thisList)
        myCMD = sprintf(myStr,fullPathFlac,outDir,thisList(iFile).name);
        [status,cmdout] = system(char(myCMD));    
        fprintf('Folder %0.0f: Done with file %0.0f of %0.0f - %s\n',iDir,iFile,nFiles,thisList(iFile).name)
    end
end

disp(' Done processing!')



%% new version (includes modifications for four channels)
cd('M:\') % Modify this to be the source drive to read files from.
dirList = dir;
fullPathFlac = '"C:\flac-1.3.2-win\win64\flac"'; % Location of FLAC programs.
%four channel use:
%myStr = '%s --keep-foreign-metadata --channel-map=none --output-prefix=%s %s';
%single channel use: 
%remove --channel-map=none when doing single channels:
myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
outDir = 'D:\ListenGoMex_MR_03_00\data\acoustic_files\';% Modify this to be the output drive where the files read to. VERY IMPORTANT TO HAVE FINAL SLASH \
if ~isdir(outDir)
    mkdir(outDir)
end

for iDir = 1:length(dirList)
    thisList = dir(fullfile(dirList(iDir).folder,dirList(iDir).name,'*.x.wav'));
    if isempty(thisList)
        continue
    end
    cd(fullfile(dirList(iDir).folder,dirList(iDir).name))
    nFiles = length(thisList);
    for iFile = 1:length(thisList)
        if ~exist(strrep(fullfile(outDir,thisList(iFile).name),'.x.wav','.x.flac'))|| (thisList(iFile).bytes<=10)
            
            [status, cmdout] = system(sprintf('dir %s',outDir(1:3)));
            
            myCMD = sprintf(myStr,fullPathFlac,outDir,thisList(iFile).name);
            [status,cmdout] = system(char(myCMD));
            if status
                fprintf('Folder %0.0f: Done with file %0.0f of %0.0f - %s\n',iDir,iFile,nFiles,thisList(iFile).name)
            else
                print(status)
                1;
            end
        end
    end
end

disp(' Done processing!')

%% This section just tests that all files were copied:
%
% flacList = dir('M:\GOM_DT_15_FLAC\');
% for iF = 1:length(flacList)
%     flacList(iF).name = flacList(iF).name(1:end-6);
% end
% xwavList = [dir('L:\**\*.x.wav'); dir('O:\**\*.x.wav')];
% for iX = 1:length(xwavList)
%     xwavList(iX).name = xwavList(iX).name(1:end-5);
% end
% [~,missingIdx] = setdiff({xwavList.name},{flacList.name});
% disp('Missing files:')
% unique({xwavList(missingIdx).folder})