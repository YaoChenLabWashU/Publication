function [amp, tau, tau2]=selectAndFit(fHandle)
	amp=[];
	tau=[];
	
	if nargin==1
		selectAnalysisRange(fHandle);
	else
		selectAnalysisRange;
	end	
	
	global display_expRange display_expFit
	if ~iswave(display_expFit)
		waveo('display_expFit', []);
	end
	logFit = polyfit( makeXData(display_expRange), log10(display_expRange.data),1);
	display_expFit.data = 10.^polyval(logFit,makeXData(display_expRange));
	display_expFit.xscale=display_expRange.xscale;

	amp=display_expFit(1);
	tau=-2.3026/logFit(1);

	top=display_expRange.data(1);
	below=display_expRange.data<(top/exp(1));
	tau2=pnt2x(display_expRange, min(find(below)));
	

	
	