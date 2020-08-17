% workflow for getting noise percentile levels
%
% Create SPDs
spdOn = 1;
% plot percentiles
% make table of percentiles at two bands.
percOn = 1;

% ------------- ANALYSIS SETTINGS -------------------------------
% % band levels to extract
flowBand = 40; % Hz adjacent to fin calls
windBand = 300; % Hz % chose based on Cauchy et al 2018 glider wind noise
% instruments = {'sg158','q001','q002'};
instruments = {'sg607','q003'};

% ------------- PATH SETTINGS ------------------------------------
% freqBand = '-HF-125kHz';
% freqBand = '-MF-10kHz';
freqBand = '-LF-1kHz';
ltsaStr = [freqBand '_ltsa_60sec_1Hz']; % use this bandwidth

% path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
%     'calibratedNoiseLevels\ltsa\'];
path_ltsa = ['C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\' ...
    'noise\ltsa\'];
% path_SPD = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise\' ...
%     'calibratedNoiseLevels\SPD\'];
path_SPD = ['C:\Users\selene\OneDrive\projects\AFFOGATO\CatalinaComparison\' ...
    'noise\SPD\'];

%% CALCULATE and PLOT SPD
if spdOn == 1
    
    ltsaStr = [freqBand '_ltsa_60sec_1Hz']; % use this bandwidth
    
    figure
    set(gcf,'Units','inches','Position',[2 1 8 (length(instruments)*3+1)])
    yLims = [25 150];
    
    for i = 1:length(instruments)
        instr = instruments{i};
        load([path_ltsa instr ltsaStr '_calibrated.mat'])
        
        % modify my ltsa to read in the SPD code
        s = ltsa; % rows are freq, cols are time
        s = [ltsaParams.timeSec'; s]; % now its 502 rows;
        s = [zeros(size(s,1),1) s];
        s(2:end,1) = ltsaParams.fBins + 0.5; % add 0.5 to get to mid point of 1 Hz bands
        
        % calculate
        [leq, perc, d, freq, X, Y] = SPD_function(s);
        
        ax(i) = subplot(length(instruments),1,i);
        g = pcolor(X,Y,d);                      %SPD
        set(g,'LineStyle','none')
        bottPosit = 1 - (i*(0.9/(length(instruments)))) + 0.05; % top 90/# instr + 5% (for labels)
        heightPosit = 0.9/(length(instruments))-0.1;
        set(gca,'Position',[0.1 bottPosit 0.80 heightPosit]);
        hold on
        
        semilogx(freq,perc(:,99),'k','linewidth',2)   %percentiles
        semilogx(freq,perc(:,95),'k','linewidth',2)
        semilogx(freq,perc(:,50),'k','linewidth',2)
        semilogx(freq,perc(:,5),'k','linewidth',2)
        semilogx(freq,perc(:,1),'k','linewidth',2)
        
        semilogx(freq,leq,'m','linewidth',2)       %RMS (linear) mean
        
        caxis([0 0.06])
        title(['Spectral Probability Density - ' instr])
        ylabel('PSD [dB re 1 \muPa^2 Hz^-^1]')
        set(gca,'XScale','log','TickDir','out','layer','top')
        ylabel(colorbar,'Empirical Probability Density')
        ylim(yLims)
        xlim([10 max(freq)])
        grid on
        if i == length(instruments)
            xlabel('Frequency [Hz]')
        
        linkaxes(ax,'x');
        hl = legend('SPD','99%','95%','50%','5%','1%','RMS Mean',...
            'Location','southoutside','orientation','horizontal');
        set(hl,'Units','normalized','Position',...
            [ax(length(instruments)).Position(1) ...
            (ax(length(instruments)).Position(2) - 0.125) ...
            ax(length(instruments)).Position(3) 0.04])
        end
    end
end


%% Extract summary percentile levels
if percOn == 1
    ltsaStr = [freqBand '_ltsa_60sec_1Hz']; % use this bandwidth
%     instrColor = [.8 0 0; 1 1 0;  1 0.6 0];
    instrColor = [.8 0 0; 1 0.6 0];
    
    summ = table;
    figure;
    hold on;
    
    for i = 1:length(instruments)
        instr = instruments{i};
        load([path_ltsa instr ltsaStr '_calibrated.mat'])
        
        flowIdx = find(ltsaParams.fBins == flowBand);
        windIdx = find(ltsaParams.fBins == windBand);
        
        % extract some data by instrument
        summ.instr{i,1} = instr;
        summ.flowH(i,1) = prctile(ltsa(flowIdx,:),5); % remember this is inverted!
        summ.flowL(i,1) = prctile(ltsa(flowIdx,:),95);
        summ.flowM(i,1) = prctile(ltsa(flowIdx,:),50);
        summ.windH(i,1) = prctile(ltsa(windIdx,:),5);
        summ.windL(i,1) = prctile(ltsa(windIdx,:),95);
        summ.windM(i,1) = prctile(ltsa(windIdx,:),50);
        
        % plot simple percentile plot
        semilogx(ltsaParams.fBins,prctile(ltsa,5,2),'--','linewidth',1,'Color',instrColor(i,:))   %percentiles
        semilogx(ltsaParams.fBins,prctile(ltsa,95,2),'--','linewidth',1,'Color',instrColor(i,:))   %percentiles
        semilogx(ltsaParams.fBins,prctile(ltsa,50,2),'linewidth',2,'Color',instrColor(i,:))   %percentiles
    end
    grid on;
    set(gca,'xscale','log')
    xlim([10 max(ltsaParams.fBins)]);
    xlabel('frequency [Hz]')
    ylabel('dB re 1 \muPa^{2}/Hz')
end


