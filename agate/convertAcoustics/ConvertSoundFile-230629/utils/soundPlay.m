function soundPlay(snd, f, rate)
%soundPlay       Play a sound with interpolated samples.
%
% soundPlay(x)
%    Play vector x at the default sampling rate of the machine.  On the 
%    Sun, this is 8000 Hz; on the Mac, 22254.54 Hz.
%
% soundPlay(x, f)
%    Play x, but slowed down by a factor of f.  f must be an integer.
%    If resample.m in the Signal Processing toolbox is available, it is
%    used; otherwise this is done by linearly interpolating samples.
%
% soundPlay(x, f, samplingrate)
%    Play x slowed down by a factor of f at the given sampling rate.
%    The sampling rate is passed to the lower-level sound hardware/software,
%    which usually interpolates samples.
%
% See also defaultsrate, sound, soundIn, and the lower-level routines
% auwrite (Sun), playsound (Mac, Next, SGI), wavwrite (PC).

% spAudioPlayer is global to prevent auto-deletion upon function return.
global spAudioPlayer

if (1)
  % This is an attempt to use 'resample'.  
  % Doesn't work yet; numer can end being huge (1000 Hz => 441/40 ratio).
  
  goodR = [8000 11025 22050 24000 44100 48000];
  %goodR = [24000 44100 48000];
  
  % Use only rates as large as 'rate', unless none such are available.
  ix = find(goodR >= rate);
  if (isempty(ix)), ix = length(goodR); end
  goodR = goodR(ix);
  
  tol = 0.01;
  while (1)
    k = goodR ./ rate;
    [numer,denom] = rat(k, tol);
    err = abs((numer ./ denom) - k) ./ k;
    err1 = err.^12 .* numer;
    ix = find(err1 < max(1, goodR(1)./rate) * 2);
    if (~isempty(ix))
      [~,ix1] = min(err(ix));
      numer = sub(numer(ix), ix1);
      denom = sub(denom(ix), ix1);
      rate = sub(goodR(ix), ix1);
      %printf('numer %d, denom %d, rate %.1f', numer, denom, rate);
      break
    end
    tol = tol * 1.5;
  end
  
  if (exist('resample','file'))
    snd = resample(snd, numer, denom);
    newrate = rate;
  else
    newrate = rate * numer / denom;     % use sound hardward to interpolate
  end
  
  if (exist('audioplayer'))                                     %#ok<EXIST>
    snd = snd / max(abs([min(snd) max(snd)]));   % scale to [-1,1]
    spAudioPlayer = audioplayer(snd, newrate);
    play(spAudioPlayer);                % no blocking during playback
  else
    soundsc(snd, newrate);              % blocks during playback
  end
  
  return                                % deletes a non-global audioplayer!
end  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% old code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global soundPlayLastB soundPlayLastF                      %#ok<NUSED,UNRCH>
if (nargin < 2), f = 1; end                                     
if (f ~= round(f)), error('Playback factor must be an integer.'); end

if (nargin < 3)
  rate = defaultsrate;
end
if (f == 1)
  %printf('soundPlay; no speedup, %d samples, rate %g Hz, max %.2f', ...
  %  length(snd), rate, max(abs(snd)))
  snd = snd / (max(abs(snd)) * 1.01);
  if (max(abs(snd)) > 1)
    %printf('soundPlay: soundsc');
    soundsc(snd, rate);
  else
    %printf('soundPlay: sound');
    sound(snd, rate);
  end
else
  snd = snd(:).';
  if (exist('resample', 'file'))
    % Interpolate using resample.  Use previous filter coeffs (B) if available.
    if (gexist4('soundPlayLastF') & f == soundPlayLastF)
      printf('Resampling by %g using existing filter.', f);
      y = resample(snd, f, 1, soundPlayLastB);
    else
      printf('Resampling by %g.', f);
      [y,soundPlayLastB] = resample(snd, f, 1, soundPlayLastB);
      soundPlayLastF = f;
    end
  else
    % Interpolate samples linearly.  No filtering done (blech!).
    y = ((f:-1:1) / f).';
    n = length(snd);
    y = reshape(y*snd(1:n-1) + (1-y)*snd(2:n), length(snd)*f-f, 1);
  end

  %printf('soundPlay; %d samples, rate %g Hz', length(y), rate)
  if (max(abs(snd)) > 1)	% OK to use snd, not y: interpolation is convex
    soundsc(y, rate);
  else
    sound(y, rate);
  end
end
