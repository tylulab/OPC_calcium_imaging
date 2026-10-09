clear;

[file,path] = uigetfile('*.mat');
if isequal(file, 0)
    disp('No file selected. Exiting.');
    return;
end
Fullname = fullfile(path, file);
load(Fullname);

% --- Prompt user to choose a channel ---
channel = input('Generate heat map for channel 1 or 2? ', 's');
while ~ismember(channel, {'1','2'})
    channel = input('Invalid input. Please enter 1 or 2: ', 's');
end

evtField = ['evtSelectedList' channel];
ftsField = ['fts' channel];

% Check that the selected channel contains data
hasData = isfield(res, evtField) && ~isempty(res.(evtField)) && ...
          isfield(res, ftsField) && isfield(res.(ftsField), 'loc') && ...
          isfield(res.(ftsField).loc, 'xSpa') && ~isempty(res.(ftsField).loc.xSpa);

if ~hasData
    disp('data is not available in the channel selected');
    return;
end

evtSelectedList = res.(evtField);          % res.evtSelectedList1 or res.evtSelectedList2
xSpa            = res.(ftsField).loc.xSpa; % res.fts1.loc.xSpa  or res.fts2.loc.xSpa
% ---------------------------------------

w = res.opts.sz(1); %movie width
h = res.opts.sz(2); %movie height
f = res.opts.sz(4); %the number of frames

n = size(evtSelectedList, 1); %No. of events
frameRate = res.opts.frameRate;
Max_Projection = zeros(w, h); %Prepare the canvas
sz = [w h];

for i = 1:n
    [row, col] = ind2sub(sz, xSpa{1, evtSelectedList(i)});
    
    L = size(row, 1); %subscript length
  
    for j = 1: L
        Max_Projection(row(j), col(j)) = Max_Projection(row(j), col(j)) + 1;
    end
end

length = (f-1) * frameRate/60; %movie length in minutes
Max_Projectionf = Max_Projection/length; %event frequency in # of events/min

MaxMap = figure;

% --- Custom colormap: black for 0, jet for values above 0 ---
nColors = 256;                         % Total number of colors in the map
jetMap = jet(nColors - 1);            % jet colormap for non-zero values
customMap = [0 0 0; jetMap];          % Prepend black (RGB: 0,0,0) for value = 0
colormap(customMap);
% ------------------------------------------------------------

clims = [0 3];
imagesc(Max_Projectionf, clims);
axis square;
yticks ([]); 
xticks ([]);
colorbar;



