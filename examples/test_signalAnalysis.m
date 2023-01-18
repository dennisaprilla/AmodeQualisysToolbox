%% SUMMARY
% This scripts shows the OFFLINE manner to estimate the bone depth. These
% are main points of this program:
% 1. Read US raw signal data
% 2. Wavelet transform the signal with frequency limit.
% 3. Detect peaks with some criterias
% 4. Clean, cluster, and curve-fit the detected peak
% 5. Estimate the window.
%
% The output of this script are: 
% 1. Estimated window for bone detection
% 2. Cleaned bone peak data

clc; clear; close all;

% add path for reading signal
addpath('../functions');
addpath('../functions/displays');
addpath('../functions/signal');
addpath(genpath('../functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 2500);

% preparing constants for data spesification
data_spec.n_ust     = size(USData, 1);
data_spec.n_samples = size(USData, 2);
data_spec.n_frames  = size(USData, 3);

% preparing constants for ultrasound spesification
us_spec.v_sound     = 1540; % mm/s
us_spec.sample_rate = 50 * 1e6;
us_spec.index2distance_constant  = (1e3 * us_spec.v_sound) / (2 * us_spec.sample_rate);

% signal processing to get m-mode data
[envelope_data, ~] = process_USsignal(USData, data_spec, us_spec, '../data/kenans_barkercode.txt');

%% Preparing variables and constants

clc; close all;
clearvars -except USData envelope_data data_spec us_spec dname;

n_probes  = size(USData,1);
n_samples = size(USData,2);
n_frame   = size(USData,3);

% signal constant
Fs = 50e6;
T = 1/Fs;
L = n_samples;
t_vector = ( (1:n_samples)*T ) * 1e6;

% ultrasound constant
v_sound = 1540;
index2distance_constant = (1e3 * v_sound) / (2*Fs);
d_vector = (0:n_samples-1) .* index2distance_constant;

% sigmoid filter to remove initial contact
% 1.7, 0.1
sig_halfpoint  = 1; % in microsecond unit
sig_rate       = 0.15;
sigFilt = sigmoid_simple(n_samples, sig_halfpoint, sig_rate, T);

% barkers code
path_barkerscode = '../data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);
sample_start = n_samples   - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
sample_end   = n_samples*2 - floor( 0.5 * length(barkerscode(:, 2)) );

% cwt
freq_lim = [7.0e6 7.3e6]; % MHz

% Figure preparation ------------------------------------------------------

% flag for recording the plot
recordplot = false;
searchpeak = true;

% data interest
probe_to_show  = 28;
frames_to_show = 1:n_frame;

% prepare window
figure1 = figure('Name', 'Wavelet Analysis');
figure1.WindowState = 'maximized';

subplot_rows  = 6;
subplot_cols  = 2;
subplot_index = reshape(1:(subplot_rows*subplot_cols), subplot_cols, subplot_rows)';

subplotidx_amoderaw    = subplot_index(1:2,1);
subplotidx_amodebarker = subplot_index(3:4,1);
subplotidx_cwt         = subplot_index(5:6,1);
subplotidx_mmode1      = subplot_index(1:3,2);
subplotidx_mmode2      = subplot_index(4:6,2);

% axes for amode raw
ax_amoderaw = subplot(subplot_rows, subplot_cols, subplotidx_amoderaw, 'Parent', figure1);
title(ax_amoderaw, 'A-mode Raw Signal', 'Interpreter', 'latex');
axis(ax_amoderaw, 'tight');
% xlabel(ax_amoderaw, 'Time ($\mu$s)', 'Interpreter', 'Latex');
ylabel(ax_amoderaw, 'Amplitude', 'Interpreter', 'Latex');
ax_amoderaw.XGrid = 'on';
ax_amoderaw.XMinorGrid = 'on';
hold(ax_amoderaw, 'on');

% axes for amode correlated
ax_amodebarker = subplot(subplot_rows, subplot_cols, subplotidx_amodebarker, 'Parent', figure1);
title(ax_amodebarker, 'A-mode Signal Correlated with Barker Code', 'Interpreter', 'latex');
axis(ax_amodebarker, 'tight');
% xlabel(ax_amodebarker, 'Time ($\mu$s)', 'Interpreter', 'Latex');
ylabel(ax_amodebarker, 'Amplitude', 'Interpreter', 'Latex');
ax_amodebarker.XGrid = 'on';
ax_amodebarker.XMinorGrid = 'on';
hold(ax_amodebarker, 'on');

% axes for cwt
ax_cwt = subplot(subplot_rows, subplot_cols, subplotidx_cwt, 'Parent', figure1);
titlestr = strcat('(Continuous) Wavelet Transform at \,', num2str(freq_lim(1)*1e-6), '\,-\,', num2str(freq_lim(2)*1e-6), '\,MHz'); 
title(ax_cwt, titlestr, 'Interpreter', 'latex');
axis(ax_cwt, 'tight');
xlabel(ax_cwt, 'Time ($\mu$s)', 'Interpreter', 'Latex');
ylabel(ax_cwt, 'Amplitude', 'Interpreter', 'Latex');
ax_cwt.XGrid = 'on';
ax_cwt.XMinorGrid = 'on';
hold(ax_cwt, 'on');

% axes for mmode
ax_mmode1 = subplot(subplot_rows, subplot_cols, subplotidx_mmode1, 'Parent', figure1);
axis(ax_mmode1, 'tight');
ax_mmode1.XGrid = 'on';
hold(ax_mmode1, 'on');

% axes for peak detection over time
ax_mmode2 = subplot(subplot_rows, subplot_cols, subplotidx_mmode2, 'Parent', figure1);
axis(ax_mmode2, 'tight');
ax_mmode2.XGrid = 'on';
hold(ax_mmode2, 'on');


% Start loop --------------------------------------------------------------


% if we specifiy record, prepare the writer object
if (recordplot)
    writerObj = VideoWriter('D:/Videos/plot.avi');
    writerObj.FrameRate = 30;
    open(writerObj);
end

% show m-mode first
display_mmode(ax_mmode1, probe_to_show, envelope_data, data_spec, t_vector, 10000);
ylabel(ax_mmode1, 'Time ($\mu$s)', 'Interpreter', 'Latex');
title(ax_mmode1, 'M-mode image with all detected peaks', 'Interpreter', 'latex');

display_mmode(ax_mmode2, probe_to_show, envelope_data, data_spec, t_vector, 10000);
ylabel(ax_mmode2, 'Time ($\mu$s)', 'Interpreter', 'Latex');
ylabel(ax_mmode2, 'Timestamp', 'Interpreter', 'Latex');
title(ax_mmode2, 'M-mode image with estimated bone', 'Interpreter', 'latex');

% all peaks
allpeaks_w_echo  = [];
allpeaks_wo_echo = [];

for current_frame=frames_to_show

    % obtain data
    S = USData(probe_to_show,:,current_frame) .* sigFilt;
    % correlate with barker code
    [S_corr, ~] = xcorr(S', barkerscode(:, 2));
    S_barker    = S_corr(sample_start:sample_end)';
    % cwt in spesific frequency
    [cfs1, ~] = cwt(S, Fs, 'FrequencyLimit', [5.3e6, 5.6e6], 'VoicesPerOctave', 48);
    [cfs2, ~] = cwt(S, Fs, 'FrequencyLimit', [7.0e6, 7.3e6], 'VoicesPerOctave', 48);
    cfs_mag_mean1 = mean(abs(cfs1), 1);
    cfs_mag_mean2 = mean(abs(cfs2), 1);
    cfs_mag_mean  = max([cfs_mag_mean1;cfs_mag_mean2], [], 1);

    if(searchpeak)
        % find peaks
        [peak_amp, peak_loc, w, p] = findpeaks(cfs_mag_mean, Fs, 'MinPeakHeight', 100, 'MinPeakProminence', 130, 'MinPeakDistance', 0.65e-6);
        
        % eliminate very fat peaks
        peaks_ratio = (p*1e-3) ./ (w*1e6);
        peaks_ratiotresh = 0.2;
        peak_amp(peaks_ratio < peaks_ratiotresh)  = [];
        peak_loc(peaks_ratio < peaks_ratiotresh) = [];
        
        % eliminate echo
        [peak_idx_softtissues, peak_idx_bone, peak_idx_echo] = eliminatePeakEcho(peak_amp, peak_loc, 0.15, 0.75);
        
        % collect data
        allpeaks_w_echo  = [ allpeaks_w_echo; repmat(current_frame, length(peak_loc), 1), peak_loc', peak_amp'];
        allpeaks_wo_echo = [ allpeaks_wo_echo; ...
                             repmat(current_frame, length(peak_idx_softtissues), 1), peak_loc(peak_idx_softtissues)'; ...
                             repmat(current_frame, length(peak_idx_bone), 1), peak_loc(peak_idx_bone)' ];
    end

    % Plotting ------------------------------------------------------------

    % plot amode
    delete(findobj(ax_amoderaw, 'Tag', 'plot_amoderaw'));
    plot(ax_amoderaw, t_vector, S, '-', 'Color', 'g', 'Tag', 'plot_amoderaw');

    % plot correlated
    delete(findobj(ax_amodebarker, 'Tag', 'plot_amodebarker'));
    plot(ax_amodebarker, t_vector, S_barker, '-', 'Color', 'b', 'Tag', 'plot_amodebarker');

    % plot cwt
    delete(findobj(ax_cwt, 'Tag', 'plot_cwt'));
    plot(ax_cwt, t_vector, cfs_mag_mean, '-', 'Color', 'r', 'Tag', 'plot_cwt');

    % plot mmode
    display_timestamp_mmode(ax_mmode1, current_frame);

    if(searchpeak)
        delete(findobj(ax_cwt, 'Tag', 'plot_amodepeaks'));
        plot(ax_cwt, peak_loc(peak_idx_bone)*1e6,        peak_amp(peak_idx_bone),        'o', 'Color', 'r', 'MarkerFaceColor', 'r', 'Tag', 'plot_amodepeaks');
        plot(ax_cwt, peak_loc(peak_idx_softtissues)*1e6, peak_amp(peak_idx_softtissues), 'o', 'Color', 'r', 'MarkerFaceColor', 'y','Tag', 'plot_amodepeaks');
        plot(ax_cwt, peak_loc(peak_idx_echo)*1e6,        peak_amp(peak_idx_echo),        'o', 'Color', 'r', 'MarkerFaceColor', '#EDB120', 'Tag', 'plot_amodepeaks');
        
        delete(findobj('Tag', 'plot_peakinframe'));
        scatter(ax_mmode1, allpeaks_wo_echo(:,1), allpeaks_wo_echo(:,2)*1e6, [], 'r',  '.', 'Tag', 'plot_peakinframe');
    end

    % Additional ----------------------------------------------------------

    drawnow;

	% if user specify recordplot then grab the frame and write it to the
    % video object
    if(recordplot)
        frame = getframe(figure1);
        writeVideo(writerObj, frame);
    end
    
    % if user press any key, break
    isKeyPressed = ~isempty(get(figure1,'CurrentCharacter'));
    if isKeyPressed
        break
    end

end

% Post Processing ---------------------------------------------------------

% cleaning the outliers
clusterparam_dim = 2;
outlierparam_gradthreshold = 5;
outlierparam_minpoint = 10;
[f, data_cleaned, cluster_idx] = estimateBoneCluster( allpeaks_wo_echo, ...
                                                      clusterparam_dim, ...
                                                      outlierparam_gradthreshold, ...
                                                      outlierparam_minpoint, ...
                                                      false);

% get the usable data
detectedbone_earliest = data_cleaned(1,1);
detectedbone_latest   = data_cleaned(end, 1);
detectedbone_X        = detectedbone_earliest:detectedbone_latest;
detectedbone_Y        = feval(f, detectedbone_X);

% get the window
window_critical       = [min(detectedbone_Y), max(detectedbone_Y)];
% window_extconst       = 1.5;
% window_extension      = abs(diff(window_critical))* window_extconst - abs(diff(window_critical));
window_extension      = 0.5 * 1e-6;
window_safe           = window_critical + ([-1 1] * window_extension);

% plot the detected bone
plot(ax_mmode2, detectedbone_X, detectedbone_Y*1e6, '.', 'Color', 'r', 'Tag', 'plot_bonepeaks');
yline(ax_mmode2, window_safe*1e6, '--y', 'LineWidth', 1);

if(recordplot)
    % get the last frame and write to video
    frame = getframe(figure1);
    writeVideo(writerObj, frame);

    % don't forget to close the writer object
    close(writerObj);
end


