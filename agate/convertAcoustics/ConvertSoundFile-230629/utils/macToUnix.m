function str = macToUnix(str)
% str = macToUnix(str)
% Convert "/" to ":".
% Also strip leading /'s.

if (str(1) == '/'), str = str(2:length(str)); end

x = find(str == '/');
str(x) = setstr(':' * ones(1, length(x)));
