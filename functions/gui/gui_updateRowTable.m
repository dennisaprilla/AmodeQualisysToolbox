function gui_updateRowTable(table_handles, row, new_data)
% I actually dont have any idea how to edit data from UItable. This is the
% only thing that i can think of.

% get data from GUI table
data_matrix = get(table_handles, 'Data');
% update certain row
data_matrix(row,:) = new_data;
% set data to GUI table
set(table_handles, 'Data', data_matrix);
% set focus
scroll(table_handles,'row',row);

end

