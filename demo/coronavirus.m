
url = 'https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide.csv';
data = webread(url);

%% Header information

% Dates
dates = data(:,1); % first column
dates = table2array(dates); % convert to datetime class
dates = days(dates - min(dates)); % convert to numeric, starting from day 0
nday = max(dates) + 1;

% Countries
countries = table2array(data(:,7)); % cell of char arrays
[countries, idxcountry2row, idxrow2country] = unique(countries);
countries = strrep(countries,'_',' ');
population = table2array(data(idxcountry2row,9));
ncountry = length(countries);

%% Data

cases = table2array(data(:,5));
deaths = table2array(data(:,6));
pop = table2array(data(:,9));
cases_prc_pop = cases ./ pop * 100;
deaths_prc_pop = deaths ./ pop * 100;
deaths_prc_cases = deaths ./ cases * 100;

data_per_row = [cases deaths cases_prc_pop deaths_prc_pop deaths_prc_cases];
datanames = {'cases' 'deaths' 'cases/population' 'deaths/population' 'deaths/cases'};
ndata = length(datanames);

% make a 3D array out of the Excel table
data3d = zeros(nday, ncountry, ndata);
for i = 1:size(data_per_row,1)
    
    data3d(dates(i)+1, idxrow2country(i), :) = data_per_row(i,:);
    
end

%% Get world map from internet (requires Mapping Toolbox and Internet connection)

folder = fullfile(fileparts(which('xplor')),'demo');
worldmapfile = fullfile(folder,'worldmap.shp');
if ~exist(worldmapfile,'file')
    %% ()
    % see https://thematicmapping.org/downloads/world_borders.php
    url = 'https://thematicmapping.org/downloads/TM_WORLD_BORDERS_SIMPL-0.3.zip';
    files = unzip(url, folder);
    for i = 1:length(files)
        f = files{i};
        if strcmp(fn_fileparts(f,'name'), 'Readme.txt')
            delete(f)
        else
            movefile(f, strrep(f, 'TM_WORLD_BORDERS_SIMPL-0.3', 'worldmap'))
        end
    end        
end
S = shaperead(worldmapfile);

%% Project map shapes into image

% projection structure
mstruct = defaultm('robinson'); 
mstruct.origin = [0 0 0]; 
mstruct = defaultm(mstruct);

% bounding box
[left, ~]   = mfwdtran(mstruct,0,-180);
[right, ~]  = mfwdtran(mstruct,0,180);
[~, bottom] = mfwdtran(mstruct,-90,0);
[~, top]    = mfwdtran(mstruct,90,0);
boundingbox = [left bottom; right top]; % columns = X/Y

% image size and scaling from mfwdtran output
nx = 500; % image width
scale = (nx-2.2) / diff(boundingbox(:,1));
ny = ceil(diff(boundingbox(:,2)) * scale + 1.7);
scale(2,1) = -scale; % Y goes from bottom to top, but image indices go from top to bottom
offset = [1.6; ny-.6] - boundingbox(1,:)'.*scale;     % offset(1) + bounddingbox(2,1) will be equal to [1+0.6 nx-0.6]

% country colors
nshape = length(S);
colors = randomcolors(nshape);

% make map!
map = zeros(nx,ny);
mapcolor = zeros(nx*ny, 3);
for i = 1:nshape
    % area-preserving projection
    [x, y] = deal(S(i).X, S(i).Y);        % longitude/latitude
    [x, y] = mfwdtran(mstruct,y,x);       % apply projection
    [x, y] = deal(offset(1) + scale(1)*x, offset(2) + scale(2)*y);  % coordinates in image
    mask = fn_poly2mask(x, y, nx, ny);
    np = sum(mask(:));
    map(mask) = i;
    mapcolor(mask, :) = repmat(colors(i,:), [np 1]);
end
mapcolor = reshape(mapcolor,[nx ny 3]);

% % display
% figure(1)
% imagesc(permute(mapcolor,[2 1 3]))
% axis image

%% Link coronavirus dataset countries with map shapes

shapenames = lower({S.NAME});

country2shape = zeros(1,ncountry);

% look for matches
for i = 1:ncountry
    name = lower(countries{i});

    % some tiny differences
    name = fn_switch(name, ...
        'cote divoire',     'cote d''ivoire', ...
        'laos',             'lao', ...
        'timor leste',      'timor', ...
        'north macedonia',  'macedonia', ...
        'south korea',      'korea, republic of', ...
        'united states of america',     'united states', ...
        'vietnam',          'viet nam', ...
        name);
    
    idx = fn_find(name,shapenames,'first');
    if isempty(idx)
        idx = fn_find(@(s)strfind(s,name), shapenames, 'first');
    end
    if ~isempty(idx)
        country2shape(i) = idx;
    else
        disp(['did not find ' lower(countries{i})])
    end
end

% remove countries not found in shapes
unfound = (country2shape == 0);
countries(unfound) = [];
country2shape(unfound) = [];
ncountry = length(countries);
data3d(:, unfound, :) = [];

%% Make movie!!

data4d = NaN(nday, nx*ny, ndata);
for i = 1:ncountry
    mask = (map == country2shape(i));
    data4d(:, mask, :) = repmat(data3d(:, i, :), [1 sum(mask(:)) 1]);
end
data4d = reshape(data4d, [nday nx ny ndata]);

%% Save data

cd(folder)
save coronavirus dates nday countries ncountry datanames ndata data3d data4d