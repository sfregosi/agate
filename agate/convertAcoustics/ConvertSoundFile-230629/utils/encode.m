function y = encode(x, radix, nplaces)
%ENCODE         Convert numbers from one base to another.
%
% y = encode(x, radix)
%     Return a vector with elements equal to the digits of x written as
%     a number of base radix.  For instance, to see the number 17 written
%     in base 2, use
%    
%           y = encode(17, 2);
%     
%     Input argument x may be a vector, in which case rows of the return 
%     value y correspond to successive elements of x.
%    
%     If radix is a vector, then this function operates somewhat like APL's 
%     encode operator, converting by a different radix at each position.  For
%     instance, to convert seconds to days, hours, minutes, and seconds, use
%    
%           y = encode(x, [24 60 60])
%    
%     To convert inches to miles, yards, feet, and inches, use
%    
%           y = encode(x, [1760 3 12])
% 
% y = encode(x, radix, nplaces)
%     As above, but return a vector y that has as many leading zeros as 
%     necessary to make it nplaces elements long.  This works only when
%     radix is a scalar.

x = x(:);
if (length(radix) <= 1)
  if (nargin <= 2)
    nplaces = floor(log(max(abs(x))) / log(radix)) + 1;
  end
  radix = radix * ones(1, nplaces - 1);
end

p = fliplr(cumprod(fliplr(radix)));

% If I had a brain left tonight there wouldn't be a loop here.
y = zeros(length(x), length(radix) + 1);
for i = 1:length(x)
  y(i,:) = floor([x(i), mod(x(i), p)] ./ [p, 1]);
end
