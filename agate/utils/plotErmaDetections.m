function plotErmaDetections(CONFIG, path_bsLocal, divenum)
%plotErmaDetections	plot the WISPR detections from a Seaglider dive
%
%   Syntax:
%       plotErmaDetections(CONFIG, path_bsLocal, pp [,divenum])
%
%   Description:
%       Read in the ws****az file from a given dive (default: the most recent
%       dive) and plot the data from it so a person can look to see if the
%       detections look like sperm whale clicks. Assumes that the detection
%       report for this dive is in the path_bsLocal directory.
%
%   Inputs:
%       CONFIG		[struct] Seaglider configuration info
%	path_bsLocal	[string] directory where basestation files have been downloaded to
%	divenum		[scalar] dive number to plot click info for
%
%   Outputs: none (but creates a figure)
%
%   Examples:
%       plotErmaDetections(CONFIG, path_bsLocal, 17)	  % plot detections from dive 17
%
%   See also readErmaReport.m
%
%   Authors:
%       D. Mellinger <David.Mellinger@oregonstate.edu>
%
%   First Version:   09 May 2023
%   Updated:	     21 May 2023
%
%   Created with MATLAB ver. 9.13.0.2049777 (R2022b)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check that this glider has WISPR, and has it turned on.
if (~isfield(CONFIG,'ws') || ~isfield(CONFIG.ws,'loggers') || ...
    CONFIG.ws.loggers == 0)
  return
end

%% Read the ERMA report.
fn = sprintf('ws%04daz', divenum);
ermaReportFileName = fullfile(path_bsLocal, fn);
if (~exist(ermaReportFileName, 'file'))
  msg = sprintf('There is no ERMA detection report for dive #%d', divenum);
  msgbox(msg, 'modal');
  return
end
s = readErmaReport(ermaReportFileName);

%% Make a figure with ICIs on the left and histograms on the right.
figure(CONFIG.plots.figNumList(8))
clf
nEnc = length(s.enc);
for ei = 1 : nEnc
  tS = s.enc(ei).t_D * (24*60*60);	% times of clicks in seconds
  ici = tS(2:end) - tS(1 : end-1);

  % Plot inter-click intervals.
  subplot(nEnc, 2, ei*2 - 1)
  plot(tS(2:end) - tS(1), ici, '-', tS(2:end) - tS(1), ici, 'o');
  set(gca, 'YLim', [0 10]);
  if (ei == ceil(nEnc/2)), ylabel('inter-click interval'); end
  if (ei == 1)
    title(sprintf('Dive %d (file %s): %d encounter(s)', divenum, fn, nEnc), ...
      'Interp', 'none');
  end
  if (ei == nEnc), xlabel('time, s'); end

  % Plot histogram of inter-click intervals. ICIs less than 1.0 s are subdivided
  % into 0.1-s bins, but the counts for these are multiplied by 10 to make them
  % comparable to ICIs greater than 1.0 s.
  subplot(nEnc, 2, ei * 2)
  [N,edges] = histcounts(ici, [0:0.1:1 2:10]);
  histogram('BinEdges', edges, 'BinCounts', [N(1:10)*10  N(11:end)]);
  if (ei == ceil(nEnc/2)), ylabel('normalized count'); end
  if (ei == nEnc), xlabel('inter-click interval, s'); end
end
set(gcf, 'name', 'Erma detection data')

% Make 'prev' and 'next' buttons.
set(gcf, 'units', 'pixel'); posn = get(gcf, 'Pos');
prevCallback = sprintf('plotErmaDetections(CONFIG, path_bsLocal, %d)', divenum-1);
uicontrol('Style', 'pushb', 'String', '← prev', 'Tooltip', 'Show previous dive', ...
  'Position', [posn(3)/2-80 0 80 22], 'Callback', prevCallback);
nextCallback = sprintf('plotErmaDetections(CONFIG, path_bsLocal, %d)', divenum+1);
uicontrol('Style', 'pushb', 'String', 'next →', 'Tooltip', 'Show next dive', ...
  'Position', [posn(3)/2 0 80 22], 'Callback', nextCallback);
