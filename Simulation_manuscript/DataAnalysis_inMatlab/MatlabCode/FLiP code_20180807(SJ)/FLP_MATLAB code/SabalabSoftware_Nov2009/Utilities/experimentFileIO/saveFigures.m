function saveFigures(pathname, filename)
	if nargin<2
		[filename, pathname] = uiputfile('*.mat', 'Select folder and prefix for figures...');
	end
	if isempty(filename) | isnumeric(filename)
		quit cancel;
		return;
	end
	periods=findstr(filename, '.');
	if any(periods)								
		fname=filename(1:periods(1)-1);
	else
		fname=filename;
	end

	disp('Saving figures...');
	persistent nosaveWindows
	if ~exist('nosaveWindows')
		nosaveWindows={...
			'SCOPE', ...
			'PULSE PATTERN', ...
			'Acquisition of Channel 1', ...
			'Acquisition of Channel 2', ...
			'Acquisition of Channel 3', ...
			'Max Projection of Channel 1', ...
			'Max Projection of Channel 2', ...
			'Max Projection of Channel 3', ...
			'Composite', ...
			'Graphical LUT', ...
			'AVG LINE SCAN', ...
			};
	end
	
	f=findobj('Type', 'figure');
	evalin('base', 'global savedFigureList');
	global savedFigureList
	savedFigureList={};
	for counter=1:length(f)
		name=get(f(counter), 'Name');
		if isempty(name)
			name=['Figure ' num2str(f(counter))];
		end
		if ~any(strcmp(name, nosaveWindows))
			disp(['Saving figure ' name ' as ' [fname '_figure' num2str(counter)] '...']);
			saveas(f(counter), fullfile(pathname, [fname '_figure' num2str(counter)]));
			savedFigureList{counter}=[fname '_figure' num2str(counter)];
		else
	%		disp(['Skipping figure ' name]);
		end			
	end
	evalin('base', ['save(''' fullfile(pathname, [fname '_savedFigureList']) ''', ''savedFigureList'');']);
