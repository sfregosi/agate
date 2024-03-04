function w = hanning(n)
%HANNING         Hanning window.

x = (0 : n-1).';
w = 0.5 * (1 - cos(2 * pi * x / (n-1)));
