function [data_out, info_saccades] = detectSaccades(data, options)
% This function parses the input dataframe and detects saccades - defined as
% samples where the angular velocity is higher than the predefined
% thresholds.If velocity is not provided in the input structure, it will be
% calculated and appended to the data frame.

if ~(isfield(options, 'fs'))
    error('Could not find a value for sampling frequency. Please include definition of fs in the options structure')
else
    fs = options.fs;
end

if ~(isfield(options, 'vel_threshold'))
    vel_threshold = 30;
else
    vel_threshold = options.vel_threshold;
end

if ~(isfield(options, 'min_sacc_duration'))
    min_sacc_duration = 10;
else
    min_sacc_duration = options.min_sacc_duration;
end

if ~(isfield(options, 'xy_units'))
    xy_units = 'px';
    
else
    xy_units = options.xy_units;
end


%% Check that there is velocity information in the data
tmp = data;

if size(tmp,2 ) ~= 7
    if ~isfield(options, 'screen_distance') || ~isfield(options, 'dpi')
        
        warning('Velocity values were not found and could not be estimated. No saccade information will be provided. Have you included distance from screen and dpi information in options?') % For now.
        new_column = size(tmp, 2) +1;
        tmp(:, new_column) = zeros(length(tmp),1);
        data_out = tmp;
        info_saccades.number_of_saccades = 0;
        
        
    else
        
        screen_distance = options.screen_distance; % Screen distance in mm
        dpi = options.dpi; % pixels/inches
        
        
        if strcmp(xy_units, 'px') % xy units are in pixels
            
            % Transform to mm
            mm_to_inch = 25.4; % 1 inch = 25.4 mm
            
            x_coord =  tmp(:, 2).*(mm_to_inch/options.dpi);
            y_coord =  tmp(:, 3).*(mm_to_inch/options.dpi);
            z_coord = screen_distance;
            
        elseif strcmp(xy_units, 'mm') % xy units are in pixels
            
            x_coord =  tmp(:, 2);
            y_coord =  tmp(:, 3);
            z_coord = screen_distance;
            
        elseif strcmp(xy_units, 'cm')
            % Transform to mm
            x_coord =  tmp(:, 2).*10;
            y_coord =  tmp(:, 3).*10;
            z_coord = screen_distance;
            
        else
            error('Please specify units for the x-y coordinates ("px"/"mm"/"cm")');
        end
        
        
        % calculate angular velocity
        angle(1:5)= 0; % BUffer of samples needed to calculate angular velocity
        
        for k = 6:length(tmp)
            
            P = [x_coord(k) y_coord(k) z_coord]; % See Duchowsky (2003)
            Q = [x_coord(k-5) y_coord(k-5) z_coord];
            vect(k) = sum(P.*Q);
            modul(k) = sqrt(sum(P.^2))*sqrt(sum(Q.^2));
            angle(k) = real(acosd(vect(k)/modul(k)));
            
        end
        
        v = angle'.* (1/(5/fs)); % velocity
        
        tmp(:, 6) = data(:, 5); % Move blink information
        tmp(:, 5) = v;
        
    end
    
elseif size(tmp, 2) == 7 % when both x-velocity and y-velocity are available
    v = max(abs(tmp(:, 5)), abs(tmp(:, 6))); % use the maximum velocity (i.e., if any of them is above threshold it will be classified as a saccade)
end

%% Define time vector:

N = length(tmp);
T= N/fs;
t = 0:(1/fs):T-(1/fs);

%% Find samples that meet saccade criterion

sacc_idx = [find(abs(v) > vel_threshold); find(isnan(v))];
sacc_idx = sort(sacc_idx);

if isempty(sacc_idx)
    
    disp('No saccades were detected')
    info_saccades.number_of_saccades = 0;
    
    % Return dataframe with no saccades index:
        new_column = size(tmp, 2) +1;
    tmp(:, new_column) = zeros(length(tmp),1);    
    data_out = tmp; 
else
    
    % Extract saccade starts and ends:
    sacc_idx_starts = [sacc_idx(1); sacc_idx(find(diff(sacc_idx) ~= 1) + 1)] ;
    sacc_idx_ends = [sacc_idx(find(diff(sacc_idx) ~= 1)); sacc_idx(end)];
    
    % time in ms
    sacc_t_starts = t(1, sacc_idx_starts)';
    sacc_t_ends = t(1, sacc_idx_ends)';
    
    % Remove saccades shorter than minimum duration
    
    tmp_saccade_durations = sacc_t_ends-sacc_t_starts;
    
    remove_idx = find( tmp_saccade_durations < min_sacc_duration*1e-3);
    
    if exist('remove_idx', 'var') % If there are saccades to remove
        % recalculate sacc durations after removal:
        sacc_idx_starts(remove_idx, :) = [];
        sacc_idx_ends(remove_idx, :) = [];
        sacc_t_starts(remove_idx, :) = [];
        sacc_t_ends(remove_idx, :) = [];
        
        saccade_durations = sacc_t_ends-sacc_t_starts;
        
    else
        saccade_durations = tmp_saccade_durations;
    end
    
    % Get time stamps:
    sacc_ts_starts = tmp(sacc_idx_starts, 1);
    sacc_ts_ends = tmp(sacc_idx_ends, 1);
    
    %% Save outputs
    
    info_saccades.number_of_saccades = length(saccade_durations);
    
    info_saccades.saccade_starts_stamps =  sacc_ts_starts;
    info_saccades.saccade_starts_idx = sacc_idx_starts;
    info_saccades.saccade_starts_s = sacc_t_starts;
    info_saccades.saccade_ends_stamps =  sacc_ts_ends;
    info_saccades.saccade_ends_idx = sacc_idx_ends;
    info_saccades.saccade_ends_s = sacc_t_ends;
    info_saccades.total_saccade_duration = sum(saccade_durations);
    info_saccades.mean_saccade_duration = mean(saccade_durations);
    info_saccades.saccade_durations = saccade_durations;
    
    %% Append saccade information to dataframe:
    
    new_column = size(tmp, 2) +1;
    
    tmp(:, new_column) = zeros(length(tmp),1);
    
    for sc_i = 1:info_saccades.number_of_saccades
        
        duration_samples = sacc_idx_ends(sc_i) - sacc_idx_starts(sc_i) + 1;
        tmp(sacc_idx_starts(sc_i):(sacc_idx_ends(sc_i)), new_column ) = sc_i*ones(1,duration_samples);
        
    end
    
    data_out = tmp;
    
end

end % EOF