% This is an example of using heterodyne(), which does frequency-shifting
% using heterodyning (and the necessary filtering). It requires 
%  (1) the signal processing toolbox (needed by heterodyne.m),
%  (2) my 'utils' folder in your MATLAB path, and
%  (3) [optionally] my 'osprey' folder in your MATLAB path (if useOsprey below
%      is true) for displaying before-and-after spectrograms
%
% Dave Mellinger

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Configuration %%%%%%%%%%%%%%%%%%%%%%%%%%
% Many parameters are set to [] here, which means 'use the default value'. See
% heterodyne.m for the defaults.
if (1)
  % Harbor porpoise example with decimation. There are porpoise clicks starting
  % at about 2.0 seconds in this sound file.
  %filename = "C:\Dave\sounds\porpoise-OERA-Fundy\examples\AMAR613.20190907T112847Z@103.5s rapid sonar scan.wav";
  filename = "C:\Dave\sounds\porpoise-OERA-Fundy\AMAR\2019-09\PAM2\filesWithClicks\AMAR613.20190907T112847Z.wav";
  passband = [100000 150000];	% frequencies to keep, Hz
  transitionBandWidth = 1000;	% how wide (Hz) filter rolloff will try to be
  filterLength = [];		% larger=>more accurate filter, smaller=>faster
  rolloffDB = [];               % amount of filter rolloff, dB
  newBottomFreq = [];		% Hz
  decim = 5;                    % 1 means no decimation
  useOsprey = true;             % display before-and-after spectrograms?
elseif (0)
  % Humpback example.
  filename = "C:\Dave\sounds\humpback-Socorro-JeffJacobsen\2002March12-JJacobsen@160s.wav";
  passband = [1500 3000];	% frequencies to keep, Hz
  transitionBandWidth = 100;	% how wide (Hz) filter rolloff will try to be
  filterLength = [];		% larger=>more accurate filter, smaller=>faster
  rolloffDB = [];               % amount of filter rolloff, dB
  newBottomFreq = [];		% Hz
  decim = 1;                    % 1 means no decimation
  useOsprey = true;             % display before-and-after spectrograms?
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% End of configuration %%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize.
global opBrightness opContrast  % Osprey display settings
B0=[]; A0=[]; B1=[]; A1=[];

%% Read in the signal.
[x,sRate] = audioread(filename);		% x is the signal

if (useOsprey)
  % Display the signal in Osprey for a couple of seconds.
  osprey(x, sRate); pause(2)
  bc = [opBrightness opContrast];
end

%% Heterodyne, using appropriate filtering.
[y,f1,f2,B0,A0,B1,A1] = heterodyne(x, sRate, passband, ...
  filterLength, rolloffDB, transitionBandWidth, newBottomFreq, decim, ...
  B0, A0, B1, A1);

%% Ask user about various possible things that can go wrong.
fprintf(['Passband of [%g %g] will be copied to [%g %g] as well as [%g %g],'...
  '\nwith the latter filtered out if possible.\n'], ...
  passband(1), passband(2), f1(1), f1(2), f2(1), f2(2))
if (f2(1) < f1(2) && f2(2) > f1(1))
  if (~yesno({'The new frequency bands overlap, which will cause' ...
      'interference in the heterodyned signal. Continue?'}))
  fprintf('%s: Exiting. Please adjust the parameters and try again.\n', mfilename);
    return
  end
end

if (1)
  H = fft(B0);
  mag = abs(H(1 : ceil(length(H)/2)));
  freqs = (0 : length(mag)-1)' .* (sRate/2 / length(mag));
  plot(freqs, log(mag) * (20/log(10)))
  title('Frequency response of pre-heterodyne filter')
  axis([0 sRate/2 -80 5]);
  xlabel('Hz'); ylabel('dB')
  
  hold on; plot([passband;passband], [ylims;ylims].', 'r:'); hold off
  set(gcf, 'Name', 'Filter frequency response')
  if (~yesno('Is the filter frequency response a good one?'))
    fprintf('%s: Exiting. Please adjust the parameters and try again.', mfilename);
    return
  end
end

%% Final display.
if (useOsprey)
  % Display heterodyned signal at same brightness/contrast as before.
  osprey(y, sRate/decim)
  opBrightness = bc(1); opContrast = bc(2); opRefChan(1);
end

disp('NB! The result is shown in the spectrogram but I have not saved it.')
