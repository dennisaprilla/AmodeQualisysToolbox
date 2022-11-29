function processed_USsignal = process_USsignal_windowed(data, data_spec, us_spec, windowrange_i)

% preparing constants for peak detection
envelop_windowlength = 30;

% pre-allocation variables, later can be deleted
USsignals_hpfilter = cell(data_spec.n_ust, data_spec.n_frames);
USsignals_envelop  = cell(data_spec.n_ust, data_spec.n_frames);
USsignals_lpfilter = cell(data_spec.n_ust, data_spec.n_frames);

% construct the filter for highpass and lowpass
hpFilt = designfilt('highpassiir','FilterOrder',2, ...
         'PassbandFrequency',3.5e6,'PassbandRipple',0.2, ...
         'SampleRate', us_spec.sample_rate);
lpFilt = designfilt('lowpassiir','FilterOrder',2, ...
         'PassbandFrequency', 1e7,'PassbandRipple',0.3, ...
         'SampleRate', us_spec.sample_rate);

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
        
        data_clipped = data(i, windowrange_i(i,1):windowrange_i(i,2), j);
        
        % 1) HP-filter because there is low frequency tendency from raw signal
        USsignals_hpfilter{i,j} = filtfilt(hpFilt, data_clipped);
        
        % 2) enveloping the signal
        USsignals_envelop{i,j} = envelope(USsignals_hpfilter{i,j}, envelop_windowlength, 'rms');
        
        % 3) LP-filter the envelop
        USsignals_lpfilter{i,j} = filtfilt(lpFilt, USsignals_envelop{i,j});
        
        
    end
    t_dsp(j) = toc;
    
end
% put indicator to terminal
fprintf("DSP is finished, average DSP/timeframe %.4f seconds, overall time %.4f seconds\n", ...
        mean(t_dsp), sum(t_dsp));
% close the progress bar
close(f);

% return the value
processed_USsignal = USsignals_lpfilter;

end

