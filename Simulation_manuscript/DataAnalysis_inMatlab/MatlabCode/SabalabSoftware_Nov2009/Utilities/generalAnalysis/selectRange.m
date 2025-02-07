function out=selectRange(fHandle)
		out=[];
		if nargin==1
			figure(fHandle);
		end
		k = waitforbuttonpress;
	
		if isempty(findobj(gcf, 'Type', 'axes'))
			disp('*** NO axes***');
			return
		end
		
		point1 = get(gca,'CurrentPoint');    % button down detected
		finalRect = rbbox;                   % return figure units
	
		point2 = get(gca,'CurrentPoint');    % button up detected
		point1 = point1(1,1:2);              % extract x and y
		point2 = point2(1,1:2);
		p1 = min(point1,point2);             % calculate locations
		offset = abs(point1-point2);         % and dimensions
		x = [p1(1) p1(1)+offset(1) p1(1)+offset(1) p1(1) p1(1)];
		y = [p1(2) p1(2) p1(2)+offset(2) p1(2)+offset(2) p1(2)];
		out=[x(1) x(2) y(1) y(3)];
		