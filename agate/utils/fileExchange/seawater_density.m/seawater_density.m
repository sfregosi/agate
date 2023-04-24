function [rho,rhodif] = seawater_density(S,T,p)
% _____________________________________________
% This function computes the seawater density (kg/m3).
% Inputs:
%    S = practical salinity (psu).
%    T = temperature (ºC).
%    p = pressure (bars).
% Outputs:
%    rho = seawater density (kg/m3).
%    rhodif = seawater density difference (kg/m3).
%
% Reference:
% Gill, A. (1983). Atmosphere-Ocean Dynamics. International 
%   Geophysics Series, Vol. 30, Academic Press. 
%   US:California. 645 p.
%
% Gabriel Ruiz
% Jan, 2021
% _______________________________________________

narginchk(1,3);

% Density of pure water as a function of the temperature (kg/m3)
% water salinity = 0 ppt
rhow = 999.842594 + (6.793952E-2 .* T) - (9.095290E-3.* T.^2) + ...
        (1.001685E-4 .* T.^3) - (1.120083E-6 .* T.^4) + (6.536332E-9 .* T.^5);
 
% Water density (kg/m3) at one standard atmosphere, p = 0. 
rhost0 = rhow + (S .* (0.824493 - (4.0899E-3 .* T) + (7.6438E-5 .* T.^2) - ...
           (8.2467E-7 .* T.^3) + (5.3875E-9 .* T.^4))) + ( S.^(3/2) .* ...
           (-5.72466E-3 + (1.0227E-4 .* T) - (1.6546E-6 .* T.^2))) + ...
           ( 4.8314E-4 .* S.^2);

% Water pure secant bulk modulus
kw = 19652.21 + (148.4206 .* T) - (2.327105 .* T.^2) + ...
    (1.360477E-2 .* T.^3) - (5.155288E-5 .* T.^4);

% Water secant bulk modulus at one standard atmosphere (p = 0)
kst0 = kw + (S .* (54.6746 - (0.603459 .* T) + (1.09987E-2 .* T.^2) -...
     (6.1670E-5 .* T.^3))) + (S .^(3/2) .* (7.944E-2 + (1.6483E-2 .* T) -...
     (5.3009E-4 .* T.^2)));
 
% Water secant bulk modulus at pressure values, p
kstp = kst0 +...
       (p.*(3.239908 + (1.43713E-3 .* T) + (1.16092E-4 .* T.^2) -(5.77905E-7.* T.^3))) +...
       ((p.*S) .*(2.2838E-3 - (1.0981E-5 .* T) - (1.6078E-6 .* T.^2))) +...
       (1.91075E-4 .* p .* S.^(3/2)) + ...
       (p.^2 .* (8.50935E-5 - (6.12293E-6 .* T) + (5.2787E-8 .* T.^2))) +...
       ((p.^2.*S) .* (-9.9348E-7 + (2.0816E-8 .* T) + (9.1697E-10 .* T.^2)));

% Water density at any pressure (kg/m3)
rho = rhost0./(1-(p./kstp));

% Water density difference (kg/m3)
rhodif = rho - 1000;

return
