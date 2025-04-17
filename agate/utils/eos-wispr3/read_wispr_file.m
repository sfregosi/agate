function [hdr, data, time, stamp] = read_wispr_file(name, first, last)
%
% matlab script to read wispr data from a dat file
%
% A data file consists of an ascii file header followed by binary data
% buffers. The ascii header is formatted as matlab expressions. 
% The binary data words are formatted as signed 16 or 24 bit integers.
%
% The data file format is:
% - 512 byte ascii header.
% - adc buffer 1
% - adc buffer 2
% ...
% - adc buffer N
% where N is the number of adc buffers per file
%
% The number of adc buffers is defined as 
% number_buffers = file_size*512 / buffer_size;
%
% The total data file size is always a multiple of 512 bytes blocks. 
% The variable 'file_size' is the number of 512 blocks in the file.
%
% Each adc buffer is of length 'buffer_size' bytes.
% The adc buffer is always a multiple of 512 bytes blocks (32 blocks in most cases). 
% Each adc buffer contains a fixed number of sample (samples_per_buffer).
% Each sample is of fixed size in bytes (sample_size).
% The sample size can be 2 or 3.
% If 3 byte samples are used, there will be extra bytes of padded at the end of each adc buffer.
% The number of bytes of padding is defined as:
% padding_per_buffer = buffer_size - (samples_per_buffer * sample_size);
%
% File header info is returned in hdr
% Data and time are returned as a matrix of size [samples_per_buffer, (last - first)] 
%

fp = fopen( name, 'r', 'ieee-le' );

% back compatability
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

% read and eval the ascii header lines
for n = 1:18
    str = fgets(fp); % read full line
    % read ascii lines until a null is found, so header buffer must be null terminated
    if( str(1) == 0 )
        break;
    end
    %fprintf('%s', str);
    eval(str);
end

if(sample_size == 2)
    q = adc_vref/32767.0;  % 16 bit scaling to volts
    fmt = 'int16';
elseif(sample_size == 3)
    q = adc_vref/8388608.0;  % 24 bit scaling to volts
    fmt = 'bit24';
elseif(sample_size == 4)
    q = adc_vref/2147483648.0;  % 32 bit scaling to volts
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
hdr.time = time; % back compatability
hdr.second = second;
hdr.usec = usec;
hdr.sensor_id = sensor_id;
hdr.platform_id = platform_id;
hdr.instrument_id = instrument_id;
hdr.location_id = location_id;
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

% number of buffer to read and concatenate
num_bufs = last - first + 1;

for n = 1:num_bufs

    % read a data buffer
    raw = fread(fp, samples_per_buffer, fmt ); % data block
    if( length(raw) ~= samples_per_buffer )
        break;
    end

    % read buffer timestamp, which is time the buffer finished, 
    % so remove the buffer duration
    if( timestamp == 8 )   
        s = fread(fp, 1, 'uint32' ); % epoch second 
        us = fread(fp, 1, 'uint32' );
        stamp(n) = (s + 0.000001 * us) - duration; 
    elseif( timestamp == 6 )
        s = fread(fp, 1, 'uint16' ); % secs from start of file
        us = fread(fp, 1, 'uint32' ); 
        stamp(n) = ((second + s) + 0.000001 * us) - duration; 
    else
        stamp(n) = t0 + (n-1) * duration;
    end

    % read padding, if any
    junk = fread(fp, padding_per_buffer, 'char');

    % add raw data buffer as a column to data matrix
    data(:,n) = double(raw)*q;

    % add a time column to the time matrix
    time(:,n) = stamp(n) + dt*(0:(samples_per_buffer-1));
    
end

fclose(fp);

return;

