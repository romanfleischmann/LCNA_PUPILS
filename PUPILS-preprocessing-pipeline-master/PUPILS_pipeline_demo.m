%  =================================== %
%  PUPILS Pre-processing Pipeline v1.0 %
%  =================================== %

% This script shows an example of how to call the PUPILS preprocessing
% pipeline and define its options, 

load('dummydata_w_velocity.mat');

%% lets try smth:
data(15:78,4) = nan;
data(:,5:6) = [];
%%

options = struct;
options.fs = 500;                 % sampling frequency (Hz)
options.blink_rule = 'vel';       % Rule for blink detection 'std' / 'vel'
% options.pre_blink_t   = 100;      % region to interpolate before blink (ms)
% options.post_blink_t  = 200;      % region to interpolate after blink (ms)
% options.xy_units = 'px';          % xy coordinate units 'px' / 'mm' / 'cm'
% options.vel_threshold =  30;      % velocity threshold for saccade detection
% options.min_sacc_duration = 10;   % minimum saccade duration (ms)
% options.interpolate_saccades = 0; % Specify whether saccadic distortions should be interpolated 1-yes 0-noB
% options.pre_sacc_t   = 50;        % Region to interpolate before saccade (ms)
% options.post_sacc_t  = 100;       % Region to interpolate after saccade (ms)
% options.low_pass_fc   = 10;       % Low-pass filter cut-off frequency (Hz)


[proc_data proc_info] = processPupilData(data, options);

%% Data visualization

info_blinks = sprintf('blink loss: %.2f %%', proc_info.percentage_blinks );
info_sacc = sprintf('saccadic movements: %.2f %%',proc_info.percentage_saccades);
info_interp = sprintf('Interpolated data: %.2f %%',proc_info.percentage_interpolated );

cols = [110 87 115;
        212 93 121;
        234 144 133;
        233 226 208;
        112 108 97]./255;

    fs = options.fs;

N = length(proc_data);
T = N/fs;
t = 0:(1/fs):T-(1/fs); % Define time vector


figure('Position', [100 100 1000 600])

subplot(3,2, [1,3,5])
sacc_col = size(proc_data, 2) - 3; 
sacc_idx = find(proc_data(:,sacc_col) ~=0);

saccades_x = proc_data(sacc_idx , 2);
saccades_y = proc_data(sacc_idx , 3);

fixations_x =  proc_data(:, 2);
fixations_x(sacc_idx) = [];

fixations_y = proc_data(:, 3);
fixations_y(sacc_idx) = [];

scatter(saccades_x, saccades_y, 'o',...
     'markerfacecolor', cols(3, :),...
     'markeredgecolor', cols(3, :),...
     'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.1); 

 hold on
 scatter(fixations_x, fixations_y, 'o',...
     'markerfacecolor', cols(1, :),...
     'markeredgecolor', cols(1, :),...
     'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.1);


le = legend('saccades', 'fixations');
set(le, 'box', 'on', 'location', 'southwest')


title('Gaze')
xlabel('x coordinates (pixels)')
ylabel('y coordinates (pixels)')


subplot(3,2,2)

plot(t, proc_data(:, 4), 'k')
ylims = get(gca, 'YLim');
axis([t(1) t(end) ylims(1) ylims(2)])

title('Original pupil traze')
xlabel('t(s)')
ylabel('Pupil diameter (\mum)')


subplot(3,2,4)

p = plot(t, proc_data(:, 4), 'k');
ylims = get(gca, 'YLim');

height = ylims(2) - ylims(1);

hold on

for i = 1:proc_info.number_of_saccades
    h(i) = rectangle('position', [proc_info.saccade_starts_s(i) ylims(1) proc_info.saccade_durations(i)  height ],...
        'facecolor', [cols(3, :) 0.4],...
        'edgecolor', 'none');
end

for i = 1:proc_info.number_of_blinks
    h2(i) = rectangle('position', [proc_info.blink_starts_s(i) ylims(1) proc_info.blink_durations(i) height ],...
        'facecolor', [cols(5, :) 1],...
        'edgecolor', 'none');
end

axis([t(1) t(end) ylims(1) ylims(2)])

hg = hggroup;
% set(h2,'Parent',hg) 
set(hg,'Displayname','Blinks')
hg2 = hggroup();
% set(h,'Parent',hg) 
set(hg2,'Displayname','Saccades')

axP = get(gca,'Position');
le = legend([hg hg2]);
set(le,'location', 'eastoutside', 'box', 'on');
set(gca, 'Position', axP)

text(5, 600, info_blinks)
text(5, 1200, info_sacc)

title('Events')
xlabel('t(s)')
ylabel('Pupil diameter (\mum)')

subplot(3,2,6)

plot(t, proc_data(:, size(proc_data, 2)), 'color', cols(2, :), 'linewidth', 1)
ylims = get(gca, 'YLim');
axis([t(1) t(end) ylims(1) ylims(2)])

text(5, 1500, info_interp)

title('Processed pupil traze')

xlabel('time (s)');
ylabel('Pupil Diameter (\mum)');

%% Export as csv file:
columns = {'time_stamps' 'x_coordinate' 'y_coordinate'...
           'pupil_size' 'x_velocity' 'y_velocity' ...
           'blink_indexes' 'saccade_indexes' 'fixation_indexes' 'interpolated_data' 'final_data'};

T = array2table(proc_data,'VariableNames',columns);

writetable(T,'data_out_example.csv', 'Delimiter', 'tab')
