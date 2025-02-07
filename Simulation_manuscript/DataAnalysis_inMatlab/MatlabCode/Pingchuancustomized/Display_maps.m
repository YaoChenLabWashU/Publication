chan=1;

figure
image(spc.rgbLifetimes{chan});
axis off;

figure
h=heatmap(spc.projects{1});
h.Colormap=gray
Ax=gca;
Ax.XDisplayLabels = nan(size(Ax.XDisplayData));
Ax.YDisplayLabels = nan(size(Ax.YDisplayData));
h.ColorbarVisible='off';
h.GridVisible='off';
h.ColorLimits=[0 600];