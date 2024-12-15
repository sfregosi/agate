function [hdr, data, time, stamp, hdrStrs] = read_wispr_file_agate(name, first, last)
%READ_WISPR_FILE_AGATE   read in a raw WISPR .dat file
%
%   Syntax:
%      [HDR, DATA, TIME, STAMP, HDRSTRS] = READ_WISPR_FILE_AGATE(NAME, FIRST, LAST)
%
%   Description:
%       
%       A data file consists of an ascii file header followed by binary 
%       data buffers. The ascii header is formatted as matlab expressions. 
%       The binary data words are formatted as signed 16 or 24 bit 
%       integers.
%
%       The data file format is:
%          - 512 byte ascii header.
%          - adc buffer 1
%          - adc buffer 2
%            ...
%          - adc buffer N
%       where N is the number of adc buffers per file
%
%       The number of adc buffers is defined as 
%       number_buffers = file_size*512 / buffer_size;
%
%       The total data file size is always a multiple of 512 bytes blocks.
%       The variable 'file_size' is the number of 512 blocks in the file.
%
%       Each adc buffer is of length 'buffer_size' bytes.
%       The adc buffer is always a multiple of 512 bytes blocks (32 blocks 
%       in most cases).Each adc buffer contains a fixed number of sample 
%       (samples_per_buffer). Each sample is of fixed size in bytes 
%       (sample_size). The sample size can be 2 or 3.
%       If 3 byte samples are used, there will be extra bytes of padded at 
%       the end of each adc buffer.
%       The number of bytes of padding is defined as:
%       padding_per_buffer = buffer_size - (samples_per_buffer*sample_size);
%
%   Inputs:
%       name    [string] fullpath filename to raw .dat file
%       first   [integer] buffer to start reading at. Set to 0 to just 
%               read the header. Set to 1 to start at the beginning.
%       last    [integer] buffer to read to. Set to 0 to read the entire 
%               file
%
%   Outputs:
%       hdr     [struct] header information
%       data    [double] sound data
%       time    [double] count of time from 0
%       stamp   [double] time in linux epoch time
%       hdrStrs [cell array] header lines as a string
%
%   Examples: 
%       % read in single file from start to finish
%       inFile = 'C:\wispr_241010_121418.dat';
%       [hdr, raw, time, timestamp, hdrStrs] = read_wispr_file_agate(inFile, 1, 0);
%
%   See also CONVERTWISPR
%
%   Authors:
%       Chris Jones, Embedded Ocean Systems
%       S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%   Updated:        13 December 2024
%
%	Created with MATLAB ver.: 24.2.0.2740171 (R2024b) Update 1
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fp = fopen( name, 'r', 'ieee-le' );

% back compatability
wisprVersion = '';	 %#ok<NASGU>  might get overridden below
instrument_id = [];
location_id = [];
sensor_id = [];
platform_id = [];
timestamp = 0;
time = [];
second = 0;
usec = 0;
adc_type = 'LTC2512';
adc_df = [];
decimation = [];
channels = 1;
version = [];

% read and eval the ascii header lines - put into a str and cell array
% hdrCell = {};
% first line with wispr ver is a comment so doesn't get evaluated but still
% want to parse that info
ln1 = fgets(fp);
[wisprVersion,nScan] = sscanf(ln1, '%% WISPR %s');		%#ok<ASGLU>
hdrStrs = {strip(ln1)};
if (nScan ~= 1)
    fprintf(1, 'Something weird with WISPR ver read. Exiting\n');
    return
end

% use eval on the remaining lines
for n = 1:18
    %str = fgets(fp, 64); % read 64 chars max in each line
    str = fgets(fp); % read full line
    % read ascii lines until a null is found, so header buffer must be null terminated
    if( str(1) == 0 )
        break;
    end
    %fprintf('%s', str);
    eval(str);
    hdrStrs = [hdrStrs; {strip(str)}];
end

if(sample_size == 2)
    q = adc_vref/32767.0;  % 16 bit scaling to volts
    fmt = 'int16';
elseif(sample_size == 3)
    q = adc_vref/8388608.0;  % 24 bit scaling to volts
    fmt = 'bit24';
elseif(sample_size == 4)
    q = 1.0;
    fmt = 'int32';
end

% The number of adc buffers in the file
number_buffers = file_size*512 / buffer_size;

% The number of bytes of padding after each adc buffer, if any
padding_per_buffer = buffer_size - timestamp - (samples_per_buffer * sample_size);

% buffer duration in secs
dt = 1.0 / sampling_rate;
duration = samples_per_buffer * dt;

% fill the header structure
hdr.wisprVersion = wisprVersion;
hdr.time = time; % back compatability
hdr.second = second;
hdr.usec = usec;
hdr.sensor_id = sensor_id;
hdr.platform_id = platform_id;
hdr.instrument_id = instrument_id;
hdr.location_id = location_id;
hdr.version = version;
hdr.file_size = file_size;
hdr.buffer_size = buffer_size;
hdr.samples_per_buffer = samples_per_buffer;
hdr.sample_size = sample_size;
hdr.sampling_rate = sampling_rate;
hdr.channels = channels;
hdr.gain = gain;
hdr.adc_type = adc_type;
hdr.adc_vref = adc_vref;
hdr.adc_df = adc_df;
hdr.decimation = decimation;
hdr.adc_timestamp = timestamp;
hdr.number_buffers = hdr.file_size * 512 / hdr.buffer_size;
hdr.buffer_duration = samples_per_buffer * dt;
hdr.file_duration = hdr.buffer_duration * hdr.number_buffers;

data = [];
time = [];
stamp = [];

% check to make sure first and last are valid
if( first >= number_buffers )
    return;
end

% if first == 0 then just read the header
if(first <= 0)
    return;
end

% read all buffers if last is zero
if(last == 0)
    last = number_buffers;
end

% past end of file
if( last > number_buffers )
    last = number_buffers;
end

% seek to the start of data
% header is always 512 bytes
fseek(fp, 512 + (hdr.buffer_size * (first-1)), -1);

% start time
t0 = (second + usec * 0.000001) + (first - 1)*duration;

% number of buffer to concatenate and plot
num_bufs = last - first + 1;

for n = 1:num_bufs

    % read a data buffer
    raw = fread(fp, samples_per_buffer, fmt ); % data block
    if( length(raw) ~= samples_per_buffer )
        break;
    end

    t0 = t0 + duration;

    % read buffer timestamp, which is time the buffer finished,
    % so remove the buffer duration
    if( timestamp == 8 )
        s = fread(fp, 1, 'uint32' );
        us = fread(fp, 1, 'uint32' );
        stamp(n) = (s + 0.000001 * us) - duration;
    elseif( timestamp == 6 )
        s = fread(fp, 1, 'uint16' );
        us = fread(fp, 1, 'uint32' );
        stamp(n) = ((second + s) + 0.000001 * us) - duration;
        %fprintf('timestamp %d bytes, padding %d bytes, ', timestamp, padding_per_buffer);
        %fprintf('sec = %lu, usec = %d\n', sec, usec);
    else
        stamp(n) = t0;
    end

    % read padding, if any
    junk = fread(fp, padding_per_buffer, 'char');

    % add raw data buffer as a column
    data(:,n) = double(raw)*q;

    time(:,n) = stamp(n) + dt*(0:(samples_per_buffer-1));
    %    time(:,n) = t0 + dt*(0:(samples_per_buffer-1))';

end

fclose(fp);

return;

