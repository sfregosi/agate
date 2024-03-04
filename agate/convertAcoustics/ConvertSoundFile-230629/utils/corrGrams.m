function c = corrGrams(g1,g2)
%corrGrams      Cross-correlate two (normalized) spectrograms in time.
%
%c = corrGrams(g1,g2)

if (nRows(g1) ~= nRows(g2))
  error('Number of rows in the two grams must be the same.  g1=%d, g2=%d',...
    nRows(g1), nRows(g2));
end

m = zeros(nRows(g1), 0);
for i = 1 : nRows(g1)
  tmp = corr(g1(i,:), g2(i,:));
  m(i, 1:length(tmp)) = tmp;
end

c = sum(m, 1);
