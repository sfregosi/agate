function [spec, specP, ltsaParams] = ...
    gliderLTSA_calcSpecDive(ltsaParams,soundFiles,sysSensFile)
%
% create an LTSA from glider data
% this works in 1 hour bins so I can create 1 sec/1 hz noise data
%
% inspired by Triton's LTSA creation
% General steps: pre-allocate ltsa variable, loop through each file, read
% it in, run pwelch, and compile ltsa.
%
%   Notes:  time to average over must be LESS THAN or EQUAL to file length
%           run gliderLTSA_checkFiles first to build up ltsaParams (lp) var
%
%   Inputs:
%       ltsaParams -    ltsaParams - defined and calculated parameters
%                           MUST include: **** FILL THIS IN ******
%       soundFiles - 	directory list of sound files to analyze
%       sysSensFile -   if exists, then LTSA is calibrated
%       path_out  - where each 1 hr file is saved
%
%   Outputs:
%       ltsa -          unpadded ltsa variable. rows = freqs, cols = time
%       ltsaP -         padded ltsa variable. NaN's for time slices with system off
%       ltsaParams -    ltsa parameters updated with anything changed or created
%                       during the cacluation process
%
%
% last updated 2019 01 25 S. Fregosi
% updated 2019 10 23 S. Fregosi renamed fBinSize to fBin
% updated 2019 10 28 S. Fregosi made hourly

% 1 hour scale
binSec = 3600;

if nargin < 3
    fprintf(1,'This LTSA is uncalibrated\n');
else
    sysSens     = load(sysSensFile);
    frqSysSens  = sysSens.frqSysSens;
end


vref = 5;

% define time limits of this hour
ltsaParams.hrLims = [ltsaParams.dayNum + (ltsaParams.hrNum/24) ...
    ltsaParams.dayNum + (ltsaParams.hrNum + 1)/24 - 1/86400];

% find what files I'm going to loop through
% find last file before the hour start
fis = find(ltsaParams.fStartTimes < ltsaParams.hrLims(1), 1, 'last');
% but make sure its full duration is not before the hour (gap at hr start)
if ltsaParams.fStartTimes(fis) + ltsaParams.fDur(fis)/86400 < ltsaParams.hrLims(1)
    fis = fis + 1; % if gap till next hour.
end
% find last file before hour end
fie = find(ltsaParams.fStartTimes < ltsaParams.hrLims(2), 1, 'last');
ltsaParams.hrFiles = fis:fie; % which files are in this hour

% create a non-padded ltsa - preallocate for speed, xtra 0s removed later
s = 0;  % count slices (unpadded)
ltsaParams.timeDN       = zeros(binSec,1);
ltsaParams.timeSec      = zeros(binSec,1);
ltsaParams.avgDur       = zeros(binSec,1);
ltsaParams.shortFiles   = [];
spec = zeros(ltsaParams.nFreq, binSec);

% create a "padded" ltsa
% with NaN's for minutes acoustic system is off
% adjust for time into hour that acoustic recordings start
if ltsaParams.fStartTimes(fis) < ltsaParams.hrLims(1) % file starts before hour
    p = 0;
elseif ltsaParams.fStartTimes(fis) == ltsaParams.hrLims(1) % file starts on the hour
    p = 0;
