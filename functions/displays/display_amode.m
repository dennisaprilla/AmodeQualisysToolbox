function display_amode(current_axes, display_mode, probeNumber_toShow, timestamp_toShow, data, envelope_data, x_axis_values, tag1, tag2)

% just to make sure the plot is clean
delete(findobj(current_axes, 'Tag', tag1));
delete(findobj(current_axes, 'Tag', tag2));

% Check whether the data is a cell or not. If it is a cell, it means that
% the user is feeding a clipped data, which comes if the user processed the
% data based on window. The length of the signal may varies, so it is not 
% possible to store it in an array/matrix. As i want to make this function 
% as general as possible i will put the cheking here
if ( iscell(data) )
    data_toShow = data{probeNumber_toShow, timestamp_toShow};
else
    data_toShow = data(probeNumber_toShow, :, timestamp_toShow);
end
% y_limit = [min(data_toShow), max(data_toShow)];

% show a-mode
yyaxis(current_axes, 'left');
plot(current_axes, x_axis_values, data_toShow, '-', 'Color', 'g', 'Tag', tag1);
xlabel(current_axes, 'Distance (mm)');
ylabel(current_axes, 'Signal Amplitude');
axis(current_axes, 'tight');

% if user specified envelope it means that the raw data is actually the
% correlated data, so we can the y limit as default
if(~isempty(envelope_data))
    y_limit = [min(data_toShow), max(data_toShow)];

% however, if the user really put raw data, the near-field interference is
% quite concerning since it is just too big and will makes other part of
% the signal flat, so let's cut the y limit
else
    y_limit = [-max(data_toShow), max(data_toShow)];
end
ylim(current_axes, y_limit);

% if user didn't specify envelope, it means they only want to show amode
% without envelope
if(~isempty(envelope_data))
    
    % Check whether the envelop variable is a cell or not. Why cell? because if
    % we clipped the envelop signal based on the window, the length of the
    % signal may varies, so it is not possible to store it in an array/matrix.
    % As i want to make this function as general as possible i will put the
    % cheking here
    if ( iscell(envelope_data) )
        data_toShow = envelope_data{probeNumber_toShow, timestamp_toShow};
    else
        data_toShow = envelope_data(probeNumber_toShow, :, timestamp_toShow);
    end
    % y_limit = [-max(data_toShow), max(data_toShow)];
    
    % show the envelope
    yyaxis(current_axes, 'right');
    plot(current_axes, x_axis_values, data_toShow, '-', 'Color', 'r', 'LineWidth',1.5, 'Tag', tag2);

    if (strcmp(display_mode, 'distance'))
        xlabel(current_axes, 'Distance (mm)');
    elseif (strcmp(display_mode, 'time'))
        xlabel(current_axes, 'Time ($\mu$s)', 'Interpreter', 'Latex');
    else
        warning("Can not recognize the display mode for A-mode, specified as 'location' (found in display_amode)");
        xlabel(current_axes, 'Distance (mm)');
    end
    ylabel(current_axes, 'Envelop Amplitude');
    ylim(current_axes, y_limit);
    title(current_axes, sprintf("A-Mode Probe #%d", probeNumber_toShow));

end

% yyaxis(current_axes, 'left');
% ylim(current_axes, y_limit);
% yyaxis(current_axes, 'right');

grid(current_axes, 'on');

end

