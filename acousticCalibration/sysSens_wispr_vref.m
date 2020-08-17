function frqSysSens = sysSens_wispr_vref(instrDeplStr,savePath)

% create system sensitivity variable for glider or quephone
% accounts for vref

if nargin < 2
    savePath = [];
end

[hydSens,hydFilt,paGain,antiAli,gain,frqSys,vref,bits] = wisprSensitivityConfig(instrDeplStr);

% ADgain = 20*log10(2^bits/vref);

% create system sensitivity vector

if length(gain) == 1
    sysSens = hydSens + paGain + hydFilt + antiAli + gain + 20*log10(1/vref);
    
    frqSysSens = [frqSys' sysSens'];
    figure;plot(frqSys,sysSens,'k','LineWidth',2); grid on
    title(sprintf('%s System Sensitivity  (vref)',instrDeplStr),'Interpreter','none');
    xlim([0 62500]);
    xlabel('frequency [hz]');
    ylabel('dB re 1V/\muPa');
    set(gca,'xscale','log','FontSize',12)
    
    % **** sg158 had adjustable gain changed during flight ****
    % this is specific to sg158 now but could be adapted in future (adapt gain change date)
elseif length(gain) > 1
    fprintf(1,['NOTE: Gain changed during deployment: ' ...
        'gain variable has 2 values\n']);
    if strcmp(instrDeplStr, 'sg158_SCORE')
    gainChangeDate = datenum(2015,12,26,16,02,29); % 1 second before the first file of Dive 27
    elseif strcmp(instrDeplStr, 'sg639_GoMex')
        gainChangeDate = datenum(2018,05,11,04,46,00); % rounded min before first file Dive 8
    end
    for g = 1:length(gain)
        sysSens(g,:) = hydSens + paGain + hydFilt + antiAli + gain(g) + 20*log10(1/vref);
    end
    frqSysSens = [frqSys' sysSens'];
    figure;plot(frqSys,sysSens); grid on
    title(sprintf('%s System Sensitivity (vref)',instrDeplStr),'Interpreter','none');
    xlim([0 62500]);
    xticks([1 10 100 1000 10000 62500])
    xlabel('frequency (hz)');
    ylabel('system sensitivity in dB re 1v/\muPa');
    set(gca,'xscale','log','FontSize',12)
    
end

% save it if path is specified
if ~isempty(savePath)
    save([savePath instrDeplStr '_sysSens_vref.mat'],'frqSysSens');
    if exist('gainChangeDate')
        save([savePath instrDeplStr '_sysSens_vref.mat'],'frqSysSens','gainChangeDate');
    end
    fprintf(1,'%s system sensitivity file created\n',instrDeplStr)
end

end

