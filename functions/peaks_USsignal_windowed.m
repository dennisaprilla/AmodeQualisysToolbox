function [allpeaks, USsignals_envelop, USsignals_corrbarker] = peaks_USsignal_windowed(data, data_spec, us_spec, windowrange, windowrange_i, path_barkercode)

% preparing constants for peak detection
minpeakwidth = 5;
minpeakprominence = 300;
envelop_windowlength = 30;

% pre-allocation variables, later can be deleted
USsignals_tgcfilter  = cell(data_spec.n_ust, data_spec.n_frames);
USsignals_bpfilter   = cell(data_spec.n_ust, data_spec.n_frames);
USsignals_corrbarker = cell(data_spec.n_ust, data_spec.n_frames);
USsignals_envelop    = cell(data_spec.n_ust, data_spec.n_frames);
allpeaks.sharpness   = zeros(data_spec.n_ust, data_spec.n_frames);
allpeaks.locations   = zeros(data_spec.n_ust, data_spec.n_frames);

% construct the filter for TGC
tgcFilt = tgc_simple(size(data,2), 2, 0.02, 1/us_spec.sample_rate);

% construct the filter for highpass and lowpass
bpFilt = designfilt('bandpassiir', 'FilterOrder', 20, ...
         'HalfPowerFrequency1', 0.3e7, 'HalfPowerFrequency2', 0.9e7, ...
         'SampleRate', us_spec.sample_rate);
     
% construct the barkers code
barkerscode = readmatrix(path_barkercode);

% construct sigmoid filter
sigFilt = sigmoid_simple(size(data,2), 1.5, 0.1, 1/us_spec.sample_rate);

% to see the time
t_dsp = zeros(data_spec.n_frames, 1);

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
        
        data_clipped    = data(i, windowrange_i(i,1):windowrange_i(i,2), j);
        tgcFilt_clipped = tgcFilt(windowrange_i(i,1):windowrange_i(i,2));
        sigFilt_clipped = sigFilt(windowrange_i(i,1):windowrange_i(i,2));
        
        % 1) TGC to increase the gain in the rear part of the signal
        USsignals_tgcfilter{i,j} = data_clipped .* tgcFilt_clipped;
        
        % 2) Bandpass filter to remove low frequency tendency and noise
        % from the raw signal
        USsignals_bpfilter{i,j} = filtfilt(bpFilt, USsignals_tgcfilter{i,j});
        
        % 3) Correlate with barkers code
        [S_correlated, ~] = xcorr(USsignals_bpfilter{i,j}', barkerscode(:, 2));
        S_correlated = S_correlated';
        % -- start from halfway of barkercode entering the US signal
        sample_start = length(S_correlated) - ...
                       size(data_clipped,2) - ...
                       floor( 0.5 * length(barkerscode(:, 2)) ) +1;
        sample_end   = length(S_correlated) - ...
                       floor(0.5 * length(barkerscode(:, 2)));
        USsignals_corrbarker{i,j} = S_correlated(sample_start:sample_end);
        
        % 4) Envelope
        S_envelop = envelope(USsignals_corrbarker{i,j}, envelop_windowlength, 'analytic');
        S_envelop = smoothdata(S_envelop, 'gaussian', 20);
        USsignals_envelop{i,j}  = S_envelop .* sigFilt_clipped;
        
        % 5) Local maxima detection
        [peaks, locs] =  findpeaks( USsignals_envelop{i,j}, ...
                                    'MinPeakWidth', minpeakwidth, ...
                                    'MinPeakProminence', minpeakprominence, ...
                                    'SortStr', 'descend');
        
        
        % we only store the locs value if it is not empty, or else, it will
        % produce an error
        if locs
            allpeaks.sharpness(i,j) = peaks(1);
            % if the user specified index2time_constant we can provide
            % information regarding peak in time
            if (isfield(us_spec, 'index2time_constant'))
                allpeaks.times(i,j) = windowrange(i, 1) + (locs(1) * us_spec.index2time_constant);
            % if the user specified index2distance_constant we can provide
            % information regarding peak in distance
            elseif (isfield(us_spec, 'index2distance_constant'))
                allpeaks.locations(i,j) = windowrange(i, 1) + (locs(1) * us_spec.index2distance_constant);
            end
        end
        
    end
    t_dsp(j) = toc;
    
end
% put indicator to terminal
fprintf("DSP is finished, average DSP/timeframe %.4f seconds, overall time %.4f seconds\n", ...
        mean(t_dsp), sum(t_dsp));
% close the progress bar
close(f);

end

