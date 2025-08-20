function [out, interp_mask] = interpolate_short_nans(data)
% INTERPOLATE_SHORT_NANS Linearly interpolates short NaN gaps in a vector.
%
%   [out, interp_mask] = interpolate_short_nans(data)
%
%   INPUT:
%       data - column or row vector (double) with NaNs
%
%   OUTPUT:
%       out         - same size as input, with interpolations
%       interp_mask - binary mask, 1 = interpolated, 0 = untouched

    % Parameters
    max_gap    = 1000;  % maximum NaN gap length to interpolate
    safe_flank = 200;   % required non-NaN samples before and after gap
    
    out = data;                      % copy input
    interp_mask = zeros(size(data)); % mask of interpolated samples
    
    isn = isnan(data);
    
    % Find contiguous NaN segments
    d = diff([0; isn(:); 0]);
    start_idx = find(d == 1);       % segment starts
    end_idx   = find(d == -1) - 1;  % segment ends
    
    for k = 1:numel(start_idx)
        s = start_idx(k);
        e = end_idx(k);
        gap_len = e - s + 1;
        
        % Check conditions
        if gap_len <= max_gap && ...
           s - safe_flank >= 1 && ...
           e + safe_flank <= numel(data) && ...
           all(~isnan(data(s-safe_flank:s-1))) && ...
           all(~isnan(data(e+1:e+safe_flank)))
       
            % Use the average of the safe flank regions instead of immediate neighbors
            left_anchor_val  = mean(data(s-safe_flank:s-1));
            right_anchor_val = mean(data(e+1:e+safe_flank));
            
            % Anchor indices (just outside the gap)
            left_anchor_idx  = s - 1;
            right_anchor_idx = e + 1;
            
            % Interpolate linearly across the gap
            out(s:e) = interp1([left_anchor_idx, right_anchor_idx], ...
                               [left_anchor_val, right_anchor_val], ...
                               s:e);
            
            % Mark mask
            interp_mask(s:e) = 1;
        end
    end
end