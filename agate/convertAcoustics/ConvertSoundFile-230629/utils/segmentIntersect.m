function int = segmentIntersect(s0, s1)
%segIntersect	find the intersection of two segments on the number line
%
% intersection = segmentIntersect(s0, s1)
%   Find the intersection of two segments on the number line. s0 and s1 are each
%   2-element vectors [start stop], or one or both can be Nx2 arrays; if both
%   are Nx2, they have to be the same size. The return value is a 2-element row
%   vector with the span of overlap, or if at least one of the args is an Nx2
%   array, then it's Nx2.
%
%   If the intersection region is empty, then the value returned has start
%   greater than stop.

int = [...
  max(min(s0, [], 2), min(s1, [], 2)) ...
  min(max(s0, [], 2), max(s1, [], 2))    ];
