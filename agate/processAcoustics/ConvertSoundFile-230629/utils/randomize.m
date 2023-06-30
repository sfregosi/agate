function randomize
% RANDOMIZE	Set Matlab's random-number generator to a random state.
%
% When Matlab starts up, the state of its pseudo-random number generator 
% is initialized to a certain fixed value, so it always produces the
% same sequence of random numbers.  RANDOMIZE makes that state random
% (specifically, based on the current time), so you get a random sequence.
%
% To undo the effects of randomize, do 
%
%           rand('state', 0)
%
% See also rand, randn.

rand('state', sum(100 * clock));
