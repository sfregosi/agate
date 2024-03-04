function B = convertSoundFile(infile, outfile, gain, outSRate, designer, ...
                                                            verbose, nomSRate)
%convertSoundFile   Change format, amplify, or change sample rate of a sound file
%
% convertSoundFile(infile, outfile)
%    Read a sound file 'infile' and write it as another sound file
%    'outfile'.  Typically this is done to convert from one sound file
%    format to another.  The file formats of both infile and outfile
%    are determined from their file extensions.  The file formats that
%    can be handled are described in soundIn.m and soundOut.m, and include
%    .wav, .aif, .au, and binary.  You can also specify the file format
%    of infile explicitly, rather than by file extension; see soundIn.
%
%    infile may be an array of file names, with one filename per row.
%    In this case, outfile should be an array too, with the same number
%    of rows.  The respective sound files are converted.
%
% B = convertSoundFile(infile, outfile, gain)
%    'gain' is an amplification factor that the sound samples are 
%    multiplied by when the sound is processed.  If gain is a vector, 
%    it specifies a different gain to apply to each channel of infile.  
%    gain defaults to 1.
%
% B = convertSoundFile(infile, outfile, gain, outSRate)
%    Change from sampling rate of infile to be outSRate, and write it
%    to outfile.  This requires MATLAB's signal processing toolbox.  
%
%    To do this resampling, a low-pass filter is first calculated using 
%    resample() (q.v.).  Then this filter is used to resample infile using
%    interpolation and decimation as necessary to obtain the desired the 
%    sampling rate, outSRate.  Filtering and resampling is done in small
%    chunks on successive passes.  So unlike resample(), arbitrarily long
%    files may be resampled.  The result is written to outfile.
%
%    Successive calls to this routine will re-use the existing filter,
%    provided the input and output sampling rates remain the same.  The
%    return value B has the coefficients of the FIR filter used.
%
%    outSRate defaults to 0, which is a special value meaning "use the
%    sampling rate of the input file."  In this case no filtering happens.
%
%    Note: When the filtering is done, it is possible for some of the
%    resulting samples to be larger in magnitude than the input samples.
%    So if your input sound is loud enough to nearly fill the available 
%    dynamic range (+/- 32767 for 16-bit samples), your output sound
%    might exceed the dynamic range and cause clipping.  In this case, 
%    you might try using a gain less than 1, like 0.5 or 0.1.
%
% B = convertSoundFile(infile, outfile, gain, outSRate, designer)
%    If 'designer' is non-zero, display the filter's frequency response
%    in a graphical user interface (GUI) so that you can see if it's
%    good enough.  You can then tweak the filter if you like, or just
%    click OK if the filter response is acceptable.  designer defaults 
%    to 0.
%
% B = convertSoundFile(infile, outfile, gain, outSRate, designer, verbose)
%    If 'verbose' is non-zero, print out the number of samples processed 
%    and the number left as the processing proceeds.  verbose defaults to 1,
%    so you will see these printouts unless you specifically ask not to.
%
% B = convertSoundFile(infile, outfile, gain, outSRate, designer, ...
%                                                    verbose, nominalOutSRate)
%    If 'nominalOutSRate' is present and non-zero, it specifies a value to
%    write into the header of the output soundfile as the sampling rate of
%    that file.  If nominalOutSRate is not present or is zero, the sampling
%    rate written into the header is simply outSRate.
%
%    nominalOutSRate is useful in two ways: (1) If the sampling rate
%    after resampling is not precisely the value you wanted, but is
%    pretty close, you can correct it to the desired value.  For instance,
%    if you up-sample a 4-kHz file to 44 kHz, you may want to make the
%    nominal sampling rate 44100 Hz so it plays out smoothly on a sound card.
%    (Many sound cards are built to play 44100-Hz sound smoothly, since this
%    is the sampling rate used for CD's.) (2) You can use nominalOutSRate to
%    play sounds sped up or slowed down.  For instance, if your sound is
%    sampled at 10 kHz, and you set the nominal sampling rate to 20 kHz,
%    it will play out sped up by a factor of 2 -- an octave higher in pitch.
%
%
% See also resample, filter, fir1, firls, upfirdn, interp, decimate, 
%    reducevolume, reducepatch.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 8 May 01

global rfFig                  % used in subfunctions
persistent rfInfile rfOutfile rfOutSRate rfVerbose rfNomSRate rfInSRate
persistent rfB rfN rfP rfQ rfPqString rfPqValue rfGain rfFilterRatio

% Set approximate number of samples done each pass.
% chunksize = 262144;
% chunksize = 1048576;
chunksize = 2097152;

if (nargin < 2)
  cmd = infile;
else
  cmd = 'init';
  if (nargin < 3), gain     = 1; end
  if (nargin < 4), outSRate = 0; end
  if (nargin < 5), designer = 0; end
  if (nargin < 6), verbose  = 1; end
  if (nargin < 7), nomSRate = 0; end
  if (nRows(infile) > 1)
    % infile has multiple rows.  Is it multiple file names, or a specifier
    % like 'fmt=b' or 'type=wav' ?
    if (isempty(infile(2,:) == '='))
      % Multiple file names.  Recurse on each one.
      for i = 1 : nRows(infile)
        convertSoundFile(deblank(infile(i,:)), deblank(outfile(i,:)), gain, ...
	    outSRate, designer, verbose, nomSRate);
      end
      return;
    end
  end
end

switch(cmd)
case 'init'
  % If needed, display GUI and get user input.  Else do filter directly.
  % If outSRate is same as inSRate, the filter is simply [1].

  [dummy, inSRate] = soundIn(infile, 0, 0);
  
  rfInfile   = infile;
  rfOutfile  = outfile;
  rfGain     = gain(:);
  rfInSRate  = inSRate;
  rfOutSRate = outSRate;
  rfVerbose  = verbose;
  rfNomSRate = nomSRate;

  % See if sampling rate ratio has changed.
  effectiveOutSRate = iff(outSRate ~= 0, outSRate, inSRate);
  diffRatio = 1;
  if (~isempty(rfInSRate) & ~isempty(rfFilterRatio))
    diffRatio = (inSRate / effectiveOutSRate ~= rfFilterRatio);
  end

  % Check to see if we need to (re-)make the filter.
  if (diffRatio)
    [rfP,rfQ,rfPqString,rfPqValue] = calcRatios(inSRate, effectiveOutSRate);
    convertSoundFile('remakeFilter')
    rfFilterRatio = inSRate / effectiveOutSRate;
  end
  
  if (designer)
    % Display the GUI, fill its slots, and get user input.	
    rfFig = findobj('Tag', 'convertFig');
    if (isempty(rfFig))
      rfFig = convertFig;          % load up and display the GUI
    end
    
    set(findobj(rfFig, 'Tag', 'ratioList'), ...
      'String', rfPqString, 'Value', rfPqValue);
  
    % Set the other fields, if values exist.
    setNumericEdit('nEdit', rfN);
    setNumericEdit('targetSRate', effectiveOutSRate);
    
    % Pretend a ratio has changed.  This makes filter response get displayed.
    convertSoundFile('ratioChange');
    
  else
    % Not designing a filter in GUI; just do the resampling.
    convertSoundFile('doIt');
  end
    
case 'remakeFilter'
  % (Re-)calculate the filter, rfB, using resample().
  P = rfP(rfPqValue);
  Q = rfQ(rfPqValue);
  if (isempty(rfN))
    rfN = 10;
  end
  if (P == 1 & Q == 1)
    rfB = [1];
  else
    if (~exist('resample'))
      error(['You must have MATLAB''s signal processing toolbox to ' ...
	      'change the sampling rate of a sound file.']);
    end
    [dummy,rfB] = resample(ones(rfInSRate, 1), P, Q, rfN);
  end
  
case 'ratioChange'            % callback from ratioList
  % User changed value on the P/Q list.  Store new value and redisplay filter.
  rfPqValue = get(findobj(rfFig, 'Tag', 'ratioList'), 'Value');
  setNumericEdit('actualSRate', rfP(rfPqValue) / rfQ(rfPqValue) * rfInSRate);
  convertSoundFile('displayResponse')
  
case 'nChange'                % callback from nEdit
  % User changed the N value.  Store new value and redisplay filter.
  rfN = sscanf(get(findobj(rfFig, 'Tag', 'nEdit'), 'String'), '%d');
  convertSoundFile('displayResponse');
  
case 'displayResponse'
  % Display filter's response in the GUI, which should be the current figure.
  convertSoundFile('remakeFilter')
  set(findobj(rfFig, 'Tag', 'nPointsText'), ...
      'String', sprintf('= %d points', length(rfB)));
  P = rfP(rfPqValue);
  Q = rfQ(rfPqValue);      
  
  % Calculate frequency response and (simultaneously) get timing.
  x = [zeros(1, 100000) 1 zeros(1, 100000)];     % impulse
  t0 = clock;
  set(gcf, 'Pointer', 'watch'); 
  filter(rfB, 1, x); 
  set(gcf, 'Pointer', 'arrow');
  t = etime(clock, t0);
  timeRatio = t / (length(x) / rfInSRate) * P;
  setNumericEdit('timing', timeRatio);
  
  % Plot frequency response.
  H = abs(fft(rfB)); 
  H = H(1 : (length(H)+1)/2);
  rfB = rfB / max(H);
  H = H / max(H);
  figure(rfFig)
  lims = [-140 +5];
  plot([1 1] * min(rfInSRate, rfOutSRate)/2, lims, 'r', ...
    linspace(0, rfInSRate/2 * P, length(H)), 20 * log10(H), 'b');
  title('Frequency response of resampling filter')
  xlabel('frequency, Hz')
  ylabel('dB')
  xlims fit; ylims(lims);

case 'doIt'
  set(findobj('Tag', 'convertFig'), 'Visible', 'off');   % hide it
  B = rfB;
  P = rfP(rfPqValue);
  Q = rfQ(rfPqValue);
  [dummy1,dummy2,ntotal,nchan,dummy3,nBits] = soundIn(rfInfile, 0, 0, 0);
  explode = strcmp(soundFileType(rfOutfile), 'binary'); % one outfile per chan?
  filterLen = length(B);
  chansPerPass = iff(explode, 1, nchan);
  buflen = chunksize / P / chansPerPass;
  buflen = buflen - rem(buflen, Q);	% make it a multiple of rfQ

  nomSRate1 = rfNomSRate;
  if (nomSRate1 == 0)
    nomSRate1 = iff(rfOutSRate ~= 0, rfOutSRate, rfInSRate); %effectiveOutSRate
  end
  if (rfVerbose), printf('Processing %s', rfInfile(1,:)); end
  
  for chan = 0 : iff(explode, nchan-1, 0)
    chansHere = iff(explode, chan, 0 : nchan-1);
    
    % Construct output file name.
    if (~explode | nchan <= 1)
      outchanfile = rfOutfile;
    else
      if (any(pathFile(rfOutfile) == '%'))
	outchanfile = [pathDir(rfOutfile) filesep ...
		sprintf(pathFile(rfOutfile), chan)];
      else
	outchanfile = sprintf('%s.ch%0*d.%s', pathRoot(rfOutfile), ...
	    ceil(log10(nchan-0.5)), chan, pathExt(rfOutfile));
      end
      if (rfVerbose)
	printf(['Channel %d' iff(explode, ', output file %s', '') ':'], ...
	    chan, outchanfile);
      end
    end
    
    nleft = ntotal;
    Z = [];
    inpos = 0;
    outpos = 0;
    while (nleft >= filterLen)
      % Read the sound.  The last pass gets fewer than buflen samples.
      [snd,dummy,nleft] = soundIn(rfInfile, inpos, buflen, chansHere);
      inpos = inpos + length(snd);

      % Interpolate zeros into each column of snd.
      if (P > 1)
	x = zeros(nRows(snd) * P, nCols(snd));
	x(1:P:nRows(x), :) = snd;
	snd = x;
      end
      
      % Filter.  Can't use resample(), as it doesn't handle initial/final 
      % conditions (Z). 
      if (~length(Z))
	[x,Z] = filter(B,1,snd);	% first time through
      else 
	[x,Z] = filter(B,1,snd,Z);	% successive times through
      end
      
      % Decimate.
      y = x(1:Q:length(x), :);
      
      % Apply gain(s).  rfGain is a column vector.
      if (length(rfGain) == 1),  y = y * rfGain;
      elseif (nCols(y) == 1),    y = y * rfGain(chan + 1);
      else                       y = y .* repmat(rfGain.', nRows(y), 1);
      end
      
      % Write output.
      soundOut(outchanfile, y, nomSRate1, outpos, nBits);
      
      outpos = outpos + length(y);
      if (rfVerbose)
	printf('    Processed %d samples with %d to go.', inpos, nleft);	
      end
    end
  end
  if (rfVerbose), printf('    Done.'); end
end  % of main switch()

if (nargout == 0)
  clear B
else
  B = rfB;
end

%-------------------------------------------------------------------------
  
function [pList,qList,str,best] = calcRatios(in, out)
% For the given IN and OUT sampling rates, calculate the set of ratios to 
% display in the list.  The list is a sequence of fractions P/Q that more and 
% more closely approximate out/in.  Then choose a 'best' one using
% an extremely simple heuristic: the best P/Q ratio for which P+Q < 20.

f = out/in;                       % the correct ratio
if (f > 1), P = floor(f); Q = 1;
else        P = 1;        Q = floor(1/f);
end
pList = P;
qList = Q;
err = abs(P/Q - f);
while (err > 1e-3)
  if (P/Q > f)
    Q = Q + 1;
  else
    P = P + 1;
  end
  err1 = abs(P / Q - f);
  if (err1 < err)
    pList = [pList P];
    qList = [qList Q];
    err = err1;
  end
end

% Construct str and set best.
str = setstr(zeros(length(pList), 1));
best = 0;
for i = 1:length(pList)
  s = sprintf('%d / %d', pList(i), qList(i));
  str(i, 1:length(s)) = s;
  if (best == 0 | pList(i) + qList(i) < 20)
    best = i;
  end
end

%-------------------------------------------------------------------------

function setNumericEdit(tag, value)
% If VALUE is non-empty, set the numeric edit named TAG to it.
% Assumes rfFig exists.

global rfFig

if (~isempty(value))
  ed = findobj(rfFig, 'Tag', tag);
  set(ed, 'String', num2str(value))
end
