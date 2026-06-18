import numpy as np
import glob
import os
import PKA_Sleep as PKA
import pandas as pd
import PKA_Sleep.Graphing_Utils as graph
from matplotlib import patches
import matplotlib.pyplot as plt
from scipy import stats
import math
from sklearn.metrics import auc
from neuroscience_sleep_scoring import SWS_utils
from statsmodels.formula.api import mixedlm
import statsmodels.api as sm


def transition_triggered_lifetime(FLP_classes, experiment_names, mouseID, window = [30,30], savedir = False, 
	these_transitions = ['NREM-Wake','REM-NREM','Wake-REM','REM-Wake','NREM-REM','Wake-NREM','Microarousals','Sleep-Wake','Wake-Sleep'],
	intensity = False, diff_wake = False, shuffled = False, fig_dict = False, color_dict = False, 
	long_short_wake = False, long_short_NREM = False, NREM_cutoff = 70, wake_cutoff = 70, allow_nextstate = False,
	raw_lifetime = False, just_dictionary = False, axes_width = 1.25, remove_short = True, zscore = False, time_range = None):
	"""
	This function calculates and visualizes average lifetime and intensity changes
	across sleep state transitions.

	Args:
	----------
	- FLP_classes : list
	    List of objects representing different experiments. Each object contains 
	    sleep states, photometry data, and related metadata.
	- experiment_names : list
	    Names corresponding to the experiments in `FLP_classes`.
	- window : list of two ints, default=[30, 30]
	    Time window around each transition in seconds.
	- savedir : str or False, default=False
	    Directory path to save the plots. If False, plots are not saved.
	- these_transitions : list of str, default=specified list
	    Sleep state transitions to analyze.
	- intensity : bool, default=False
	    If True, also analyzes and plots photon count intensity changes.
	- diff_wake : bool, default=False
	    If True, differentiates between types of wake states.
	- shuffled : bool, default=False
	    If True, includes analysis of shuffled data for comparison.
	- fig_dict : Dictionary of Matplotlib objects or False, default=False
	    Custom figure and axes for plotting. If False, new ones are created.
	- color_dict : dict or False, default=False
	    Custom colors for transitions. Defaults to a predefined dictionary.
	- long_short_wake, long_short_NREM : bool, default=False
	    If True, separates Wake-NREM or NREM-Wake transitions into short/long 
	    based on cutoffs.
	- NREM_cutoff, wake_cutoff : int, default=70, 150
	    Duration thresholds (in seconds) for classifying short/long NREM/Wake.
	- raw_lifetime : bool, default=False
	    If True, uses raw lifetime data; otherwise uses normalized data.
	- just_dictionary : bool, default=False
	    If True, returns data as a dictionary without generating plots.
	- axes_width : float, default=1.25
	    Width of plot axes.

	Returns:
	-------
	- lifetime_fig, lifetime_ax : Matplotlib figure and axes
	    Plots of triggered lifetimes.
	- lifetime_dict : dict
	    Dictionary containing computed lifetime data.
	- FLP_exp : object
	    Last processed experiment class.
	"""
	if type(FLP_classes) is not list:
		FLP_classes = [FLP_classes]
	if type(experiment_names) is not list:
		experiment_names = [experiment_names]
	if type(mouseID) is not list:
		mouseID = [mouseID]

	# Initialize experimental variables
	experimental_sensor = FLP_classes[0].Sensor
	if FLP_classes[0].PhosMeasure == 'Lifetime (ns)':
		y_negative = True
	elif FLP_classes[0].PhosMeasure == 'Binding Fraction':
		y_negative = False

	# Initialize the dictionary to store lifetime and intensity data
	lifetime_dict = {'Experiment Name':[], 'Mouse ID': [], 'Lifetime':{experimental_sensor: {}},
		'Time':{}, 'Previous Bout Length': {'NREM-Wake':[], 'Wake-NREM': []}}

	if intensity:
		lifetime_dict['Intensity'] = {}

	if shuffled:
		lifetime_dict['Lifetime']['Shuffled'] = {}

	# Initialize transition-specific entries in lifetime dictionary
	for k in these_transitions:
		lifetime_dict['Lifetime'][experimental_sensor][k] = []
		if shuffled:
			lifetime_dict['Lifetime']['Shuffled'][k] = []
		if intensity:
			lifetime_dict['Intensity'][k] = []

	# Add labels for long and short states, if enabled
	if long_short_wake:
		new_labels = ['Wake-NREM Long', 'Wake-NREM Short']
		for k in new_labels:
			lifetime_dict['Lifetime'][experimental_sensor][k] = []
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled'][k] = []
			if intensity:
				lifetime_dict['Intensity'][k] = []

	if long_short_NREM:
		new_labels = ['NREM-Wake Long', 'NREM-Wake Short']
		for k in new_labels:
			lifetime_dict['Lifetime'][experimental_sensor][k] = []
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled'][k] = []
			if intensity:
				lifetime_dict['Intensity'][k] = []

	# Additional graph formatting
	graph.make_bigandbold(axeslabelsize = 22)

	# Process each experiment

	for i, (FLP_exp,b,m) in enumerate(zip(FLP_classes, experiment_names, mouseID)):
		if zscore:
			FLP_exp.Shuff = stats.zscore(FLP_exp.Shuff, ddof=0)
		# Storing experiment name into data dictionary
		lifetime_dict['Experiment Name'].append(b)
		lifetime_dict['Mouse ID'].append(m)
		print('Working on '+str(b)+'...')
		# If enabled, initialize arrays for determining previous wake and NREM bouts
		prev_wake = []
		prev_NREM = []

		# Setting sampling frequency based on binning status
		fs = 0.25 if 'binned' in FLP_exp.filename else 1
		x_vect = np.arange(-window[0]+1, window[1], 1/fs)

		# Getting dictionary timestamps for every beahvior state transition
		transition_dict = FLP_exp.transition_timestamps(diff_wake = diff_wake)

		# Getting a dataframe with the duration and start and end time of every beahvior bout in experiment
		onoff_df = FLP_exp.ss_onset_offset()
		if time_range is not None:
			range_start = time_range[i][0]
			range_end = time_range[i][1]
		# Iterate through all transition types
		for k in these_transitions:
			print(k)
			if k not in list(transition_dict['Timestamps'].keys()):
				lifetime_dict['Lifetime'][experimental_sensor][k].append([])
				if shuffled:
					lifetime_dict['Lifetime']['Shuffled'][k].append([])
				continue
			if 'Microarousal' not in k:
				second_state = k[k.find('-')+1:] # Extract the second state of the transition.

			# Define and store the time vector for the transition window.
			
			lifetime_dict['Time'][k] = x_vect

			# Initialize matrices to hold aligned data.
			stacked_lifetime = np.empty([len(transition_dict['Timestamps'][k]), len(x_vect)])
			stacked_lifetime[:] = np.nan

			# Conditional initialization for intensity and shuffled data.
			if intensity:
				stacked_intensity = np.empty([len(transition_dict['Timestamps'][k]), len(x_vect)])
				stacked_intensity[:] = np.nan
			if shuffled:
				stacked_lifetime_shuffled = np.empty([len(transition_dict['Timestamps'][k]), len(x_vect)])
				stacked_lifetime_shuffled[:] = np.nan

			# Process each timestamp in the transition.
			for i,t in enumerate(transition_dict['Timestamps'][k]):
				if time_range is not None:
					if (t <= range_start) or (t >= range_end):
						# print(str(t) + ' is not within time range '+ str(range_start) + '-' + str(range_end))
						continue
				this_bout = onoff_df.loc[onoff_df['Start Time'] == t] # Current bout starting at timestamp `t`.
				if (len(this_bout.index) == 0) or (this_bout.index == 0):
					continue
				else:
					prev_bout = onoff_df.loc[this_bout.index-1] # Identify the previous bout.
				# Special handling for specific transitions (e.g., splitting by long/short durations)
				if k == 'NREM-Wake':
					assert prev_bout['State'].iloc[0] == 2 # Verify the previous state is NREM.
					# Storing duration of bout for future splitting of long and short NREM bouts
					prev_NREM.append(prev_bout['Duration'].iloc[0])

				if k == 'Wake-NREM':
					assert prev_bout['State'].iloc[0] == 1 # Verify the previous state is Wake.
					# Storing duration of bout for future splitting of long and short Wake bouts
					prev_wake.append(prev_bout['Duration'].iloc[0])

				if ('Microarousal' not in k) and (this_bout['Duration'].iloc[0] < window[1]) and (remove_short):
					continue
				# Pulling bout duration to determine length of photometry data to plot.
				if 'Microarousal' in k:
					# Handle microarousal transitions by combining duration with next beahvior bout.
					try:
						next_bout = onoff_df.loc[this_bout.index+1]
					except KeyError:
						continue
					bout_duration = this_bout['Duration'].iloc[0]+next_bout['Duration'].iloc[0]
					bout_end = next_bout['End Time'].iloc[0]
				else:
					# Standard bout duration.
					bout_duration = this_bout['Duration'].iloc[0]
					bout_end = this_bout['End Time'].iloc[0]

				# Calculate trace start and end times, ensuring boundaries are within the `window`.
				if prev_bout['Duration'].iloc[0] >= window[0]:
					trace_start = t-window[0]
				else:
					trace_start = prev_bout['Start Time'].iloc[0]
				
				if (bout_duration >= window[1]) or (allow_nextstate):
					trace_end = t+window[1]
				else:
					trace_end = bout_end

				# Extract and normalize photometry/lifetime data within the trace.
				idx, = np.where(np.logical_and(FLP_exp.Time >= trace_start, FLP_exp.Time <= trace_end))
				normIdx = np.where(FLP_exp.Time >= t)[0][0]  # Reference index for normalization.
				photometry_time = FLP_exp.Time[idx] - t  # Time vector centered at the transition.
				interp_idx, = np.where(np.logical_and(x_vect >= int(photometry_time[0]), x_vect <= int(photometry_time[-1])))
				interp_time = x_vect[interp_idx]

				# Normalize and interpolate lifetime data.
				if raw_lifetime:
					rawdata = FLP_exp.Lifetime[idx]
				elif zscore:
					rawdata = FLP_exp.ZScore[idx]
				else:
					rawdata = FLP_exp.Lifetime[idx]-FLP_exp.Lifetime[normIdx]
				stacked_lifetime[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)
				
				# Normalize and interpolate shuffled data, if applicable.
				if shuffled:
					if (raw_lifetime) or (zscore):
						rawdata = FLP_exp.Shuff[idx]
					else:
						rawdata = FLP_exp.Shuff[idx]-FLP_exp.Shuff[normIdx]
					stacked_lifetime_shuffled[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)

				# Normalize and interpolate intensity data, if applicable.
				if intensity:
					stacked_intensity[i, interp_idx] = PKA.interpolate_photometry(FLP_exp.PhotonCount[idx]-FLP_exp.PhotonCount[normIdx], photometry_time, interp_time)
			
			# Store the results in the dictionary for this transition.
			lifetime_dict['Lifetime'][experimental_sensor][k].append(stacked_lifetime)
			if intensity:
				lifetime_dict['Intensity'][k].append(stacked_intensity)
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled'][k].append(stacked_lifetime_shuffled)
		if 'NREM-Wake' in these_transitions:
			lifetime_dict['Previous Bout Length']['NREM-Wake'].append(prev_NREM)
		if 'Wake-NREM' in these_transitions:
			lifetime_dict['Previous Bout Length']['Wake-NREM'].append(prev_wake)


		# Handling the special cases of splitting up long and short Wake and NREM 
		if long_short_NREM:
			# Identifying which NREM-Wake transitions are coming off a long or short wake based on defined cutoffs
			long_NREM_idx, = np.where(np.asarray(prev_NREM) >= NREM_cutoff)
			short_NREM_idx, = np.where(np.asarray(prev_NREM) < NREM_cutoff)
			# Verify that all transitions are assigned to one of the two groups.
			assert len(long_NREM_idx)+len(short_NREM_idx) == len(prev_NREM) 

			# Store segregated lifetime and time data into new keys in dictionary
			lifetime_dict['Lifetime'][experimental_sensor]['NREM-Wake Long'].append(lifetime_dict['Lifetime'][experimental_sensor]['NREM-Wake'][-1][long_NREM_idx])
			lifetime_dict['Lifetime'][experimental_sensor]['NREM-Wake Short'].append(lifetime_dict['Lifetime'][experimental_sensor]['NREM-Wake'][-1][short_NREM_idx])
			lifetime_dict['Time']['NREM-Wake Long'] = lifetime_dict['Time']['NREM-Wake']
			lifetime_dict['Time']['NREM-Wake Short'] = lifetime_dict['Time']['NREM-Wake']

			# Optionally store segregated intentsity data into new keys in dictionary
			if intensity:
				lifetime_dict['Intensity']['NREM-Wake Long'].append(lifetime_dict['Intensity']['NREM-Wake'][-1][long_NREM_idx])
				lifetime_dict['Intensity']['NREM-Wake Short'].append(lifetime_dict['Intensity']['NREM-Wake'][-1][short_NREM_idx])

			# Optionally store segregated shuffled data into new keys in dictionary
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled']['NREM-Wake Long'].append(lifetime_dict['Lifetime']['Shuffled']['NREM-Wake'][-1][long_NREM_idx])
				lifetime_dict['Lifetime']['Shuffled']['NREM-Wake Short'].append(lifetime_dict['Lifetime']['Shuffled']['NREM-Wake'][-1][short_NREM_idx])

		if long_short_wake:
			long_wake_idx, = np.where(np.asarray(prev_wake) >= wake_cutoff)
			short_wake_idx, = np.where(np.asarray(prev_wake) < wake_cutoff)
			assert len(long_wake_idx)+len(short_wake_idx) == len(prev_wake)

			lifetime_dict['Lifetime'][experimental_sensor]['Wake-NREM Long'].append(lifetime_dict['Lifetime'][experimental_sensor]['Wake-NREM'][-1][long_wake_idx])
			lifetime_dict['Lifetime'][experimental_sensor]['Wake-NREM Short'].append(lifetime_dict['Lifetime'][experimental_sensor]['Wake-NREM'][-1][short_wake_idx])
			lifetime_dict['Time']['Wake-NREM Long'] = lifetime_dict['Time']['Wake-NREM']
			lifetime_dict['Time']['Wake-NREM Short'] = lifetime_dict['Time']['Wake-NREM']

			if intensity:
				lifetime_dict['Intensity']['Wake-NREM Long'].append(lifetime_dict['Intensity']['Wake-NREM'][-1][long_wake_idx])
				lifetime_dict['Intensity']['Wake-NREM Short'].append(lifetime_dict['Intensity']['Wake-NREM'][-1][short_wake_idx])

			if shuffled:
				lifetime_dict['Lifetime']['Shuffled']['Wake-NREM Long'].append(lifetime_dict['Lifetime']['Shuffled']['Wake-NREM'][-1][long_wake_idx])
				lifetime_dict['Lifetime']['Shuffled']['Wake-NREM Short'].append(lifetime_dict['Lifetime']['Shuffled']['Wake-NREM'][-1][short_wake_idx])
	# Optionally returning only the data dictionary and skipping the plotting
	if just_dictionary:
		return lifetime_dict

	# Default color dictionary for transitions
	if not color_dict:
		color_dict = graph.SW_colordict('transitions')
		color_dict['REM-Wake'] = color_dict['NREM-Wake']


	# Initialize figures if figure dictionary isn't provided
	if not fig_dict:
		# Initialize dictionary to hold plots for lifetime and optionally intensity
		fig_dict = {'Lifetime':{}}
		if intensity:
			fig_dict = {'Lifetime':{}, 'Intensity':{}}
		
		# Create and store figure and axes objects for main transitions plots
		for k in fig_dict.keys():
			fig_dict[k] = {'Figure': [], 'Axes': []}
			fig_dict[k]['Figure'], fig_dict[k]['Axes'] = plt.subplots(
				nrows = 1, ncols = len(these_transitions), figsize = [4*len(these_transitions), 4])

			# Add consistent styling with custom axis width
			fig_dict[k]['Figure'], fig_dict[k]['Axes'] = graph.thick_axes(
				fig_dict[k]['Figure'], fig_dict[k]['Axes'], width = axes_width)

		# If enabled, create and store figure and axes objects for split NREM plot
	if long_short_NREM:
		print([s for s in lifetime_dict['Lifetime'][experimental_sensor].keys()
			if 'NREM-Wake' in s])
		NREM_Wake_plot_option = input('Which of the above conditions do you want to plot?')
	else:
		NREM_Wake_plot_option = 'NREM-Wake'
	# If enabled, create and store figure and axes objects for split wake plot
	if long_short_wake:
		print([s for s in lifetime_dict['Lifetime'][experimental_sensor].keys()
			if 'Wake-NREM' in s])
		Wake_NREM_plot_option = input('Which of the above conditions do you want to plot?')
	else:
		Wake_NREM_plot_option = 'Wake-NREM'

	# Define the y-axis label based on whether raw or zeroed lifetime data is used
	if raw_lifetime:
		y_label = FLP_classes[0].PhosMeasure
	else:
		y_label = r'$\Delta$' + FLP_classes[0].PhosMeasure

	# Plot the triggered average for the primary data

	# Pull figure and axes objects from the figure dictionary
	for k in lifetime_dict['Lifetime'].keys():
		if 'Wake-NREM' in these_transitions:
			lifetime_dict['Lifetime'][k]['Wake-NREM'] = lifetime_dict['Lifetime'][k][Wake_NREM_plot_option]
		if 'NREM-Wake' in these_transitions:
			lifetime_dict['Lifetime'][k]['NREM-Wake'] = lifetime_dict['Lifetime'][k][NREM_Wake_plot_option]

	lifetime_fig, lifetime_ax = fig_dict['Lifetime']['Figure'], fig_dict['Lifetime']['Axes']
	if len(lifetime_dict['Experiment Name']) > 1:
		all_dicts, y_data = split_by_animal(lifetime_dict, average_function = np.nanmean)
	else:
		y_data = lifetime_dict['Lifetime']
	lifetime_fig, lifetime_ax = plot_triggered_average(y_data[experimental_sensor], lifetime_dict['Time'], 
		these_transitions, lifetime_fig, lifetime_ax, color_dict, y_label, average_function = np.nanmean, error_function = stats.sem,
		y_negative = y_negative, legend_label = experimental_sensor + '\n(n = '+str(len(np.unique(mouseID))) + ')')

	# If shuffled data is available, plot it using a separate color scheme
	if shuffled:
		color_dict_shuff = {k: 'k' for k in lifetime_dict['Lifetime']['Shuffled'].keys()}
		lifetime_fig, lifetime_ax = plot_triggered_average(y_data['Shuffled'], lifetime_dict['Time'], 
			these_transitions, lifetime_fig, lifetime_ax, color_dict_shuff, y_label, average_function = np.nanmean, error_function = stats.sem,
			y_negative = y_negative, legend_label = 'Shuffled\n(n = '+str(len(np.unique(mouseID))) + ')')
	
	# If intensity data is plot it
	if intensity:
		# Pull figure and axes objects from the figure dictionary
		intensity_fig = fig_dict['Intensity']['Figure']
		intensity_ax = fig_dict['Intensity']['Axes']

		y_label = '-'+r'$\Delta$'+ 'Photon Count (ns)'
		intensity_fig, intensity_ax = plot_triggered_average(lifetime_dict['Intensity'], lifetime_dict['Time'], 
			these_transitions, intensity_fig, intensity_ax, color_dict, y_label, average_function = np.nanmean, error_function = stats.sem,
			y_negative = y_negative, legend_label = experimental_sensor+'\n(n = '+str(len(np.unique(mouseID))) + ')')

	# Save figures if a save directory is provided
	if savedir:
		lifetime_fig.savefig(savedir) # Save the main lifetime plot
		if intensity:
			idx = savedir.find(os.path.splitext(savedir)[1])
			int_savename = savedir[:idx]+'_intensity'+savedir[idx:]
			intensity_fig.savefig(int_savename) # Save the intensity plot

	return fig_dict, lifetime_dict

