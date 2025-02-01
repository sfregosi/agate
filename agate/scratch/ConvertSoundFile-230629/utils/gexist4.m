function gexist_x = gexist4(arg)
%gextist4	Test for existence and non-emptiness of a global variable.
%
% x = gexist4(arg)
%    Test for the existence of a global variable.  This is done in the manner
%    of 'exist' in Matlab Version 4, which returns 1 if the variable exists and
%    is non-empty, 0 otherwise.  (Later versions of Matlab return 1 for an
%    empty variable, and also initialize global variable to [].  This function
%    help you tell whether such variables have been initialized.)
%
% See also exist, gexist (Matlab Version 6 and later), which, isempty.

eval(['global ' arg]);
gexist_x = exist(arg, 'var');

if (gexist_x)
  if (str2num(sub(version, 1:2)) >= 5 & eval(['isempty(' arg ')']))
    gexist_x = 0;
  end
end
