function [data_out] = denoisePupilData(data, info, options)
% This function applies a low pass filter to the piupil data in order to
% reduce noisiness

%% Check options:
if ~(isfield(options, 'fs'))
    error('Could not find a value for sampling frequency. Please include definition of fs in the options structure')
else
    fs = options.fs;
end

if ~(isfield(options, 'low_pass_fc'))
    fc = 10; % defaults
else
    fc = options.low_pass_fc;
end

%% De-noise:

tmp = data;
new_column = size(tmp, 2) +1;

if info.percentage_interpolated < 50
    
    [b,a] = butter(4,fc/(fs/2));
    tmp(:, new_column) = filtfilt(b, a, tmp(:, new_column-1)); % zero-phase filtering, to avoid time lag
    
else
    
    warning('Too much missing data for lowpass filtering - data output was not denoised')
    tmp(:, new_column) = tmp(:, new_column-1 );
end

data_out = tmp;


end % EOF