def plot_triggered_average(y_data, x_data, these_keys, fig, ax, color_dict, y_label, average_function = np.nanmean, 
	error_function = stats.sem, x_label = 'Time from\nTransition (s)', y_negative = False, legend_label = None):

	"""
	This function plots the average trace of a given list of traces with error.

	Args:
	----------
	- y_data : Dictionary containing y-values (e.g., data lifetimes) for each key in `these_keys`.
	- x_data : Dictionary containing corresponding x-values (e.g., time points) for each key in `these_keys`.
	- these_keys : List of keys to iterate through, typically identifying specific datasets. 
	- fig : A matplotlib figure object to plot on
	- ax : A list or array of Axes objects, one for each key in `these_keys`
	- color_dict : Dictionary mapping each key in 'these_keys' to a specific color for consistent plot styling.
	- y_label : Label for the y-axis, applied to the first plot only.
	- average_function : Function to compute the average of `y_data` (default is `np.nanmean`).
	- error_function : Function to compute the error for `y_data` (default is `stats.sem`).

	Returns:
	-------
	- fig : modified Figure object
	- ax : A list or array of modified axes objects
	"""
	if (len(fig.axes) == 1) & (type(ax) is not list):
		ax = [ax]
	for ii, s in enumerate(these_keys): # Loop through each key and its index.
		if s not in y_data.keys():
			continue
		x = x_data[s] # Extract x-values for the current key.
		y_full = []
		for y in y_data[s]:
			if len(y) > 0:
				if type(y[0]) == np.ndarray:
					y_full.append(y)
		y_data[s] = y_full
		try:
			these_lifetimes = np.concatenate(y_data[s], axis = 0) # Combine data arrays for this key.
		except ValueError:
			continue
		y = average_function(these_lifetimes, axis = 0) # Compute average based on inputted function.
		err = error_function(these_lifetimes, axis = 0, nan_policy='omit')  # Compute error based on inputted function.

		# Plot data with error bars.
		if y_negative:
			y = -y
		ax[ii] = graph.linegraph_w_error(ax[ii], x, y, err, color = color_dict[s], label = legend_label, linewidth = 1,
			alpha = 0.3)

		# Add a vertical line at x=0 to mark a transition or reference point.
		ax[ii].axvline(0, linestyle = '--', linewidth = 1, color = 'k')

		# Add labels and titles to the axes.
		ax[ii] = graph.label_axes(ax[ii], x = x_label, title = s, title_fontsize = 20,
			fontweight = 'normal')
		ax[ii].set_xlim([x[0], x[-1]]) # Set the x-axis limits to the range of `x`.
		ax[ii].autoscale(axis = 'y')
	
	# Match the y-axis scale across all subplots.
	graph.match_yaxes(ax)

	# Add the y-axis label to the first subplot.
	if y_negative:
		y_label = '-'+y_label
	ax[0] = graph.label_axes(ax[0], y = y_label)

	# Adjust spacing between subplots to avoid overlap.
	fig.tight_layout()

	return fig, ax

