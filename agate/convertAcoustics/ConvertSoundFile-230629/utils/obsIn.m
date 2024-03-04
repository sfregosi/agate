% [data, startTime] = obsIn( filename, runLengthInBlocks )
%
% This example program reads and calibrates data from a clean OBS file.
%
% INPUTS
%    filename:            The file to read from
%    runLengthInBlocks:   The amount of data to read 
% OUTPUTS
%    data:                The calibrated data
%    startTime:           The time in ms from Jan 1, 1970
%
% Author:         Brian Ellis
% Created:        2/24/03
% Last Modified:  2/24/03
%
%          Marine Physical Laboratory
%      Scripps Institution of Oceanography
function [data, startTime] = readOBS( filename, runLengthInBlocks )

% Some constants
NSAMPLES = 128;
SAMPLESIZE = 2;
HEADERSIZE = 32;

% File ID
fid = fopen( filename, 'r', 'b' );

% Read in the header
startBytes = fread(fid,4,'uint8');
startTime = fread(fid,1,'uint32');
fs = 2 ^ fread(fid,1,'ubit4');
nch = fread(fid,1,'ubit4');
id = fread(fid,1,'ubit8');
pag = fread(fid,6,'ubit4');
empty = fread(fid,1,'uint8');
fgc = fread(fid,18,'uint8');

% Calculate the blocksize
blocksize = NSAMPLES * nch * SAMPLESIZE + HEADERSIZE;

% Figure out how much data there is going to be so that Matlab doesn't % spend days resizing its arrays as they grow
filesize = getfield( dir(filename), 'bytes' );
numBlocks = fix( filesize / blocksize );
numSamplesPerChannel = numBlocks * NSAMPLES;
if( nargin < 2 )  % Default to whole file
   runLengthInBlocks = numBlocks - 1;
end
numSamplesPerChannel = (runLengthInBlocks-1) * NSAMPLES;

data = zeros( nch, numSamplesPerChannel );

for iter = 1:runLengthInBlocks
   % Read in the data
   d = fread( fid, NSAMPLES*nch, 'uint16' );
   d = reshape( d - 2^15, nch , NSAMPLES );

   % Apply PreAmp Gains
   d = d .* ((2.^(9-pag(1:nch)))*ones(1,NSAMPLES));
   
   % Read in a header
   dummy = fread(fid,10,'uint8');
   pag = fread(fid,6,'ubit4');
   dummy = fread(fid,1,'uint8');
   fgc = fread(fid,18,'uint8');

   % Apply Flow Gain Controls
   gain = ones(nch,NSAMPLES);    % gen gain matrix
   gainloc = reshape(fgc,6,3);   % gain change locations
   for i = 1:nch
   	gainlocold = 0;
   	for j = 3:-1:1
   		if gainloc(i,j) ~= 0 & gainlocold == 0
   			gain(i,gainloc(i,j):128) = 2^(2*j);
   			gainlocold = gainloc(i,j);
   		elseif gainloc(i,j) ~=0 & gainlocold ~= 0
   			gain(i,gainloc(i,j):gainlocold-1) = 2^(2*j);
   			gainlocold = gainloc(i,j);
   		end
   	end
   end
   d = d .* gain;
   
   data(:, ((iter-1)*NSAMPLES+1):(iter*NSAMPLES) ) = d;
end
