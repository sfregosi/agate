% SCORE sensitivities

savePath = ['C:\Users\selene\OneDrive\projects\AFFOGATO\finComparison\noise' ...
    '\calibratedNoiseLevels\sysSensitivities\'];

instruments = {'sg158','q001','q002'};

for i = 1:3
instrDeplStr = [instruments{i} '_SCORE'];

frqSysSens = sysSens_wispr(instrDeplStr,savePath);
end