def transition_triggered_quant(lifetime_dict, amp_windows, slope = False,
								FLP_classes = None, sleep_slope_win = [30,100], 
								wake_slope_win = [0,20]):

	"""
	This function calculates and plots normalized area under the curve (AUC) for different state transitions across groups.
	Can optionally include shuffled data on the same plot.

	Args:
	----------
	- lifetime_dict : Dictionary containing lifetime and time data for each experimental condition.
	- mouse_names : List of mouse identifiers corresponding to the data.
	- just_dictionary : If True, only returns the AUC dictionary, skipping the plotting. Default=False
	- shuffled : If True, computes AUC for shuffled data, otherwise will just compute for experimental data.
	- color_dict : Colors for different conditions in the plot.
	- fig : Optional matplotlib Figure object for plotting. If None, figure object is made within function. Default=None.
	- ax : Optional matplotlib Axes object for plotting. If None, axes objects are made within function. Default=None.
	- auc_win_start : Time (in seconds) to start calculating AUC for transitions into Wake.

	Returns:
	-------
	- fig : If applicable, modified Figure object
	- ax : If applicable,, a list or array of modified axes objects
	- auc_dict: Dictionary containing AUC data for every state transition type
	"""

	# Initialize AUC dictionary structure.
	if 'Shuffled' in lifetime_dict['Lifetime'].keys():
		data = dict(zip(list(lifetime_dict['Lifetime'].keys()), [{}, {}]))  # Two groups for shuffled data.
	else:
		data = dict(zip(list(lifetime_dict['Lifetime'].keys()), [{}]))  # One group for experimental data.

	quant_dict = {'Experiment Name': lifetime_dict['Experiment Name'], # Store experiment metadata.
	'Mouse ID': lifetime_dict['Mouse ID'], # Store mouse identifiers.
	'LFT Quant': data} # Dictionary to store computed AUCs.

	# Extract groups (e.g., experimental vs. shuffled) and state transitions.
	groups = list(quant_dict['LFT Quant'].keys())
	state_transitions = list(amp_windows.keys())
	
	# Loop through each group and state transition to compute AUC.
	for k in groups:
		quant_dict['LFT Quant'][k] = {k:[] for k in amp_windows.keys()}
		for s in state_transitions:
			print('Working on '+s)
			t = lifetime_dict['Time'][s] # Time vector for the current state transition.
			averaging_window, = np.where((t >= amp_windows[s][0]) & 
				(t <= amp_windows[s][1]))
			# Compute AUC for each dataset in the current group and state.
			for a in lifetime_dict['Lifetime'][k][s]:
				quant = []
				for l in a:
					quant.append(np.nanmean(l[averaging_window]))
				quant_dict['LFT Quant'][k][s].append(quant)
	if slope:
		for k in quant_dict['LFT Quant']:
			quant_dict['LFT Quant'][k]['NREM Slope'] = []
			quant_dict['LFT Quant'][k]['REM Slope'] = []
			for FLP_exp in FLP_classes:
				onoff_df = FLP_exp.ss_onset_offset()
				if k == 'Shuffled':
					onoff_df = FLP_exp.slope_bystate(onoff_df, sleep_slope_win = sleep_slope_win, 
						wake_slope_win = wake_slope_win, shuffled = True)
				else:
					onoff_df = FLP_exp.slope_bystate(onoff_df, sleep_slope_win = sleep_slope_win, 
						wake_slope_win = wake_slope_win, shuffled = False)
				quant_dict['LFT Quant'][k]['NREM Slope'].append(
					list(onoff_df['Slope'].loc[onoff_df['State'] == 2]))
				quant_dict['LFT Quant'][k]['REM Slope'].append(
					list(onoff_df['Slope'].loc[onoff_df['State'] == 3]))

	return quant_dict

