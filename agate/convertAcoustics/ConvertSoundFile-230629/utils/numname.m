function [c,o] = numname(n, British)
%NUMNAME	Return a string representing the name of an integer.
%
% str = numname(n)
%   Return the American cardinal name of integer n, such as 'one', 'two', 
%   'negative ten', etc.  Would work for numbers up to 10^36-1, except that 
%   floating-point roundoff causes problems first -- around 10^15 on
%   IEEE-standard floating point machines.
%
% str = numname(n, 1)
%   If a second argument is present and non-zero, return the British name
%   instead of the American name.  These names differ for numbers 10^9 and
%   larger:
%
%                                       American name     British name
%                                       -------------     ------------
%   10^3  =                     1 000   thousand          thousand
%   10^6  =                 1 000 000   million           million
%   10^9  =             1 000 000 000   billion           thousand million
%   10^12 =         1 000 000 000 000   trillion          billion
%   10^15 =     1 000 000 000 000 000   quadrillion       thousand billion
%   10^18 = 1 000 000 000 000 000 000   quintillion       trillion
%                            ... etc. ...
%
% [cardinalStr, ordinalStr] = numname(n)
%   A second return value is the ordinal name, such as 'first', 'second', 
%   'negative tenth', etc.

% David K. Mellinger
% David.Mellinger@oregonstate.edu
% 31 Mar 99

global nnLowCards nnLowOrds nnTensNames nnExpNames

if (length(nnLowOrds) < 1)
  nnLowCards = str2mat('zero', 'one', 'two', 'three', 'four', 'five','six', ...
      'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', ...
      'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen');
  nnLowOrds = str2mat('zeroth', 'first', 'second', 'third', 'fourth', ...
      'fifth', 'sixth', 'seventh', 'eighth', 'ninth', 'tenth', 'eleventh', ...
      'twelfth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth', ...
      'seventeenth', 'eighteenth', 'nineteenth');
  nnTensNames = str2mat('ten', 'twenty', 'thirty', 'forty', 'fifty', ...
      'sixty', 'seventy', 'eighty', 'ninety');
  nnExpNames = str2mat('thousand', 'million', 'billion', 'trillion', ...
      'quadrillion', 'quintillion', 'sextillion', 'septillion', ...
      'octillion', 'nonillion', 'decillion');  
end

if (rem(n,1))
  error('Argument must be an integer.');
end

if (nargin < 2), British = 0; end

c = '';
o = '';
if (n < 0)
  c = ['negative ' c];
  o = ['negative ' o];
  n = -n;
end

% Deal with thousands, millions, etc.
while (n >= 1000)
  e = floor(log10(n + 0.5) / 3);	% 0.5 helps w/float error for small n
  k = e;				% index into nnExpNames
  if (British & e > 1)
    k = floor(e/2) + 1;
    e = e - rem(e,2);
  end
  if (k <= size(nnExpNames, 1))
    expname = deblank(nnExpNames(k, :));
  else
    expname = ['10^' num2str(e*3)];
  end

  % Handle leading digit group: 1-3 digits American, 1-6 digits British
  lead = floor(n / 10 ^ (e*3));
  n = rem(n, 10 ^ (e*3));
  c = [c numname(lead) ' ' expname ' '];
  o = c;
  if (n == 0)
    o(length(o)) = [];			% make suffix for, e.g., 'thousandth'
    o = [o 'th'];
  end
end

% Handle hundreds.
if (n >= 100)
  x = floor(n/100);
  n = rem(n,100);
  c = [c deblank(nnLowCards(x + 1, :)) ' hundred '];
  o = c;
  if (n == 0)
    o(length(o)) = [];			% make suffix for 'hundredth'
    o = [o 'th']; 
  end
end

% Handle tens.
if (n >= 20)
  x = floor(n/10);
  n = rem(n,10);
  c = [c deblank(nnTensNames(x, :)) '-'];
  o = c;
  if (n == 0)
    o(length(o)-1:length(o)) = [];	% make suffix for, e.g., 'twentieth'
    o = [o 'ieth'];
    c(length(c)) = [];			% strip trailing '-'
  end
end

% Handle units.
if (n > 0)
  c = [c nnLowCards(n+1, :)];
  o = [o nnLowOrds(n+1, :)];
elseif (~length(c))
  c = nnLowCards(1,:);			% zero
  o = nnLowOrds (1,:);			% zeroth
end
c = deblank(c);
o = deblank(o);
