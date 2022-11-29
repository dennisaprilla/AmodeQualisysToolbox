function [allpeaks, USsignals_corrbarker] = peaks_USsignal(data, data_spec, us_spec)

% preparing constants for peak detection
minpeakwidth = 5;
minpeakprominence = 300;
envelop_windowlength = 30;

% pre-allocation variables, later can be deleted
% USsignals_hpfilter = zeros(size(data));
% USsignals_tgc      = zeros(size(data));
% USsignals_envelop  = zeros(size(data));
% USsignals_lpfilter = zeros(size(data));
USsignals_tgcfilter  = zeros(size(data));
USsignals_bpfilter   = zeros(size(data));
USsignals_corrbarker = zeros(size(data));
USsignals_envelop    = zeros(size(data));

% peaks need to be stored in cell because sometimes, for one probe at one
% frame it can have variable length of values.
allpeaks.sharpness = cell(data_spec.n_ust, data_spec.n_frames);
allpeaks.locations = cell(data_spec.n_ust, data_spec.n_frames);

% construct the filter for TGC
tgcFilt = tgc_simple(size(data,2), 2, 0.02, 1/us_spec.sample_rate);

% construct the filter for highpass and lowpass
% hpFilt = designfilt('highpassiir','FilterOrder',2, ...
%          'PassbandFrequency',3.5e6,'PassbandRipple',0.2, ...
%          'SampleRate', us_spec.sample_rate);
% lpFilt = designfilt('lowpassiir','FilterOrder',2, ...
%          'PassbandFrequency',5e6,'PassbandRipple',0.3, ...
%          'SampleRate', us_spec.sample_rate);
bpFilt = designfilt('bandpassiir', 'FilterOrder', 20, ...
         'HalfPowerFrequency1', 0.3e7, 'HalfPowerFrequency2', 0.9e7, ...
         'SampleRate', us_spec.sample_rate);

% construct the barkers code
path_barkerscode = 'data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);

% construct sigmoid filter
sigFilt = sigmoid_simple(size(data,2), 1.5, 0.1, 1/us_spec.sample_rate);

% to see the time
t_peak_detection = zeros(data_spec.n_frames, 1);

% put indicator to terminal
disp("DSP is running, please wait ...");
% show the progress bar, so that the user is not bored
f = waitbar(0, sprintf('%d/%d Frame', 0, data_spec.n_frames), 'Name', 'Running DSP');

for j=1:data_spec.n_frames
    
    % display progress bar
    if (mod(j,25)==0)
        waitbar( j/data_spec.n_frames, f, sprintf('%d/%d Frame', j, data_spec.n_frames) );
    end
    
    tic;
    for i=1:data_spec.n_ust
        
        % 1) TGC to increase the gain in the rear part of the signal
        USsignals_tgcfilter(i,:,j) = data(i,:,j) .* tgcFilt;
        
        % 2) Bandpass filter to remove low frequency tendency and noise
        % from the raw signal
        USsignals_bpfilter(i,:,j) = filtfilt(bpFilt, USsignals_tgcfilter(i,:,j));
        
        % 3) Correlate with barkers code
        [S_correlated, ~] = xcorr(USsignals_bpfilter(i,:,j)', barkerscode(:, 2));
        S_correlated = S_correlated';
        % -- start from halfway of barkercode entering the US signal
        sample_start = length(S_correlated) - ...
                       size(data,2) - ...
                       floor( 0.5 * length(barkerscode(:, 2)) ) +1;
        sample_end   = length(S_correlated) - ...
                       floor(0.5 * length(barkerscode(:, 2)));
        USsignals_corrbarker(i,:,j) = S_correlated(sample_start:sample_end);
        
        % 4) Envelope
        S_envelop = envelope(USsignals_corrbarker(i,:,j), envelop_windowlength, 'analytic');
        S_envelop = smoothdata(S_envelop, 'gaussian', 20);
        USsignals_envelop(i,:,j)  = S_envelop .* sigFilt;
        
        %{
        % 1) HP-filter because there is low frequency tendency from raw signal
        USsignals_hpfilter(i,:,j) = filtfilt(hpFilt, data(i,:,j));
        
        % 2) TGC to increase the gain in the rear part of the signal
        tgc_data(i,:,j) = hpfiltered_data(i,:,j)./(n_samples:-1:1);
        
        % 3) LP-filter just to make sure there is not much noise (not really necessary actually)
        lpfiltered_data(i,:,j) = filtfilt(lpFilt, hpfiltered_data(i,:,j));
        
        % 4) enveloping the signal
        USsignals_envelop(i,:,j) = envelope(USsignals_hpfilter(i,:,j), envelop_windowlength, 'rms');
        
        % 5) LP-filter for the envelop signal, to make it smooth and easier
        % to determine the peaks
        USsignals_lpfilter(i,:,j) = filtfilt(lpFilt, USsignals_envelop(i,:,j));
        %}
        
        % 6) Local maxima detection
        [peaks, locs] =  findpeaks(USsignals_envelop(i, :, j), ...
                                   'MinPeakWidth', minpeakwidth, ...
                                   'MinPeakProminence', minpeakprominence, ...;
                                   'SortStr', 'descend');
        
        % we only store the locs value if it is not empty, or else, it will
        % produce an error
        if locs
            allpeaks.sharpness{i,j} = peaks;
            allpeaks.locations{i,j} = locs * us_spec.index2distance_constant;
        end
        
    end
    t_peak_detection(j) = toc;
    
end
fprintf("DSP is finished, average DSP/timeframe %.4f seconds, overall time %.4f seconds\n", ...
        mean(t_peak_detection), sum(t_peak_detection));
% close the progress bar
close(f);

end
