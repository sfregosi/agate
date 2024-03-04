function [y,f1,f2,B0,A0,B1,A1] = heterodyne(x, sRate, passband, ...
  filterLength, rolloffDB, transitionBandWidth, newBottomFreq, decim, ...
  B0, A0, B1, A1)
%heterodyne	frequency-shift a signal by heterodyning, with required filtering
%
% y = heterodyne(x, sRate, passband)
%   Given a signal x, its sample rate sRate, and passband of a two-element
%   vector [loFreq highFreq], transform the signal by shifting the passband in
%   frequency down to 0 Hz and removing the signal at other frequencies. This is
%   done by (1) filtering the signal to remove energy outside the passband, (2)
%   heterodyning to frequency-shift the passband down to 0 Hz (the 'difference
%   frequencies'), and (3) filtering again to remove the second copy of the
%   signal that heterodyning creates (the 'sum frequencies').
%
%   The signal processing toolbox is required (for fir2 filter design).
%
%  Example: An audio signal x was recorded at 512 kHz sample rate. It has
%  interesting sound in the 120-140 kHz band that we wish to move to the 0-20
%  kHz band, which makes it audible (human hearing extends up to around 20 kHz):
%      y = heterodyne(x, 512000, [120000 140000]);
%
% y = heterodyne(x, sRate, passband, transitionBandWidth, filterLength, ...
%                                              rolloffDB, newBottomFreq, decim)
%   Additional arguments control how the filtering and heterodyning is done. The
%   default values here are used if an argument is missing or if it is []:
%     filterLength         length of the FIR filter used in filtering (see
%                          fir2.m); a larger filterLength gives a filter with
%                          steeper rolloff and hopefully less ripple, while a
%                          smaller one runs faster; default is 512 (coefficients)
%     rolloffDB            amount of rolloff outside the passband in the
%                          filters, in decibels; default is -60 (dB)
%     transitionBandWidth  width of the filters' transition bands (the bands
%                          where the filter frequency response goes from 0 to
%                          -rolloffDB decibels); default is 0.1 times the width
%                          of the passband
%     newBottomFreq        heterodyning moves the bottom edge of the passband to
%                          this frequency; default is 0 Hz so that the passband
%                          is shifted as far down in frequency as possible
%     decim                decimation factor: if this is present and larger than
%                          1, the signal resulting after heterodyning and
%                          filtering is decimated by this factor (i.e., by
%                          extracting only every decim'th sample), so that the
%                          sample rate of y is sRate/decim; default is 1, which
%                          means "don't decimate"
%
%   Example: An audio signal x was recorded at 512 kHz sample rate. It has
%   interesting sound in the 100-150 kHz band that we wish to move to the 0-50
%   kHz band, which both makes the bottom 20 kHz of it audible and also allows
%   decimation by 5 to make the resulting signal have 1/5 as many samples. We
%   use a transition bandwidth of 1 kHz. This call results in a new signal y
%   with a sample rate of 512000/5 = 102400 Hz:
%      y = heterodyne(x, 512000, [100000 150000], 1000, [], [], 0, 5);
%
% [y,f1,f2] = heterodyne( ... )
%   Additional return values are f1, a 2-element vector with the new frequency
%   band that the original passband was shifted into (also called the
%   'difference frequencies'), and f2, a 2-element vector with the new frequency
%   band that also has a copy of the original passband (also called the 'sum
%   frequencies'). If f2 is aliased (i.e., one or both elements are above
%   sRate/2), the returned f2 values are 'wrapped' to accurately reflect where
%   the signal energy will be; the upper limit might be sRate/2.
%
% [y,f1,f2,B0,A0,B1,A1] = heterodyne(x, sRate, passband, ...
%       filterLength, rolloffDB, transitionBandWidth, newBottomFreq, decim, ...
%       B0, A0, B1, A1)
%   You can also pass in vectors of filter coefficients to be used in the two
%   filters (B0 and A0 before heterodyning, and B1 and A1 after) and/or get the
%   filter coefficients that are used as return values. There are a couple of
%   reasons for doing this: (1) By specifying B and A yourself, you can use a
%   filter that you design instead of one that is calculated automatically,
%   allowing you to shape the filter, use IIR filtering for speed, or whatever.
%   (2) By using the B and A values that are returned from one call to this
%   function in successive calls, you can prevent re-design of the filter (i.e.,
%   re-calculation of the filter coefficients) on every call and thus save
%   signficant computation time. To do (2) without doing (1), initialize your
%   B0, A0, B1, and A1 all to [] before the first call to heterodyne(), then as
%   shown here, pass in these four variables and assign the return values to
%   these same variables. On the first call to this function, the function sees
%   that B0 etc. are [] and designs the filters (calculates the A and B
%   coefficients), which will then get returned; when you pass in B0, A0, Ba,
%   and A1 on the next call, the function sees that they are already calculated
%   and won't re-do the filter design.
%
% Dave Mellinger

% Set up default values. Sometimes people use decim==0 to mean they don't want
% to decimate, so check for that.
if (nargin < 4 || isempty(filterLength)),        filterLength         = 512; end
if (nargin < 5 || isempty(rolloffDB)),           rolloffDB            = -60; end
if (nargin < 6 || isempty(transitionBandWidth)), transitionBandWidth  = diff(passband) * 0.1; end
if (nargin < 7 || isempty(newBottomFreq)),       newBottomFreq        = 0;   end
if (nargin < 8 || isempty(decim) || decim == 0), decim                = 1;   end

% IF NEW ARGS ARE ADDED, BE VERY CAREFUL ABOUT nargin VALUES, AS nargin IS USED
% IN THE CODE BELOW TOO.

% Fix a likely user error.
if (rolloffDB > 0), rolloffDB = -rolloffDB; end

if (decim ~= floor(decim))
  error('Decimation value ''decim'' is %f. It must be a whole number.');
end

% Initialize.
tb = transitionBandWidth;		% shorter name
nyq = sRate / 2;			% Nyquist frequency
rLin = 10 ^ (rolloffDB / 20);		% rolloff in linear units
hetF = passband(1) - newBottomFreq;	% heterodyne frequency
f1 = passband - hetF;                   % difference frequency band
f2 = passband + hetF;                   % sum frequency band

% If heterodyning would send passband over Nyquist frequency, wrap it.
if (any(f2 > nyq))
  if (all(f2 > nyq))
    f2 = 2 * nyq - mod(f2, sRate);
  else
    f2 = [nyq*2-max(f2) nyq];
  end
end

% Design the filters. The first one is for before heterodyning, to remove energy
% outside the passband:
if (nargin < 9 || isempty(B0))
  freq = [0  passband(1)+[-tb tb]  min(nyq, passband(2)+[-tb tb])  nyq];
  gain = [rLin  rLin 1 1 rLin rLin];
  if (freq(2) < 0)
    freq(2:3) = [];
    gain(2:3) = [];
    gain(1) = 1;
  end
  B0 = fir2(filterLength, freq / nyq, gain);
  A0 = 1;               % A-coefficient vector is just [1] for FIR filters
end
% Second one is for after heterodyning, to remove energy in the 'sum
% frequencies' band:
if (nargin < 11 || isempty(B1))
  B1 = fir2(filterLength, [0 f1(2) f1(2)+tb nyq] / nyq, [1 1 rLin rLin]);
  A1 = 1;               % A-coefficient vector is just [1] for FIR filters
end

% Filter first time to remove energy at frequencies outside the passband.
xFilt = filter(B0,A0,x);		% x, filtered

% Perform the heterodyning.
t = (0 : length(xFilt)-1).' / sRate;    % time steps
h = sin(2 * pi * hetF * t);             % sinusoid to heterodyne with
if (hetF > 0)
  xHet = xFilt .* h * 2;                % heterodyne xFilt
else
  xHet = xFilt;                         % no shift needed!
end

% Filter a second time to remove the unwanted frequency band (the 'sum
% frequencies').
xHetFilt = filter(B1, A1, xHet);

% Decimate if desired.
if (decim == 1)
  y = xHetFilt;                         % no decimation
else
  y = xHetFilt(1 : decim : end);        % decimate
end
