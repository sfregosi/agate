

addpath(genpath('C:\Users\selene\OneDrive\MATLAB\gliderTools\'));
addpath(genpath('C:\Users\selene\Box\HDR-SOCAL-2018\piloting\SeagliderPilotingTools_1.3.R3\Matlab\'));
addpath(genpath('C:\Users\selene\OneDrive\MATLAB\myFunctions\'));

DiveData

% ****** SG607 ********
downloadScript_SoCal_2020_sg607
close([450 451 452]);

% ****** SG639 ********
% downloadScript_SoCal_2020_sg639
% close([450 451 452]);

% Speed calcs
dtgt = 990;
tdive = 400;
wd = (2*dtgt*100)/(tdive*60)

wd = 7;
dtgt = 600;
tdive = (2*dtgt*100)/(60*wd)

% 990/470 = 7. actual 
% 500/240 = 7. actual ~
% 700/330 = 7. actual ~
% 600/280 = 7

% 990/360 wd is 9.1
% 800/290 wd is 9.2
% 600/220 wd is 9.0
% 400/150 wd is 8.9
% 300/110 wd is 9.1

% 990/400 = 8.25. actual ~340. speeds 9-14 
% 800/320 = 8.25. actual ~
% 700/280 = 8.25. actual ~
% 500/200 = 8.25. actual ~
% 300/120 = 8.25. actual ~

dAngle = 20;
vSpeed = 10;
stw = vSpeed/sin((dAngle*pi)/180)

%% Current progress
currgbFree = 272;
currTotalDistance = 614;

% Major waypoints
dive1 = datenum(2020, 02, 07, 15, 20, 00);
dive12 = datenum(2020, 02, 09, 07, 30, 00); %WPo2
dive27 = datenum(2020, 02, 11, 11, 44, 00); %WPo3
dive79 = datenum(2020, 02, 23, 07, 30, 00); %WPo4
dive111 = datenum(2020, 03, 02, 01, 34, 00); %WPo5
dive135 = datenum(2020, 03, 07, 09, 45, 00); % reached WPo6
dive156 = datenum(2020, 03, 12, 13, 10, 00); % reached WPoj
dive165 = datenum(2020, 03, 14, 17, 30, 00); % reached WPok
currDive = dive165;

% avg speed over ground whole deployment
currTotalDistance/(currDive-dive1)
% avg speed over ground for each stretch. 
WPo2sog= 23.7/(dive12-dive1) % 14.16
WPo3sog = 36/(dive27-dive12) % 16.5
WPo4sog = 200/(dive79-dive27) % 16.9
WPo5sog = 115/(dive111-dive79) % 14.8
WPo6sog = 110/(dive135-dive111) % 20.6
WPoksog = 130/(dive165-dive135) % 17.7

% space use per day and per km whole deployment
gbDay = (1000 - currgbFree)/(currDive-dive1) % 20.2 gb/day
gbkm = (1000-currgbFree)/currTotalDistance % 1.2 gb/km

% space use over last stretch
gbDayS = (419 - currgbFree)/(currDive - dive135) % 20 gb/day
gbkmS = (419 - currgbFree)/(currTotalDistance - 483) % 1.1 gb/km



% power usage - PLENTY
ampHrDay = 68/(dive135-dive1)
ampHrKm = 68/483

%% FORWARD CALCULATIONS

daysToNext = 220/17 % how many days from WPo6 to WP07
datestr(dive135 + daysToNext) 
daysToNext*gbDayS % gb used to next
220*gbkmS
gbLeftNext = 419 - daysToNext*gbDayS - 25 % subtract 25 bc 95% cut off. 

daysToWPx1 = 33/17
datestr(dive165 + daysToWPx1)
daysToWPx1*gbDayS
33*gbkmS
gbLeft = 272 - daysToWPx1*gbDayS - 25

daysToWPol = (33+38)/17
datestr(dive165 + daysToWPol)
daysToWPol*gbDayS
(33+38)*gbkmS
gbLeft = 272 - daysToWPol*gbDayS - 25

daysToWPx2 = (33+38+30)/17
datestr(dive165 + daysToWPx2)
daysToWPx2*gbDayS
(33+38+30)*gbkmS
gbLeft = 272 - daysToWPx2*gbDayS - 25

daysToWPo7 = (33+38+30+30)/17
datestr(dive165 + daysToWPo7)
daysToWPo7*gbDayS
(33+38+30+30)*gbkmS
gbLeft = 272 - daysToWPo7*gbDayS - 25

daysToWPo8 = (33+38+30+30+26+34)/17
datestr(dive165 + daysToWPo8)
daysToWPo8*gbDayS
(33+38+30+30+26+34)*gbkmS
gbLeft = 272 - daysToWPo8*gbDayS - 25




daysToWPo8 = (220 + 58)/17
datestr(dive135 + daysToWPo8)
daysToWPo8*gbDayS
gbLeftWPo8 = 419 - daysToWPo8*gbDayS - 25

daysToRec = (220 + 58 + 30)/17
datestr(dive135 + daysToRec)
daysToRec*gbDayS
gbLeftRec = 419 - daysToRec*gbDayS - 25

% KM To work with??
gbLeftWPo8/gbkmS




%% plotting mamps over time
figure;
yyaxis left
plot(pp607.diveStartTime,pp607.PMAR_MAMPS, '.')
ylabel('MAMPS')
xlabel('date')
vline(pp607.diveStartTime(115))
yyaxis right
% plot(pp607.diveStartTime, pp607.diveDur, 'b.')
plot(pp607.diveStartTime, -pp607.D_TGT, '+')
ylabel('D TGT')
