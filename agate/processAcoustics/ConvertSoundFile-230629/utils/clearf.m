function clearf
%CLEARF		Like clf/clg, but does not complain like MATLAB 5.0 does.

if (version4)
  clg
else
  clf
end
