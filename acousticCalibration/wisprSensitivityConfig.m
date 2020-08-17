function [hydSens,hydFilt,paGain,antiAli,gain,frqSys,vref,bits] = wisprSensitivityConfig(instrDeplStr)
%
%
% creates a system sensitivity matrix for each instrument, accounting
% hydrophone sensitivity, pre-amp gain, hydrophone filter, anti-aliasing
% filter, and any additional gain.
% Input instrument name and deployment as following examples:
%		q001_SCORE
%		sg607_CatBasin
% 		sg639_GoMex
%		q002_QUTR
%
% updated 2019 02 11 S. Fregosi

%% ***** INDIVIDUAL INSTRUMENTS AND DEPLOYMENTS ******

%  -------------- SCORE 2015 --------------
% Q001 @ SCORE 2015
if strcmp(instrDeplStr,'q001_SCORE')
    hydSens = -174.0; % HTI92 # 638008
    hydHP = 50;% Hz
    preAmp = 'EOS_HM1_1504';
    paGain = [-2.5 6.7 13.4 15.4 16.1 16.4 16.6 17.1 19.7 23.7 ...
        28.5 35.7 40.5 43.8 44.7 45.1 45.1 45.0 44.8 44.6 ...
        44.3 44.0 43.6 43.3]; % From gain curve file/same as plot_wispr_flacQUE as of 4/5/16 - CORRECT
    frqType = '24'; % skips 62.5 and 64.5 bc EOS system
    gainSet = 2; % this is + 6 dB for this deployment (switched pins)
    gain = 6;
    
    %Q002 @ SCORE 2015
elseif strcmp(instrDeplStr,'q002_SCORE')
    hydSens = -175; % HTI92 #635012
    hydHP = 50; % Hz
    preAmp = 'WBPA_Rev4A_002';
    paGain= [-4.4 -4.0 12.1 16.3 18.6 19.5 19.8 20.4 22.8 26.4 ...
        31.4 38.8 43.6 47.3 48.5 49.0 49.1 49.2 49.2 49.2 ...
        49.1 48.8 48.5 48.6 48.0 47.6]; % from gain curve; matches plot_wispr_flacQUE as of 4/5/16 - CORRECT
    frqType = '26';
    gainSet = 2; % this is 6 dB for this deployment (switched pins)
    gain = 6;
    
    % SG158 @ SCORE 2015
elseif strcmp(instrDeplStr,'sg158_SCORE')   
    hydSens = -175; % From email from Haru 10/25/2016
    hydHP = 50;% Hz
    preAmp = 'HM1';
    paGain= [-2.3 1.6 7.6 11.5 13.6 14.6 14.8 15.3 17.7 21.4 ...
        26.4 33.4 38.3 41.6 42.5 42.8 42.8 42.7 42.5 42.3 ...
        41.9 41.6 41.2 40.8]; % from gain curve
    frqType = '24'; % skips 62.5 and 64.5 bc EOS system
    gainSet = [1 2]; % CHANGED DURING DEPLOYMENT. 
    gain = [12 6]; % thought it was 6. trying with 0 to get a baseline.
    % **** GAIN CHANGED PARTWAY THROUGH DEPLOYMENT
    % initial gain setting 1 (+12 dB bc switched pins)
    % gain changed to 2 (+6 dB) following dive 26/before dive 27
    % Dive 26 last file 151226-150040.wav
    % Dive 27 last file 151227-160230.wav
    fprintf(1,['NOTE: Gain changed during deployment: ' ...
        'gain variable has 2 values\n']);
    
    %  -------------- Catalina 2016 --------------
    % Q003 @ Catalina 2016
elseif strcmp(instrDeplStr,'q003_CatBasin')
    hydSens = -174.7; % HTI92 635001
    hydHP = 50; % Hz
    preAmp = 'WBPA_Rev4A_001';
    paGain= [-16.1 -7.2 1.9 7.5 12.8 17.7 19.3 20.1 22.5 26.5 ...
        31.4 38.8 43.9 47.8 49.1 49.7 49.8 49.8 49.7 49.7 ...
        49.6 49.4 49.1 48.8 48.4 48.1]; % from Haru's noise code % IS THIS ONE RIGHT????????????
    % or should it be same as SG158 @ SCORE
    frqType = '26';
    gainSet = 1; 
    gain = 12;
    % this is + 12 dB for this deployment??; 1 is from from deployment log.
    % if 1 = 6 dB...noise levels do not match glider...are ~ 6dB too high
    
    % SG607 @ Catalina 2016
elseif strcmp(instrDeplStr,'sg607_CatBasin')
    hydSens = -162.5; % HTI92 653007
    hydHP = 50;
    preAmp = 'EOS_HM1_003.3';
    paGain = [-6.0 0.0 6.8 10.7 12.9 13.9 14.3 14.8 17.5 21.5 ...
        26.7 33.8 38.7 41.9 42.8 43.2 43.2 43.1 42.8 42.6 ...
        42.2 41.9 41.5 41.1]; % from gain curve
    frqType = '24'; % skips 62.5 and 64.5 bc EOS system
    gainSet = 0; % Haru thinks this is 1?
    gain = 0;
    % unsure about this gain - outputs say 0 but Haru thought was 1? 
    % looking at noise levels in same hour, SG levels are ~ 6dB less than Q
    % so yes gain is 6 dB???

    
    % -------------- GoMex 2017 --------------
    % SG607 @ GoMex 2017
