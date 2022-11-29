function display_signalwindow_mmode(current_axes, window_lowerbound, window_upperbound, tag1, tag2 )

delete(findobj(current_axes, 'Tag', tag1));
delete(findobj(current_axes, 'Tag', tag2));

% % yline(current_axes, window.center, '-', 'Center', 'Color', 'b', 'LineWidth', 2,  'Tag', 'plot_windowcenter');
% yline(current_axes, window_center-(window_width/2), '--', 'Color', 'w', 'Tag', tag1);
% yline(current_axes, window_center+(window_width/2), '--', 'Color', 'w', 'Tag', tag2);

yline(current_axes, window_lowerbound, '--', 'Color', 'w', 'Tag', tag1);
yline(current_axes, window_upperbound, '--', 'Color', 'w', 'Tag', tag2);

end

