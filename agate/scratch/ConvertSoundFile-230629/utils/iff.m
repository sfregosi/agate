function result = iff(predicate, trueValue, falseValue)
% y = IFF(predicate, trueValue, falseValue)
% Return trueValue if the predicate is non-zero, falseValue if it's zero.
% This is like the ?: operator in C, but without short-circuit evaulation.
%
% If predicate, trueValue, and falseValue are all vectors or matrices of
% the same size, then the operation is done element-wise: The return value
% has elements of trueValue where at positions where predicate is true,
% and elements of falseValue elsewhere.

if (length(predicate) > 1 & samesize(predicate, trueValue, falseValue))
  result = zeros(size(trueValue));
  lPred = logical(predicate);
  result( lPred) =  trueValue( lPred);
  result(~lPred) = falseValue(~lPred);
else
  if (predicate),
    result = trueValue;
  else
    result = falseValue;
  end
end
