function prev = pushProp(h, varargin)
%pushProp	install new property values, saving old ones for restoration
%
% prev = pushProp(h, 'Property', 'val')
%    Store the existing value of 'Property' in prev and install 'val' as the
%    current value.  'prev' can later be passed in a call popProp(h, prev) to
%    restore the old value.  It is a cell row vector with one cell per property. 
%
% prev = pushProp(h, 'Property1', 'val1', 'Property2', 'val2', ...)
%    Set multiple property/value pairs at once.  The same call popProp(h, prev)
%    is used to restore the old values.
%
% See also popProp, get, set.

nvar = size(varargin,2);
if (mod(nvar, 2) ~= 0)
  error('Properties and values must come in pairs');
end

prev = cell(1, nvar);
for i = 1 : 2 : nvar
  prev{i}   = varargin{i};		% property name
  prev{i+1} = get(h, varargin{i});	% old property value
  set(h, varargin{i}, varargin{i+1});	% new property value
end
