function [b] = gliderLTSA_extractSingleBand(instr,ltsaStr,path_ltsa,band)

load([path_ltsa instr ltsaStr '_calibrated.mat'])

for bNum = 1:length(band)
    bIdx = ltsaParams.fBins == band(bNum); % in Hz
    b(1,:) = ltsaP(bIdx,:);
    
    save([path_ltsa instr ltsaStr '_calibrated_' num2str(band(bNum)) 'HzOnly.mat'], ...
        'ltsaParams','b')
end

end
