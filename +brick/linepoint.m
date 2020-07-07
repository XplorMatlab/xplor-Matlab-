function [idx x y] = linepoint(hl,outflag)
% function [idx x y] = linepoint(hl)
% function x = linepoint(hl,'x')
% function y = linepoint(hl,'y')
%---
% When a line has been selected with mouse, get index of its point that is
% closer to the mouse location

if ~strcmp(get(hl,'type'),'line'), error 'input handle must be a line', end
ha = get(hl,'parent');
if ~strcmp(get(ha,'type'),'axes'), error 'line parent must be an axes', end

% current point
p = get(ha,'CurrentPoint'); p = p(1,1:2);

% line points
[xx yy] = brick.get(hl,'xdata','ydata');

% ratio of line display
s = brick.pixelsize(ha);
r = (diff(get(ha,'xlim'))/s(1)) / (diff(get(ha,'ylim'))/s(2));

% find closest point on the line
D2 = sum(brick.subtract([p(1) p(2)*r],[xx(:) yy(:)*r]).^2,2);
[~, idx] = min(D2);
x = xx(idx);
y = yy(idx);

% output
if nargin>=2
    switch outflag
        case 'x'
            idx = x;
        case 'y'
            idx = y;
        otherwise
            error 'out flag'
    end
end




