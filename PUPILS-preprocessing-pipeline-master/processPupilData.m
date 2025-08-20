function [data_out, info] = processPupilData(data, options)
% processPupilData is the main function of the PUPILS preprocessing
% pipeline, it calls the different event detection algorithms and producess
% a dataframe with event information and interpolated data. 
%
% Inputs:
%  - data     :   dataframe (samples x categories) minimum dataframe should
%                 include [time stamps, x-coordinate, y-coordinate,
%                 pupilsize] in that order. In addition, x and y velocity
%                 values might be included.
%  - options  :   structure defining the options for the event detection
%                 algorithms, missing data interpolation and noise removal. 
%
% Outputs:
%  - data_out :   dataframe that contains the original data with appended
%                 information, in the following order: [blink information,
%                 saccade information, interpolated data, denoised data]
% 
%  - info     :   structure containing metadata regarding events and
%                 quality of the pre-processed data
%
% ----------------------------------------------------------------------- %
%% Check that data stamps are equally spaced

if ~checkSampleSpacing(data)
    error('Time samples are not equally spaced - Check your data for missing samples')
end


%% Check options and define default values
if nargin == 1 % Defaults
      
options.fs = 500;               % sampling frequency (Hz)
options.vel_threshold =  30;    % velocity threshold for saccade detection
options.pre_blink_t   = 100;    % region to interpolate before blink (ms)
options.post_blink_t  = 200;    % region to interpolate after blink (ms)
options.low_pass_fc   = 10;    % Low-pass filter cut-off frequency (Hz)      
options.min_sacc_duration = 10; % Minimum saccade duration in (ms)
options.xy_units = 'px';        % Input units for the x-y coordinates (pixels)
warning('No processing options were definded. The pipeline will work with default values only');

end

info = initializeInformationStructure();


%% Event detections

% Blinks
[data_out info_blinks] = detectBlinks(data, options);

 bf = fieldnames(info_blinks); % Add metadata to main info structure
 for i = 1:length(bf)
    info.(bf{i}) = info_blinks.(bf{i});
 end
 

% Sacaddes

[data_out info_saccades] = detectSaccades(data_out, options);

sf = fieldnames(info_saccades);

 for i = 1:length(sf)
         info.(sf{i}) = info_saccades.(sf{i});
 end
 
 
 
 % Fixations

[data_out info_fixations] = generateFixationInfo(data_out, options);

sf = fieldnames(info_fixations);

 for i = 1:length(sf)
         info.(sf{i}) = info_fixations.(sf{i});
 end
 
%% Data interpolation

[data_out info_interp] = interpolatePupilData(data_out, info, options); 

intf = fieldnames(info_interp);

 for i = 1:length(intf)
         info.(intf{i}) = info_interp.(intf{i});
 end
 
 
%% De-noising

data_out = denoisePupilData(data_out, info, options);

end

