% plot LTSAs with gaps all on one plot

% deployment period
load(['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\' ...
'detectionCounts\overlap_final_20180221.mat'])
xlims = [datenum(overlap.start(1)) datenum(overlap.stop(3))];
ylims = [0 5000];
path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
    'calibratedNoiseLevels\ltsa\'];
ltsaStr = '-MF-10kHz_ltsa_80sec_10Hz_Calibrated.mat';

figure; 
% ----------------------------------------------------------------------
instr = 'sg158';
load([path_ltsa instr ltsaStr])

ax(1) = subplot(311);
imagesc(ltsaParams.pTimeDN,ltsaParams.fBins,ltsaP,'AlphaData',~isnan(ltsaP))
set(gca,'YDir','normal','color',[.2 .2 .2], ...
    'XTick',[round(ltsaParams.pTimeDN(1)):(3600*24/86400):round(ltsaParams.pTimeDN(end))]);
ylabel('Frequency [Hz]')
% xlabel('date');
datetick('x','mm/dd','keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis([40 180]); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);

% --------------------------------------------------------------------
instr = 'q001';
load([path_ltsa instr ltsaStr])

ax(2) = subplot(312);
imagesc(ltsaParams.pTimeDN,ltsaParams.fBins,ltsaP,'AlphaData',~isnan(ltsaP))
set(gca,'YDir','normal','color',[.2 .2 .2], ...
    'XTick',[round(ltsaParams.pTimeDN(1)):(3600*24/86400):round(ltsaParams.pTimeDN(end))]);
ylabel('Frequency [Hz]')
% xlabel('date');
datetick('x','mm/dd','keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis([40 180]); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);

% --------------------------------------------------------------------
instr = 'q002';
load([path_ltsa instr ltsaStr])

ax(3) = subplot(313);
imagesc(ltsaParams.pTimeDN,ltsaParams.fBins,ltsaP,'AlphaData',~isnan(ltsaP))
set(gca,'YDir','normal','color',[.2 .2 .2], ...
    'XTick',[round(ltsaParams.pTimeDN(1)):(3600*24/86400):round(ltsaParams.pTimeDN(end))]);
ylabel('Frequency [Hz]')
xlabel('date');
datetick('x','mm/dd','keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis([40 180]); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);


linkaxes(ax);


