#This is a package of graphing things I use often
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch
from matplotlib.lines import Line2D
from copy import deepcopy
import random
import math
from matplotlib import cm

def thick_axes(fig, ax, width = 3):
	num_ax = len(fig.get_axes())
	if num_ax > 1:
		if len(np.shape(ax)) > 1:
			rows = np.shape(ax)[0]
			cols = np.shape(ax)[1]
			for r in np.arange(0, rows):
				for c in np.arange(0, cols):
					ax[r,c].tick_params(width=width)
					for axis in ['bottom','left']:
						ax[r,c].spines[axis].set_linewidth(width)
					for axis in ['right','top']:
						ax[r,c].spines[axis].set_visible(False)
		else:
			for ii in np.arange(0, num_ax):
				ax[ii].tick_params(width=width)
				for axis in ['bottom','left']:
					ax[ii].spines[axis].set_linewidth(width)
				for axis in ['right','top']:
					ax[ii].spines[axis].set_visible(False)
	else:
		ax.tick_params(width=width)
		for axis in ['bottom','left']:
			ax.spines[axis].set_linewidth(width)
		for axis in ['right','top']:
			ax.spines[axis].set_visible(False)

	return fig, ax

def linegraph_w_error(ax, x,y, error, color = 'k', label = None, linewidth = 1, 
	linestyle = '-', alpha = 0.5):
	ax.plot(x,y, color = color, label = label, linewidth = linewidth, 
		linestyle = linestyle)
	upper_bound = y+error
	lower_bound = y-error
	ax.fill_between(x, upper_bound, lower_bound, color = color, alpha = alpha, edgecolor = None)
	return ax


def make_bigandbold(xticksize = 15, yticksize = 15, axeslabelsize = 17, font = "Arial", bold = False):
	plt.rc('xtick', labelsize = xticksize)
	plt.rc('ytick', labelsize = yticksize)
	plt.rc('axes', labelsize = axeslabelsize)
	if bold:
		plt.rcParams["font.weight"] = "bold"
		plt.rcParams["axes.labelweight"] = "bold"
	plt.rcParams["font.family"] = font

def label_axes(ax, x = False, y= False, title= False, title_fontsize = 25, fontweight = 'normal'):
	if x:
		ax.set_xlabel(x)
	if y:
		ax.set_ylabel(y)
	if title:
		ax.set_title(title, fontsize = title_fontsize, fontweight = fontweight)

	return ax

def SW_colordict(keys):
	color_dict = {}
	if keys == 'numbers':
		color_dict['1'] = '#54ac68'
		color_dict['2'] = '#a2bffe'
		color_dict['3'] = '#ff6163'
		color_dict['4'] = '#54ac68'
		color_dict['5'] = '#fac205'
	if keys == 'single state':
		color_dict['Wake'] = '#54ac68'
		color_dict['NREM'] = '#a2bffe'
		color_dict['REM'] = '#ff6163'
		color_dict['Wake'] = '#54ac68'
		color_dict['Microarousals'] = '#fac205'
	if keys == 'transitions':
		color_dict['NREM-Wake'] = '#54ac68'
		color_dict['NREM-Active Wake'] = '#54ac68'
		color_dict['NREM-Quiet Wake'] = '#a55af4'

		color_dict['Sleep-Wake'] = '#54ac68'
		color_dict['REM-Wake'] = '#9be5aa'
		color_dict['REM-Active Wake'] = '#9be5aa'
		color_dict['REM-Quiet Wake'] = '#c48efd'

		color_dict['NREM-REM'] = '#ff6163'
		color_dict['Wake-REM'] = '#ff000d'

		color_dict['REM-NREM'] = '#488ee4'
		color_dict['Wake-NREM'] = '#a2bffe'
		color_dict['Wake-Sleep'] = '#a2bffe'
		color_dict['Active Wake-NREM'] = '#a2bffe'
		color_dict['Quiet Wake-NREM'] = '#a2bffe'

		color_dict['Active Wake-Quiet Wake'] = '#c48efd'
		color_dict['Quiet Wake-Active Wake'] = '#9be5aa'

		color_dict['Unknown'] = '#d8dcd6'

		color_dict['Microarousal'] = '#fac205'
		color_dict['Microarousals'] = '#fac205'

	return color_dict

def remove_yticks(fig, ax):
	num_ax = len(fig.get_axes())
	for ii in np.arange(1, num_ax):
		ax[ii].set_yticklabels([])
	return fig, ax

def grouped_bargraph(fig, ax, yvals, colors, x_labels = [], legend_labels = None, edgecolor = None, 
	linewidth = None, rotation = 0):
	assert len(yvals) == len(x_labels)
	assert len(yvals[0]) == len(colors)
	tot_group_width = len(colors)
	xvals = []
	count = 0
	for i in np.arange(0, len(x_labels)):
		xvals.append(np.arange(count, count+len(colors)))
		count += len(colors)+1
	assert len(yvals) == len(xvals) == len(x_labels)
	for ii in np.arange(0, len(yvals)):
		bars = ax.bar(xvals[ii], yvals[ii], color = colors, width = 1, align = 'edge', 
			edgecolor = edgecolor, linewidth = linewidth)
	x_ticks = [x[0]+(len(x)/2) for x in xvals]
	ax.set_xticks(x_ticks)
	ax.set_xticklabels(x_labels, rotation = rotation)
	color_map = list(zip(list(yvals[0]), colors))
	patches = [Patch(color=v, label=k) for k, v in color_map]
	if legend_labels is not None:
		assert len(yvals[0]) == len(colors) == len(legend_labels)
		ax.legend(labels = legend_labels, handles = patches, fontsize = 15, ncols = math.ceil(len(legend_labels)/3))

	return fig, ax, xvals

