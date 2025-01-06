function fieldValue = fieldOrDflt(struc, fieldname, defaultValue)
%fieldOrDflt	value of a structure field if present, or a default
%
% fieldValue = fieldOrDflt(struc, fieldname, defaultValue)
%   If 'fieldname' is a field of the structure 'struc', return its value,
%   otherwise return defaultValue.
%
% See also struct, getfield, fieldnames, isfield, rmfield.

if (isfield(struc, fieldname))
  fieldValue = getfield(struc, fieldname);
else 
  fieldValue = defaultValue;
end
