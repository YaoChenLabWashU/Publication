function [rgbLifetime] = Yao_applyFilter(filterType,chan)
global spc gui


if ~exist('chan','var')
    chan = 1;
end
if ~exist('filterType','var')
    filterType = 'median';
end
filterType = lower(filterType);



if strcmp(filterType,'median')
    % Median filter both the lifetimeMap and the projection image 2X2.
    spc.lifetimeMaps{chan}=medfilt2(spc.lifetimeMaps{chan},[3 3]);
    spc.projects{chan}=medfilt2(spc.projects{chan},[3 3]);
elseif strcmp(filterType,'density')
    spc.lifetimeMaps{chan}=...
        Yao_generic_applyDensityFilter(spc.lifetimeMaps{chan});
    spc.projects{chan}=...
        Yao_generic_applyDensityFilter(spc.projects{chan});
elseif strcmp(filterType,'fft')
    spc.lifetimeMaps{chan}=...
        Yao_generic_applyFFTFilter(spc.lifetimeMaps{chan});
    spc.projects{chan}=...
        Yao_generic_applyFFTFilter(spc.projects{chan});
end


spc_makeRGBLifetimeMap(chan);
% and now redisplay them
set(gui.spc.lifetimeMaps{chan}.image, 'CData', spc.rgbLifetimes{chan});
set(gui.spc.lifetimeMaps{chan}.axes, 'XTick', [], 'YTick', []);
newSize=size(spc.projects{chan},1);
axis(gui.spc.lifetimeMaps{chan}.axes,[1 newSize 1 newSize]);

%axes(gui.spc.projects{chan}.axes);
set(gui.spc.projects{chan}.projectImage, 'CData', spc.projects{chan}, 'CDataMapping', 'scaled');
axis(gui.spc.projects{chan}.axes,[1 newSize 1 newSize]);



rgbLifetime = spc.rgbLifetimes{1,chan};