def get_jittered_x(x, size, width = 0.25):
	x_vals = np.random.uniform(low=x-width, high=x+width, size=size)
	return x_vals

def violin_plot(fig, ax, data, x_positions, colors, showmeans = False, showmedians = True, xlabels = []):
	for i,d in enumerate(data):
		d = d[~np.isnan(d)]
		violin_parts = ax.violinplot(d, showmeans = showmeans, showmedians = showmedians, positions = [x_positions[i]])
		violin_parts['bodies'][0].set_color(colors[i])
		violin_parts['cmins'].set_color(colors[i])
		violin_parts['cmaxes'].set_color(colors[i])
		violin_parts['cbars'].set_color(colors[i])
		if showmedians:
			violin_parts['cmedians'].set_color(colors[i])
		if showmeans:
			violin_parts['cmeans'].set_color(colors[i])
	ax.set_xticks(x_positions)
	ax.set_xticklabels(xlabels)
	return fig, ax
def pick_scatter_markers(num_markers):
	marker_dict = deepcopy(Line2D.markers)
	for m in ['None', None, ' ', '', '_', '.',',','|', 0,1]:
		marker_dict.pop(m)
	all_markers = len(marker_dict.keys())
	these_markers = random.sample(list(marker_dict.keys()), num_markers)
	return these_markers

def swarm_plot(fig, ax, scatter_vals, x_centers, colors, edgecolors = None, x_width = 0.25, avg_type = 'median', percentiles = [25, 75], 
	x_labels = None, ylabel = None, capsize = 15, markersize = 60, alpha = 0.7, scatter_size = 5, match_ebarcolor = False, legend_labels = None):
	idx = []
	for s in range(len(scatter_vals)):
		scatter_vals[s] = np.asarray(scatter_vals[s])[~np.isnan(np.asarray(scatter_vals[s]))]
		if len(scatter_vals[s]) > 0:
			idx.append(s)

	scatter_vals = [scatter_vals[i] for i in idx]
	x_centers = [x_centers[i] for i in idx]
	colors = [colors[i] for i in idx]

	x_vals = [get_jittered_x(ii, len(scatter_vals[i]), width = x_width) for i,ii in enumerate(x_centers)]
	if avg_type:
		if avg_type == 'median':
			avgs = [np.median(scatter_vals[i]) for i in range(len(scatter_vals))]
			y_err = [abs(np.percentile(scatter_vals[i], percentiles)-avgs[i]) for i in range(len(scatter_vals))]
		elif avg_type == 'mean':
			avgs = [np.mean(scatter_vals[i]) for i in range(len(scatter_vals))]
			y_err = [np.std(scatter_vals[i]) for i in range(len(scatter_vals))]
		else:
			print('I do not understand your average type. Please try again')
			return

	for ii in range(len(scatter_vals)):
		if match_ebarcolor:
			bar_color = colors[ii]
		else:
			bar_color = 'k'
		if edgecolors:
			e_color = edgecolors[ii]
		else:
			e_color = colors[ii]
		if legend_labels:
			label = legend_labels[ii]
		else:
			label = False
		ax.scatter(x_vals[ii], scatter_vals[ii], color = colors[ii], alpha = alpha, s = scatter_size, edgecolors = e_color, label = label)
		if avg_type == 'median':
			ax.errorbar(x_centers[ii], avgs[ii], ecolor = bar_color, yerr = np.reshape(y_err[ii], [2,-1]), elinewidth = 2,
			             linestyle = 'none', capsize = capsize, zorder = 10, marker = '_', markeredgecolor = bar_color, markersize = markersize)
		elif avg_type == 'mean':
			ax.errorbar(x_centers[ii], avgs[ii], ecolor = bar_color, yerr = y_err[ii], elinewidth = 2,
			             linestyle = 'none', capsize = capsize, zorder = 10, marker = '_', markeredgecolor = bar_color, markersize = markersize)

	if x_labels:
		ax.set_xticks(x_centers)
		ax.set_xticklabels(x_labels)
	if ylabel:
		ax.set_ylabel(ylabel)
	fig.tight_layout()

	return fig, ax

def match_yaxes(axes):
	ylims = [a.get_ylim() for a in axes]
	ymin = min([y[0] for y in ylims])
	ymax = max([y[1] for y in ylims])
	for a in axes:
		a.set_ylim([ymin, ymax])

def match_xaxes(axes):
	xlims = [a.get_xlim() for a in axes]
	xmin = min([x[0] for x in xlims])
	xmax = max([x[1] for x in xlims])
	for a in axes:
		a.set_xlim([xmin, xmax])

def get_colormap(num_colors, cmap_name = 'viridis'):
	colormap = cm.get_cmap(cmap_name)
	colors_list = colormap(np.linspace(0, 1, num_colors))
	return colors_list






