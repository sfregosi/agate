function cache = cacheAdd(cache, key, value)
%cacheAdd	Add an item to a cache using a given key
%
% An associative memory cache stores a series of keys and, for each key,
% a value, then lets you look up the key later on and retrieve the
% corresponding value. All keys in a given cache should be numbers or all
% should be strings; the values may be anything.
%
% cache = cacheAdd(cache, key, value)
%   Add 'value' in the cache under the given 'key' string, or replace an
%   existing value if that key already exists in the cache, and return the
%   updated cache. The value can be of any type that can be a struct element.
%
%   NB: Make sure you have the 'cache =' part of this statement, as otherwise
%   this function will modify the cache you pass in and then throw the modified
%   one away!
%
% See also cacheMatch, cacheRemove.

% Dave Mellinger 10/2016

[~,ix] = cacheMatch(cache, key);		% already in cache?
if (isempty(ix)), ix = length(cache)+1; end
cache(ix).key   = key;
cache(ix).value = value;
