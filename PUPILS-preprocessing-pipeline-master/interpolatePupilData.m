function [data_out,info_interp] = interpolatePupilData(data, info, options)
% This function reads the information about events in the data frame and
% linearly interpolates the selected data points.

tmp = data;

%% Check options and define interpolation region

if ~(isfield(options, 'pre_blink_t'))
    s_pre_blink = 50e-3; % Recomendation from Winn et al. 2018 for eyetracking data interpolation
else
    s_pre_blink = options.pre_blink_t*1e-3;
end

if ~(isfield(options, 'post_blink_t'))
    s_post_blink = 150e-3;
else
    s_post_blink = options.post_blink_t*1e-3;
end

if ~(isfield(options, 'fs'))
    error('Could not find a value for sampling frequency. Please include definition of fs in the options structure')
else
    fs = options.fs;
end

samps_pre_blink = ceil(s_pre_blink *fs);
samps_post_blink = ceil(s_post_blink *fs);


%% Interpolation of missing values


new_column = size(tmp, 2) +1;
blink_column = size(tmp, 2) -2;
saccade_column = size(tmp, 2)-1;
fixation_column = size(tmp, 2);

tmp(:, new_column) = data(:, 4);  % assign original pupils diameter values to a new column of the dataframe
used_saccades = [];



    %% Saccadic distortions:
    
    % If saccadic movements (without blinks) need to be interpolated:
    if isfield(options, 'interpolate_saccades')
        if options.interpolate_saccades % Activated?
            
            % Check for pre and post interpolation times:
            
            if ~(isfield(options, 'pre_sacc_t'))
                s_pre_saccade = 50e-3; % Recomendation from Winn et al. 2018 for eyetracking data interpolation
            else
                s_pre_saccade = options.pre_sacc_t*1e-3;
            end
            
            if ~(isfield(options, 'post_sacc_t'))
                s_post_saccade = 150e-3;
            else
                s_post_saccade = options.post_sacc_t*1e-3;
            end
            
            % Define pre and post saccade times in samples
            samps_post_sacc= ceil(s_post_saccade *fs);
            samps_pre_sacc = ceil(s_pre_saccade *fs);
            
%             %Saccades with no blinks:
            saccades_noblinks = setdiff(1:info.number_of_saccades,used_saccades);
%             

% saccades_noblinks = 1:info.number_of_saccades;

            if ~isempty(saccades_noblinks) % if there actally are saccades with no blinks.
                for sacc_nb_idx = 1:length(saccades_noblinks)
                    % Select non-blink saccades:
                    sacc_num = saccades_noblinks(sacc_nb_idx );
                    
                    sacc_nb_all_idx  = find(tmp(:, saccade_column)== sacc_num);
                    
                    if sacc_nb_all_idx > 50 % min duration 100 ms
                        % Define interpolation region:
                        
                        duration_samples = length(sacc_nb_all_idx);
                        sacc_safe_duration = duration_samples + samps_post_sacc + samps_pre_sacc;
                        sacc_safe_region = sacc_nb_all_idx(1)-samps_pre_sacc:sacc_nb_all_idx(end)+samps_post_sacc;
                        
                        % Interpolate:
                        
                        if sacc_nb_all_idx(1) <= samps_pre_sacc % Correction for starting saccades that cannot be interpolated
                            
                            tmp(1:sacc_nb_all_idx(end), new_column) = tmp(sacc_nb_all_idx(end)+1, new_column); % equalize to the fisrt available value
                            
                        elseif sacc_nb_all_idx(end) >= length(tmp)-samps_post_sacc %If data ends in blink, use the last available value as "truth"
                            tmp(sacc_nb_all_idx(1):end, new_column) = tmp(sacc_nb_all_idx(1), new_column);
                            break; % If the dataframe is reduced, no more saccades need to be checked
                            
                        else
                            ps_pre = tmp(sacc_nb_all_idx(1)-1, new_column); % Last measured pupil size
                            ps_post =  tmp(sacc_nb_all_idx(end)+1, new_column); % First measured pupil size
                            
                            tmp(sacc_safe_region, new_column) = interp1([sacc_nb_all_idx(1)-samps_pre_sacc-1 sacc_nb_all_idx(end)+samps_post_sacc], [ps_pre ps_post], sacc_safe_region); % Linear interpolation
                            
                        end % End interpolation cases
                    end % Minimum length of saccades check
                end % End loop over saccades with no blinks
            end % No saccades
        end % ACtive saccade interpolation
    end % ENd saccade interpolation
    
    
    % % For each blink
