function [leq, perc, d, freq, X, Y] = SPD_function(s,plotOn)
%% SPD

% Calculates and plots spectral probability density (SPD).

% Input array "s" is the power spectral density (in dB re 1 uPa^2 Hz^-1)
% with frequency along the columns and time down the rows.
% The code assumes the first column is centre frequencies of each bin,
% and the first row a time vector (which isignored in the code).
% The PSD data is then s(2:r,2:c), where [r,c] = size(s).

% Code written by Nathan Merchant, 2013. ndmercha@syr.edu
% modified into a function by S. Fregosi 2019

% SPD method is presented in Merchant et al. 2013, JASA 133(4) EL262-EL267
% http://dx.doi.org/10.1121/1.4794934

% SF MODIFIED FEB 2019

if nargin < 2
    plotOn = 0;
end

tic

%% Input data

[r,c] = size(s);        %size of input array
freq = s(2:r,1);           %vector of frequencies
fint = freq(3)-freq(2);       %frequency bin separation (assumes linear f)
sa = s(2:r,2:c);        %data array
sa(sa<0) = NaN;         %suppress any negative bin values

%% Define analysis parameters

% hind = 0.1;   % default!          %histogram bin width for probability densities (PD)
hind = 1;
%(in dB re 1 uPa^2 Hz^(-1)
mindB = floor(min(min(sa))/10)*10;
%minimum dB level rounded down to nearest 10
maxdB = ceil(max(max(sa))/10)*10;
%maximum dB level rounded up to nearest 10
dbvec = mindB:hind:maxdB;
%dB values at which to calculate empirical PD

%% Compute stats
leq = 10*log10(mean(10.^(sa.'/10)));    %calculate linear mean
perc = prctile(sa.',1:99).';               %prctile is in the MATLAB Statistics Toolbox. If you don't have the toolbox you can download an equivalent function (place in same folder as MMAH.m) here: http://users.powernet.co.uk/kienzle/octave/matcompat/scripts/statistics/prctile.m
d = hist(sa.',dbvec)/(hind*(c-1));      %SPD array
d(d == 0) = NaN;                        %suppress plotting of empty hist bins
d = [d d(:,r-1)];                       %add dummy column for highest frequency
[X,Y] = meshgrid([freq;freq(r-1)]-0.5*fint,dbvec);
%array of x and y-axis values

%% Plot
if plotOn == 1
    figure(660)                             %initialise figure
    set(figure(666),'color','w')
    cla, hold off
    
    g = pcolor(X,Y,d);                      %SPD
    set(g,'LineStyle','none')
    
    hold on
    
    semilogx(freq,perc(:,99),'k','linewidth',2)   %percentiles
    semilogx(freq,perc(:,95),'k','linewidth',2)
    semilogx(freq,perc(:,50),'k','linewidth',2)
    semilogx(freq,perc(:,5),'k','linewidth',2)
    semilogx(freq,perc(:,1),'k','linewidth',2)
    
    semilogx(freq,leq,'m','linewidth',2)       %RMS (linear) mean
    
    caxis([0 0.06])
    title('Spectral Probability Density')
    xlabel('Frequency [ Hz ]')
    ylabel('PSD [ dB re 1 \muPa^2 Hz^-^1 ]')
    set(gca,'XScale','log','TickDir','out','layer','top')
    ylabel(colorbar,'Empirical Probability Density')
    ylim([mindB maxdB])
    xlim([min(freq) max(freq)])
    
    legend('SPD','99%','95%','50%','5%','1%','RMS Mean')
end

tock = toc;
disp(['SPD computed in ' num2str(tock) ' s.'])
