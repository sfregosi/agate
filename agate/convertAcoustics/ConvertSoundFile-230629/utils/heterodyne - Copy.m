
filename = "C:\Dave\sounds\humpback-Socorro-JeffJacobsen\2002March12-JJacobsen@160s.wav";
passband = [5000 9000];		% Hz
transitionBand = 100;		% how wide (Hz) filter rolloff will try to be
filterLength = 512;		% larger=>more accurate filter, smaller=>faster
rolloffDB = -60;                % amount of filter rolloff, dB (should be <0)
newBottomFreq = 0;		% Hz

[x,sRate] = soundIn(filename);		% x is the signal
tb = transitionBand;			% shorter name
nyq = sRate / 2;			% Nyquist frequency
rolloffLin = 10^(rolloffDB/20);		% rolloff in linear units
hetF = passband(1) - newBottomFreq;	% heterodyne frequency
f1 = passband - hetF;
f2 = passband + hetF;
B0=[]; A0=[]; B1=[]; A1=[];             % initialize

subplot(1,2,1)
[B0,A0] = designFilter('fir2', sRate, ...
    [0 passband(1)+[-tb tb] passband(2)+[-tb tb] nyq], ... 	% frequencies
    [rolloffLin rolloffLin 1 1 rolloffLin rolloffLin], filterLength, 1);
subplot(1,2,2)
[B1,A1] = designFilter('fir2', sRate, ...
  [0 f1(2) f1(2)+tb nyq], [1 1 rolloffLin rolloffLin], filterLength, 1);
hold on; plot([passband;passband], [ylims;ylims].', 'r:'); hold off
set(gcf, 'Name', 'Filter frequency response')
if (0) %~yesno('Is the filter frequency response a good one?'))
  mprintf('Exiting. Please adjust the parameters and try again.');
  return
end

osprey(x, sRate); pause(2) %fprintf(1, '\nPress enter to continue: '); pause; printf
global opBrightness opContrast
bc = [opBrightness opContrast];
xf = filter(B0,A0,x);			% x, filtered



osprey(xf, sRate); 
opBrightness = bc(1); opContrast = bc(2); opRefChan(1); 
pause(2)
%fprintf(1, '\nPress enter to continue: '); pause; printf




% If heterodyning would send passband over Nyquist frequency, wrap it.
if (any(f2 > nyq))
  if (all(f2 > nyq))
    f2 = 2 * nyq - mod(f2, sRate);
  else
    f2 = [nyq*2-max(f2) nyq];
  end
end
printf('Passband of [%g %g] will be copied to', passband(1), passband(2))
printf('[%g %g] as well as [%g %g]', f1(1), f1(2), f2(1), f2(2))
if (f2(1) < f1(2) && f2(2) > f1(1))
  if (~yesno({'The new frequency bands overlap, which will cause' ...
      'interference in the heterodyned signal. Continue?'}))
  mprintf('Exiting. Please adjust the parameters and try again.');
    return
  end
end
t = (0 : length(x)-1).' / sRate;        % time steps
h = sin(2 * pi * hetF * t);             % sinusoid to heterodyne with
hetX = xf .* h * 2;                     % do the heterodyning
osprey(hetX, sRate); opBrightness = bc(1); opContrast = bc(2); opRefChan(1); pause(2)

hetXfilt = filter(B1, A1, hetX);
osprey(hetXfilt, sRate)
opBrightness = bc(1); opContrast = bc(2); opRefChan(1);
