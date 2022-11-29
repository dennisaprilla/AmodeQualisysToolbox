function display_signalwindow_amode(current_axes, window_lowerbound, window_upperbound, tag1, tag2 )

% delete previous window in the plot
delete(findobj(current_axes, 'Tag', tag1));
delete(findobj(current_axes, 'Tag', tag2'));

% % redraw the window
% xline(current_axes, window_center, '-', 'Center', 'Color', 'b', 'LineWidth', 2,  'Tag', tag1);
% xline(current_axes, window_center-(window_width/2), '--', 'Color', 'm', 'LineWidth', 2, 'Tag', tag2);
% xline(current_axes, window_center+(window_width/2), '--', 'Color', 'm', 'LineWidth', 2, 'Tag', tag2);

% redraw the window
xline(current_axes, window_lowerbound, '--', 'LB', 'Color', 'b', 'LineWidth', 2,  'Tag', tag1);
xline(current_axes, window_upperbound, '--', 'UB', 'Color', 'm', 'LineWidth', 2, 'Tag', tag2);

% % you can uncomment this, i use this function after displaying amode with
% % display_amode_woPeaks() function. in that particular function, there is
% % hold on; command. so just to make sure the plot is not became chaotic, i
% % put hold off here.
% hold(current_axes, 'off');

end