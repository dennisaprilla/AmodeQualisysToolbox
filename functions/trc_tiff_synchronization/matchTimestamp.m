function searchindex_all = matchTimestamp(timestamps_reference, timestamps_target, tolerance)
% DESCRIPTION:
% Function for matching floating values between two vector. Usually used
% for matching floating point timestamps.
% INPUT:
% timestamps_reference  A vector of floating points (timestamps) which will
%                       be the reference, i.e. we will look for the match
%                       for each elements in this vector. We usually use
%                       the first input for the timestamps which have
%                       bigger framerates
% timestamps_target     Similar to timestamps_reference, but this one is
%                       for the target, i.e. some of this vector will not
%                       have a match. We usually use the second input for
%                       the timestamps which have smaller framerates
% tolerance             Time range of tolerance to say it is a match. The
%                       timestamps are floating points, we can't pint point
%                       one value, so we need a range of value. If you put
%                       too big tolerance, the correspondance can be
%                       one-to-many, so, be responsible.
% OUTPUT:
% searchindex_all       A vector consisting index in timestamps_target that
%                       that match to timestamps_reference. You can use
%                       this as timestamps_reference(searchindex_all);
% NOTES:
% Originally this function is for matching timestamps_USData and 
% timestamps_markerpc, but this function actually can be reusable for
% another case. timestamps_USData usually longer than timestamps_markerpc
% so than timestamps_USData become the reference and timestamps_markerpc
% become the target

% get the mean framerate
framerate_reference = mean(diff(timestamps_reference));
framerate_target    = mean(diff(timestamps_target));

% initialize several variables
searchindex_target = 1;
searchindex_all    = [];
flag_isnomatch     = false;
flag_isendsearch   = false;

% currentindex_reference have bigger framerate, so we match currentindex_reference
% to timestamps_target
for currentindex_reference=1:length(timestamps_reference)
    
    % loop through the qualisys timestamp until it reach the data within
    % predefined range of timestamp
    while ( ~inrangeof(timestamps_reference(currentindex_reference), ...
                       timestamps_target(searchindex_target), ...
                       tolerance) )
        
        % as long as it is not in the range, skip it
        searchindex_target = searchindex_target+1;
        
        % a flag if the timestamps_target data is finished
        if (searchindex_target == length(timestamps_target))
            flag_isendsearch = true;
            break;
        end
        
        
    end
    
    % as long as there is timestamps_target data, store the matching timestamp index
    if (~flag_isendsearch)
        searchindex_all = [searchindex_all; searchindex_target];

        % i add +1 so that the next timestamp_reference will be compared to
        % the next timestamp_target
        searchindex_target = searchindex_target + 1;
        
        % a flag if the timestamps_target data is finished
        if (searchindex_target == length(timestamps_target))
            flag_isendsearch = true;
            break;
        end

    else
        if (isempty(searchindex_all))
            warning("Can't find match for a value in timestamps_reference, consider (1) bigger tolerance, or (2) flip the variable for timestamps_reference and timestamps_target")
        end
        break;
    end
    
end

end

