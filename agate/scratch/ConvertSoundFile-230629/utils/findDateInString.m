function dtnum = findDateInString(str)
%findDateInString	deprecated; use extractDatestamp instead

persistent warned

if (isempty(warned))
  stack = dbstack;
  warning([mfilename ':deprecated'], ...
    [mfilename ' is deprecated. Use extractDatestamp instead. Called from ', ...
    stack(2).file '.']);
  warned = true;
end

dtnum = extractDatestamp(str);