def plot_lifetime_ss_fig(FLP_classes, experiment_names, savedir = False, num_std = False, discrete_cutoff = 0.01,
	FWHM_thresh = False, fig_ext = '.png', intensity = False, transient_detection = False, dont_display = False, 
	negative_lifetime = True, use_P1 = False):
	
	"""
	This function visualizes lifetime and optional intensity data overlayed with sleep states for each acquisition 
	of an experiment. Supports additional transient detection and filtered data plotting.

	Args:
	----------
	- FLP_classes (list): List of FLP class objects.
	- experiment_names (list): Corresponding list of names for the experiments in `FLP_classes`.
	- savedir (str, optional): Directory to save generated plots. If `False`, plots are not saved. Default=False
	- num_std (int or float64, optional): Standard deviation threshold for transient detection. Default=False
	- discrete_cutoff (float64 or bool, optional): Cutoff value for transient detection (discrete transitions). Default=0.01
	- FWHM_thresh (bool, optional): Whether to use Full Width at Half Maximum threshold for transient detection. Default=False
	- fig_ext (str): File extension for saving plots (e.g., '.png', '.pdf'). Default='.png'
	- intensity (bool): Whether to create additional figure for intensity data
	- transient_detection (bool): Whether to perform and plot transient detection.
	- dont_display (bool): Whether to close the figure after saving (to avoid GUI display).
	- negative_lifetime (bool): Whether to plot the negative of the lifetime data (flipped vertically).

	Returns:
	-------
	- fig_dict (dict): Dictionary of figure and axes objects
	"""

	fig_dict = {} # Dictionary to store figures for each experiment.
	graph.make_bigandbold(xticksize = 14, yticksize = 14, axeslabelsize = 15) # Set global plot aesthetics.
	color_dict = graph.SW_colordict('numbers') # Color mapping for sleep state numbers.

	# Loop through each experiment
	for FLP_exp,b in zip(FLP_classes, experiment_names):
		# Check if the experiment object has sleep state data.		
		include_ss = hasattr(FLP_exp, 'SleepStates')
		fig_dict[b] = [] # Initialize a list to store figures for this experiment.

		# Get filter type and boundary string for filtered data (if applicable).
		filter_type, filt_bound_str = PKA.get_filter_type(FLP_exp.FilterBounds)

		# Determine the number of subplot rows based on the data to be displayed.
		num_rows = 1 # Row for raw lifetime plot.
		if any(FLP_exp.FilterBounds):  # Add a row for filtered lifetime data.
			num_rows += 1
		if intensity: # Add a row for photon count data.
			num_rows += 1

		# Get unique acquisition numbers for the experiment.
		acqs = np.unique(FLP_exp.AcqNum)

		# Loop through each acquisition in the experiment.
		for i,a in enumerate(acqs):
			hs = []  # List to store plot heights for aligning sleep state patches.
			ys = []  # List to store y-axis limits for aligning sleep state patches.

			# Create a new figure for the current acquisition.
			lifetime_ss_fig, ax = plt.subplots(ncols = 1, nrows = num_rows, figsize = (12,2.5*num_rows))

			ax_idx = 0 # Index to track the current subplot.
			plot_idx, = np.where(FLP_exp.AcqNum == a)  # Indices corresponding to the current acquisition.
			
			# Ensure `ax` is always a list for consistent indexing.
			if num_rows == 1:
				ax = [ax]

			# Plot raw lifetime data.
			if use_P1:
				ax[ax_idx].plot(FLP_exp.Time[plot_idx], FLP_exp.P1[plot_idx], color = 'k', linewidth = 1)
				yaxis_label = 'P1'				
			elif negative_lifetime:
				ax[ax_idx].plot(FLP_exp.Time[plot_idx], -FLP_exp.Lifetime[plot_idx], color = 'k', linewidth = 1)
				yaxis_label = '-Lifetime (ns)' # Label for flipped lifetime data.
			else:
				ax[ax_idx].plot(FLP_exp.Time[plot_idx], FLP_exp.Lifetime[plot_idx], color = 'k', linewidth = 1)
				yaxis_label = 'Lifetime (ns)' # Label for regular lifetime data.			
			ax[ax_idx].set_xlim(FLP_exp.Time[plot_idx[[0]]], FLP_exp.Time[plot_idx][-1])
			graph.label_axes(ax[ax_idx], y = yaxis_label, x = 'Time (s)', 
				title = 'Experiment: '+b+'\n'+'Acquisition: '+str(a), title_fontsize = 17)

			# Store y-axis range for sleep state patches.
			y_low, y_high = ax[ax_idx].get_ylim()
			ys.append(y_low)
			hs.append(y_high-y_low)

			# Plot filtered lifetime data (if applicable).
			if any(FLP_exp.FilterBounds):
				t_color = '#c5c9c7'  
				ax_idx += 1
				if negative_lifetime:
					ax[ax_idx].plot(FLP_exp.Time[plot_idx], -FLP_exp.Filt[plot_idx], color = 'k', linewidth = 1)
					yaxis_label = '-Lifetime (ns)'
				else:
					ax[ax_idx].plot(FLP_exp.Time[plot_idx], FLP_exp.Filt[plot_idx], color = 'k', linewidth = 1)
					yaxis_label = 'Lifetime (ns)'					
				ax[ax_idx].set_xlim(FLP_exp.Time[plot_idx[[0]]], FLP_exp.Time[plot_idx][-1])

				# Overlay detected transients (if applicable).
				if transient_detection:
					transient_dict = FLP_exp.find_transients(num_std = num_std, discrete_cutoff = discrete_cutoff, 
						FWHM_thresh = FWHM_thresh)
					for t in transient_dict['FLIM-AKAR']['Transient Idx']:
						if (t[0] in plot_idx) & (t[-1] in plot_idx):
							ax[ax_idx].plot(FLP_exp.Time[t], FLP_exp.Filt[t], color = t_color, linewidth = 1, linestyle = '--')
						elif (t[0] in plot_idx) & (t[-1] not in plot_idx):
							ax[ax_idx].plot(FLP_exp.Time[t[0]:], FLP_exp.Filt[t[0]:], color = t_color, linewidth = 1, linestyle = '--')
						elif (t[0] not in plot_idx) & (t[-1] in plot_idx):
							ax[ax_idx].plot(FLP_exp.Time[plot_idx[0]:t[-1]], FLP_exp.Filt[plot_idx[0]:t[-1]], color = t_color, 
								linewidth = 1, linestyle = '--')
						else:
							continue
				# Store y-axis range for sleep state patches.
				y_low, y_high = ax[ax_idx].get_ylim()
				ys.append(y_low)
				hs.append(y_high-y_low)
				graph.label_axes(ax[ax_idx],y = yaxis_label, x = 'Time (s)', 
					title = 'Filtered ('+filter_type+filt_bound_str+')'+'\n'+'Acquisition: '+str(a),
					title_fontsize = 17)

			# Plot intensity (photon count) data (if applicable).
			if intensity:
				ax_idx += 1
				ax[ax_idx].plot(FLP_exp.Time[plot_idx], FLP_exp.PhotonCount[plot_idx], color = 'k', linewidth = 1)
				order = np.sort(FLP_exp.PhotonCount[plot_idx])
				ax[ax_idx].set_xlim(FLP_exp.Time[plot_idx[[0]]], FLP_exp.Time[plot_idx][-1])
				y_low, y_high = ax[ax_idx].get_ylim()
				y_low = order[1]-10000 # Adjust lower limit for outliers.
				ax[ax_idx].set_ylim([y_low, y_high])
				ys.append(y_low)
				hs.append(y_high-y_low)
				graph.label_axes(ax[ax_idx],y = 'Photon Count', x = 'Time (s)', title = 'Experiment: '+b+'\n'+'Acquisition: '+str(a),
					title_fontsize = 17)

			# Add sleep state overlays (if data is available).
			if include_ss:
				for state in [1,2,3,4,5]: # Loop through all possible sleep states.
					state_window, = np.where(np.logical_and(FLP_exp.SSTime>=math.floor(FLP_exp.Time[plot_idx[[0]]]), 
						FLP_exp.SSTime<math.ceil(FLP_exp.Time[plot_idx[[-1]]]))) 
					cont_state = PKA.find_continuous(FLP_exp.SleepStates[state_window], [state])
					if len(cont_state) > 0:
						if len(cont_state[0])>0:
							for s in cont_state:
								if s[0] == 0:
									x = FLP_exp.SSTime[state_window[s[0]]]-4
								else:
									x = (FLP_exp.SSTime[state_window[s[0]-1]])
								w = (FLP_exp.SSTime[state_window[s[-1]]]-x)
								for ii in np.arange(0, num_rows):
									rect = patches.Rectangle((x,ys[ii]), w, hs[ii], facecolor = color_dict[str(int(state))], 
									                          alpha = 1, edgecolor = None, zorder = 0)
									ax[ii].add_patch(rect)

			lifetime_ss_fig.tight_layout()
			fig_dict[b].append((lifetime_ss_fig, ax)) # Store figure and axes for this acquisition.

			# Save the figure (if `savedir` is specified).
			if savedir:
				try:
					os.mkdir(os.path.join(savedir,b,'photometry_w_SS'))
				except FileExistsError:
					pass
				if use_P1:
					savefilename_lifetime = os.path.join(savedir,b,'photometry_w_SS','P1_')
				else:
					savefilename_lifetime = os.path.join(savedir,b,'photometry_w_SS','LFT_')
				if 'binned' in FLP_exp.filename:
					savefilename_lifetime = savefilename_lifetime + 'binned_Acq_'+str(a)+fig_ext
				else:
					savefilename_lifetime = savefilename_lifetime + 'Acq_'+str(a)+fig_ext

				lifetime_ss_fig.savefig(savefilename_lifetime)

			# Close the figure to avoid display (if `dont_display` is True).
			if dont_display:
				plt.close('all')
				
	return fig_dict # Return the dictionary of figures.

