function abstractError(exampleSubclass)
%abstractError	Generate an error for a method that should be in a subclass
%
% abstractError
%   Print out an error message that says not to create a member of a given
%   class -- that one should create only members of subclasses.  The name
%   of the class is gotten automatically from the environment.  (The class
%   that should not be created is known in c++ as an 'abstract' class, hence
%   the name of this function.)
%
% abstractError(exampleSubclass)
%   Also provide, as part of the error message, an example subclass name
%   so the user can create on of those if needed.

str = '';
if (nargin > 0)
  str = ['like ' exampleSubclass ', '];
end

% Get the names of the class and of the offending function.
stk = dbstack('-completenames');
cls = pathFile(pathDir(stk(2).file));	% get caller's class name
cls = cls(2:end);			% remove '@'
funcname = stk(2).name;

error(['Don''t create ' cls ' objects directly.  Use only subclasses of it,'...
	10 str 'which should implement ' funcname '(...).'])
