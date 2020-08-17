% plot LTSAs with gaps all on one plot
% with dive profiles overlayed on top of spectrogram
% One day only

% ------- PLOT SETTINGS -------------------------------------
path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
    'calibratedNoiseLevels\ltsa\'];
ltsaStr = '-LF-1kHz_ltsa_10sec_1Hz_Calibrated.mat';

xLims = [datenum(2015,12,26,16,0,0) datenum(2015,12,27,16,0,0)];
xTicks = [xLims(1):3600*4/86400:xLims(2)];
xTickFmt = 'HH:MM';

yLimsFrq = [0 100];
yTicksFrq = [0:10:100];
yLimsDep = [-4000 100];

cLims = [80 140];

instruments = {'sg158','q001','q002'};
% --------------------------------------------------------------

figure;
set(gcf,'Units','inches','Position',[2 4 8 7])
% ----------------------------------------------------------------------
for i = 1:3
    instr = instruments{i};
    load([path_ltsa instr ltsaStr])
    load(['G:\score\2015\profiles\' instr '_SCORE_Dec15\' instr '_SCORE_Dec15_locCalcT_pam.mat']);
    
    subplot(3,1,i);
    bottPosit = 1-(i*.28);
    set(gca,'Position',[0.08 bottPosit 0.80 0.22]);
    hold on;
    xImage = [ltsaParams.pTimeDN(1) ltsaParams.pTimeDN(end)];
    yImage = [ltsaParams.fBins(1) ltsaParams.fBins(end)];
    [ax(3*i-2:3*i-1),h11,h12] = plotyy(xImage,yImage,locCalcT.time,-locCalcT.depth);
    
    ax(3*i) = imagesc(xImage,yImage,ltsaP,'AlphaData',~isnan(ltsaP));
    caxis(cLims); % may need to adjust this depending on downsampled data
    
    set(h12,'color','w','LineWidth',1.2)
    set(h11,'color',[.2 .2 .2]);
    set(ax(3*i-2:3*i-1),{'ycolor'},{'k';'k'});
    set(ax(3*i-2),'ydir','Normal','color',[.2 .2 .2],'ylim',yLimsFrq,'ytick',yTicksFrq, ...
        'xlim',xLims,'XTick',xTicks);
    ylabel(ax(3*i-2),'Frequency [Hz]','FontSize',12)
    set(ax(3*i-1),'ylim',yLimsDep,'xlim',xLims,'ytick',[-1200:400:0]);
    ylabel(ax(3*i-1),'depth (m)','FontSize',12,'Position',[xLims(end)+0.06 -800 -1])
    datetick('x',xTickFmt,'keeplimits','keepticks');
    title(instr,'FontSize',12);
    if i == 3
        xlabel('time [UTC]','FontSize',12);
        h1cb = colorbar('horiz',...
            'Position',[ax(3*i-2).Position(1), ... % left
            ax(3*i-2).Position(2)- 0.09, ... % bottom
            ax(3*i-2).Position(3), ... % width
            .02]); % height
        h1cb.Label.String = 'dB re 1 \muPa^{2}/Hz';
        h1cb.Label.FontSize = 12;
    end
end

linkaxes(ax,'x')
% linkaxes(ax(1)); % this doesn't work with the diff scales of depth and
% spectrogram



