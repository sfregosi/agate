% plot LTSAs with gaps all on one plot, only 1 day of time to show fin band
% better. 

% ------ plot settings -------
% ltsaStr = '-LF-1kHz_ltsa_10sec_1Hz.mat';
ltsaStr = '-MF-10kHz_ltsa_20sec_5Hz.mat';

ylims = [0 5000];
% deployment period
load(['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\' ...
'detectionCounts\overlap_final_20180221.mat'])
xlims = [datenum(overlap.start(1)) datenum(overlap.stop(3))];
% xlims = [datenum(2016,1,3,4,0,0) datenum(2016,1,3,16,0,0)];
tickSize = 1*3600/86400; % hours
tickFormat = 'HH:MM';
cLims = [40 180]; % may need to adjust this depending on downsampled data

path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
    'calibratedNoiseLevels\ltsa\'];
% ------------------------------

figure; 
% ----------------------------------------------------------------------
instr = 'sg158';
load([path_ltsa instr ltsaStr])
% time vectors as datenums
tcdn = ltsaParams.sfStartTimes;% in in datenum
tcdnP = ltsaParams.paddedTimes;
tcdnP(tcdnP == 0) = NaN;
ltsaPN = ltsaP;
ltsaPN(ltsaPN == 0) = NaN;

ax(1) = subplot(311);
% imagesc(tc/3600,fc,ltsa)
imagesc(tcdn',fc,ltsaPN,'AlphaData',~isnan(ltsaPN))
set(gca,'YDir','normal','color',[.2 .2 .2],'XTick',[round(tcdn(1)):tickSize:round(tcdn(end))]);
ylabel('Frequency [Hz]')
% xlabel('date');
datetick('x',tickFormat,'keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis(cLims); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);

% --------------------------------------------------------------------
instr = 'q001';
load([path_ltsa instr ltsaStr])
% time vectors as datenums
tcdn = ltsaParams.sfStartTimes;% in in datenum
tcdnP = ltsaParams.paddedTimes;
tcdnP(tcdnP == 0) = NaN;
ltsaPN = ltsaP;
ltsaPN(ltsaPN == 0) = NaN;

ax(2) = subplot(312);
% imagesc(tc/3600,fc,ltsa)
imagesc(tcdn',fc,ltsaPN,'AlphaData',~isnan(ltsaPN))
set(gca,'YDir','normal','color',[.2 .2 .2],'XTick',[round(tcdn(1)):tickSize:round(tcdn(end))]);
ylabel('Frequency [Hz]')
% xlabel('date');
datetick('x',tickFormat,'keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis(cLims); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);

% --------------------------------------------------------------------
instr = 'q002';
load([path_ltsa instr ltsaStr])
% time vectors as datenums
tcdn = ltsaParams.sfStartTimes;% in in datenum
tcdnP = ltsaParams.paddedTimes;
tcdnP(tcdnP == 0) = NaN;
ltsaPN = ltsaP;
ltsaPN(ltsaPN == 0) = NaN;

ax(3) = subplot(313);
% imagesc(tc/3600,fc,ltsa)
imagesc(tcdn',fc,ltsaPN,'AlphaData',~isnan(ltsaPN))
set(gca,'YDir','normal','color',[.2 .2 .2],'XTick',[round(tcdn(1)):tickSize:round(tcdn(end))]);
ylabel('Frequency [Hz]')
xlabel('hour');
datetick('x',tickFormat,'keeplimits','keepticks');
title(instr);
hcb = colorbar;
hcb.Label.String = 'dB re 1 \muPa^{2}/Hz';
caxis(cLims); % may need to adjust this depending on downsampled data
xlim(xlims)
ylim(ylims);


linkaxes(ax);