for bk_idx = 1:info.number_of_blinks
    
    blnk_start = info.blink_starts_idx(bk_idx);
    blnk_end = info.blink_ends_idx(bk_idx);
    duration_samples = blnk_end - blnk_start + 1;
    
    safe_duration = duration_samples + samps_post_blink + samps_pre_blink;
    
    if safe_duration >= length(tmp) % When the entire recording is empty ("blink")
        
        tmp(:, new_column) =NaN;
        break;
    else
        
        blink_safe_region = blnk_start-samps_pre_blink:blnk_end+samps_post_blink;
        
        if tmp(blnk_start, saccade_column) ~= 0 %if its within a saccade
            sacc_num = tmp(blnk_start, saccade_column);
            sacc_idx  = find(tmp(:, saccade_column)== sacc_num);
            used_saccades = [used_saccades sacc_num];
            
            
            sacc_idx_full_region = (sacc_idx(1)-samps_pre_blink):sacc_idx(end)+samps_post_blink;
            
            
            if length(sacc_idx_full_region ) < length( blink_safe_region ) 
                sacc_idx_full_region = blink_safe_region;  % in case that the saccade is shorter that the blink
            end
            
            if sacc_idx(1) <= samps_pre_blink +1 % Correction for starting saccades that cannot be interpolated
                
                tmp(1:sacc_idx_full_region(end), new_column) = tmp(sacc_idx_full_region(end)+1, new_column); % equalize to the fisrt available value
                
            elseif sacc_idx_full_region(end) >= length(tmp)-samps_post_blink %If data ends in blink, use the last available value as "truth"
                tmp(sacc_idx_full_region(1):end, new_column) = tmp(sacc_idx_full_region(1), new_column);
                break; % If the dataframe is reduced, no more blinks need to be checked
                
            else
                
                ps_pre = tmp(sacc_idx_full_region(1)-1, new_column); % Last measured pupil size
                
                % Check that the future sample is not within a blink
                
                if tmp(sacc_idx_full_region(end)+1, saccade_column) == 0 && tmp(sacc_idx_full_region(end)+1, blink_column) == 0
                    ps_post =  tmp(sacc_idx_full_region(end)+1, new_column); % First measured pupil size
                    
                else
                    % Get first point out of the blink & saccade:
                    idx_post_blink =  find(tmp(sacc_idx_full_region(end)+1:end, saccade_column)==0 & tmp(sacc_idx_full_region(end)+1:end, blink_column)==0);
                    
                    if ~isempty(idx_post_blink) % if the next blink is not the last one
                        ps_post =  tmp(sacc_idx_full_region(end)+1+idx_post_blink(1), new_column); % First measured pupil size
                    else %
                        ps_post = [];
                    end
                    
                end
                
                if ~isempty(ps_post) % if the next blink is not the last one
tmp(sacc_idx_full_region, new_column) = interp1([sacc_idx_full_region(1)-1 sacc_idx_full_region(end)], [ps_pre ps_post], sacc_idx_full_region); % Linear interpolation
                else
                    tmp(sacc_idx_full_region(1):end, new_column) = tmp(sacc_idx_full_region(1), new_column);
                    
                    
                end
            end
        else
            
            if blnk_start <= samps_pre_blink +1 % Starting blink
                
                tmp(1:blink_safe_region(end), new_column) = tmp(blink_safe_region(end)+1, new_column); % equalize to the fisrt available value
                
            elseif blnk_end >= length(tmp)-samps_post_blink  % If data ends in blink, use last true value until ending
                tmp(blink_safe_region(1):end, new_column) = tmp(blink_safe_region(1), new_column);
                break; %
            else
                ps_pre = tmp(blnk_start-1-samps_pre_blink,  new_column); % Last measured pupil size
                
                if tmp(blink_safe_region(end)+1, saccade_column) == 0 & tmp(blink_safe_region(end)+1, blink_column) == 0
                    ps_post =  tmp(blink_safe_region(end)+1, new_column); % First measured pupil size
                    
                else
                    % Get first point out of the blink & saccade:
                    idx_post_blink =  find(tmp(blink_safe_region(end)+1:end, saccade_column)==0 & tmp(blink_safe_region(end)+1:end, saccade_column)==0);
                    
                    
                    if ~isempty(idx_post_blink) % if the next blink is not the last one
                        ps_post =  tmp(blink_safe_region(end)+idx_post_blink(1), new_column); % First measured pupil size
                    else %
                        ps_post = [];
                    end
                    
                    
                    
                    
                end
                
                %saftey check for NaN:
                if isnan(ps_post)
                    non_nan_idx = find(~isnan(tmp(blnk_end:blnk_end+1+samps_post_blink-2, new_column)));
                    ps_post = tmp(blnk_end+non_nan_idx(end)-1,  new_column);
                    samps_post_blink = non_nan_idx(end)-1;
                end
                
                
                if ~isempty(ps_post) % if the next blink is not the last one
                    tmp(blink_safe_region, new_column) = interp1([blnk_start-samps_pre_blink-1 blnk_end+samps_post_blink], [ps_pre ps_post], blink_safe_region); % Linear interpolation
                else
                    tmp(blink_safe_region(1):end, new_column) = tmp(blink_safe_region(1), new_column);
                end
                    
                end
            end % End blink type (inside or outside saccade)
        end % End safety check for empty recordings
    end % End loop over blinks
    
    
    %% Calculate % of interpolated data:
    interp_perc = 100*(size(find(tmp(:, 4) ~= tmp(:, new_column)), 1)/length(tmp));
    blink_perc = 100*(size(find(tmp(:, blink_column) ~= 0), 1)/length(tmp));
    sacc_perc = 100*(size(find(tmp(:, saccade_column) ~= 0), 1)/length(tmp));
    fix_perc = 100*(size(find(tmp(:, fixation_column) ~= 0), 1)/length(tmp));
    
    data_out = tmp;
    
    info_interp.percentage_interpolated = interp_perc;
    info_interp.percentage_blinks = blink_perc;
    info_interp.percentage_saccades = sacc_perc;
    info_interp.percentage_fixations = fix_perc;
    
end %% EOF

