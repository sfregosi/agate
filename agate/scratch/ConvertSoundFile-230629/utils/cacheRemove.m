function cache = cacheRemove(cache, key)
%cacheRemove	Remove the entry in a cache associated with a given key
%
% An associative memory cache stores a series of keys and, for each key,
% a value, then lets you look up the key later on and retrieve the
% corresponding value. All keys in a given cache should be numbers or all
% should be strings; the values may be anything.
%
% cache = cacheRemove(cache, key)
%    Find the cache entry with the given key and remove it from the cache.
%    Subsequent calls to cacheMatch looking for that key will return [].
%
%   NB: Make sure you have the 'cache =' part of this statement, as otherwise
%   this function will modify the cache you pass in and then throw the modified
%   one away!
%
% See also cacheAdd, cacheMatch.

% Dave Mellinger 10/2015

[~,ix] = cacheMatch(cache, key);
if (~isempty(ix))
  cache(ix) = [];
end
