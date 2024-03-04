function [ept,yr,jd,hr,mn,sc,samprate,t,y]=readCF2hdr(FILE,datayes) 

% Examples 
%[ept,yr,jd,hr,mn,sc,samplerate]=readH3hdr('/dateDir/00000728.DAT',0); %return start time of file.
%[ept,yr,jd,hr,mn,sc,samplerate, t,y]=readH3hdr(''/dateDir/00000728.DAT',1);  % return start time and data.
% 
% OUTPUT 
% file start times from header 
% ept is unix time since 1970 
% yr, jd, hr, min, sc of start time 
% samprate from header (approx) 
% t= dummy time axis for plottting 
% y = time series in counts
% 
% MODIFIED
% Sept. 16th, 2013.
%
% Note that t and samprate are approximate. 
% to get real sample rate difference file start times



fid2=fopen(FILE,'r','b');
%
st2= fseek(fid2, 90, 'bof' );
t1 = fread(fid2, 64,'*char');  % GMT.
%
st2= fseek(fid2,196, 'bof'  );
samprate = fread(fid2,  1,'*long'); % Sample Rate. 

% Decode the GMT.
yr = str2num(t1(1:3)')+1900; 
jd = str2num(t1(5:7)');
hr = str2num(t1(9:10)');
mn = str2num(t1(12:13)');
sc = str2num(t1(15:16)') + ( str2num(t1(18:21)')/1000 );

ept=24*60*60*(datenum(yr,1,jd,hr,mn,sc)- datenum(1970,1,1,0,0,0));
%%%%%%%%%%%%%%

if datayes > 0
fid=fopen(FILE,'r','b');
st =fseek(fid,256,'bof');
y  =fread(fid,inf,'uint16'); 
fclose(fid)
s  = 1/double( samprate )
t  = ept: s : (ept+((length(y)-1)*s)); 
y  = y-mean(y); 
%plot(t,y);

else
t=[];
y=[];
end

fclose(fid2);

