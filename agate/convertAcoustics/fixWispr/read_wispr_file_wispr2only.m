function [count, hdr, data, time] = read_wispr_file(name, start, num_bufs)
%
% matlab script to read the specified number of data buffers between 'start' and 'start+num_bufs'.
% Each buffer is size 'buffer_size' byte long.
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
%Spectral energy is corrected for the type of window function used for time
%series. H.M. 6/21/2021
%

%clear all;

%[file, dpath, filterindex] = uigetfile('G:/*.dat', 'Pick a data file');
%name = fullfile(dpath,file);

fp = fopen( name, 'r', 'ieee-le' );

% read and eval the ascii header lines
for n = 1:15
    str = fgets(fp, 64); % read 64 chars max in each line
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
    q = 1.0;
    fmt = 'int32';
end

% remove fixed gain specified in the file header
gain_factor = bitshift(1,gain);
q = q / gain_factor;

% The total number of adc buffers in the file
total_number_buffers = file_size*512 / buffer_size;

% The number of bytes of padding after each adc buffer, if any
padding_per_buffer = buffer_size - (samples_per_buffer * sample_size);

if(start == 0) 
    start = 1;
end

if(num_bufs == 0)
    num_bufs = total_number_buffers;
end

hdr.time = time;
%hdr.second = second;
%hdr.usec = usec;
hdr.instrument_id = instrument_id;
hdr.location_id = location_id;
hdr.version = 2.0;
hdr.volts = volts;
hdr.file_size = file_size;
hdr.buffer_size = buffer_size;
hdr.samples_per_buffer = samples_per_buffer;
hdr.sample_size = sample_size;
hdr.sampling_rate = sampling_rate;
hdr.gain = gain;
%hdr.adc_type = adc_type;
hdr.adc_vref = adc_vref;
hdr.adc_df = decimation;
hdr.free = blocks_free;
    
% seek to the start of data
% header is always 512 bytes
fseek(fp, 512 + buffer_size * (start-1), -1);

dt = 1.0 / sampling_rate;
t0 = (start - 1) * samples_per_buffer * dt;

time = t0 * ones(samples_per_buffer, num_bufs);
data = zeros(samples_per_buffer, num_bufs);

count = 0;

if(start >= total_number_buffers) 
    fclose(fp);
    return;
end

for n = 1:num_bufs

    % read a data buffer
    raw = fread(fp, samples_per_buffer, fmt ); % data block
    if( length(raw) ~= samples_per_buffer )
        break;
    end
    
    % read padding, if any
    junk = fread(fp, padding_per_buffer, 'char');

    % add raw data buffer as a column
    data(:,n) = double(raw)*q;
    dt = 1.0 / sampling_rate;
    time(:,n) = t0 + (1:length(raw)) * dt;
    t0 = time(end,n);

    duration = samples_per_buffer * dt;

    count = count + 1;

end

fclose(fp);

return;

