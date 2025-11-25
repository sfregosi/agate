% Make a test signal
fs = 1000;             % sampling frequency (Hz)
t = 0:1/fs:1-1/fs;     % 1 second time vector
x = cos(2*pi*100*t) + 0.5*randn(size(t));  % 100 Hz tone + noise

% Pick parameters
nfft = 256;
win = hamming(nfft);
noverlap = nfft/2;
t0 = 0;   % starting time (not really used for PSD check)

% call cal_spec function
[spec_custom, freq_custom] = cal_spec(x, fs, win, noverlap, t0);

% call pwelch
[spec_pwelch, freq_pwelch] = pwelch(x, win, noverlap, nfft, fs);

% Compute U the way pwelch does
U = sum(win.^2)/nfft;

fprintf('Window normalization constant U = %.6f\n', U);

% plot side-by-sidefigure;
subplot(2,1,1)
plot(freq_custom,10*log10(spec_custom),'r','LineWidth',1.5)
hold on
plot(freq_pwelch,10*log10(spec_pwelch),'k--','LineWidth',1.5)
grid on
hold off
xlabel('Frequency (Hz)')
ylabel('PSD (dB/Hz)')
legend('cal\_spec','pwelch')
title('PSD comparison')

subplot(2,1,2)
plot(freq_custom, spec_custom ./ spec_pwelch - 1, 'b')
grid on
xlabel('Frequency (Hz)')
ylabel('Relative Error')
title('Relative difference (custom / pwelch - 1)')
