function tf_wispr(instrDeplStr,savePath)

% create transfer functions for each glider and QUEphone at
% SCORE 2015 and
% Catalina 2016
% Input instrument name and deployment as following examples:
%		q001_SCORE
%		sg607_CatBasin
% 		sg639_GoMex
%		q002_QUTR

instrDeplStr = 'sg607_CatBasin';

% updated 2019 05 17 S. Fregosi


% ****** SETUP *******



% ********************

[hydSens,hydFilt,paGain,antiAli,gain,frqSys,vref,bits] = wisprSensitivityConfig(instrDeplStr);

ADgain = 20*log10(2^(bits)/vref);


%% create transfer function
tf = -1*(hydSens + paGain + hydFilt + antiAli + ADgain + gain);
frqtf = [frqSys' tf'];
figure;plot(frqSys,tf); grid on
save([savePath instrDeplStr '_inverse.tf'],'frqtf','-ascii')
save([savePath instrDeplStr '_inverse.mat'],'frqtf');