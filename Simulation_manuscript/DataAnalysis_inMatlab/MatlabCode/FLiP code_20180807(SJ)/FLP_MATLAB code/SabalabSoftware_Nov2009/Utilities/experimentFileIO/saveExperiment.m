function saveExperiment(pathname, filename)
	if nargin<2
		[filename, pathname] = uiputfile('*.mat', 'Select folder and name for experiment...');
	end
	if isempty(filename) | isnumeric(filename)
		quit cancel;
		return;
	end
	
	saveFigures(pathname, filename);
	
	disp('Saving workspace...');
	evalin('base', ['save(''' fullfile(pathname, filename) ''');']);
	disp(['*** SAVE EXPERIMENT ' fullfile(pathname, filename) ' ***']);
