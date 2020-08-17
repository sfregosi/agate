% plot LTSAs with gaps all on one plot
% with dive profiles overlayed on top of spectrogram

% ------- PLOT SETTINGS -------------------------------------
path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
    'calibratedNoiseLevels\ltsa\'];
ltsaStr = '-LF-1kHz_ltsa_10sec_1Hz_Calibrated.mat';

load(['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\' ...
    'detectionCounts\overlap_final_20180221.mat'])
xlims = [datenum(overlap.start(1)) datenum(overlap.stop(3))];
xticks = [round(ltsaParams.pTimeDN(1)):(3600*24/86400):round(ltsaParams.pTimeDN(end))];

ylimsFrq = [0 100];
yticksFrq = [0:10:100];
ylimsDep = [-4000 100];

clims = [80 180];

instruments = {'sg158','q001','q002'};
% --------------------------------------------------------------

figure;
set(gcf,'Units','inches','Position',[10 6 16 10])
% ----------------------------------------------------------------------
for i = 1:3
    instr = instruments{i};
    load([path_ltsa instr ltsaStr])
    load(['G:\score\2015\profiles\' instr '_SCORE_Dec15\' instr '_SCORE_Dec15_locCalcT_pam.mat']);
    
    subplot(3,1,i);
    hold on;
    xImage = [ltsaParams.pTimeDN(1) ltsaParams.pTimeDN(end)];
    yImage = [ltsaParams.fBins(1) ltsaParams.fBins(end)];
    [ax(3*i-2:3*i-1),h11,h12] = plotyy(xImage,yImage,locCalcT.time,-locCalcT.depth);
    
    ax(3*i) = imagesc(xImage,yImage,ltsaP,'AlphaData',~isnan(ltsaP));
    caxis(clims); % may need to adjust this depending on downsampled data
    
    set(h12,'color','w','LineWidth',1.2)
    set(h11,'color',[.2 .2 .2]);
    set(ax(3*i-2:3*i-1),{'ycolor'},{'k';'k'});
    set(ax(3*i-2),'ydir','Normal','color',[.2 .2 .2],'ylim',ylimsFrq,'ytick',yticksFrq, ...
        'xlim',xlims,'XTick',xticks);
    ylabel(ax(3*i-2),'Frequency [Hz]')
    set(ax(3*i-1),'ylim',ylimsDep,'xlim',xlims,'ytick',[-1200:400:0]);
    ylabel(ax(3*i-1),'depth (m)')
    datetick('x','mmm dd','keeplimits','keepticks');
    title(instr);
    if i == 3
%         xlabel('date');
        h1cb = colorbar('horiz',...
            'Position',[ax(3*i-2).Position(1), ... % left
            ax(3*i-2).Position(2)- 0.07, ... % bottom
            ax(3*i-2).Position(3), ... % width
            .02]); % height
        h1cb.Label.String = 'dB re 1 \muPa^{2}/Hz';
    end
end

linkaxes(ax,'x')
% linkaxes(ax(1)); % this doesn't work with the diff scales of depth and
% spectrogram



