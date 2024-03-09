function y = mapcar(fun, x)
%mapcar		Evaluate a function on each member of an array.
%
% y = mapcar(fun, x)
%   Apply the function fun to each member of the array x.  If x is a cell 
%   array, fun is applied to each member x{i}, with the result put in the 
%   cell y{i}.  If x is any other kind of array, fun is applied to each
%   member x(i), with the result (again) put into the cell y{i}.  So in
%   all cases, the return value y is a cell array the same size as x.
%   To remove the cell-ness of y, you can use reshape([y{:}], size(x)).
%
%   fun must be a function that takes one argument.  It can be either an
%   anonymous function (see 'help function_handle') or a handle to a
%   named function.
%
%   Examples:
%      mapcar(@(x)x^2, {1 2 3})    ==>  {1 4 9}        (a cell array)
%      mapcar(@uminus, [0 -2 4 -6])  ==>  {0 2 -4 6}   (also a cell array!)
%
%
% mapcar is apparently the same at Matlab's 'cellfun' function, except that 
% cellfun returns numeric arrays by default, while mapcar returns cell arrays.
%
% Dave Mellinger
% June 2007

y = cell(size(x));
for i = 1 : numel(x)
  if (iscell(x))
    y{i} = fun(x{i});
  else
    y{i} = fun(x(i));
  end
end
