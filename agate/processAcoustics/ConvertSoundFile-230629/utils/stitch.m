% stitch.m
%
% Stitch all soundfiles in the current directory together into a new, 
% single soundfile.  The source soundfiles should be contiguous in time,
% i.e., samples from one file follow the preceeding file immediately.
% Soundfile names are sorted to determine their order.
%
% The set of source soundfiles is determined by the first line of real
% code below, the one on the configuration section that sets f.  Change
% this line as needed.
%
% If the input file has multiple channels, these can be separated (exploded) 
% so that each channel is placed into its own soundfile.  Whether this
% is done depends on the switch 'explode'.  All input soundfiles should
% have the same number of channels.
%
% When exploding, this reads the soundfiles one channel at a time.
% This is slow, but it avoids the out-of-memory problems that can 
% occur when all channels are read at once.  (This works only
% because the low-level routines aiffIn, wavIn, etc. can read
% soundfiles in short blocks.)  It is assumed that all of one
% channel of each file can fit in memory at once; it wouldn't be
% hard to change the code to avoid this assumption, but I haven't 
% done this yet.
%
% Dave Mellinger
% David.Mellinger@oregonstate.edu
% 6 Feb 02

%%%%%%%%%%%%%%%%%%%%%%%%% configuration section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f = dir('*.wav');	        % names of all files to process
outdir = 'C:\Dave\sounds\jason\sonobuoy-1999\'; % where the result is deposited
explode = 1;			% set to 1 to 'explode' channels into
				%   separate files, 0 to keep them together
%%%%%%%%%%%%%%%%%%%%%%%%% end of configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


f = sort({f.name});
ch = 0;
nChan = inf;		% gets changed when we read a soundfile
out = -1;
while (ch < nChan)
  if (explode)
    printf('Channel %d ------------------------------------------------',ch+1);
  end
  k = 0;
  for i = 1 : length(f);
    if (~strcmp(f{i}, '.') & ~strcmp(f{i}, '..'))   
      disp(f{i})
      % Get channel ch (if explode is true), or all channels (if it's false).
      [s,sRate,left,nChan] = soundIn(f{i}, 0, inf, iff(explode, ch, NaN));
      if (k == 0)
	printf('sample rate %g on %d channels', sRate, nChan)
	outname = [outdir pathRoot(f{i}) ...
		iff(explode, ['-ch' num2str(ch+1)], '') '.aif'];
      end
      soundOut(outname, s, sRate, k);
      k = k + length(s);
    end
  end
  % Go to next channel, or terminate the loop if explode is 0.
  ch = iff(explode, ch + 1, inf);
end
