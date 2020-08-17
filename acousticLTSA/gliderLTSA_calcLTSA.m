function [ltsa, ltsaP, ltsaParams] = ...
    gliderLTSA_calcLTSA(ltsaParams,soundFiles,sysSensFile)
%
% create an LTSA from glider (or QUE) WISPR data
% possibly could be adapted for ANY wav files.
% But for now I'm working with glider files named in yymmdd-HHMMSS.wav data
%
% inspired by Triton's LTSA creation
% General steps: pre-allocate ltsa variable, loop through each file, read
% it in, run pwelch, and compile ltsa.
%
%   Notes:  time to average over must be LESS THAN or EQUAL to file length
%           *** BUILD IN CATCH FOR THIS IN THE FUTURE ***
%           run gliderLTSA_checkFiles first to build up ltsaParams (lp) var
%
%   Inputs:
%       ltsaParams -    ltsaParams - defined and calculated parameters
%                           MUST include: **** FILL THIS IN ******
%       soundFiles - 	directory list of sound files to analyze
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
% updated 2020 02 17 S. Fregosi fixed bugs - nw use vref syssens and
% speclev



if nargin < 3
    fprintf(1,'This LTSA is uncalibrated\n');
else
    sysSens     = load(sysSensFile);
    frqSysSens  = sysSens.frqSysSens;
end

tic
fprintf(1,'Calculating spectra for %i files. tAvg: %i sec, fBinSize: %i Hz.\n', ...
    ltsaParams.fCount, ltsaParams.tAvg, ltsaParams.fBin)

vref = 5;

% create a non-padded ltsa - preallocate for speed
s = 0;  % count slices (unpadded)
ltsaParams.timeDN       = zeros(sum(ltsaParams.fNumAvg),1);
ltsaParams.timeSec      = zeros(sum(ltsaParams.fNumAvg),1);
ltsaParams.avgDur       = zeros(sum(ltsaParams.fNumAvg),1);
ltsaParams.shortFiles   = [];
ltsa = nan(ltsaParams.nFreq,sum(ltsaParams.fNumAvg));

% create a "padded" ltsa spanning entire deployment period
% with NaN's for minutes acoustic system is off
p = 0; % count padded averages
ltsaParams.deplDur      = (ltsaParams.fStartTimes(end) - ltsaParams.fStartTimes(1))*24; % in hours
tBins = ceil((ltsaParams.deplDur*3600)/ltsaParams.tAvg);
ltsaParams.pTimeDN      = nan(tBins,1);
ltsaParams.pTimeSec     = nan(tBins,1);
ltsaP = NaN(ltsaParams.nFreq,tBins);

% loop through all files
for f = 1:ltsaParams.fCount
    fprintf(1, '.');
    if (rem(f,80) == 0), fprintf(1, '\n%3d ', floor((ltsaParams.fCount-f)/80)); end
    
    % calculate number of averages in this file (unrounded)
    nAvg1 = ltsaParams.fNumSamp(f)/(ltsaParams.tAvg*ltsaParams.fs);
    dAvg = ltsaParams.fNumAvg(f) - nAvg1;
    
    % --------------------------------------------------------------------
    % loop through all time avg slices within that file (based on tAvg)
    for a = 1:ltsaParams.fNumAvg(f)
        
        s = s+1; %advance the slice location in the unpadded LTSA
        p = p + 1; % advanced in the padded LTSA
        
        % --------------------------------------------------------------
        % get current time datenum and add to time vectors
        currDN = ltsaParams.fStartTimes(f) + ltsaParams.tAvg*(a-1)/86400;
        ltsaParams.timeDN(s)    = currDN;
        ltsaParams.pTimeDN(p)   = currDN;
        
        ltsaParams.timeSec(s) = int16(currDN - ...
            ltsaParams.fStartTimes(1));
        
        % --------------------------------------------------------------
        % get the number of samples for this average slice
        if dAvg == 0 % divides evenly into file size
            nSamp = ltsaParams.sampPerAvg;
        else
            if a == ltsaParams.fNumAvg(f)% its the last average so not full sampPerAvg
                nSamp = ltsaParams.fNumSamp(f) - ((ltsaParams.fNumAvg(f) - 1)*ltsaParams.sampPerAvg);
            else
                nSamp = ltsaParams.sampPerAvg;
            end % if last avg
        end % if file size
        ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
