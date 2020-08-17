function [ltsa, ltsaP] = gliderLTSA_calibrateLTSA(ltsa, ltsaP, ltsaParams, sysSensFile)
% adjust an uncalibrated LTSA for system sensitivity
%
% Originally pulled this out of gliderLTSA_calcLTSA code to see if it'd run
% faster without it, but it was negligable.
%
% IS useful for sg158 @ SCORE where gain was changed during deployment and
% it needs to be applied differentially
% So updated it accordingly.
%

% load in the system sensitivity file
sysSens = load(sysSensFile);
frqSysSens = sysSens.frqSysSens;
numSens = size(frqSysSens,2)-1; % how many curves?

if numSens == 1 % only 1 curve for entire deployment - simple
    % interpolate
    sysSensI = interp1(frqSysSens(:,1),frqSysSens(:,2),ltsaParams.fBins,'pchip');
    
    % repeat across gram size
    ltsaSens = repmat(sysSensI,1,size(ltsa,2));
    ltsaPSens = repmat(sysSensI,1,size(ltsaP,2));
    
    % apply to ltsa
    ltsa = ltsa- ltsaSens; % dB re 1 uPa^2/Hz
    ltsaP = ltsaP - ltsaPSens;
    
elseif numSens == 2 % only set up for 2 for now
    % multiple curves over deployment (gain changed)
    % get the gain date change
    gainChangeDate = sysSens.gainChangeDate;

% first half. 
    % find that date in the time vectors
    [r1,~] = find(ltsaParams.timeDN < gainChangeDate,1,'last'); % 8348
    [rP1,~] = find(ltsaParams.pTimeDN < gainChangeDate,1,'last'); % 9357

    % interpolate
    sysSensI1 = interp1(frqSysSens(:,1),frqSysSens(:,2),ltsaParams.fBins,'pchip');
    
    % repeat across first half of gram
    ltsaSens1 = repmat(sysSensI1,1,size(ltsa(:,1:r1),2));
    ltsaPSens1 = repmat(sysSensI1,1,size(ltsaP(:,1:rP1),2));
    
    % apply to ltsa 
    ltsa(:,1:r1) = ltsa(:,1:r1) - ltsaSens1; % dB re 1 uPa^2/Hz
    ltsaP(:,1:rP1) = ltsaP(:,1:rP1) - ltsaPSens1;
    
% second half
    % find that date in the time vectors
    [r2,~] = find(ltsaParams.timeDN > gainChangeDate,1,'first'); % 8349
    [rP2,~] = find(ltsaParams.pTimeDN > gainChangeDate,1,'first'); % 9358

    % interpolate
    sysSensI2 = interp1(frqSysSens(:,1),frqSysSens(:,3),ltsaParams.fBins,'pchip');
    
    % repeat across first half of gram
    ltsaSens2 = repmat(sysSensI2,1,size(ltsa(:,r2:end),2));
    ltsaPSens2 = repmat(sysSensI2,1,size(ltsaP(:,rP2:end),2));
    
    % apply to ltsa
    ltsa(:,r2:end) = ltsa(:,r2:end) - ltsaSens2; % dB re 1 uPa^2/Hz
    ltsaP(:,rP2:end) = ltsaP(:,rP2:end) - ltsaPSens2;
end
