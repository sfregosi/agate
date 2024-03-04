function popProp(h, prev)
%popProp	restore property values that were saved by pushProp
%
% popProp(h, prev)
%    Restore the property/value pair(s) 'prev' that were saved by a prior call
%    to pushProp.
%
% See also pushProp, get, set.

nvar = size(prev, 2);
if (mod(nvar, 2) ~= 0)
  error(['It appears that input argument ''prev'' did not come from a prior' 10
    'call to pushProp().  Properties and values must come in pairs.  ']);
end

for i = 1 : 2 : nvar
  set(h, prev{i}, prev{i+1});
end
