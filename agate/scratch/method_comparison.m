% convert WISPR comparison

fname = 'D:\sg639_CalCurCEAS_Sep2024_raw_acoustic_data\SG639_Fall24_card2\241021\WISPR_241021_004352.dat';
path_out = 'C:\Users\selene.fregosi\Desktop\wispr_convert_test\method_comparison';
% header data
% % WISPR 3.0
% sensor_id = 'WISPR3_no4';
% platform_id = 'SG639';
% version = 'v1.3.0';
% file_size = 70291;
% buffer_size = 23040;
% samples_per_buffer = 7680;
% sample_size = 3;
% sampling_rate = 200000;
% adc_type = 'LTC2512';
% adc_vref = 5.000000;
% adc_df = 4;
% gain = 0;
% second = 1729471432.267800;
% timestamp = 0;


% C. Jones/Haru method
% C:\Users\selene.fregosi\Documents\MATLAB\agate\agate\convertAcoustics\fixWispr
% read_wispr_file

[nrd1, hdr1, data1, time] = read_wispr_file(fname, 1, 0);
% immediately breaks because WISPR3 has different header entries


% Dave method
%C:\Users\selene.fregosi\Documents\MATLAB\agate\agate\scratch\ConvertSoundFile-230629
% convertDir which uses soundIn and audioWrite. soundIn calls wisprIn

[x,r] = soundIn(fname, 0, inf, NaN);
% also immediately breaks because now WISPR3 time header entry

[sound,nChan,~,sRate,left,dt] = wisprIn(fname, 0, inf, NaN);
% error that dt (Date/time) output arg is not populated
% manually set dt to 0 at top of wisprIn function to test and that worked
% then write it
	nOutputBits = 24;
audiowrite(fullfile(path_out, 'test_dkm.flac'), sound / 2^(nOutputBits-1), ...
    sRate, 'BitsPerSample', nOutputBits);





% % WISPR 2.0
% time = '05:04:23:20:45:37';
% instrument_id = 'WISPR';
% location_id = 'HWSG';
% volts = 14.78;
% blocks_free = 99.74;
% version = 0.2;
% file_size = 63261;
% buffer_size = 16896;
% samples_per_buffer = 5632;
% sample_size = 3;
% sampling_rate = 180000;
% gain = 0;
% decimation = 4;
% adc_vref = 5.000000;