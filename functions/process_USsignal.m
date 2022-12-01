function [USsignals_envelop, USsignals_corrbarker] = process_USsignal(data, data_spec, us_spec, path_barkercode)

% preparing constants for peak detection
envelop_windowlength = 50;

% pre-allocation variables, later can be deleted
USsignals_tgcfilter  = zeros(size(data));
USsignals_bpfilter   = zeros(size(data));
USsignals_corrbarker = zeros(size(data));
USsignals_envelop    = zeros(size(data));

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
        
    end
    t_dsp(j) = toc;
    
end
% put indicator to terminal
fprintf("DSP is finished, average DSP/timeframe %.4f seconds, overall time %.4f seconds\n", ...
        mean(t_dsp), sum(t_dsp));
% close the progress bar
close(f);

% return the value
% processed_USsignal = USsignals_lpfilter;
% processed_USsignal = USsignals_envelop;

end

