function [condition1 condition2, all_trials1 all_trials2] = plot_diff_conditions(folderPath, row_nr)

% Get a list of all .mat files in the folder
files = dir(fullfile(folderPath, '*.mat'));

all_trials_odd_hi = [];
all_trials_nodd_hi = [];
all_trials_odd_lo = [];
all_trials_nodd_lo = [];

cnt = 1; % counter
for k = 1:length(files)

    fullFilePath = fullfile(folderPath, files(k).name);  % Full path to the file
    disp(['Loading: ', fullFilePath])
    
    load(fullFilePath);  % Load the .mat file into a struct

    % temp trials is a logical defining the trial which fit our condition
    oddball_strengthhi = logical(info_con.usable) & logical(info_con.isStrengthHi) & logical(~info_con.isoddball);
    nonoddball_strengthhi = logical(info_con.usable) & logical(info_con.isStrengthHi) & logical(info_con.isoddball);
    oddball_strengthlo = logical(info_con.usable) & logical(~info_con.isStrengthHi) & logical(~info_con.isoddball);
    nonoddball_strengthlo = logical(info_con.usable) & logical(~info_con.isStrengthHi) & logical(info_con.isoddball);

    disp(['trials in oddball_strengthhi: ', num2str(sum(oddball_strengthhi))]);
    disp(['trials in nonoddball_strengthhi: ', num2str(sum(nonoddball_strengthhi))]);
    disp(['trials in oddball_strengthlo: ', num2str(sum(oddball_strengthlo))]);
    disp(['trials in nonoddball_strengthlo: ', num2str(sum(nonoddball_strengthlo))]);

    % baselining 0 - 3000 ms (grip phase)
    for t = 1:length(data_con.trial)
        data = data_con.trial{1, t}(row_nr,:);        
        baseline = mean(data(1, 1:3000));   % compute baseline for each column
        data_con.trial{1, t}(row_nr,:) = data - baseline; % subtract baseline
    end
    
    %%% for plotting:
    selected_trials_odd_hi = data_con.trial(oddball_strengthhi);
    selected_trials_nodd_hi = data_con.trial(nonoddball_strengthhi);
    selected_trials_odd_lo = data_con.trial(oddball_strengthlo);
    selected_trials_nodd_lo = data_con.trial(nonoddball_strengthlo);

    % cellfun extract trials
    extracted_rows_odd_hi = cellfun(@(x) x(row_nr, :), selected_trials_odd_hi, 'UniformOutput', false);
    extracted_rows_nodd_hi = cellfun(@(x) x(row_nr, :), selected_trials_nodd_hi, 'UniformOutput', false);
    extracted_rows_odd_lo = cellfun(@(x) x(row_nr, :), selected_trials_odd_lo, 'UniformOutput', false);
    extracted_rows_nodd_lo = cellfun(@(x) x(row_nr, :), selected_trials_nodd_lo, 'UniformOutput', false);

    % Concatenate rows
    temp_all_trial_odd_hi= vertcat(extracted_rows_odd_hi{:});
    temp_all_trial_nodd_hi = vertcat(extracted_rows_nodd_hi{:});
    temp_all_trial_odd_lo= vertcat(extracted_rows_odd_lo{:});
    temp_all_trial_nodd_lo = vertcat(extracted_rows_nodd_lo{:});

    all_trials_odd_hi = vertcat(all_trials_odd_hi, temp_all_trial_odd_hi);
    all_trials_nodd_hi = vertcat(all_trials_nodd_hi, temp_all_trial_nodd_hi);
    all_trials_odd_lo = vertcat(all_trials_odd_lo, temp_all_trial_odd_lo);
    all_trials_nodd_lo = vertcat(all_trials_nodd_lo, temp_all_trial_nodd_lo);
    %%% %%% %%%

    cnt = cnt+1; %countervariable
end

% % average oddball wave per strength
% avg_oddball_hi = mean(all_trials_odd_hi, 1);
% avg_oddball_lo = mean(all_trials_odd_lo, 1);
% 
% all_trials_oddbdiff_hi = all_trials_nodd_hi - avg_oddball_hi;
% all_trials_oddbdiff_lo = all_trials_nodd_lo - avg_oddball_lo;

amt_data_hi = height(all_trials_odd_hi);
amt_data_lo = height(all_trials_odd_lo);
all_trials_oddbdiff_hi = all_trials_nodd_hi(1:amt_data_hi, :) - all_trials_odd_hi;
all_trials_oddbdiff_lo = all_trials_nodd_lo(1:amt_data_lo, :) - all_trials_odd_lo;


%%%%%%%%%%%%%%%%%% PLOTTING

% Compute mean and SEM across trials
n1 = size(all_trials_oddbdiff_hi, 1);
n2 = size(all_trials_oddbdiff_lo, 1);

mean1 = mean(all_trials_oddbdiff_hi, 1);
sem1  = std(all_trials_oddbdiff_hi, [], 1) / sqrt(n1);

mean2 = mean(all_trials_oddbdiff_lo, 1);
sem2  = std(all_trials_oddbdiff_lo, [], 1) / sqrt(n2);

% Time 
t = 1:size(all_trials_oddbdiff_hi, 2);

% Plot
figure; hold on;

% Shaded SEM area for condition 1
fill([t fliplr(t)], [mean1+sem1 fliplr(mean1-sem1)], ...
     [0.2 0.6 1], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

% Shaded SEM area for condition 2
fill([t fliplr(t)], [mean2+sem2 fliplr(mean2-sem2)], ...
     [1 0.4 0.4], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

% Mean lines
plot(t, mean1, 'Color', [0 0.3 0.8], 'LineWidth', 1.8);
plot(t, mean2, 'Color', [0.8 0 0],   'LineWidth', 1.8);

% Add vertical dashed lines
stim1_onset = 3700; % stimulus onset
stim2_onset = 3700 + 600; % stimulus onset (second stimulus)
resp_wind_onset = 3700 + 600 + 350;     % appearance of answer window

xline(stim1_onset, '--k', 'LineWidth', 1.5);
xline(stim2_onset, '--k', 'LineWidth', 1.5);   % black dashed line
xline(resp_wind_onset, '--k', 'LineWidth', 1.5);

% labels and stuff 
xlabel('time (ms)');
ylabel('delta Noddball-oddball');
title(['Nonoddball-oddball (Mean ± SEM) per strength']);
legend({'Cond 1 ± SEM','Cond 2 ± SEM'}, 'Location','best');
grid on; box off;

