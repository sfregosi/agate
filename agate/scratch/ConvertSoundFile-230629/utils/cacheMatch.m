function [value,ix] = cacheMatch(cache, key)
%cacheMatch	Look up a key in a cache and return the corresponding value
%
% An associative memory cache stores a series of keys and, for each key,
% a value, then lets you look up the key later on and retrieve the
% corresponding value. All keys in a given cache should be numbers or all
% should be strings; the values may be anything.
%
%value = cacheMatch(cache, key)
%   This function does the lookup step. If the 'key' arg here matches any of
%   the keys in the cache, then the corresponding value is returned. If there
%   is no match for the key, then [] is returned.
%
% See also cacheAdd, cacheRemove.

% Dave Mellinger 10/2016

% The cache is set up as a struct vector with elements 'key' and 'value'. Also,
% a second return arg 'ix' says which element of the struct vector was the
% cache hit, or [] if none.
value = [];
ix = [];
if (~isempty(cache))
  if (isnumeric(key))
    ix = find(key == [cache.key], 1, 'first');
  elseif (ischar(key))
    ix = find(strcmp(key, {cache.key}), 1, 'first');
  else
    error('cache:badCacheKeyType', 'A cache key must be a number or string.');
  end
  if (~isempty(ix))
    value = cache(ix).value;
  end
end
