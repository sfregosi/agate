function [fList,pList] = dependencies(function_name, arg2)
%dependencies   find code dependencies
%
% [fList,pList] = dependencies('myFun.m'[, 'toponly'])
%    This is just a synonym for matlab.codetools.requiredFilesAndProducts since
%    the latter name is impossible to remember (and doesn't include any form of
%    the word 'dependency').

if (nargin == 1)
  [fList,pList] = matlab.codetools.requiredFilesAndProducts(function_name);
else
  [fList,pList] = matlab.codetools.requiredFilesAndProducts(function_name, arg2);
end
