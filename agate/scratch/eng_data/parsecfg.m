% 
% Copyright (c) 2006-2011 by University of Washington.  All rights reserved.
%
% This file contains proprietary information and remains the 
% unpublished property of the University of Washington. Use, disclosure,
% or reproduction is prohibited.

% reads a v64 or v65 eng file to return the software version
% and sensors in a version independent manner.  
%
% [version, sensors] = parsecfg(eng_filename)
%
% sensors will be a cell array of strings on return.
% For v64 this will be the sensor names. For v65 it will
% actually be the column names
%

function [version, sensors] = parsecfg(eng_file)
   fid = fopen(eng_file, 'r');
   s = fgetl(fid);
   fclose(fid);

   if strncmp(s, '%version:', 8) == 1
      [hdr, fid] = read_header(eng_file);
      fclose(fid);
      version = hdr.version;
      sensors = hdr.columns; 
   else

      [version, remain] = strtok(s, ',');
      version = str2num(version);

      if length(version) > 1 | length(remain) == 0
         version = 63;
         sensors{1} = 'TCM2/80';
         sensors{2} = 'CT';
         sensors{3} = 'SBE43';
         sensors{4} = 'BB2F';
      else 
         i = 1;
         while length(remain) > 0
            [sensors{i}, remain] = strtok(remain, ',');
            i = i + 1;
         end
         version = 64;
      end
   end
