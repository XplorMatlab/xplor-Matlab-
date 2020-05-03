classdef DisplayLayout
    % function L = displaylayout(D)
    %---
    % This is a simple class that defines where each dimension is displayed
    % in XPLOR display.
    
    properties
        % parent display
        D
        % layout: the properties below are dimension identifiers (not
        % numbers)
        x
        y
        merged_data
        xy
        yx
    end
    properties (Dependent, SetAccess='private')
        dim_locations
        grid_display
    end
    
    % Create
    methods
        function L = DisplayLayout(D)
            % parent display
            L.D = D;
            
            % choose a default organization for display D
            nd = D.nd;
            do_image = strcmp(D.display_mode, 'image');
            data_dim_id = [D.slice.header.dim_id];
            if D.nd == 3 && do_image
                L.x = data_dim_id(1);
                L.y = data_dim_id(2);
                L.xy = data_dim_id(3);
            else
                L.x = data_dim_id(1:2:nd);
                L.y = data_dim_id(2:2:nd);
            end
        end
    end
    
    % Simple get dependent
    methods
        function d = get.grid_display(L)
            d = [L.xy, L.yx];
        end
    end
    
    % Manipulation
    methods
        function pos = get.dim_locations(L)
            pos = cell(1, L.D.nd);
            data_head = L.D.slice.header;
            data_dim_id = [data_head.dim_id];
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i=1:length(F)
                f = F{i};
                dim_id = L.(f);
                [ok, dim] = ismember(dim_id, data_dim_id);
                pos(dim(ok)) = {f}; 
            end
        end
        function pos = dim_location(L, dim)
            if ~isscalar(dim), error 'argument ''dim'' must be scalar', end
            dim_id = L.D.slice.dimension_id(dim);
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i=1:length(F)
                f = F{i};
                if any(L.(f) == dim_id)
                    pos = f;
                    return
                end
            end
            error('no location found for dimension %g', dim_id)
        end
        function s = dimension_number(L)
            % function s = dimension_number(L)
            %---
            % Return a structure with same fields x, y, merged_data, xy and yx
            % as L, but where values will be dimension numbers instead of
            % identifiers.
            s = struct;
            data_head = L.D.slice.header;
            data_dim_id = [data_head.dim_id];
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i=1:length(F)
                f = F{i};
                dim_id = L.(f);
                [ok, dim] = ismember(dim_id, data_dim_id);
                if ~all(ok)
                    error 'some dimension is not in data'
                end
                s.(f) = dim;
            end
        end
        function L2 = current_layout(L)
            % function L2 = current_layout(L)
            %---
            % keep from layout L only dimensions that are non-singleton
            L2 = L; % copy (displaylayout is not a handle class)
            data_head = L.D.slice.header;
            data_dim_id = [data_head.dim_id];
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i = 1:length(F)
                f = F{i};
                dim_idf = L.(f);      % dimension identifiers
                [present, dim_f] = ismember(dim_idf, data_dim_id);
                if ~all(present)
                    error 'programming: some layout dimensions are not present in the slice'
                end
                keep = ([data_head(dim_f).n] > 1);
                L2.(f) = data_dim_id(dim_f(keep));
            end
        end
        function [L, L2] = update_layout(L)
            % function [L, L2] = update_layout(L)
            %---
            % Update layout upon slice change.
            % Keep locations of dimensions already present in L, 
            % remove dimensions that are not in L.D.slice anymore,
            % use some heuristic to choose locations of new dimensions
            % 
            % Input:
            % - L   layout
            %
            % Output:
            % - L   new layout
            % - L2  new layout, with singleton dimensions removed
            
            L2 = L; % copy (displaylayout is not a handle class)
            data_head = L.D.slice.header;
            data_dim_id = [data_head.dim_id];
            
            % dimensions already positionned + remove dimensions that
            % disappeared
            dim_positionned = false(1, L.D.nd);
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i = 1:length(F)
                f = F{i};
                dim_idf = L.(f);      % dimension identifiers
                % mark among data dimensions those that are positionned
                dim_positionned = dim_positionned | ismember(data_dim_id, dim_idf);
                % and keep among L.(f) and L2.(f) only dimensions that are
                % still present in the data
                [present, dim] = ismember(dim_idf, data_dim_id);
                dim_present = dim(present); % dimension numbers of those actually present in the data
                singleton = ([data_head(dim_present).n] == 1);
                L.(f) = data_dim_id(dim_present);
                L2.(f) = data_dim_id(dim_present(~singleton));
            end
            
            % layout without the singleton dimensions
            L2 = L.current_layout();
            
            % position missing dimensions
            for d = find(~dim_positionned)
                if data_head(d).n > 1
                    % insert in both L (which gathers all dimensions) and
                    % L2 (which keeps only displayed dimensions); try to
                    % keep L2 balanced between number of dimensions in x
                    % and y
                    if length(L2.y) <= length(L2.x)
                        L.y(end+1) = data_dim_id(d);
                        L2.y(end+1) = data_dim_id(d);
                    else
                        L.x(end+1) = data_dim_id(d);
                        L2.x(end+1) = data_dim_id(d);
                    end
                else
                    % insert only in L because dimension is not displayed;
                    % try to keep L balanced
                    if length(L.y) <= length(L.x)
                        L.y(end+1) = data_dim_id(d);
                    else
                        L.x(end+1) = data_dim_id(d);
                    end
                end
            end
        end
        function [L, L2] = set_dim_location(L, dim_id, location)
            % function [L, L2] = set_dim_location(L,dim_id,location)
            %---
            % set new location of specific dimensions; locations of other
            % dimensions will automatically be adjusted
            %
            % Input:
            % - dim_id       dimension identifier(s)
            % - location    character arrays: 'x', 'y', 'xy', 'yx' or
            %               'merged_data', with, for 'x' and 'y' optional
            %               indication of index where to insert the
            %               location ('x0' = at the beginning = default,
            %               'x1' = next, 'x-1' = last)
            %               or cell array thereof for multiple dimensions
            %
            % Output:
            % - L   new layout
            % - L2  new layout, with singleton dimensions removed
            
            % input
            dim_id = L.D.slice.dimension_id(dim_id);
            if ~iscell(location), location = {location}; end
            if length(dim_id) ~= length(location), error 'input lengths mismatch', end
            
            % remove these dimensions from the layout
            F = {'x', 'y', 'merged_data', 'xy', 'yx'};
            for i = 1:length(F)
                f = F{i};
                L.(f)(ismember(L.(f), dim_id)) = [];
            end
            
            % add them at the requested locations
            dim_idmove = []; 
            for i = 1:length(dim_id)
                f = location{i};
                if ismember(f, {'xy', 'yx'})
                    % dimension that is already at 'xy' or 'yx' location if
                    % any will need to be moved somewhere else
                    dim_idmove = [L.xy, L.yx];
                    [L.xy, L.yx] = deal([]);
                    % assign requested dimension to the requested location
                    L.(f) = dim_id(i);
                else
                    % insert in either location 'x', 'y' or 'merged_data' at a
                    % specific position
                    [f, index] = fn_regexptokens(f, '^(x|y|merged_data)([\-0-9]*)$');
                    if isempty(index)
                        index = 0;
                    else
                        index = str2double(index);
                        if index < 0
                            % negative index: count from the end
                            index = length(L.(f)) + 1 - index;
                        end
                    end
                    L.(f) = [L.(f)(1:index), dim_id(i), L.(f)(index+1:end)];
                end
            end
            
            % layout without the singleton dimensions
            L2 = L.current_layout();
            
            % dimension that needs to be moved somewhere else
            for d = dim_idmove
                if data_head(d).n > 1
                    % insert in both L (which gathers all dimensions) and
                    % L2 (which keeps only displayed dimensions); try to
                    % keep L2 balanced between number of dimensions in x
                    % and y
                    if length(L2.y) <= length(L2.x)
                        L.y(end+1) = data_dim_id(d);
                        L2.y(end+1) = data_dim_id(d);
                    else
                        L.x(end+1) = data_dim_id(d);
                        L2.x(end+1) = data_dim_id(d);
                    end
                else
                    % insert only in L because dimension is not displayed;
                    % try to keep L balanced
                    if length(L.y) <= length(L.x)
                        L.y(end+1) = data_dim_id(d);
                    else
                        L.x(end+1) = data_dim_id(d);
                    end
                end
            end
                
        end
    end
    
end