elseif strcmp(instrDeplStr,'sg607_GoMex')
    hydSens = -162.5; % HTI92 653007
    hydHP = 50;
    preAmp = 'EOS_HM1_003.3';
    paGain = [-6.0 0.0 6.8 10.7 12.9 13.9 14.3 14.8 17.5 21.5 ...
        26.7 33.8 38.7 41.9 42.8 43.2 43.2 43.1 42.8 42.6 ...
        42.2 41.9 41.5 41.1]; % from gain curve
    frqType = '24'; % skips 62.5 and 64.5 bc EOS system
    gainSet = 1; % from PA files
    gain = 6; % THIS IS A GUESS!!!!
    
    
    % -------------- GoMex 2018 --------------
    % SG639 @ GoMex 2018
elseif strcmp(instrDeplStr,'sg639_GoMex')
    hydSens = -164.5; % HTI92 # 653013 physical label on phone
    hydHP = 50; % from Haru email 1/28/2019
    preAmp = 'EOS_HM1_1507';
    paGain = [-2.9 6.8 13.6 15.7 16.3 16.6 16.8 17.3 19.9 23.9 ...
        29.1 36.3 41.2 44.5 45.6 45.5 45.2 44.9 44.6 44.3 ...
        44 43.5]; % From gain curve file
    frqType = '22'; % skips 30, 40, 62.5 and 64.5 bc EOS system
    gainSet = 0; 
    gain = 0;
    % pa files following dive 8 say gain was set to 2. THIS IS INCORRECT
    % there is no difference in noise levels from dive 7 to 8 so gain DID
    % not change 
    % gain changed to 2 (+12 dB) following dive 7/before dive 8
    % Dive 7 last file wispr_180511_042746.flac
    % Dive 8 first file wispr_180511_044616.flac
    
    
    % -------------- QUTR 2015 ---------------------
    % SG607 @ QUTR 2015 - for references from OLD plot_wispr_flacSG code of Haru's
elseif strcmp(instrDeplStr,'sg607_QUTR')
    hydSens = -164.8; % HTI92 # ?? % email 7/8/2015 to Holger
    hydHP = 25; % from HARU's code. % email 7/8/2015 to Holger
    preAmp = 'WBPA'; % is this right????????????????
    paGain = [-10.0 -2.1 5.9 10.1 12.4 13.4 13.8 14.2 16.7 20.4 ...
        25.5 32.8 38.0 41.9 42.5 43.2 43.7 43.7 43.6 43.5 ...
        43.3 43.2 42.8 42.5 42.0 41.7]; % From gain curve file - this differs from email from alex 7/8/2015 it says it should be EOS_HM1_003.3
    frqType = '26';
    gain = []; % pins not switched here so 1 = 6; BUT NEED TO CHECK DEPLOYMENT SHEETS
    
    % Q002 @ QUTR 2015
elseif strcmp(instrDeplStr,'q002_QUTR')
    hydSens = -173.7; 			% email 7/8/2015 to Holger
    hydHP = 50; 				% email 7/8/2015 to Holger
    preAmp = 'WBPA_Rev4A_002'; 	% from gain curve in email from Alex 7/8/2018
    paGain = [-17.6 -9.1 -0.6 5.3 10.8 16.3 18.8 20 22.6 26.4 ...
        31.7 39.0 44.1 48.0 49.8 49.7 49.5 49.3 48.9 48.6 ...
        48.2 47.8]; %
    frqType = '22';
    gain = 12; % from Haru' email 7/13/2015 and Alex's email 7/8/2015; SWITCHED to +18dB April 16 1700 UTC
     
else
    fprintf(1,'No valid instrument entered\n');
    return
end

%% Create adjustment matrices
% Frequency matrix and anti aliasing filter- changes depending on pre-amp style.
if strcmp(frqType,'26')
    frqSys = [1 2 5 10 20 50 100 200 500 1000 ...
        2000 5000 10000 20000 30000 40000 50000 60000 62500 64500 ...
        70000 80000 90000 100000 110000 120000];
    antiAli= [zeros(1,length(frqSys)-9) ...
        -5 -15 -40 -108 -108 -108 -108 -110 -112];
elseif strcmp(frqType,'24')
    frqSys = [1 2 5 10 20 50 100 200 500 1000 ...
        2000 5000 10000 20000 30000 40000 50000 60000 70000 80000 ...
        90000 100000 110000 120000];
    antiAli= [zeros(1,length(frqSys)-7) ...
        -5 -108 -108 -108 -108 -110 -112]; % this ditches the values at 62.5 and 64.5 kHz
elseif strcmp(frqType,'22')
    frqSys = [1 2 5 10 20 50 100 200 500 1000 ...
        2000 5000 10000 20000 50000 60000 70000 80000 90000 100000 ...
        110000 120000];
    antiAli= [zeros(1,length(frqSys)-7) ...
        -5 -108 -108 -108 -108 -110 -112]; % this ditches the values at 62.5 and 64.5 kHz
else
    fprintf(1,'No valid frequency matrix or anti-aliasing filter\n');
    return
end

% Hydrophone High-pass filter matrix
if hydHP == 25
    % HTI92 hydrophone with a one-pole high pass at 25 Hz
    hydFilt = [-28 -22 -14 -8.6 -4 -1 -0.3 -0.06 ...
        zeros(1,length(frqSys)-8)];
elseif hydHP == 50
    % HTI92 hydrophone with a one-pole high pass at 50 Hz
    hydFilt =  [-34 -28 -20 -14 -8.6 -3 -1 -0.3 ...
        zeros(1,length(frqSys)-8)];
else
    fprintf(1,'No valid hydrophone high pass filter setting\n');
    return
end

% this is the same for all instrumentuments
vref = 5.0;
bits = 16; % should this be 8????


end