def plot_lifetime_EEG_fig(ax, EEG_fn, LFT, t, fsd = 200, minfreq = 1, 
	maxfreq = 16, window_length = 10, vmin = None, vmax = None, linewidth = 0.5, ylims = None, ylabel = '-Lifetime (ns)'):
	EEG_sig = np.load(EEG_fn)
	SWS_utils.plot_spectrogram(ax, EEG_sig, fsd, minfreq = minfreq, maxfreq = maxfreq, 
		window_length = window_length, vmin = vmin, vmax = vmax)
	ax_LFT = ax.twinx()
	ax_LFT.plot(t, LFT, color = 'k', linewidth = linewidth)
	if ylims:
		ax_LFT.set_ylim(ylims)
	graph.label_axes(ax_LFT, y = ylabel)
	return ax_LFT

def split_by_animal(lifetime_dict, average_function = np.nanmean, data_key = 'Lifetime'):
	all_dicts = {}
	for a in np.unique(lifetime_dict['Mouse ID']):
		these_exp, = np.where(np.asarray(lifetime_dict['Mouse ID']) == a)
		all_dicts[a] =  {'Time': lifetime_dict['Time'],
						'Experiment Name': [lifetime_dict['Experiment Name'][i] for i in these_exp],
						data_key: {g: {s: [lifetime_dict[data_key][g][s][i] for i in these_exp if len(lifetime_dict[data_key][g][s][i]) > 0] 
						for s in lifetime_dict[data_key][g].keys()} for g in lifetime_dict[data_key].keys()}}
		all_dicts[a]['Average ' + data_key] = {g: {s: average_function(np.concatenate(all_dicts[a][data_key][g][s], axis = 0), axis = 0) 
										if len(all_dicts[a][data_key][g][s]) > 0 else []
						for s in all_dicts[a][data_key][g].keys()} for g in all_dicts[a][data_key].keys()}


	y_data = {g: {s:[[all_dicts[a]['Average '+data_key][g][s]] for a in np.unique(lifetime_dict['Mouse ID'])] 
					for s in lifetime_dict[data_key][g].keys()} for g in all_dicts[a][data_key].keys()}

	return all_dicts, y_data

