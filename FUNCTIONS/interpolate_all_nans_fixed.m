function [out, interp_mask] = interpolate_all_nans_fixed(data)
% INTERPOLATE_ALL_NANS Linearly interpolates all NaN gaps in a vector.
% Handles edge cases safely:
%   - If all values are NaN: replace with 9999.
%   - If NaNs are at edges: fill with nearest non-NaN value.
%
%   [out, interp_mask] = interpolate_all_nans(data)
%
%   INPUT:
%       data - column or row vector (double) with NaNs
%
%   OUTPUT:
%       out         - same size as input, with interpolations
%       interp_mask - binary mask, 1 = interpolated/replaced, 0 = untouched

    safe_flank = 200;              % preferred flank size
    n = numel(data);
    out = data;                     
    interp_mask = zeros(size(data));
    isn = isnan(data);

    % ---- Case 1: everything is NaN ----
    if all(isn)
        out(:) = 9999;
        interp_mask(:) = 1;
        return;
    end
    
    % Find contiguous NaN segments
    d = diff([0; isn(:); 0]);
    start_idx = find(d == 1);      % segment starts
    end_idx   = find(d == -1) - 1; % segment ends
    
    for k = 1:numel(start_idx)
        s = start_idx(k);
        e = end_idx(k);
        
        % Determine usable left flank
        avail_left = s-1;
        flank_left = min(safe_flank, avail_left);
        if flank_left > 0
            left_vals = data(s-flank_left:s-1);
            left_vals = left_vals(~isnan(left_vals));
        else
            left_vals = [];
        end
        
        % Determine usable right flank
        avail_right = n-e;
        flank_right = min(safe_flank, avail_right);
        if flank_right > 0
            right_vals = data(e+1:e+flank_right);
            right_vals = right_vals(~isnan(right_vals));
        else
            right_vals = [];
        end
        
        % Anchor values
        if isempty(left_vals)
            left_anchor_idx = find(~isnan(data(1:s-1)),1,'last');
            if isempty(left_anchor_idx)
                % No non-NaN to the left -> use right anchor
                left_anchor_idx = s-1;
                left_anchor_val = [];
            else
                left_anchor_val = data(left_anchor_idx);
            end
        else
            left_anchor_idx = s-1;
            left_anchor_val = mean(left_vals);
        end
        
        if isempty(right_vals)
            right_anchor_idx = find(~isnan(data(e+1:end)),1,'first');
            if isempty(right_anchor_idx)
                % No non-NaN to the right -> use left anchor
                right_anchor_idx = e+1;
                right_anchor_val = [];
            else
                right_anchor_idx = right_anchor_idx + e;
                right_anchor_val = data(right_anchor_idx);
            end
        else
            right_anchor_idx = e+1;
            right_anchor_val = mean(right_vals);
        end
        
        % ---- Edge cases ----
        if isempty(left_anchor_val) && ~isempty(right_anchor_val)
            % Only right anchor available -> fill with that
            out(s:e) = right_anchor_val;
        elseif isempty(right_anchor_val) && ~isempty(left_anchor_val)
            % Only left anchor available -> fill with that
            out(s:e) = left_anchor_val;
        else
            % Normal case: interpolate
            out(s:e) = interp1([left_anchor_idx, right_anchor_idx], ...
                               [left_anchor_val, right_anchor_val], ...
                               s:e);
        end
        
        % Mark mask
        interp_mask(s:e) = 1;
    end
end