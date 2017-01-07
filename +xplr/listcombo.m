classdef listcombo < hgsetget
    % function C = listcombo(container,linkkey,filters)
    %---
    % if container is empty, a new figure will be created; this
    % figure will auto-delete once all filters will be removed
    
    properties
        container
        linkkey
        filters = xplr.filterAndPoint.empty(1,0);
    end
    
    events
        Empty
    end
    
    % Constructor, add and remove lists
    methods
        function C = listcombo(container,linkkey,filters)
            
            % input
            if nargin<1, container = []; end
            if nargin<2, linkkey = 1; end
            if nargin<3, filters = []; end
            C.linkkey = linkkey;
                
            % create new containing figure? (in this case, set auto-delete)
            if isempty(container)
                container = figure('integerhandle','off','handlevisibility','off', ...
                    'numbertitle','off','menubar','none', ...
                    'name',sprintf('Shared Filters [key=%i]',linkkey));
                %                 if linkkey>0
                %                     col = xplr.colors('linkkey',linkkey)*.5 + get(container,'color')*.5;
                %                     set(container,'color',col)
                %                 end
                delete(findall(container,'parent',container))
                addlistener(C,'Empty',@(u,e)delete(container));
            end
            if ~isa(container,'panelorganizer')
                container = panelorganizer(container,'H');
            end
            addlistener(container,'ObjectBeingDestroyed',@(u,e)delete(C));
            C.container = container;
            
            % display lists
            C.addList(filters)
        end
        function delete(C)
            if ~isprop(C,'filters'), return, end
            if ~isempty(C.filters), notify(C,'Empty'), end
        end
        function addList(C,filter)
            % empty or multiple filters?
            if ~isscalar(filter)
                for i=1:length(filter), C.addList(filter(i)), end
                return
            end
            
            % new panel
            [hp idx] = C.container.addSubPanel;
            
            % create graphic objects
            % (list)
            hlist = uicontrol('parent',hp,'style','listbox');
            fn_controlpositions(hlist,hp,[0 0 1 1],[8 5 -16 -5-21-2])
            % (label)
            hlabel = uicontrol('parent',hp,'style','text');
            if C.linkkey>0
                set(hlabel,'backgroundcolor',xplr.colors('linkkey',C.linkkey))
            end
            fn_controlpositions(hlabel,hp,[0 1 1 0],[8 -21 -8-18 18])
            % (close button)
            x = fn_printnumber(ones(18),'x','pos','center')'; 
            x(x==1) = NaN; x = repmat(x,[1 1 3]);
            hclose = uicontrol('parent',hp,'cdata',x,'callback',@(u,e)C.removeList(hp));
            fn_controlpositions(hclose,hp,[1 1],[-8-18 -3-18 18 18])

            % create list
            xplr.list(filter,'in',[hlist hlabel]);
            
            % memorize which filter is at this position
            C.filters(idx) = filter;
        end
        function removeList(C,hp_or_idx)
            % function removeList(C,hp|idx)
            
            % remove panel
            idx = C.container.removeSubPanel(hp_or_idx);
            C.filters(idx) = [];
            % signal whether there are no more list being displayed
            if C.container.nchildren==0
                notify(C,'Empty')
            end
        end
    end
    
    methods (Static)
        function C = test
            head = xplr.header({'x' 10},{'y' 12},{'cond' {'a' 'b' 'c' 'd'}});
            for i=1:length(head)
                filters(i) = xplr.filterAndPoint(head(i),'indices'); %#ok<AGROW>
            end
            key = 2;
            C = xplr.listcombo([],key,filters);
            % repeat the 2d list
            C.addList(filters(2))
        end
    end
    
end