def transition_triggered_power(FLP_classes, experiment_names, mouseID, window = [30,30], 
	freq_dict = {'Delta': [0.5, 4], 'Theta': [4, 8], 'Sigma': [10, 15], 'Beta': [15, 30]},
	these_transitions = ['NREM-Wake'], diff_wake = False, remove_short = True, EEG_chan = 0,
	downsamp_EEG = True, window_length = 10, noverlap = 9, window_type = None, norm = True):

	if type(FLP_classes) is not list:
		FLP_classes = [FLP_classes]
	if type(experiment_names) is not list:
		experiment_names = [experiment_names]
	if type(mouseID) is not list:
		mouseID = [mouseID]

	# Additional graph formatting
	graph.make_bigandbold(axeslabelsize = 22)
	power_dict = {'Experiment Name':[], 
					'Mouse ID': [],
					'Power':{p:{k:[] for k in these_transitions} for p in freq_dict.keys()},
					'Time':{k:[] for k in these_transitions},
					'Previous State Duration':{k:[] for k in these_transitions}}

	# Process each experiment

	for FLP_exp,b,m in zip(FLP_classes, experiment_names, mouseID):

		# Storing experiment name into data dictionary
		power_dict['Experiment Name'].append(b)
		power_dict['Mouse ID'].append(m)
		print('Working on '+str(b)+'...')
		FLP_exp.add_EEG(downsamp_EEG = downsamp_EEG, get_EMG = False, chan = EEG_chan)
		
		# Getting dictionary timestamps for every beahvior state transition
		transition_dict = FLP_exp.transition_timestamps(diff_wake = diff_wake)

		# Getting a dataframe with the duration and start and end time of every beahvior bout in experiment
		onoff_df = FLP_exp.ss_onset_offset()
		fs = int(1/(FLP_exp.EEGTime[1]-FLP_exp.EEGTime[0]))

		power_vals = SWS_utils.bandPower(FLP_exp.EEG, fs, freq_dict = freq_dict, minfreq = 0.5, 
			maxfreq = 30, window_length = window_length, 
			noverlap = noverlap, window_type = window_type)
		power_vals['Bins'] = power_vals['Bins']+FLP_exp.Time[0]

		# Iterate through all transition types
		for p in freq_dict.keys():
			for k in these_transitions:
				durations = np.empty(transition_dict['Number'][k])
				durations[:] = np.nan
				print(k)
				if k not in list(transition_dict['Timestamps'].keys()):
					for p in freq_dict.keys():
						power_dict['Power'][p][k].append([])
					continue
				if 'Microarousal' not in k:
					second_state = k[k.find('-')+1:] # Extract the second state of the transition.
				dx = power_vals['Bins'][1]-power_vals['Bins'][0]
				x_vect = np.arange(-window[0], window[1], dx)
				power_dict['Time'][k] = x_vect
				# Initialize matrices to hold aligned data.
				stacked_power = np.empty([transition_dict['Number'][k], len(x_vect)])
				stacked_power[:] = np.nan

				# Process each timestamp in the transition.
				for i,t in enumerate(transition_dict['Timestamps'][k]):

					this_bout = onoff_df.loc[onoff_df['Start Time'] == t] # Current bout starting at timestamp `t`.
					if (len(this_bout.index) == 0) or (this_bout.index == 0):
						continue
					else:
						prev_bout = onoff_df.loc[this_bout.index-1] # Identify the previous bout.
					if ('Microarousal' not in k) and (remove_short) and ((this_bout['Duration'].iloc[0] < window[1]) or (prev_bout['Duration'].iloc[0] < window[0])):
						continue
					# Pulling bout duration to determine length of photometry data to plot.
					if 'Microarousal' in k:
						# Handle microarousal transitions by combining duration with next beahvior bout.
						try:
							next_bout = onoff_df.loc[this_bout.index+1]
						except KeyError:
							continue

					if prev_bout['Duration'].values[0] < window[0]:
						trace_start = prev_bout['Start Time'].values[0]
					else:
						trace_start = t-window[0]
					if prev_bout['Duration'].values[0] < window[1]:
						trace_end = this_bout['End Time'].values[0]
					else:
						trace_end = t+window[1]

					data_idx, = np.where((power_vals['Bins'] > trace_start) & (power_vals['Bins'] < trace_end))
					power_time = power_vals['Bins'][data_idx]-t

					interp_idx, = np.where(np.logical_and(x_vect >= power_time[0], x_vect <= power_time[-1]))
					interp_time = x_vect[interp_idx]

					if norm:
						power_arr = power_vals[p][data_idx]/power_vals['Total_Power'][data_idx]
					else:
						power_arr = power_vals[p][data_idx]
					stacked_power[i, interp_idx] = PKA.interpolate_photometry(power_arr, power_time, interp_time)
					durations[i] = prev_bout['Duration'].iloc[0]
				power_dict['Previous State Duration'][k].append(durations)
				# Store the results in the dictionary for this transition.
				power_dict['Power'][p][k].append(stacked_power)


	return power_dict

