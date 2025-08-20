function [data_out, info_fixations] = generateFixationInfo(data, options)
% This function parses the input dataframe , finding the saccade information and 
% using it to define the fixation regions. Finally it computes metadata
% about fixation regions. Note that here a fixation is defined as every
% region within two saccades.


if ~(isfield(options, 'fs'))
    error('Could not find a value for sampling frequency. Please include definition of fs in the options structure')
else
    fs = options.fs;
end

tmp = data;

N = length(tmp);
T= N/fs;
t = 0:(1/fs):T-(1/fs);



sacc_column = size(tmp, 2);

% Find regions that meet criterion:
fix_idx = find(tmp(:, sacc_column) == 0);



if isempty(fix_idx)
    
    disp('No fixations were detected')
    info_fixations.number_of_fixations = 0;
    
    % Return dataframe with no saccades index:
        new_column = size(tmp, 2) +1;
    tmp(:, new_column) = zeros(length(tmp),1);    
    data_out = tmp; 
else
    
    
% Extract fixations starts and ends:
fix_idx_starts = [fix_idx(1); fix_idx(find(diff(fix_idx) ~= 1) + 1)] ;
fix_idx_ends = [fix_idx(find(diff(fix_idx) ~= 1)); fix_idx(end)];
    
    
% time in ms
fix_t_starts = t(1, fix_idx_starts)';
fix_t_ends = t(1, fix_idx_ends)';

% Calculate durations:
fixation_durations = fix_t_ends-fix_t_starts;

% Get time stamps:
fix_ts_starts = tmp(fix_idx_starts, 1);
fix_ts_ends = tmp(fix_idx_ends, 1);


    %% Save outputs
    
    info_fixations.number_of_fixations = length(fixation_durations);
    info_fixations.fixation_starts_stamps =  fix_ts_starts;
    info_fixations.fixation_starts_idx = fix_idx_starts;
    info_fixations.fixation_starts_s = fix_t_starts;
    info_fixations.fixation_ends_stamps =  fix_ts_ends;
    info_fixations.fixation_ends_idx = fix_idx_ends;
    info_fixations.fixation_ends_s = fix_t_ends;
    info_fixations.total_fixation_duration = sum(fixation_durations);
    info_fixations.mean_fixation_duration = mean(fixation_durations);
    info_fixations.fixation_durations = fixation_durations;
    
    
%% Append saccade information to dataframe:
    
    new_column = size(tmp, 2) +1;
    
    tmp(:, new_column) = zeros(length(tmp),1);
    
    for fx_i = 1:info_fixations.number_of_fixations
        
        duration_samples = fix_idx_ends(fx_i) - fix_idx_starts(fx_i) + 1;
        tmp(fix_idx_starts(fx_i):(fix_idx_ends(fx_i)), new_column ) = fx_i*ones(1,duration_samples);
        
    end
    
    data_out = tmp;
end % End if exists fixations
end % EOF

