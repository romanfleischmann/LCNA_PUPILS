function [info] = initializeInformationStructure()

% This function initializes the information structure that will be used to
% output the event and quality information after the pupil recording has
% been processed.

% Initialize info structure with fields:
info = struct();
info.number_of_blinks = [];
info.blink_starts_stamps = [];
info.blink_starts_idx = [];
info.blink_starts_s = [];
info.blink_ends_stamps = [];
info.blink_ends_idx = [];
info.blink_ends_s = [];
info.blink_durations = [];
info.total_blink_duration = [];
info.mean_blink_duration = [];
info.number_of_saccades = [];
info.saccade_starts_stamps = [];
info.saccade_starts_idx = [];
info.saccade_starts_s = [];
info.saccade_ends_stamps = [];
info.saccade_ends_idx = [];
info.saccade_ends_s = [];
info.total_saccade_duration = [];
info.mean_saccade_duration = [];
info.saccade_durations = [];

info.number_of_fixations = [];
info.fixation_starts_stamps = [];
info.fixation_starts_idx = [];
info.fixation_starts_s = [];
info.fixation_ends_stamps = [];
info.fixation_ends_idx = [];
info.fixation_ends_s = [];
info.total_fixation_duration = [];
info.mean_fixation_duration = [];
info.fixation_durations = [];

info.percentage_interpolated = [];
info.percentage_blinks = [];
info.percentage_saccades = [];
info.percentage_fixations = [];

end