else % file starts into the hour (gap in beginning
    dv = datevec(ltsaParams.fStartTimes(fis));
    p = dv(5)*60 + dv(6) - 1;
end
ltsaParams.pTimeDN      = [ltsaParams.hrLims(1):1/86400:ltsaParams.hrLims(2)];
ltsaParams.pTimeSec     = [0:1:binSec-1]';
specP = NaN(ltsaParams.nFreq, binSec);

% loop through this hour's files
for f = ltsaParams.hrFiles
    if f == fis % if first file, might not read in whole file
        fStart = floor((ltsaParams.hrLims(1) - ltsaParams.fStartTimes(f))*86400)/ltsaParams.tAvg;
        % this is how many avg into file to start reading
        aRange = fStart + 1:ltsaParams.fNumAvg(f);
    elseif f == fie
        % if its the last file in this hour, when does it end?
        fEnd = floor(((ltsaParams.fStartTimes(f) + ltsaParams.fDur(f)/86400) - ...
            ltsaParams.hrLims(2))*86400)/ltsaParams.tAvg;
        if fEnd > 0 % last file extends beyond end of hour
            aRange = 1:ltsaParams.fNumAvg(f) - fEnd;
        else % last file within hour (gap at end of hour)
            aRange = 1:ltsaParams.fNumAvg(f);
        end
    else
        aRange = 1:ltsaParams.fNumAvg(f); % whole file is in this hour
    end
    
    % calculate number of averages in this file (unrounded)
    nAvg1 = ltsaParams.fNumSamp(f)/(ltsaParams.tAvg*ltsaParams.fs);
    dAvg = ltsaParams.fNumAvg(f) - nAvg1; % remainder??
    
    % --------------------------------------------------------------------
    % loop through all time avg slices within that file (based on tAvg)
    for a = aRange
        
        s = s+1; %advance the slice location in the unpadded LTSA
        p = p + 1; % advanced in the padded LTSA

        % --------------------------------------------------------------
        % get current time datenum and add to time vectors
        currDN = ltsaParams.fStartTimes(f) + ltsaParams.tAvg*(a-1)/86400;
        ltsaParams.timeDN(s)    = currDN;
        ltsaParams.pTimeDN(p)   = currDN;
        
        ltsaParams.timeSec(s) = int16((currDN - ...
            (ltsaParams.dayNum + ltsaParams.hrNum/24))*86400);

        % --------------------------------------------------------------
        % get the number of samples for this average slice
        % and the starting sample number (yi)
        if dAvg == 0 % divides evenly into file size
            nSamp = ltsaParams.sampPerAvg;
        else
            if a == ltsaParams.fNumAvg(f)% its the last average so not full sampPerAvg
                % so resample the avgslice before (plus this partial).
                nSamp = ltsaParams.fNumSamp(f) - ...
                    ((ltsaParams.fNumAvg(f) - 2)*ltsaParams.sampPerAvg);
                ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
                yi = ltsaParams.fs*(a-2) + 1;
            else
                nSamp = ltsaParams.sampPerAvg; % in middle - sample rate
                ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
                yi = ltsaParams.fs*(a-1) + 1;
                % subtract one from a bc want to start after last slice
                % but add 1 to move into next slice.               
            end
        end
        %         ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
        % this is not padded
                
        % --------------------------------------------------------------
        % load in **PART OF** sound file
        % which is bigger, sample or end of file?
        endTmp = yi-1+nSamp;
        endFile = ltsaParams.fNumSamp(f); % end of file
        if endTmp < endFile % just read that bit
            try
                [data,~] = audioread([soundFiles(f).folder '\' ltsaParams.fNames{f,:}], ...
                    [yi endTmp]);
                %         data = data*vref; %/(2^ltsaParams.nBits); % vref is now in
                %         the system sensitivity.
            catch
                fprintf('%s file issue\n', ltsaParams.fNames{f,:});
            end
        elseif endTmp >= endFile % just read to end of file
            [data,~] = audioread([soundFiles(f).folder '\' ltsaParams.fNames{f,:}], ...
                [yi endFile]);
            %             fprintf('end of %s\n', ltsaParams.fNames{f,:})
        end
        
        % ------------------------------------------------------------
        % Check file length and pad if needed
%         data = data - mean(data); % DC offset
        dsz = length(data);
        
        % if shorter than nfft, pad with zeros
        if dsz < ltsaParams.nfft
            %             disp('short');
            %             win = hann(dsz);
            dz = zeros(ltsaParams.nfft-dsz,1);
            data = [data;dz];
            %             fprintf(1,'\nFile #%i of %i DataSize: %i\n', f, ...
            %                 ltsaParams.fCount, dsz);
            %         else
            %             win = ltsaParams.window;
        end
        
        % --------------------------------------------------------------
        data = data*vref;
        % calculate spectra @ 1 Hz resolution
        [slice,~] = pwelch(data,hann(ltsaParams.nfft),(ltsaParams.nfft)*0.75,ltsaParams.nfft,ltsaParams.fs);
        % slice has an extra row - ditch it.
        slice = slice(1:end-1);
        
        
        % --------------------------------------------------------------
        % average over fBin - this should be nothing in 1 hr bins
        if ltsaParams.fBin > 1
            bandAvg = zeros(ltsaParams.nFreq,1);
            for fB = 1:length(ltsaParams.fBins)-1
                bandSum = sum(slice(ltsaParams.fBins(fB)+1:ltsaParams.fBins(fB+1)));
                bandAvg(fB) = bandSum/ltsaParams.fBin;
            end
        else
            bandAvg = slice;
        end
        
        % --------------------------------------------------------------
        % if calibration available, adjust for system sensitivity
        if exist('frqSysSens','var')
            if size(frqSysSens,2) == 2
                sysSensI = interp1(frqSysSens(:,1),frqSysSens(:,2),ltsaParams.fBins,'pchip');
                bandAvgdB = 10*log10(bandAvg);
                bandAvgdB = bandAvgdB - sysSensI; % dB re 1 uPa^2/Hz
            end
        else
            % otherwise just convert to dB (will be neg values)
            bandAvgdB = 10*log10(bandAvg);
        end
        
        % --------------------------------------------------------------
        % place slice in plain ltsa (no gaps)
        spec(:,s) = bandAvgdB;
        
        % --------------------------------------------------------------
        % place slice in padded ltsa
        specP(:,p) = bandAvgdB;
        %
        %---------------------------------------------------------------
        % pad ltsaP if necessary
        
        % if its the last slice of this file, but not last file in hour
        if a == ltsaParams.fNumAvg(f) && f < ltsaParams.hrFiles(end)-1
            % what is the gap
            gap = (ltsaParams.fStartTimes(f+1) - currDN)*86400 - ltsaParams.avgDur(s);
            % is it bigger than 1 sec?
            if gap > ltsaParams.tAvg
                p = p + round(gap);
                fprintf(1,'gap! ');
                %                     ltsaParams.pTimeDN(p) = ;
            elseif gap < -1
                p = p - 1;
                fprintf(1,'step back! ');
                % does not add a p so repeats that slice
            end
        end
    end
end % % loop through all files, f, for this hour.



%     fprintf(1,'File %i: %s done.\n',f,ltsaParams.sfNames(f,:));

% -----------------------------------------------------------------------
% clean up the ltsa
% remove any ending 0's in the padded LTSA to NaNs

% remove any zeros in non-padded LTSA\
spec(:,~all(spec)) = [];
ltsaParams.timeDN = ltsaParams.timeDN(ltsaParams.timeDN ~= 0);
ltsaParams.timeSec = ltsaParams.timeSec(1:length(ltsaParams.timeDN));

spec = int16(spec*100);
specP = int16(specP*100);

% % check fig
% figure(40)
% imagesc(ltsaParams.timeDN,ltsaParams.fBins,single(ltsa)/100)
% set(gca,'YDir','normal');
% caxis([35 120]);

% figure(41)
% imagesc(ltsaParams.pTimeDN, ltsaParams.fBins, single(ltsaP)/100, 'AlphaData', (ltsaP ~= 0));
% set(gca,'YDir','normal');


end

