function ust_config = readINI_ustconfig(path, data_spec)

% read ini file
ust_struct = ini2struct(path);

% initialize a table for containing the probe properties
ust_config = table( 'Size', [1,3], ...
                    'VariableTypes', ["string", "double", "double"], ...
                    'VariableNames', ["Group", "WindowLowerBound", "WindowUpperBound"]);

% get the field names
ust_struct_fieldnames = fieldnames(ust_struct);
% loop through all the fields
for i=1:data_spec.n_ust
    % get lower and upper bound data
    lowerbound_str = ust_struct.(ust_struct_fieldnames{i}).LowerBound;
    upperbound_str = ust_struct.(ust_struct_fieldnames{i}).UpperBound;
    group_str      = ust_struct.(ust_struct_fieldnames{i}).Group;
    
    % but because it is string, and the US machine somehow uses comma 
    % separator for floating point, so we need to replace the comma as 
    % point first, then convert it to double.
    ust_config.WindowLowerBound(i) = str2double(strrep(lowerbound_str, ',', '.'));
    ust_config.WindowUpperBound(i) = str2double(strrep(upperbound_str, ',', '.'));
    % remove double quote in the group string from ini fle
    ust_config.Group(i) = strrep(group_str, '"', '');
end

end