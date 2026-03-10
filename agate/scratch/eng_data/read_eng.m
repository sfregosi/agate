% 
% Copyright (c) 2006-2012 by University of Washington.  All rights reserved.
%
% This file contains proprietary information and remains the 
% unpublished property of the University of Washington. Use, disclosure,
% or reproduction is prohibited.

%*********************************************************
% Read Seaglider v64 and v65+ *.eng file.
%
% For v65+ assumes *.eng has an arbitrary number of header lines, all 
% marked by a leading '%', followed by N lines of data (M columns wide).
% Expects a 'columns' tag followed by M comma-delimited strings.
% Each of these strings identifies a column of data. These
% strings are used as identifiers for the data in the returned
% 'eng' structure.
% Structure 'eng' will have elements:
% - <tag name> corresponding to each tag:value header line pair
% - data elements tagged with the strings taken from 'columns'

function [eng] = read_eng(eng_file)
  
  [version, sensors] = parsecfg(eng_file);
  
  data = load(eng_file);
  
  if version < 65
    
    eng.version = 64;
    eng.start = zeros(1, 6);
    eng.columns = sensors;
    % BUG: if this is really early (<64)
    % elaps_t is column 1
    column = 0; % for original code, this should be 0
    eng.elaps_t   = data(:,column + 2);
    eng.condFreq = data(:,column + 3);
    eng.tempFreq = data(:,column + 4);
    eng.depth  = data(:,column + 5);
    eng.head = data(:,column + 6);
    eng.pitchAng = data(:,column + 7);
    eng.rollAng = data(:,column + 8);
    eng.pitchCtl = data(:,column + 9);
    eng.rollCtl = data(:,column + 10);
    eng.vbdCC = data(:,column + 11);
    
    column = 12;
    for k = 3:length(sensors)
      if strcmp(sensors{k}, 'SBE43') == 1
        eng.o2_freq = data(:,column);
        column = column + 1;
      elseif strcmp(sensors{k}, 'BB2F') == 1
        eng.redRef = data(:,column);
        eng.redCount = data(:,column + 1);
        eng.blueRef = data(:,column + 2);
        eng.blueCount = data(:,column + 3);
        eng.fluorCount = data(:,column + 4);
        eng.VFtemp = data(:,column + 5); % not VFTemp
        column = column + 6;
      elseif strcmp(sensors{k}, 'RAFOS') == 1
        column = column + 8;
      elseif strcmp(sensors{k}, 'Optode') == 1
        eng.O2 = data(:,column);
        eng.temp = data(:,column+1);
        eng.dphase = data(:,column+2);
        column = column + 3;
      end
    end
    
  else
    
    [eng,fp] = read_header(eng_file);
    fclose(fp);
    
    [n, m] = size(data);
    if (m ~= length(eng.columns))
      error ('read_eng.m: number of data columns and tags does not match.');
    end
    
    for ii = 1 : m
      s = strrep(eng.columns{ii},'.','_');
      eval(['eng.', s, ' = data(:,ii);']);
      if (0) %DEAD -- used to drop sensor name prefix in sensor.field, now kept as sensor_field
        [s,v] = strtok(eng.columns{ii}, '.');
        if isempty(v)
          eval(['eng.', s, ' = data(:,ii);']);
        else
          eval(['eng.', v(2:end), ' = data(:,ii);']);
        end
      end
    end
    if (isfield(eng,'VFTemp')) % wetlabs
      eng.VFtemp = eng.VFTemp; % capitalization drift.  65.03 spells as VFTemp
    end
    if (isfield(eng,'O2Freq')) % sbe43
      eng.o2_freq = eng.O2Freq; % spelling drift, 66.04++
    end
  end
  if isfield(eng, 'start')
    eng.start_ts_dn = datenum(eng.start(3),eng.start(1),eng.start(2),eng.start(4),eng.start(5),eng.start(6));
    unix_start_dn = datenum([1970, 1, 1, 0, 0, 0]); % for computing secs since unix epoch
    eng.start_ts = (eng.start_ts_dn - unix_start_dn)*86400; % unix epoch seconds
  end
  if isfield(eng, 'depth')
    eng.depth = eng.depth / 100.0;
  end
  