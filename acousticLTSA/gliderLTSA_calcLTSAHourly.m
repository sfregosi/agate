function [ltsa, ltsaP, ltsaParams] = ...
    gliderLTSA_calcLTSAHourly(ltsaParams,soundFiles,sysSensFile,path_out)
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

if nargin < 4
    fprintf(1,'This LTSA is uncalibrated\n');
else
    sysSens     = load(sysSensFile);
    frqSysSens  = sysSens.frqSysSens;
end

tic
% how many hours to calculate for?
ltsaParams.deplDurHrs = (ltsaParams.fStartTimes(end) - ltsaParams.fStartTimes(1))*24;
hr1 = datevec(ltsaParams.fStartTimes(1));
fprintf(1,'Calculating %i 1-hour spectra for %i files. tAvg: %i sec, fBinSize: %i Hz.\n', ...
    ceil(ltsaParams.deplDurHrs), ltsaParams.fCount, ltsaParams.tAvg, ltsaParams.fBin)

vref = 5;
hrCount = 1;
% loop through ALL HOURS
ltsaParams.hrNum = 7;% error threw after 5/13 hr 7 saved. 
ltsaParams.dayNum = datenum(2018,5,13); 
for hr = 1:ceil(ltsaParams.deplDurHrs)
    
    % define the hour number
    if hr == 1
        ltsaParams.hrNum = hr1(4);
        hrNum = hr1(4);
        ltsaParams.dayNum = floor(ltsaParams.fStartTimes(1));
    else
        %         disp('not hour 1');
        ltsaParams.hrNum = ltsaParams.hrNum + 1;
        ltsaParams.dayNum = ltsaParams.dayNum; % same as previous
        if ltsaParams.hrNum == 24 % next day
            ltsaParams.hrNum = 0;
            ltsaParams.dayNum = ltsaParams.dayNum + 1; % this will work across months
        elseif ltsaParams.hrNum > 24
            disp('hr error')
        end
    end
    
    ltsaParams.hrLims = [ltsaParams.dayNum + (ltsaParams.hrNum/24) ...
        ltsaParams.dayNum + (ltsaParams.hrNum + 1)/24 - 1/86400];
    % find what files I'm going to loop through
    if hr == 1
        fis = 1;
    else
        fis = find(ltsaParams.fStartTimes < ltsaParams.hrLims(1), 1, 'last');
        if ltsaParams.fStartTimes(fis) + ltsaParams.fDur(fis)/86400 < ltsaParams.hrLims(1)
            fis = fis + 1; % if gap till next hour. 
        end
    end
    fie = find(ltsaParams.fStartTimes < ltsaParams.hrLims(2), 1, 'last');
    ltsaParams.hrFiles = fis:fie; % which files are in this hour
    
    % create a non-padded ltsa - preallocate for speed but 0 extras
    s = 0;  % count slices (unpadded)
    ltsaParams.timeDN       = zeros(binSec,1);
    ltsaParams.timeSec      = zeros(binSec,1);
    ltsaParams.avgDur       = zeros(binSec,1);
    ltsaParams.shortFiles   = [];
    ltsa = zeros(ltsaParams.nFreq, binSec);
    
    % create a "padded" ltsa spanning entire deployment period
    % with NaN's for minutes acoustic system is off
    % adjust for time into hour that acoustic recordings start
    if hr == 1
        p = hr1(5)*60 + hr1(6); % Adjust for time into hour count padded averages
    elseif ltsaParams.fStartTimes(fis) < ltsaParams.hrLims(1) % file starts before hour
        p = 1;
    elseif ltsaParams.fStartTimes(fis) == ltsaParams.hrLims(1) % file starts on the hour
        p = 1;
    else % start into the hour already. 
        dv = datevec(ltsaParams.fStartTimes(fis));
        p = dv(5)*60 + dv(6);
    end
    ltsaParams.pTimeDN      = NaN(binSec,1);
    ltsaParams.pTimeSec     = [0:1:binSec-1]';
    ltsaP = NaN(ltsaParams.nFreq, binSec);
    
    % loop through this hour's files
    for f = ltsaParams.hrFiles
        if f == fie
            % if its the last file in this hour, may not include whole file
            % in ltsa. 
            fEnd = floor(((ltsaParams.fStartTimes(f) + ltsaParams.fDur(f)/86400) - ...
                ltsaParams.hrLims(2))*86400)/ltsaParams.tAvg;
            if fEnd > 0 % last file ends before end of hour and no new files
                aRange = 1:ltsaParams.fNumAvg(f) - fEnd;
            else
                aRange = 1:ltsaParams.fNumAvg(f);
            end
        else
            aRange = 1:ltsaParams.fNumAvg(f);
        end
        
        % calculate number of averages in this file (unrounded)
        nAvg1 = ltsaParams.fNumSamp(f)/(ltsaParams.tAvg*ltsaParams.fs);
        dAvg = ltsaParams.fNumAvg(f) - nAvg1; % remainder??
        
        % --------------------------------------------------------------------
        % loop through all time avg slices within that file (based on tAvg)
        for a = aRange
            
            s = s+1; %advance the slice location in the unpadded LTSA
            % --------------------------------------------------------------
            % get the number of samples for this average slice
            if dAvg == 0 % divides evenly into file size
                nSamp = ltsaParams.sampPerAvg;
            else
                if a == ltsaParams.fNumAvg(f)% its the last average so not full sampPerAvg
                    nSamp = ltsaParams.fNumSamp(f) - ((ltsaParams.fNumAvg(f) - 1)*ltsaParams.sampPerAvg);
                else
                    nSamp = ltsaParams.sampPerAvg; % in middle - sample rate
                end
            end
            ltsaParams.avgDur(s) = nSamp/ltsaParams.fs;
            % this is not padded
            
            % --------------------------------------------------------------
            % get current time datenum and add to time vectors
            currDN = ltsaParams.fStartTimes(f) + ltsaParams.tAvg*(a-1)/86400;
            ltsaParams.timeDN(s)    = currDN;
            ltsaParams.pTimeDN(p)   = currDN;
            
            ltsaParams.timeSec(s) = int16((currDN - ...
                (ltsaParams.dayNum + ltsaParams.hrNum/24))*86400);
            
            % ---------------------------------------------------------------
            % get samples indices to read and analyze
            if a == 1
                yi = 1;
            else
                yi = yi + nSamp;
            end
            
            % --------------------------------------------------------------
            % load in **PART OF** sound file
            % which is bigger, sample or end of file?
            endTmp = yi-1+nSamp;
            endTrue = ltsaParams.fNumSamp(f); % end of file
            if endTmp < endTrue % just read that bit
                try
                [data,~] = audioread([soundFiles(f).folder '\' ltsaParams.fNames{f,:}], ...
                    [yi yi-1+nSamp]);
                %         data = data*vref; %/(2^ltsaParams.nBits); % vref is now in
                %         the system sensitivity.
                catch
                    fprintf('%s file issue\n', ltsaParams.fNames{f,:});
                end
            elseif endTmp > endTrue % just read to end of file
                 [data,~] = audioread([soundFiles(f).folder '\' ltsaParams.fNames{f,:}], ...
                    [yi endTrue]);
                fprintf('end of %s\n', ltsaParams.fNames{f,:})                
            end
            
            % ------------------------------------------------------------
            % Check file length and pad if needed
            dsz = length(data);
            
            % if shorter than nfft, pad with zeros
            if dsz < ltsaParams.nfft
                dz = zeros(ltsaParams.nfft-dsz,1);
                data = [data;dz];
                fprintf(1,'\nFile #%i of %i DataSize: %i\n', f, ...
                    ltsaParams.fCount, dsz);
            end
            
            % --------------------------------------------------------------
            % calculate spectra @ 1 Hz resolution
            [slice,~] = pwelch(data,ltsaParams.window,ltsaParams.noverlap,ltsaParams.nfft,ltsaParams.fs);
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
            ltsa(:,s) = bandAvgdB;
            
            % --------------------------------------------------------------
            % place slice in padded ltsa
            ltsaP(:,p) = bandAvgdB;
            %
            %---------------------------------------------------------------
            % pad ltsaP if necessary
            
            % if its the last slice, but NOT the last file...and there is a
            % gap?
            if a == ltsaParams.fNumAvg(f) && f < length(ltsaParams.hrFiles)-1
                % what is the gap
                gap = round((ltsaParams.fStartTimes(f+1) - currDN)*86400 - ltsaParams.avgDur(s));
                % is it bigger than 1 sec?
                if gap > ltsaParams.tAvg
                    p = p + gap;
                    disp('gap!');
                    %                     ltsaParams.pTimeDN(p) = ;
                elseif gap < 0
                    p = p - 1;
                    disp('step back!')
                    % does not add a p so repeats that slice
                end
            end
            % end of all averages (1 sec) for that file
            p = p + 1;
        end % loop through all files, f, for this hour.
        
    end % 1 hour
    
    
    %     fprintf(1,'File %i: %s done.\n',f,ltsaParams.sfNames(f,:));
    
    % -----------------------------------------------------------------------
    % clean up the ltsa
    % remove any ending 0's in the padded LTSA to NaNs
    
    % remove any zeros in non-padded LTSA\
    ltsa(:,~all(ltsa)) = [];
    ltsaParams.timeSec = ltsaParams.timeSec(ltsaParams.timeSec ~= 0);
    ltsaParams.timeDN = ltsaParams.timeDN(ltsaParams.timeDN ~= 0);

    %
    % test plot
    figure(45);
    imagesc(ltsaParams.timeDN,ltsaParams.fBins,ltsaP)
    set(gca,'YDir','normal');
    
    ltsa = int16(ltsa*100);
    ltsaP = int16(ltsaP*100);
    
    saveDateStr = datestr(ltsaParams.dayNum, 'yyyymmdd');
    save([path_out 'sg639_' saveDateStr '_' num2str(ltsaParams.hrNum,'%02.f') ...
        '_' ltsaParams.str '.mat'], 'ltsa', 'ltsaP', 'ltsaParams');
    
    
    fprintf(1,'%s Hour %i Done\n', datestr(ltsaParams.dayNum, 'yyyy-mm-dd'), ...
        ltsaParams.hrNum);
    
    t = toc;
    
    
    
end % all hours done.
end

