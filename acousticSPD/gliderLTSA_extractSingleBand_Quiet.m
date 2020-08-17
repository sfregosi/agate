function [minMat, minLev, b] = gliderLTSA_extractSingleBand_Quiet(instr,ltsaStr,path_ltsa,band)

load([path_ltsa instr ltsaStr '_calibrated.mat'])

% work with padded LTSA...every minute
% build empty min by min matrix
pTimeDT = datetime(ltsaParams.pTimeDN,'convertfrom','datenum');
startMin = dateshift(pTimeDT(1),'start','minute');
stopMin = dateshift(pTimeDT(end),'start','minute');

minMat = startMin:minutes(1):stopMin;
minMat = minMat';

minLev = nan(length(minMat),1);

for bNum = 1:length(band)
    bIdx = ltsaParams.fBins == band(bNum); % in Hz
    b(1,:) = ltsaP(bIdx,:);
        
    for t = 1:length(minMat)
        activeSlices = isbetween(pTimeDT,minMat(t),minMat(t) + minutes(1));
        minLev(t,1) = min(b(1,activeSlices));
    end
    
    save([path_ltsa instr ltsaStr '_calibrated_' num2str(band(bNum)) 'HzOnly_Quiet.mat'], ...
        'ltsaParams','b','minMat','minLev')
end
end
