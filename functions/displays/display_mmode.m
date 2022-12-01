function display_mmode(current_axes, probeNumber_toShow, envelope_data, data_spec, x_axis_values, mmode_display_threshold)

% set the constant
% mmode_display_threshold = 15000;
compression_factor = 1;

if (iscell(envelope_data))
    
    % cell2mat(envelope_data(x,:))   -> give me looong vector since each cell
    % contains long vector
    % cell2mat(envelope_data(x,:)')  -> transpose will stack the vector of cell 
    % vertically, so almost what i wanted, the row is now the timestamp
    % cell2mat(envelope_data(x,:)')' -> now it is perfect
    probe = cell2mat(envelope_data(probeNumber_toShow,:)')';
    
else
    probe = reshape( envelope_data(probeNumber_toShow,:,:), [data_spec.n_samples, data_spec.n_frames]);
end

probe_image = uint8(255 * mat2gray(probe, [0 mmode_display_threshold]));
% probe_image = uint8(255 * mat2gray(probe));
% log_compression = 10 * log10( (compression_factor * probe) + eps);
% probe_image = uint8(255 * mat2gray(log_compression));

% show m-mode
imagesc(current_axes, [1 data_spec.n_frames], [x_axis_values(1) x_axis_values(end)], probe_image);
% xlabel(current_axes, 'Timestamp');
ylabel(current_axes, 'Depth (mm)');
title(current_axes, sprintf("M-Mode Probe #%d", probeNumber_toShow));
% colorbar(current_axes);

axis(current_axes, 'tight');

end

