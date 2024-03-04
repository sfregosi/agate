function y = bitreverse(x, nbits)
%BITREVERSE	Reverse the bits of a number.
%
% y = bitreverse(x, nbits)
%   
%   Returns the binary number y = dcba (base 2),
%   where                     x = abcd (base 2)
%   and n is the number of bits in x and y (4 in this case).

% Since we need another dimension and x might already be 2-dimensional, have to
% make x into a vector first, then later reshape y back to x's original shape.
%
shape = size(x);
x = x(:)';		% make row vector


z = 2 .^ (0:nbits)' * ones(1,length(x));
bits = diff(rem(ones(nbits+1, 1) * x, z)) ~= 0;
y = reshape(sum(z(1:nbits,:) .* flipud(bits)), shape);
