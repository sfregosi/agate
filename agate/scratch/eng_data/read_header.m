% 
% Copyright (c) 2006-2011 by University of Washington.  All rights reserved.
%
% This file contains proprietary information and remains the 
% unpublished property of the University of Washington. Use, disclosure,
% or reproduction is prohibited.

% Returns the header information as a structre from
% a v65 log or eng file.  Also returns the open file
% pointer to allow for reading beginning at the file
% contents.
%
% [hdr, fp] = reasd_header(filename)

function [hdr, fp] = read_header(file)

   fp = fopen(file, 'r');
   if fp == -1
      hdr = struct([]);
      return;
   end

   while 1,
      line = fgetl(fp);
      if line == -1
          break;
      end

      line = strtok(line, '%'); % strip leading % sign if any

      [tag, value] = strread(line, '%s%s', 'delimiter', ':');
     
      if isempty(tag) | isempty(value)
          break;
      end

      v = char(value);
      h = char(tag);

      i = find(',' == v);  
      if isempty(i)
          eval (['hdr.' h ' = str2num(v);']);
      else
          [tmp, remainder] = strtok(value, ',');
            
          ii = 0;
          values = [];
          while ~isempty(remainder{1}) & ~isempty(tmp{1})
              ii = ii + 1;
              values{ii} = char(tmp);
              [tmp, remainder] = strtok(remainder, ',');
          end

	  if length(tmp) > 0
              values{ii + 1} = char(tmp);
          end 

          h = char(tag);
          eval (['hdr.' h ' = values;']);
 
      end
   end

   if isfield(hdr, 'start')
      hdr.start(3) = hdr.start(3) + 1900;
   end

   return;
