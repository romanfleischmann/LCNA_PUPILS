function [data_out, info_blinks] = detectBlinks(data, options)
% This function parses the input dataframe and detects blinks
% For blink rule 'std' blinks are defined as samples where a
% pupil size lower than three standard deviations from the mean
% was measured.
% For blink rule 'vel' blinks are defined as those regions where
% the pupil dilation velocity is above a pre-defined threshold
% The function returns the dataframe with appended information about blink areas.


if ~(isfield(options, 'fs'))
    error('Could not find a value for sampling frequency. Please include definition of fs in the options structure')
else
    fs = options.fs;
end

if ~(isfield(options, 'blink_rule'))
    blink_rule = 'vel';
    warning('A blink rule was not defined. Using default optimized velocity threshold')
else
    blink_rule = options.blink_rule;
end

tmp = data;

%% Search for blinks:

if strcmp(blink_rule, 'std') % Dilation size-based blink detection
    
    blink_idx_z = [find(tmp(:, 4) == 0) ; find(isnan(tmp(:, 4)))]; % Find all samples that fit the blink rule
    tmp2=tmp;
    tmp2(blink_idx_z, 4) =NaN;
    
    blink_idx_rule = [find(tmp2(:, 4) <= (nanmean(tmp2(:, 4))-3*nanstd(tmp2(:, 4))))]; % Find all samples that fit the blink rule
    
    blink_idx = sort(unique([blink_idx_z; blink_idx_rule  ]));
    
elseif strcmp(blink_rule, 'vel') % velocity-based blink detection
    %  Calculate dilation velocity:
    
    sample_distance= 5;

dila_v(1:sample_distance)= zeros(1,sample_distance); 
       for k = (sample_distance+1):length(tmp)
                        dila_v(k) = abs((tmp(k, 4) - tmp(k-sample_distance, 4))* (1/(sample_distance/fs)));
       end
       
    
    if (isfield(options, 'blink_v_threshold'))
   
        v_thresh = options.blink_v_threshold; % User-defined dilation velocity threshold
    else
        
    
    % Find optimal threshold:
    
     % Define analysis windows:
    t_win= 0.5; % half a second
    s_win = t_win * fs; % samples
    overlap = 50/100 * t_win;  % 50 per. overlap
    p = overlap * fs;
    
    x= dila_v;
    n = s_win;
    
    windows = buffer(x,n,p);
    
    % Calculate rms for all windows:
    
    rms_dist = rms(windows);
    
    v_thresh = median(rms_dist)*3; % optimal velocity threhold 1.5 * median(rms)
    
    info_blinks.optimal_v_threshold = v_thresh;
    
    end

    % Find blinks:
        blink_idx_z = [find(tmp(:, 4) == 0) ; find(isnan(tmp(:, 4)))]; % Find all samples that fit the blink rule
        blink_idx_rule = [find(dila_v>= v_thresh)]';
 blink_idx = sort(unique([blink_idx_z; blink_idx_rule  ]));
else
    error('Unknown blink detection rule. Please specify "std" or "vel"')
end


%% Format and append blinks:

if isempty(blink_idx)
    
    disp('No blinks were detected')
    info_blinks.number_of_blinks = 0;
    
    new_column = size(tmp, 2) +1;
    tmp(:, new_column) = zeros(length(tmp),1);
    data_out = tmp;
    
else
    
    % Extract blink starts and ends:
    
    blinks_idx_starts = [blink_idx(1); blink_idx(find(diff(blink_idx) ~= 1) + 1)] ;
    blinks_idx_ends = [blink_idx(find(diff(blink_idx) ~= 1)); blink_idx(end)];
    
    % Get time stamps:
    
    blinks_ts_starts = tmp(blinks_idx_starts, 1);
    blinks_ts_ends = tmp(blinks_idx_ends, 1);
    
    % Calculate temporal values:
    
    N = length(tmp);
    T = N/fs;
    t = 0:(1/fs):T-(1/fs); % Define time vector
    
    blinks_t_starts = t(1, blinks_idx_starts);
    blinks_t_ends = t(1, blinks_idx_ends);
    
    %% Save blink information
    
    info_blinks.number_of_blinks = length(blinks_idx_starts);
    

    info_blinks.blink_starts_stamps =  blinks_ts_starts;
    info_blinks.blink_starts_idx = blinks_idx_starts;
    info_blinks.blink_starts_s = blinks_t_starts;
    info_blinks.blink_ends_stamps =  blinks_ts_ends;
    info_blinks.blink_ends_idx = blinks_idx_ends;
    info_blinks.blink_ends_s = blinks_t_ends;
    
    info_blinks.blink_durations = blinks_t_ends - blinks_t_starts;
    info_blinks.total_blink_duration = sum(info_blinks.blink_durations);
    info_blinks.mean_blink_duration = mean(info_blinks.blink_durations);
    
    %% Append blink information to dataframe:
    
    new_column = size(tmp, 2) +1;
    
    tmp(:, new_column) = zeros(length(tmp),1);
    
    for bk_i = 1:info_blinks.number_of_blinks
        
        duration_samples = blinks_idx_ends(bk_i) - blinks_idx_starts(bk_i) + 1;
        tmp(blinks_idx_starts(bk_i):blinks_idx_ends(bk_i) , new_column ) = bk_i*ones(1,duration_samples);
        
    end
    
    data_out = tmp;
    
end

end %% EOF