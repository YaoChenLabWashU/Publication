function spc_drawLifetime_FLP(chan,fast)
% calculates the lifetime (above the LutLower and cropped to ROI) and displays it
% fast just avoids bringing the window to the front
% multiFLIM gy 2011116
global spc state gui

if nargin<2
    fast = 1;
end

if bitget(state.spc.FLIMchoices(chan),3)  % special channel
    % right now, no lifetime display for special channels
    return
end

nsPerPoint=spc.datainfo.psPerUnit/1000;
range = round([spc.fits{chan}.fitstart spc.fits{chan}.fitend]/nsPerPoint);
%range = round([spc.fits{1}.fitstart spc.fits{1}.fitend]/nsPerPoint); %SJ: there is only one fitstart and fitend defined for lifetime plot
 
% now get the 1D lifetime data restricted to the fit range
lifetime = spc.lifetimes{chan}(range(1):1:range(2));
lifetime = lifetime(:);
t = (range(1):range(2))*nsPerPoint;

% the plots for different channels are created in spc_drawInit
set(gui.spc.figure.lifetimePlot(chan), 'XData', t, 'YData', lifetime);
% gy 201112 don't make the fit look like the data
%set(gui.spc.figure.fitPlot(chan), 'XData', t, 'YData', lifetime);
%set(gui.spc.figure.residualPlot(chan), 'Xdata', t, 'Ydata', zeros(length(lifetime), 1));
set(gui.spc.figure.lifetimeAxes, 'XTick', []);
if (spc.switches.logscale == 0)
    set(gui.spc.figure.lifetimeAxes, 'YScale', 'linear');
else
    set(gui.spc.figure.lifetimeAxes, 'YScale', 'log');
end

% if not fast, bring the lifetime plot figure to the front
if ~fast
    figure(gui.spc.figure.lifetime);
end
end