def bout_centered_lifetime(FLP_classes, experiment_names, mouseID, center_len_range = [0,300], before_interval = 20, after_interval = 20, 
							centered_state = 'NREM', before_state = 'Wake', after_state = 'Wake', shuffled = False, zscore = True, 
							diff_wake = False, state_key = {'Wake':1, 'NREM': 2, 'REM': 3, 'Microarousal': 5}, long_prev_cutoff = 50):

	if type(FLP_classes) is not list:
		FLP_classes = [FLP_classes]
	if type(experiment_names) is not list:
		experiment_names = [experiment_names]
	if type(mouseID) is not list:
		mouseID = [mouseID]

	# Initialize experimental variables
	experimental_sensor = FLP_classes[0].Sensor
	if FLP_classes[0].PhosMeasure == 'Lifetime (ns)':
		y_negative = True
	elif FLP_classes[0].PhosMeasure == 'Binding Fraction':
		y_negative = False

	# Initialize the dictionary to store lifetime and intensity data
	fs = 0.25 if 'binned' in FLP_classes[0].filename else 1
	
	lifetime_dict = {'Experiment Name':[], 'Mouse ID': [], 'Center Duration':[],
					'Lifetime':{experimental_sensor: {before_state+'-'+centered_state:[],centered_state+'-'+after_state:[]}},
					'Time': {before_state+'-'+centered_state:np.arange(-before_interval, center_len_range[1], 1/fs),
					centered_state+'-'+after_state:np.arange(-center_len_range[1], after_interval, 1/fs)}}
	if shuffled:
		lifetime_dict['Lifetime']['Shuffled'] = {before_state+'-'+centered_state:[],centered_state+'-'+after_state:[]}
	
	for FLP_exp,b,m in zip(FLP_classes, experiment_names, mouseID):
		if zscore & shuffled:
			FLP_exp.Shuff = stats.zscore(FLP_exp.Shuff, ddof=0)
		# Storing experiment name into data dictionary
		lifetime_dict['Experiment Name'].append(b)
		lifetime_dict['Mouse ID'].append(m)
		print('Working on '+str(b)+'...')

		# Getting a dataframe with the duration and start and end time of every beahvior bout in experiment
		onoff_df = FLP_exp.ss_onset_offset()
		center_bouts = [i for i in onoff_df.loc[onoff_df['State'] == state_key[centered_state]].index if (i != 0) & (i < len(onoff_df)-1)]
		center_bouts = [i for i in center_bouts if (onoff_df['State'].loc[i-1] == state_key[before_state]) & (onoff_df['State'].loc[i+1] == state_key[after_state]) 
		& (onoff_df['Duration'].loc[i-1] > long_prev_cutoff)]
		before_bouts = [i-1 for i in center_bouts]
		after_bouts = [i+1 for i in center_bouts]
		lifetime_dict['Center Duration'].append([row['Duration'] for i, row in onoff_df.loc[center_bouts].iterrows()])
		for (k, x_vect), (b1, b2) in zip(lifetime_dict['Time'].items(), [[before_bouts, center_bouts], [center_bouts, after_bouts]]):
			stacked_lifetime = np.empty([len(b1), len(x_vect)])
			stacked_lifetime[:] = np.nan

			# Conditional initialization for intensity and shuffled data.
			if shuffled:
				stacked_lifetime_shuffled = np.empty([len(b1), len(x_vect)])
				stacked_lifetime_shuffled[:] = np.nan

			# Process each timestamp in the transition.
			for i in range(len(b1)):
				bout_start = onoff_df.loc[b1[i]]['Start Time']
				zero_point = onoff_df.loc[b2[i]]['Start Time']
				bout_end = onoff_df.loc[b2[i]]['End Time']

				# Extract and normalize photometry/lifetime data within the trace.
				p_idx, = np.where(np.logical_and(FLP_exp.Time >= bout_start, FLP_exp.Time <= bout_end))
				photometry_time = FLP_exp.Time[p_idx]-zero_point  # Time vector centered at the transition.
				interp_idx, = np.where(np.logical_and(x_vect >= int(photometry_time[0]), x_vect <= int(photometry_time[-1])))
				interp_time = x_vect[interp_idx]

				# Normalize and interpolate lifetime data.
				if zscore:
					rawdata = FLP_exp.ZScore[p_idx]
				else:
					rawdata = FLP_exp.Lifetime[p_idx]
				stacked_lifetime[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)
				
				# Normalize and interpolate shuffled data, if applicable.
				if shuffled:
					rawdata = FLP_exp.Shuff[idx]
					stacked_lifetime_shuffled[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)
			# Store the results in the dictionary for this transition.
			lifetime_dict['Lifetime'][experimental_sensor][k].append(stacked_lifetime)
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled'][k].append(stacked_lifetime_shuffled)
	return lifetime_dict






