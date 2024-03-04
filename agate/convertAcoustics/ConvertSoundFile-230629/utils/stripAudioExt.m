function out = stripAudioExt(in)
% outFileName = stripAudioExt(inFileName)
%    If inFileName ends with one of the known audio filename suffixes,
%    remove the suffix.

ext = lower(pathExt(in));

% Look for a binary file extension like 'b5' or 'b1_3'.
isbinary = 0;
if (length(ext) > 0 && ext(1) == 'b' && sum(ext == '_') <= 1)
  [x,y] = meshgrid(ext, '0123456789_');   % NB: meshgrid fails on empty strings
  isbinary = all(any(x == y));            % has only 0-9 or '_' characters?
end  

if (isbinary | strmatch(ext, {'aif','aiff','au','cbin','dat','m22','mat',...
    'str','wav'}, 'exact'))
  out = pathRoot(in);
else
  out = in;
end
