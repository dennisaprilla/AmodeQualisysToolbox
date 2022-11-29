function display_timestamp_mmode(current_axes, timestamp_toshow)

    delete(findobj(current_axes, 'Tag', 'plot_timestamp'));
    xline(current_axes, timestamp_toshow, '-', 'Timestamp', 'LineWidth', 2, 'Color', 'r',  'Tag', 'plot_timestamp');
end

