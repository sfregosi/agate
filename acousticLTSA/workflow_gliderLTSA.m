% script for workflow through creating an LTSA from glider data
%(outside of Triton)
instruments = {'sg158','q001','q002'};
for i = 1:3
% ***************PARAMETERS TO DEFINE ********************
% path-type settings
instr = instruments{i};
% freqBand = '-HF-125kHz';
freqBand = '-MF-10kHz';
% freqBand = '-LF-1kHz';
path_data = ['G:\score\2015\data\' instr freqBand '\'];
path_out = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\' ...
    'noise\calibratedNoiseLevels\ltsa\'];
soundFiles = dir([path_data '*.wav']);
% soundFiles = soundFiles(1000:1100); % to test work with fewer files
sysSensFile = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise' ...
    '\calibratedNoiseLevels\sysSensitivities\' instr '_SCORE_sysSens.mat'];

% LTSA settings
ltsaParams = struct;
ltsaParams.tAvg = 10;   % in sec (MUST BE <= FILE LENGTH)
ltsaParams.fBinSize = 1;   % in Hz
ltsaParams.overlap = 0; % in percent
ltsaParams.str = [num2str(ltsaParams.tAvg) 'sec_' num2str(ltsaParams.fBinSize) 'Hz'];

outFileName = [instr freqBand '_ltsa_' ltsaParams.str];

% ************** END DEFINED *****************

%% checking steps -
% get sample rates for all files, make sure none are
% corrupt etc. 
% adds info to ltsaParams

if exist([path_out instr freqBand '_ltsa_' ltsaParams.str '_params.mat'],'file')
    load([path_out instr freqBand '_ltsa_' ltsaParams.str '_params.mat']);
    fprintf(1,'loaded calculated and checked ltsaParams for %i files\n',ltsaParams.fCount)
else
    ltsaParams = gliderLTSA_checkFiles(ltsaParams,soundFiles);
    save([path_out instr freqBand '_ltsa_' ltsaParams.str '_params.mat'],'ltsaParams');   
end

%% calculate LTSA

% [ltsa, ltsaP, fc, tc, tcP, ltsaParams] = gliderLTSA_calcLTSA(ltsaParams,soundFiles,sysSensFile);
[ltsa, ltsaP, ltsaParams] = gliderLTSA_calcLTSA(ltsaParams,soundFiles);

save([path_out outFileName '_uncalibrated.mat'],'ltsa','ltsaP','ltsaParams');

[ltsa, ltsaP] = gliderLTSA_calibrateLTSA(ltsa, ltsaP, ltsaParams, sysSensFile);

% save([path_out outFileName '_unCalibrated.mat'],'ltsa','ltsaP','ltsaParams');
save([path_out outFileName '_Calibrated.mat'],'ltsa','ltsaP','ltsaParams');

%% plot
% this plots them as hours - does not account for acoustic data gaps at
% surfacings, etc

figure(26);
a1 = imagesc(ltsaParams.timeSec/3600,ltsaParams.fBins,ltsa);
set(gca,'YDir','normal');
ylabel('Frequency [Hz]')
xlabel('time [hr]');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis([60 140]); % may need to adjust this depending on downsampled data
print([path_out outFileName '.png'],'-dpng');

% if I want to plot those gaps, I have to pad the ltsa. 
figure(27);
a2 = imagesc(ltsaParams.pTimeSec/3600,ltsaParams.fBins,ltsaP,'AlphaData',~isnan(ltsaP));
set(gca,'YDir','normal','color',[.2 .2 .2]);
ylabel('Frequency [Hz]')
xlabel('time [hr]');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis([50 140]); % may need to adjust this depending on downsampled data
print([path_out outFileName '_padded.png'],'-dpng');

% cla reset

end