%         ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
        
        
        % ---------------------------------------------------------------
        % get samples indices to read and analyze
        if a == 1
            yi = 1;
        else
            yi = yi + nSamp;
        end
        
        % --------------------------------------------------------------
        % load in **PART OF** sound file
        [data,~] = audioread([soundFiles(f).folder '\' ltsaParams.fNames{f,:}], ...
            [yi yi-1+nSamp]); %,'native');
        
        % ------------------------------------------------------------
        % Check file length and pad if needed
        dsz = length(data);
        
        % if shorter than nfft, pad with zeros
        if dsz < ltsaParams.nfft
            dz = zeros(ltsaParams.nfft-dsz,1);
            data = [data;dz];
            fprintf(1,'\nFile# %i DataSize: %i\n',f,dsz);
        end
        
        % --------------------------------------------------------------
        % calculate spectra @ 1 Hz resolution
        %         [slice,~] = pwelch(data,ltsaParams.window,ltsaParams.noverlap,ltsaParams.nfft,ltsaParams.fs);
        [slice,~] = speclev(data,ltsaParams.nfft,ltsaParams.fs,ltsaParams.nfft);
        
        % --------------------------------------------------------------
        % average over fBin
        if ltsaParams.fBin > 1
            bandAvg = nan(ltsaParams.nFreq,1);
            numAvgs = floor(ltsaParams.fs/2/ltsaParams.fBin);
            for fB = 1:numAvgs
                bandSum = sum(slice(ltsaParams.fBins(fB): ...
                    ltsaParams.fBins(fB) + ltsaParams.fBin - 1));
                bandAvg(fB) = bandSum/ltsaParams.fBin;
            end
        else
            bandAvg = slice;
        end
        
        % --------------------------------------------------------------
        % if calibration available, adjust for system sensitivity
        if exist('frqSysSens','var')
            %             if size(frqSysSens,2) == 2
            sysSensI = interp1(frqSysSens(:,1),frqSysSens(:,2),ltsaParams.fBins,'pchip');
            %                 bandAvgdB = 10*log10(bandAvg);
            bandAvgdB = bandAvg;
            bandAvgdB = bandAvgdB - sysSensI; % dB re 1 uPa^2/Hz
            %             end
        else
            % otherwise just convert to dB (will be neg values)
            bandAvgdB = bandAvg;
        end
        
        % --------------------------------------------------------------
        % place slice in plain ltsa (no gaps)
        ltsa(:,s) = bandAvgdB;
        
        % --------------------------------------------------------------
        % place slice in padded ltsa
        ltsaP(:,p) = bandAvgdB;
        
        %---------------------------------------------------------------
        % pad ltsaP if necessary
        
        % if its the last nAvg of that file check if it needs to be padded
        if a == ltsaParams.fNumAvg(f) && f < ltsaParams.fCount-1
            gap = round((ltsaParams.fStartTimes(f+1) - currDN)*86400 - ltsaParams.avgDur(s));
            if gap > ltsaParams.tAvg
                pSkip = ceil(gap/ltsaParams.tAvg); % how many slices to skip
                % this rounding may make things a few secs off, but since the
                % recording system is inexact timing wise, I think that is ok
                % for this case.
                
                % pad the time vectors
                pSkipIdx = [p+1:p+pSkip];
                pSkipTimes = [ltsaParams.pTimeDN(p) + ltsaParams.avgDur(s)/86400: ...
                    ltsaParams.tAvg/86400 : ...
                    ltsaParams.pTimeDN(p) + ltsaParams.tAvg/86400*(pSkip)];
                ltsaParams.pTimeDN(pSkipIdx) = pSkipTimes;
                
                % and add NaN's to the ltsaP
%                 ltsaP(:,pSkipIdx) = NaN;
                p = p + pSkip;                
                fprintf(1,'gap! ');
            elseif gap < -1
                p = p - 1;
                fprintf(1,'step back! ');
            end
        end
    end% end of all averages, a, for single file, f
end % loop through all files,f

%     fprintf(1,'File %i: %s done.\n',f,ltsaParams.sfNames(f,:));

% -----------------------------------------------------------------------
% clean up the ltsa
% remove any ending 0's in the padded LTSA to NaNs

% remove any nans in non-padded LTSA\
% if exist('frqSysSens','var')
ltsa = ltsa(:,all(~isnan(ltsa)));
% end
ltsaParams.timeDN = ltsaParams.timeDN(ltsaParams.timeDN ~= 0);
ltsaParams.timeSec = (ltsaParams.timeDN - ltsaParams.timeDN(1))*86400;

t = toc;
fprintf(1,'Time to calculate %i spectra is %.0f seconds\n',f,t);

end

