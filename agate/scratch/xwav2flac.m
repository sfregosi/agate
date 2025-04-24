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
    fileList = dir(fullfile(dirList(iDir).folder,dirList(iDir).name,'*.x.wav'));
    if isempty(fileList)
        continue
    end
    cd(fullfile(dirList(iDir).folder,dirList(iDir).name))
    nFiles = length(fileList);
    for iFile = 1:length(fileList)
        myCMD = sprintf(myStr,fullPathFlac,outDir,fileList(iFile).name);
        [status,cmdout] = system(char(myCMD));
        fprintf('Folder %0.0f: Done with file %0.0f of %0.0f - %s\n',iDir,iFile,nFiles,fileList(iFile).name)
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
    fileList = dir(fullfile(dirList(iDir).folder,dirList(iDir).name,'*.x.wav'));
    if isempty(fileList)
        continue
    end
    cd(fullfile(dirList(iDir).folder,dirList(iDir).name))
    nFiles = length(fileList);
    for iFile = 1:length(fileList)
        if ~exist(strrep(fullfile(outDir,fileList(iFile).name),'.x.wav','.x.flac'))|| (fileList(iFile).bytes<=10)

            [status, cmdout] = system(sprintf('dir %s',outDir(1:3)));

            myCMD = sprintf(myStr,fullPathFlac,outDir,fileList(iFile).name);
            [status,cmdout] = system(char(myCMD));
            if status
                fprintf('Folder %0.0f: Done with file %0.0f of %0.0f - %s\n',iDir,iFile,nFiles,fileList(iFile).name)
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

%% sf version - encode (WAV to FLAC)
% only works on single folder

tic
% set input folder containing wav files
inDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\test_wavs';
cd(inDir)
% set output directory to put new files - VERY IMPORTANT TO HAVE FINAL SLASH \
outDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\output_flacs\';

% set location of FLAC program
fullPathFlac = 'C:\Users\selene.fregosi\programs\flac-1.5.0-win\Win64\flac';
% myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
encodeStr = '%s --keep-foreign-metadata-if-present --output-prefix=%s %s';

% make output directory if it doesn't exist
if ~isfolder(outDir)
    mkdir(outDir)
end

% loop through all files and convert
fileList = dir(fullfile(inDir, '*.wav'));
if isempty(fileList)
    return
end
cd(inDir)
nFiles = length(fileList);
for iFile = 1:length(fileList)
    myCMD = sprintf(encodeStr, fullPathFlac, outDir, fileList(iFile).name);
    [status, cmdout] = system(char(myCMD));
    fprintf('Done with file %0.0f of %0.0f - %s\n', ...
        iFile, nFiles, fileList(iFile).name)
end

fprintf(' Done processing %s\n Elapsed time %.0f seconds\n', inDir, toc)

%% sf version - decode (FLAC to WAV)
% only works on single folder

tic
% set input folder containing flac files
inDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\test_flacs';
cd(inDir)
% set output directory to put new files - VERY IMPORTANT TO HAVE FINAL SLASH \
outDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\output_wavs\';

% set location of FLAC program
fullPathFlac = 'C:\Users\selene.fregosi\programs\flac-1.5.0-win\Win64\flac';
% myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
decodeStr = '%s --decode --keep-foreign-metadata-if-present --output-prefix=%s %s';

% make output directory if it doesn't exist
if ~isfolder(outDir)
    mkdir(outDir)
end

% loop through all files and convert
fileList = dir(fullfile(inDir, '*.flac'));
if isempty(fileList)
    return
end
cd(inDir)
nFiles = length(fileList);
for iFile = 1:length(fileList)
    myCMD = sprintf(decodeStr, fullPathFlac, outDir, fileList(iFile).name);
    [status, cmdout] = system(char(myCMD));
    fprintf('Done with file %0.0f of %0.0f - %s\n', ...
        iFile, nFiles, fileList(iFile).name)
end

fprintf(' Done processing %s\n Elapsed time %.0f seconds\n', inDir, toc)

%% speed test comparison (FLAC to WAV)
% only works on single folder

tic
% set input folder containing flac files
inDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\test_flacs';
cd(inDir)
% set output directory to put new files - VERY IMPORTANT TO HAVE FINAL SLASH \
outDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\output_wavs_matlab\';

% % set location of FLAC program
% fullPathFlac = 'C:\Users\selene.fregosi\programs\flac-1.5.0-win\Win64\flac';
% % myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
% decodeStr = '%s --decode --keep-foreign-metadata-if-present --output-prefix=%s %s';

% make output directory if it doesn't exist
if ~isfolder(outDir)
    mkdir(outDir)
end

% loop through all files and convert
fileList = dir(fullfile(inDir, '*.flac'));
if isempty(fileList)
    return
end
cd(inDir)
nFiles = length(fileList);
for iFile = 1:length(fileList)
    % myCMD = sprintf(decodeStr, fullPathFlac, outDir, fileList(iFile).name);
    % [status, cmdout] = system(char(myCMD));
    inFile = fullfile(fileList(iFile).folder, fileList(iFile).name);
   [path, name, ext] = fileparts(inFile);
   info = audioinfo(inFile);
    [data, fs] = audioread(inFile);
    audiowrite(fullfile(outDir, [name, '.wav']), data, fs, ...
        'BitsPerSample', info.BitsPerSample)
    fprintf('Done with file %0.0f of %0.0f - %s\n', ...
        iFile, nFiles, fileList(iFile).name)
end

fprintf(' Done processing %s\n Elapsed time %.0f seconds\n', inDir, toc)

%% speed test comparison (WAV to FLAC)
% only works on single folder

tic
% set input folder containing flac files
inDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\test_wavs';
cd(inDir)
% set output directory to put new files - VERY IMPORTANT TO HAVE FINAL SLASH \
outDir = 'F:\CalCurCEAS2024_glider_data\flac_tests\output_flacs_matlab\';

% % set location of FLAC program
% fullPathFlac = 'C:\Users\selene.fregosi\programs\flac-1.5.0-win\Win64\flac';
% % myStr = '%s --keep-foreign-metadata --output-prefix=%s %s';
% decodeStr = '%s --decode --keep-foreign-metadata-if-present --output-prefix=%s %s';

% make output directory if it doesn't exist
if ~isfolder(outDir)
    mkdir(outDir)
end

% loop through all files and convert
fileList = dir(fullfile(inDir, '*.wav'));
if isempty(fileList)
    return
end
cd(inDir)
nFiles = length(fileList);
for iFile = 1:length(fileList)
    % myCMD = sprintf(decodeStr, fullPathFlac, outDir, fileList(iFile).name);
    % [status, cmdout] = system(char(myCMD));
    inFile = fullfile(fileList(iFile).folder, fileList(iFile).name);
   [path, name, ext] = fileparts(inFile);
   info = audioinfo(inFile);
    [data, fs] = audioread(inFile);
    audiowrite(fullfile(outDir, [name, '.flac']), data, fs, ...
        'BitsPerSample', info.BitsPerSample)
    fprintf('Done with file %0.0f of %0.0f - %s\n', ...
        iFile, nFiles, fileList(iFile).name)
end

fprintf(' Done processing %s\n Elapsed time %.0f seconds\n', inDir, toc)