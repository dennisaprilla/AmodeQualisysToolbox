function [file_detail, qualisys_data] = readTRC_qualisysData(file_path)

% open the file
fid = fopen(file_path);
% make sure we are on the first line of the file
% frewind(fid)
% skip first line
fgetl(fid);

% get second line
str = fgetl(fid);
strings = split(str);
% get third line
str = fgetl(fid);
values = split(str);
for i=1:length(strings)
    % there is a field called Units, it is a string
    if( strcmp(strings{i}, 'Units'))
        file_detail.(strings{i}) = values{i};
    else
        file_detail.(strings{i}) = str2num(values{i});
    end
end

% get fourth line
str = fgetl(fid);
% get the name of the column, later we need to put to our table
column_strings = split(str);
% there is delimiter in the end of the line, so it counted as another data
% by split() function, so i need to delete it
column_strings(end) = [];
column_length = length(column_strings);

% make list of string of the column data type
type_columns = "double";
type_columns(1:column_length) = type_columns;
% first column is just index so it can be integer
type_columns(1) = "uint16";

% create the table
qualisys_data = table('Size', [1 column_length], 'VariableTypes', type_columns, 'VariableNames', column_strings);

% skip the fifth and sixth line
fgetl(fid);
fgetl(fid);

% Turn off warning. I stored the data to the table per-column, whereas matlab
% recommends that I suppose to create a vector for whole column than store it
% to the table. It is complicated to follow matlab's recomendation, because i
% need to put a 3-vector inside a column. The only way to store this (as
% far as i know) is only by store it column-by-column. So, fuck the warning
warning('off');

disp('Reading trc file, please wait...');
tic;

% now it is the time to get all of the data
table_rowindex = 1;
while ~feof(fid)
    
    % get the line
    str = fgetl(fid);
    value_strings = split(str);
    value_length = length(value_strings);
    
    % insert frame and timpstamp data to table
    qualisys_data.(column_strings{1})(table_rowindex) = str2num(value_strings{1});
    qualisys_data.(column_strings{2})(table_rowindex) = str2double(value_strings{2});
    
    value_currentindex = 3;
    for i=3:column_length
        % every column will have 3 data (x,y,z)
        value_toinsert = [ str2double(value_strings{value_currentindex}), ...
                           str2double(value_strings{value_currentindex + 1}), ...
                           str2double(value_strings{value_currentindex + 2}) ];
        
        % So matlab has this weirdness. I want to store vector, e.g. [1,2,3]
        % to a single column of table. If I index the row, it will not work.
        % But if I didn't index at the first time (like the true case of
        % this if), then i index it later (like the false case of this if),
        % it will work just fine.
        if (table_rowindex==1)
            qualisys_data.(column_strings{i}) = value_toinsert;
        else
            qualisys_data.(column_strings{i})(table_rowindex, :) = value_toinsert;
        end
        
        % skip current index by 3, since we take 3 values per read
        value_currentindex = value_currentindex + 3;
    end
    
    % prepare for next row
    table_rowindex = table_rowindex+1;
end

disp(sprintf('Finished reading file, %.4f seconds', toc));

% i finish my bussiness, let's turn on the warning again.
warning('on');

end

