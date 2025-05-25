function out=GrabCyclePosition(filename)
% Grab Cycle Position for parsed analysis.
fid=fopen(filename,'r'); % open the file.
C=textscan(fid,'%s'); % read a string
matches=strfind(C{1,1}, 'state.cycle.currentCyclePosition='); % Find the cell with string 'state.cycle.currentCyclePosition='
index=find(~cellfun(@isempty,matches)); % Find the index of the cell that contains current cycle position.
D=C{1,1}(index); %Get current cycle position

name=char(D);
out = name(end);

fclose(fid);

end

