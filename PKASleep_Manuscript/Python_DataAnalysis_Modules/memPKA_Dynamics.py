import numpy as np
import glob
import os
import PKA_Sleep as PKA
import pandas as pd
import PKA_Sleep.Graphing_Utils as graph
import matplotlib.pyplot as plt
from copy import deepcopy
from neuroscience_sleep_scoring import SWS_utils
from scipy import stats
from statsmodels.stats.proportion import proportion_confint
from scipy.ndimage import uniform_filter1d
import statsmodels.api as sm
import statsmodels.formula.api as smf
from lifelines import CoxPHFitter,KaplanMeierFitter
import subprocess
import tempfile


def power_crosscorr(FLP_classes, experiment_names, freq_dict, parent_data_directory, eeg_dir, window = [75, 75], fig_dict = False, color_dict = False, 
	fsd = 200, ignore_microarousals = True, shuffle = False, plot_microarousal = False, add_movement = True,
	savedir = False, plot_ind = True, plot_grouped = False, group_name = False):
	"""
	Computes cross-correlations between EEG power bands and photometry data during specific sleep states.

	Parameters:
	----------
	FLP_classes : list
	    A list of FLP experiment class objects containing photometry and sleep state data.
	experiment_names : list
	    A list of strings with the names of the experiments.
	freq_dict : dict
	    Dictionary of frequency bands for EEG analysis, e.g., {'Delta': [0.5, 4], 'Theta': [4, 8]}.
	parent_data_directory : str
	    Path to the parent directory containing the experiment data.
	eeg_dir : list
	    List of directories where EEG data is stored for each experiment.
	fig_dict : dict, optional
		Dictionary of matplotlib figure and axes objects
	color_dict : dict, optional
	    Custom color mapping for the sleep states. Defaults to `graph.SW_colordict('single state')`.
	fsd : int, optional
	    Sampling frequency for EEG data (default: 200 Hz).
	ignore_microarousals : bool, optional
	    If True, treats microarousals as NREM (default: True).
	shuffle : bool, optional
	    If True, computes cross-correlation for shuffled photometry data (default: False).
	plot_microarousal : bool, optional
	    If True, includes microarousals in the analysis (default: False).
	add_movement : bool, optional
	    If True, includes cross-correlation with movement data (default: True).
	savedir : str or bool, optional
	    Directory path to save plots. If False, plots are not saved (default: False).
	plot_ind : bool, optional
	    If True, plots individual experiment data (default: True).
	plot_grouped : bool, optional
	    If True, combines data across all experiments into one summary plot (default: False).
	group_name : str or bool, optional
	    Name for the combined summary plot if `plot_grouped` is True (default: False).

	Returns:
	-------
	fig_dict : dict
	    A dictionary containing matplotlib figures and axes for the generated plots.
	"""

	# Initialize color mapping and data structures
	if not color_dict:
		color_dict = graph.SW_colordict('single state')
	
	# Initialize figures if figure dictionary isn't provided
	if not fig_dict:
		if (ignore_microarousals) or (not plot_microarousal):
			num_cols = 3
		else:
			num_cols = 4
		# If grouped average plotting enabled
		if plot_grouped:
			fig_dict = {'Grouped': dict([(f, plt.subplots(nrows = 1, ncols= num_cols, figsize = [4*num_cols, 4])) for f in list(freq_dict.keys())])}
			if add_movement:
				fig_dict['Grouped']['Movement'] = plt.subplots(nrows = 1, ncols = 1, figsize = [4, 4])

		# If individual plotting enabled, loop through all experiments
		if plot_ind:
			for b in experiment_names:
				# Initializing figure and axes objects for every frequency band
				fig_dict[b] = dict([(f, plt.subplots(nrows = 1, ncols= num_cols, figsize = [4*num_cols, 4])) for f in list(freq_dict.keys())])
				if add_movement:
					fig_dict[b]['Movement'] = plt.subplots(nrows = 1, ncols = 1, figsize = [4, 4])
				

	state_dict = {1: 'Wake', 2: 'NREM', 3:'REM', 5:'Microarousal'} # State mapping

	# If applicable, initalize structures for averaging across experiments
	if plot_grouped:
		all_dicts = []
		if shuffle:
			all_shuff_dicts = []

	# Loop through each experiment
	for FLP_exp,b,e_dir in zip(FLP_classes, experiment_names, eeg_dir):

		# Handle microarousal states based on user input
		if ignore_microarousals: # Rescoring microarousals as NREM
			FLP_exp_nomicro = deepcopy(FLP_exp)
			FLP_exp_nomicro.SleepStates[FLP_exp_nomicro.SleepStates == 5] = 2 
			onoff_df = FLP_exp_nomicro.ss_onset_offset()
			these_states = [state_dict[i] for i in np.unique(onoff_df['State'])]
		else: # Keep microarousals intact
			onoff_df = FLP_exp.ss_onset_offset()
			these_states = [state_dict[i] for i in np.unique(onoff_df['State'])]
			if not plot_microarousal: # Does not calculate a cross correlation for microarousals
				these_states.remove('Microarousal')

		# Compute durations for each bout and load EEG data
		onoff_df['Duration'] = onoff_df['End Time']-onoff_df['Start Time']
		eeg = PKA.get_all_EEG(e_dir, concatenate = True)

		# Calculate band power for EEG
		minfreq = min(np.concatenate(list(freq_dict.values())))
		maxfreq = max(np.concatenate(list(freq_dict.values())))
		power_dict = SWS_utils.bandPower(eeg, fsd, freq_dict = freq_dict, minfreq = minfreq, maxfreq = maxfreq, 
		                                   window_length = 5, noverlap = 2, window_type = np.hamming)
		
		# Initialize dictionaries for correlation results
		corr_dict = {}
		if shuffle:
			shuff_dict = {}

		# Include movement data if requested
		if add_movement:
			# Loading velocity vector for entire experiment
			velocity_fn = glob.glob(os.path.join(FLP_exp.rawdatdir, '*'+b+'*', '*velocity_vector*'))[0]
			v = np.load(velocity_fn)
			vel_x = v[1]
			vel_y = v[0]

			# Initialize dictionary for movement data
			corr_dict['Movement'] = {'Correlation':[], 'Lags':[]}
			if shuffle:
				shuff_dict['Movement'] = {'Correlation':[], 'Lags':[]}

			# Only calculating movement cross correlation during wake
			state_df = onoff_df.loc[onoff_df['State'] == 1] 
			for ii in state_df.index:
				# Extract photometry and movement data for the current bout
				photometry_idx, = np.where(np.logical_and(FLP_exp.Time >= state_df['Start Time'].loc[ii], 
					(FLP_exp.Time < state_df['End Time'].loc[ii])))
				movement_idx, = np.where(np.logical_and(vel_x >= state_df['Start Time'].loc[ii], 
						(vel_x < state_df['End Time'].loc[ii])))

				# Compute cross-correlation between photometry and movement power
				correlation, lags = PKA.get_crosscorr(FLP_exp.Lifetime[photometry_idx], FLP_exp.Time[photometry_idx], 
					vel_y[movement_idx], vel_x[movement_idx])

				# Store store values in previously created dictionary
				corr_dict['Movement']['Correlation'].append(correlation)
				corr_dict['Movement']['Lags'].append(lags)

				# Optionally, repeat process with shuffled data
				if shuffle:
					correlation, lags = PKA.get_crosscorr(FLP_exp.Shuff[photometry_idx], FLP_exp.Time[photometry_idx], 
						vel_y[movement_idx], vel_x[movement_idx])
					shuff_dict['Movement']['Correlation'].append(correlation)
					shuff_dict['Movement']['Lags'].append(lags)

			# Pad correlation and lag data so all lists are the same length (for future averaging)
			corr_dict['Movement']['Correlation'] = PKA.pad_array(corr_dict['Movement']['Correlation'])
			corr_dict['Movement']['Lags'] = PKA.pad_array(corr_dict['Movement']['Lags'])
			if shuffle:
				shuff_dict['Movement']['Correlation'] = PKA.pad_array(shuff_dict['Movement']['Correlation'])
				shuff_dict['Movement']['Lags'] = PKA.pad_array(shuff_dict['Movement']['Lags'])

		# Process each frequency band
		for f in list(freq_dict.keys()):
			# Add corresponding key for current frequency band
			corr_dict[f] = {}
			if shuffle:
				shuff_dict[f] = {}

			# Loop through each sleep state
			for s in these_states:
				# Add corresponding key for current state
				corr_dict[f][s] = {'Correlation':[], 'Lags':[]}
				if shuffle:
					shuff_dict[f][s] = {'Correlation':[], 'Lags':[]}

				 # Isolate bouts of the current state
				state_idx = list(state_dict.values()).index(s)
				state_df = onoff_df.loc[onoff_df['State'] == list(state_dict.keys())[state_idx]]

				# Loop through all bouts
				for ii in state_df.index:
					# Extract photometry and EEG data for the current bout
					photometry_idx, = np.where(np.logical_and(FLP_exp.Time >= state_df['Start Time'].loc[ii], 
						(FLP_exp.Time < state_df['End Time'].loc[ii])))
					power_idx, = np.where(np.logical_and(power_dict['Bins'] >= state_df['Start Time'].loc[ii], 
							(power_dict['Bins'] < state_df['End Time'].loc[ii])))

					# Skip bouts that are too short or fall outside EEG data
					if not len(power_idx) | (state_df['Duration'].loc[ii] <= 8):
						continue

					# Compute cross-correlation between photometry and EEG power
					correlation, lags = PKA.get_crosscorr(FLP_exp.Lifetime[photometry_idx], FLP_exp.Time[photometry_idx], 
						power_dict[f][power_idx], power_dict['Bins'][power_idx])
					corr_dict[f][s]['Correlation'].append(correlation)
					corr_dict[f][s]['Lags'].append(lags)
					
					# Optionally, compute cross-correlation with shuffle data
					if shuffle:
						correlation, lags = PKA.get_crosscorr(FLP_exp.Shuff[photometry_idx], FLP_exp.Time[photometry_idx], 
						power_dict[f][power_idx], power_dict['Bins'][power_idx])
						shuff_dict[f][s]['Correlation'].append(correlation)
						shuff_dict[f][s]['Lags'].append(lags)

				# Pad correlation and lag data so all lists are the same length (for future averaging)
				corr_dict[f][s]['Correlation'] = PKA.pad_array(corr_dict[f][s]['Correlation'])
				corr_dict[f][s]['Lags'] = PKA.pad_array(corr_dict[f][s]['Lags'])

				if shuffle:
					shuff_dict[f][s]['Correlation'] = PKA.pad_array(shuff_dict[f][s]['Correlation'])
					shuff_dict[f][s]['Lags'] = PKA.pad_array(shuff_dict[f][s]['Lags'])

		# If individual plotting enabled, generate and save plots
		# Loop through each frequency (1 figure for each)
		if plot_ind:
			for f in list(freq_dict.keys()):
				dt = np.unique(np.diff(power_dict['Bins'])) # Get binsize 

				# Create figure and title it by frequency
				fig1, ax1 =  fig_dict[b][f] # 1 axis per state
				fig1.suptitle(f, fontweight = 'bold', fontsize = 25)

				# Loop through each state (each in a different subplot)
				for si, s in enumerate(these_states):
					# Compute mean and SEM for cross-correlation for current state
					x = np.nanmean(corr_dict[f][s]['Lags'], axis = 0)*dt
					y = np.nanmean(corr_dict[f][s]['Correlation'], axis = 0) 
					error = stats.sem(corr_dict[f][s]['Correlation'], axis = 0, nan_policy = 'omit')

					# Plot average trace with error
					graph.linegraph_w_error(ax1[si], x,y, error, color = color_dict[s] , label = None, 
						linewidth = 1, linestyle = '-', alpha = 0.5)

					# Optionally, compute mean and SEM for shuffled data and plot
					if shuffle:
						x = np.nanmean(shuff_dict[f][s]['Lags'], axis = 0)*dt
						y = np.nanmean(shuff_dict[f][s]['Correlation'], axis = 0)
						error = stats.sem(shuff_dict[f][s]['Correlation'], axis = 0, nan_policy = 'omit')
						graph.linegraph_w_error(ax1[si], x,y, error, color = 'k', label = None, 
							linewidth = 1, linestyle = '--', alpha = 0.3)

					# Plotting aesthetics
					ax1[si].set_xlim([-75,75])
					ax1[si].set_ylim([-1,1])
					graph.thick_axes(fig1, ax1, width = 2)
					graph.label_axes(ax1[si], x = 'Time Lag (s)', y = 'Cross-Correlation', title = s, 
						title_fontsize = 20)

				fig1.tight_layout()

				# Save figure
				if savedir:
					fname  = b+'_'+f+'_chan'+e_dir[e_dir.find('AD')+2]+'.png'
					fig1.savefig(os.path.join(savedir, fname))

			# Optionally include another figure with cross-correlation with movement
			if add_movement:
				fig2, ax2 = fig_dict[b]['Movement']
				x = np.nanmean(corr_dict['Movement']['Lags'], axis = 0)*dt
				y = np.nanmean(corr_dict['Movement']['Correlation'], axis = 0)
				error = stats.sem(corr_dict['Movement']['Correlation'], axis = 0, nan_policy = 'omit')
				graph.linegraph_w_error(ax2, x,y, error, color = color_dict['Movement'], label = None, 
					linewidth = 1, linestyle = '-', alpha = 0.5)
				if shuffle:
					x = np.nanmean(shuff_dict['Movement']['Lags'], axis = 0)*dt
					y = np.nanmean(shuff_dict['Movement']['Correlation'], axis = 0)
					error = stats.sem(shuff_dict['Movement']['Correlation'], axis = 0, nan_policy = 'omit')
					graph.linegraph_w_error(ax2, x,y, error, color = 'k', label = None, 
						linewidth = 1, linestyle = '--', alpha = 0.3)

				# Plotting aesthetics
				ax2.set_xlim([-75,75])
				ax2.set_ylim([-1,1])
				graph.thick_axes(fig2, ax2, width = 2)
				graph.label_axes(ax2, x = 'Time Lag (s)', y = 'Cross-Correlation', title = 'Movement', 
					title_fontsize = 20)

				fig2.tight_layout()

				if savedir:
					fname  = b+'_Movement.png'
					fig2.savefig(os.path.join(savedir, fname))

		# Optionally store data dictionary for future group averaging
		if plot_grouped:
			all_dicts.append(corr_dict)
			if shuffle:
				all_shuff_dicts.append(shuff_dict)	
		
	if plot_grouped: # Average across experiments
		# Loop through each frequency
		for f in list(freq_dict.keys()):
			dt = np.unique(np.diff(power_dict['Bins']))
			fig1, ax1 = fig_dict['Grouped'][f]
			fig1.suptitle(f, fontweight = 'bold', fontsize = 25)

			# Loop through each state
			for si, s in enumerate(these_states):
				# Pull corresponding lags from every experiment
				all_x = [d[f][s]['Lags'] for d in all_dicts]
				all_x = [row.tolist() for arr in all_x for row in arr]

				# Pull corresponding correlations from every experiment
				all_y = [d[f][s]['Correlation'] for d in all_dicts]
				all_y = [row.tolist() for arr in all_y for row in arr]

				# Pad lists to match lengths before computing mean and SEM
				x = np.nanmean(PKA.pad_array(all_x), axis = 0)*dt
				y = np.nanmean(PKA.pad_array(all_y), axis = 0)
				error = stats.sem(PKA.pad_array(all_y), axis = 0,nan_policy='omit')

				# Plot average trace with SEM
				graph.linegraph_w_error(ax1[si], x,y, error, color = color_dict[s] , label = None, 
					linewidth = 1, linestyle = '-', alpha = 0.5)

				# Optionally repeat analysis with shuffled data
				if shuffle:
					all_x = [d[f][s]['Lags'] for d in all_shuff_dicts]
					all_x = [row.tolist() for arr in all_x for row in arr]

					all_y = [d[f][s]['Correlation'] for d in all_shuff_dicts]
					all_y = [row.tolist() for arr in all_y for row in arr]

					x = np.nanmean(PKA.pad_array(all_x), axis = 0)*dt
					y = np.nanmean(PKA.pad_array(all_y), axis = 0)
					error = stats.sem(PKA.pad_array(all_y), axis = 0,nan_policy='omit')
					graph.linegraph_w_error(ax1[si], x,y, error, color = 'k', label = None, 
						linewidth = 1, linestyle = '--', alpha = 0.3)

				# Plotting aesthetics
				ax1[si].set_xlim([-75,75])
				ax1[si].set_ylim([-1,1])
				graph.thick_axes(fig1, ax1, width = 2)
				graph.label_axes(ax1[si], x = 'Time Lag (s)', y = 'Cross-Correlation', title = s, 
					title_fontsize = 20)
			fig1.tight_layout()
			if savedir:
				fname  = group_name+'_'+f+'_chan'+e_dir[e_dir.find('AD')+2]+'.png'
				fig1.savefig(os.path.join(savedir, fname))
		
		# Optionally, plot averaged movement
		if add_movement:
			all_x = [d['Movement']['Lags'] for d in all_dicts]
			all_x = [row.tolist() for arr in all_x for row in arr]

			all_y = [d['Movement']['Correlation'] for d in all_dicts]
			all_y = [row.tolist() for arr in all_y for row in arr]

			fig2, ax2 = fig_dict['Grouped']['Movement']

			x = np.nanmean(PKA.pad_array(all_x), axis = 0)*dt
			y = np.nanmean(PKA.pad_array(all_y), axis = 0)
			error = stats.sem(PKA.pad_array(all_y), axis = 0, nan_policy = 'omit')
			graph.linegraph_w_error(ax2, x,y, error, color = color_dict['Movement'], label = None, 
				linewidth = 1, linestyle = '-', alpha = 0.5)
			if shuffle:
				all_x = [d['Movement']['Lags'] for d in all_shuff_dicts]
				all_x = [row.tolist() for arr in all_x for row in arr]

				all_y = [d['Movement']['Correlation'] for d in all_shuff_dicts]
				all_y = [row.tolist() for arr in all_y for row in arr]

				x = np.nanmean(PKA.pad_array(all_x), axis = 0)*dt
				y = np.nanmean(PKA.pad_array(all_y), axis = 0)
				error = stats.sem(PKA.pad_array(all_y), axis = 0, nan_policy = 'omit')
				graph.linegraph_w_error(ax2, x,y, error, color = 'k', label = None, 
					linewidth = 1, linestyle = '--', alpha = 0.3)

			ax2.set_xlim([-75,75])
			ax2.set_ylim([-1,1])
			graph.thick_axes(fig2, ax2, width = 2)
			graph.label_axes(ax2, x = 'Time Lag (s)', y = 'Cross-Correlation', title = 'Movement', 
				title_fontsize = 20)

			fig2.tight_layout()
			if savedir:
				fname  = group_name+'_Movement.png'
				fig2.savefig(os.path.join(savedir, fname))

	return fig_dict

def mAKAR_dynamics_correlations(FLP_clsasses, experiment_names, end_LFT_bin = 5, 
			history_bin = 3600, MA_to_NREM = False, return_df = False, shuffle = False):
	###DEPRECATED: reworking this whole thing
	"""
	Computes correlations between dynamics of fluorescence lifetime (LFT) 
	and features of sleep-wake cycles, including durations and densities of states.

	Parameters:
	----------
	FLP_classes : list
	    A list of FLP experiment class objects containing photometry and sleep state data.
	experiment_names : list
	    A list of strings with the names of the experiments.
	end_LFT_bin : int, optional
	    Time window (in seconds) at the end of a NREM bout for averaging fluorescence data (default: 5).
	history_bin : int, optional
	    Time window (in seconds) for calculating state densities before and after transitions (default: 3600).
	MA_to_NREM : bool, optional
	    If True, treats microarousals as NREM for the analysis (default: False).

	Returns:
	-------
	corr_dict : dict
	    A dictionary containing 2 dictionaries of the following correlations for REM and NREM:
	    - 'End LFT': LFT at the end of NREM bouts
	    - 'Wake SS' : Steady State LFT value during wake bout
	    - 'Wake Duration (Subsequent Epoch)': Duration of the previous wake bout
	    - 'Sleep Duration (Previous Epoch)': Duration of the subsequent sleep bout
	    - 'Subsequent Wake Density': Density of wake states following Sleep bouts
	    - 'Previous Sleep Density': Density of Sleep states preceding Sleep bouts
	"""

	 # Initialize a dictionary to store correlation results
	corr_dict = {'NREM': {'End LFT':[], 'Wake Duration (Subsequent Epoch)': [], 
	'Sleep Duration (Previous Epoch)': [], 'Subsequent Wake Density': [], 'Previous Sleep Density': []},
				'REM': {'End LFT':[], 'Wake Duration (Subsequent Epoch)': [], 
	'Sleep Duration (Previous Epoch)': [], 'Subsequent Wake Density': [], 'Previous Sleep Density': []}}
	# Process each experiment
	for FLP_exp,b in zip(FLP_classes, experiment_names):
		print(b)
		onoff_df_full = FLP_exp.ss_onset_offset()

		# If specified, reclassify microarousals (state 5) as NREM (state 2)
		if MA_to_NREM:
			FLP_exp.SleepStates[FLP_exp.SleepStates == 5] = 2
			onoff_df = FLP_exp.ss_onset_offset()
			onoff_df['Duration'] = onoff_df['End Time'] - onoff_df['Start Time']

		else:
			onoff_df = onoff_df_full

		transition_dict = FLP_exp.transition_timestamps()
		
		# Populated the NREM correlations
		transition_idx = [onoff_df.loc[onoff_df['Start Time'] == i].index[0] for i in transition_dict['Timestamps']['NREM-Wake']]
		corr_dict['NREM']['Sleep Duration (Previous Epoch)'].append(
			[onoff_df['Duration'].loc[i-1] for i in transition_idx])
		corr_dict['NREM']['End LFT'].append([onoff_df['End LFT'].loc[i-1] for i in transition_idx])
		corr_dict['NREM']['Wake Duration (Subsequent Epoch)'].append([onoff_df['Duration'].loc[i] for i in transition_idx])

		# Populated the REM correlations
		transition_idx = list(onoff_df.loc[onoff_df['State'] == 3].index)
		corr_dict['REM']['Sleep Duration (Previous Epoch)'].append([onoff_df['Duration'].loc[i]+onoff_df['Duration'].loc[i-1] for i in transition_idx])
		corr_dict['REM']['End LFT'].append([onoff_df['End LFT'].loc[i] for i in transition_idx])
		corr_dict['REM']['Wake Duration (Subsequent Epoch)'].append([onoff_df_full['Duration'].loc[i+1] for i in transition_idx])

		return corr_dict


def add_end_LFT(onoff_df, FLP_exp, end_LFT_bin, shuffle = False, zscore = False):
	# Compute average fluorescence (LFT) at the end of each sleep bout
	if zscore:
		for i in onoff_df.loc[(onoff_df['State'] == 2) | (onoff_df['State'] == 3)].index:
			this_bout = onoff_df.loc[i]
			if this_bout['Duration'] > end_LFT_bin:
				# Use the last `end_LFT_bin` seconds of the bout
				onoff_df.loc[i, 'End LFT'] = np.mean(FLP_exp.ZScore[(FLP_exp.Time >= this_bout['End Time']-end_LFT_bin) & (FLP_exp.Time <= this_bout['End Time'])])
				if shuffle:
					onoff_df.loc[i, 'End LFT Shuffle'] = np.mean(FLP_exp.Shuff[(FLP_exp.Time >= this_bout['End Time']-end_LFT_bin) & (FLP_exp.Time <= this_bout['End Time'])])
			else:
				# Use the entire bout if it's shorter than `end_LFT_bin`
				onoff_df.loc[i, 'End LFT'] = np.mean(FLP_exp.Lifetime[(FLP_exp.Time >= this_bout['Start Time']) & (FLP_exp.Time <= this_bout['End Time'])])
				if shuffle:
					onoff_df.loc[i, 'End LFT Shuffle'] = np.mean(FLP_exp.Shuff[(FLP_exp.Time >= this_bout['Start Time']) & (FLP_exp.Time <= this_bout['End Time'])])
	else:
		for i in onoff_df.loc[(onoff_df['State'] == 2) | (onoff_df['State'] == 3)].index:
			this_bout = onoff_df.loc[i]
			if this_bout['Duration'] > end_LFT_bin:
				# Use the last `end_LFT_bin` seconds of the bout
				onoff_df.loc[i, 'End LFT'] = np.mean(FLP_exp.Lifetime[(FLP_exp.Time >= this_bout['End Time']-end_LFT_bin) & (FLP_exp.Time <= this_bout['End Time'])])
				if shuffle:
					onoff_df.loc[i, 'End LFT Shuffle'] = np.mean(FLP_exp.Shuff[(FLP_exp.Time >= this_bout['End Time']-end_LFT_bin) & (FLP_exp.Time <= this_bout['End Time'])])
			else:
				# Use the entire bout if it's shorter than `end_LFT_bin`
				onoff_df.loc[i, 'End LFT'] = np.mean(FLP_exp.Lifetime[(FLP_exp.Time >= this_bout['Start Time']) & (FLP_exp.Time <= this_bout['End Time'])])
				if shuffle:
					onoff_df.loc[i, 'End LFT Shuffle'] = np.mean(FLP_exp.Shuff[(FLP_exp.Time >= this_bout['Start Time']) & (FLP_exp.Time <= this_bout['End Time'])])

	return onoff_df

def add_d2(FLP_exp, onoff_df, binsize, d2):
    wake_idx = onoff_df.loc[onoff_df['State'] == 1].index
    for i in wake_idx:
        this_bout = onoff_df.loc[i]
        if this_bout['Duration'] > binsize:
            val_idx, = np.where((FLP_exp.Time >= this_bout['Start Time']) & (FLP_exp.Time < this_bout['Start Time'] + binsize))
            onoff_df.loc[i,'d2'] = np.mean(d2[val_idx])
    return onoff_df

def LFT_WakeSleepDistance(FLP_exp, time_range, get_wake_distance = True, get_sleep_distance = False,
	MA_to_NREM = False, NREM_wake_only = False, shuffled = True, buffer = 0):

	data_dict = {}
	if shuffled:
		data_dict['Shuffled'] = []

	alt_sleepstates = deepcopy(FLP_exp.SleepStates)
	if MA_to_NREM:
		alt_sleepstates[alt_sleepstates == 5] = 2
	else:
		alt_sleepstates[alt_sleepstates == 5] = 1

	if not NREM_wake_only:
		alt_sleepstates[alt_sleepstates == 3] = 2
	onoff_df = FLP_exp.ss_onset_offset(alt_sleepstates = alt_sleepstates)
	LFT_vals = PKA.LFTvals_byState(FLP_exp, onoff_df, time_range, shuffled = shuffled, buffer = buffer, 
		state_key = {'0': 'Unscored', '1': 'Wake', '2': 'NREM', '3': 'REM', '5':'Microaorusal'})
	transition_dict = FLP_exp.transition_timestamps(alt_sleepstates = alt_sleepstates)
	if 'NREM' not in list(LFT_vals['Time'].keys()):
		print('There is no NREM here')
		return
	for d in LFT_vals['Lifetime'].keys():
		if get_wake_distance:
			temp = []
			for t,l in zip(LFT_vals['Time']['NREM'][1:], LFT_vals['Lifetime'][d]['NREM'][1:]):
				flag = 0
				for s in transition_dict['Timestamps']['NREM-REM']:
					if any(abs(t-s) < 2):
						flag = 1
						continue
				if flag == 0:
					temp.append((t,l))

			timepoints, lft = zip(*temp)
			timepoints = np.concatenate(timepoints)
			distance = np.asarray(PKA.distance_from_transition(transition_dict, 'NREM-Wake', 
				timepoints))
			data_dict[d] = np.concatenate(lft)
			data_dict['Distance'] = distance
			data_dict['Timepoints'] = timepoints
		elif get_sleep_distance:
		# print('working on sleep duration')
			temp = []
			for t,l in zip(LFT_vals['Time']['NREM'][1:], LFT_vals['Lifetime'][d]['NREM'][1:]):
				for s in transition_dict['Timestamps']['NREM-Wake']:
					if any(abs(t-s) < 2):
						np.append(t,s)
						temp.append((t,l))						

			timepoints, lft = zip(*temp)
			# distance = np.asarray(PKA.distance_from_transition(transition_dict, 'Wake-NREM', 
			# 	timepoints, relation = 'before'))
			distance = np.concatenate([t-t[0] for t in timepoints])
			data_dict[d] = np.concatenate(lft)
			data_dict['Distance'] = distance
			data_dict['Timepoints'] = np.concatenate(timepoints)

	return data_dict

def plot_wake_probability(fig, ax, LFT, distance, bin_edges, waking_binsize = 16, label = None, include_n = False,
	savedir = None, color = 'k', confidence_int = True):
	wake_prop = np.zeros([len(bin_edges)-1,2])
	wake_prop[:] = np.nan
	for i in range(len(wake_prop)):
		distance_idx, = np.where((LFT >= bin_edges[i]) & (LFT < bin_edges[i+1]))
		waking_idx, = np.where(distance[distance_idx] <= waking_binsize)
		if len(waking_idx) > 0: 
			wake_prop[i] = (len(waking_idx), len(distance_idx))
	# keep_idx = [i for i in range(len(wake_prop)) if wake_prop[i][0] > 0]
	bin_centers =  np.asarray([np.mean([bin_edges[i], bin_edges[i+1]]) 
		for i in range(len(bin_edges)-1)])
	# bin_centers = np.asarray(bin_centers)[keep_idx]
	# wake_prop = np.asarray(wake_prop)[keep_idx]

	binsize = bin_edges[1]-bin_edges[0]
	temp = [(proportion_confint(wake_prop[i][0], wake_prop[i][1], alpha=0.05, method='wilson'), wake_prop[i][0]/wake_prop[i][1])
			for i in range(len(wake_prop))]
	CIs, wake_prob = zip(*temp)
	CIs = np.asarray(CIs)
	wake_prob = list(wake_prob)
	y_err = [abs(c-wake_prob) for c in CIs.T]
	if confidence_int:
		for ii in range(len(bin_centers)):
			ax.errorbar(bin_centers[ii], wake_prob[ii], yerr = [[y_err[0][ii]], [y_err[1][ii]]], linestyle = None, 
						fmt = '_', color = color, capsize = 5, linewidth = 2, label = label)

		if include_n:
			height = wake_prob[ii]+y_err[1][ii]+ 0.008
			ax.text(
			    bin_centers[ii],  # x position (center of the bar)
			    height,                      # y position (slightly above the bar)
			    str(hue_vals[ii]),                       # text to display (the value)
			    ha='center',                       # horizontal alignment
			    va='bottom',                       # vertical alignment
			    fontweight='bold'                  # optional: make the text bold
			)
	else:
		ax.plot(bin_centers, wake_prob, color = color, marker = 'o', linewidth = 0.5)
	# ax.set_xticks(bin_centers)
	# ax.set_xticklabels(np.round(bin_centers, 2), rotation= 15)
	# graph.thick_axes(fig, ax, width = 0.4)
	graph.label_axes(ax, y = 'Probability of Waking\n(Threshold: '+str(waking_binsize)+'s)', 
	                 x = 'Z-Scored Binding Fraction', fontweight = 'normal')
	fig.tight_layout()
	if savedir:
		fig.savefig(savedir)

	return fig, ax, wake_prop, bin_centers

def PhosphoPlot(lifetime, fig, ax, b, filterbin_width = 40, scale = 1, alpha = 0.75, headwidth=2, 
		headlength=4, headaxislength=3.5, width = 0.002):
    # Moving mean with window size 40
	try: 
		x = uniform_filter1d(lifetime, size=filterbin_width, mode='nearest')
		# Compute derivative
		y = np.diff(x, append=0)
	except ValueError:
		x = [uniform_filter1d(l, size=filterbin_width, mode='nearest') for l in lifetime]
		y = [np.diff(xi, append=0) for xi in x]
		x = np.concatenate(x)
		y = np.concatenate(y)

	# Filter derivative values
	for i in range(1, len(y)):
		if y[i] > 0.005 or y[i] < -0.005:
			y[i] = y[i-1]
	N = len(x)

	# Define parameters
	tau = 5
	numBinsX = 100
	numBinsY = 100

	# Define bin edges
	xEdges = np.linspace(x.min(), x.max(), numBinsX+1)
	yEdges = np.linspace(y.min(), y.max(), numBinsY+1)

	# Compute 2D histogram and bin assignments
	countsS, xEdges_out, yEdges_out = np.histogram2d(x, y, bins=[xEdges, yEdges])

	# Get bin indices for each point
	BINX = np.digitize(x, xEdges) - 1  # -1 to make it 0-indexed
	BINY = np.digitize(y, yEdges) - 1

	# Clip bin indices to valid range
	BINX = np.clip(BINX, 0, numBinsX - 1)
	BINY = np.clip(BINY, 0, numBinsY - 1)

	# Pre-allocate array for average vectors
	avgVectors = np.full((numBinsX, numBinsY, 2), np.nan)

	# Compute bin centers
	centersX = (xEdges[:-1] + xEdges[1:]) / 2
	centersY = (yEdges[:-1] + yEdges[1:]) / 2

	# Loop over each bin
	for i in range(numBinsX):
		for j in range(numBinsY):
			# Find indices of points in current bin
			idx = np.where((BINX == i) & (BINY == j))[0]

			# Only keep indices where t+tau exists
			idx = idx[idx + tau < N]

			if len(idx) > 0:
				# Compute displacement vectors
				dx = x[idx + tau] - x[idx]
				dy = y[idx + tau] - y[idx]

				# Average the displacement vectors
				avgVectors[i, j, 0] = np.mean(dx)
				avgVectors[i, j, 1] = np.mean(dy)
	# Plot heatmap
	num_bins = 300
	x_edges = np.linspace(x.min(), x.max(), num_bins+1)
	y_edges = np.linspace(y.min(), y.max(), num_bins+1)

	# Compute 2D histogram for plotting
	counts, XEDGES, YEDGES = np.histogram2d(x, y, bins=[x_edges, y_edges])

	# plt.figure(figsize=(10, 8))
	im = ax.imshow(counts.T, extent=[x_edges[0], x_edges[-1], y_edges[0], y_edges[-1]], 
	           origin='lower', aspect='auto', cmap='jet', norm='log')
	plt.colorbar(mappable = im, label='Counts')
	graph.label_axes(ax, x = 'Binding Fraction', y = r'$\Delta$Binding Fraction', title = str(b))
	fig.tight_layout()
	# Create a meshgrid of bin centers for plotting the vectors.
	# Note: meshgrid will create matrices with dimensions (numBinsY x numBinsX)
	
	Xc, Yc = np.meshgrid(centersX, centersY)

	U = avgVectors[:, :, 0].T  # Average dx for each bin
	V = avgVectors[:, :, 1].T  # Average dy for each bin

	mag = np.sqrt(U**2 + V**2)  # Compute magnitude
	U_norm = U / mag  # Normalize U
	V_norm = V / mag  # Normalize V

	# Replace NaN values for zero-magnitude vectors
	U_norm = np.nan_to_num(U_norm, nan=0.0)
	V_norm = np.nan_to_num(V_norm, nan=0.0)

	x_range = centersX.max() - centersX.min()
	y_range = centersY.max() - centersY.min()

	Xc_norm = (Xc - centersX.min()) / x_range
	Yc_norm = (Yc - centersY.min()) / y_range

	U_ax = U / x_range  # normalize vector components
	V_ax = V / y_range

	# Overlay the averaged displacement vectors using quiver
	# fig, ax = plt.subplots()
	# ax2 = ax.twinx()
	ax.quiver(Xc, Yc, U_ax, V_ax, color='k', linewidth=0.5, scale = scale, alpha = alpha, headwidth=headwidth, 
		headlength=headlength, headaxislength= headaxislength, width = width)	
	plt.show()

	return fig, ax

def compute_mutual_info(X, Y, num_bins):
    """
    Computes mutual information between two signals.
    
    Parameters:
    -----------
    X : array-like
        First signal
    Y : array-like
        Second signal
    num_bins : int
        Number of bins for histogram
    
    Returns:
    --------
    MI : float
        Mutual information value
    """
    # Compute 2D histogram
    N, edgesX, edgesY = np.histogram2d(X, Y, bins=num_bins)
    
    # Joint probability
    Pxy = N / np.sum(N)
    
    # Marginal probabilities
    Px = np.sum(Pxy, axis=1)
    Py = np.sum(Pxy, axis=0)
    
    # Compute entropies (using nansum equivalent with eps for numerical stability)
    Hx = -np.sum(Px * np.log2(Px + np.finfo(float).eps))
    Hy = -np.sum(Py * np.log2(Py + np.finfo(float).eps))
    Hxy = -np.sum(Pxy * np.log2(Pxy + np.finfo(float).eps))
    
    # Compute Mutual Information
    MI = Hx + Hy - Hxy
    
    return MI

def nlcc_mi(signal1, signal2, max_lag, num_bins, normalize=False):
    """
    Computes the Nonlinear Cross-Correlation (NLCC) using Mutual Information.
    
    Parameters:
    -----------
    signal1 : array-like
        First input time series
    signal2 : array-like
        Second input time series
    max_lag : int
        Maximum lag to evaluate
    num_bins : int
        Number of bins used for histogram-based probability estimation
    
    Returns:
    --------
    MI_values : ndarray
        Mutual information values at each lag
    lags : ndarray
        Array of lag values
    """
    signal1 = np.array(signal1)
    signal2 = np.array(signal2)
    
    lags = np.arange(-max_lag, max_lag + 1)
    MI_values = np.zeros(len(lags))
    
    for i, lag in enumerate(lags):
        if lag < 0:
            # Shift signal2 backward (leading)
            shifted_signal2 = np.concatenate([
                signal2[-lag:],
                np.full(-lag, np.nan)
            ])
        elif lag > 0:
            # Shift signal2 forward (lagging)
            shifted_signal2 = np.concatenate([
                np.full(lag, np.nan),
                signal2[:-lag]
            ])
        else:
            # No shift
            shifted_signal2 = signal2.copy()
        
        # Remove NaN values introduced by shifting
        valid_idx = ~np.isnan(shifted_signal2)
        s1 = signal1[valid_idx]
        s2 = shifted_signal2[valid_idx]
        
        # Compute Mutual Information
        mi = compute_mutual_info(s1, s2, num_bins)
        
        if normalize:
            # Normalize by geometric mean of marginal entropies
            h1 = compute_entropy(s1, num_bins)
            h2 = compute_entropy(s2, num_bins)
            MI_values[i] = mi / np.sqrt(h1 * h2) if (h1 > 0 and h2 > 0) else 0
        else:
            MI_values[i] = mi

    
    return MI_values, lags

def compute_entropy(signal, num_bins):
    """Compute Shannon entropy of a signal."""
    hist, _ = np.histogram(signal, bins=num_bins, density=True)
    # Remove zero probabilities
    hist = hist[hist > 0]
    # Normalize
    hist = hist / hist.sum()
    entropy = -np.sum(hist * np.log2(hist))
    return entropy

def wake_prob_logreg(wake_distance_vals, sleep_duration_vals, pka_sp, animal_list, cat_zt, wake_threshold = 16,  
	standardized = False, gee = True):
	# wake_mask = wake_distance_vals
	# Create your DataFrame
	try:
		assert len(wake_distance_vals) == len(sleep_duration_vals) == len(pka_sp)
	except AssertionError:
		clean_idx, = np.where(~np.isnan(wake_distance_vals))
		wake_distance_vals = wake_distance_vals[clean_idx]
		pka_sp = pka_sp[clean_idx]
		animal_list = animal_list[clean_idx]
	assert len(wake_distance_vals) == len(sleep_duration_vals) == len(pka_sp)
	wake_mask = (wake_distance_vals < wake_threshold).astype(int)
	if standardized:
		df = pd.DataFrame({
		    'mask': wake_mask,
		    'pka_sp': stats.zscore(pka_sp),
		    'duration_sleep': stats.zscore(sleep_duration_vals),
		    'animal_id': animal_list,
		    'cat_zt': cat_zt
		})
	else:
		df = pd.DataFrame({
		    'mask': wake_mask,
		    'pka_sp': pka_sp,
		    'duration_sleep': sleep_duration_vals,
		    'animal_id': animal_list,
		    'cat_zt': cat_zt
		})
	
	# Fit model with standardized predictors
	formula = 'mask ~ pka_sp + duration_sleep'
	if gee:
		full_model = smf.gee("mask ~ pka_sp + duration_sleep",
			groups=df["animal_id"],
			data=df,
			family=sm.families.Binomial(),
			cov_struct=sm.cov_struct.Exchangeable())  # Assumes constant correlation within animal
		full_result = full_model.fit()
	else:
		formula_onlysleep = 'mask ~ duration_sleep'
		formula_onlypka = 'mask ~ pka_sp'
		if animal_list is not None:
			formula = formula + ' + C(animal_id)'
			formula_onlysleep = formula_onlysleep + ' + C(animal_id)'
			formula_onlypka = formula_onlypka + ' + C(animal_id)'
		if cat_zt is not None:
			formula = formula + ' + C(cat_zt)'
			formula_onlysleep = formula_onlysleep + ' + C(cat_zt)'
			formula_onlypka = formula_onlypka + ' + C(cat_zt)'

		full_model = smf.logit(formula, data=df)

		# Model without PKA-SP
		no_pka_result = smf.logit(formula_onlysleep, data=df).fit()

		# Model without duration_sleep
		no_duration_result = smf.logit(formula_onlypka, data=df).fit()
		full_result = full_model.fit()
		# Likelihood ratio tests
		lr_pka = -2 * (no_pka_result.llf - full_result.llf)
		lr_duration = -2 * (no_duration_result.llf - full_result.llf)
	
	
	coeffs = full_result.params

	model_measures = {p+'_coeff': coeffs[p] for p in coeffs.keys()}
	for p in full_result.pvalues.keys():
		model_measures[p+'_pval'] = full_result.pvalues[p]
	if not gee:
		model_measures['LR_pka'] = lr_pka
		model_measures['LR_sleepduration'] = lr_duration

	return model_measures, full_result


def hazard_model(sleep_duration_vals, pka_sp, animal_list, event, bout_ID, MA_count, ZT_time,
                 R_file_dir = '/Users/lizzie/Desktop/Remote_Git/Chen_Lab/PKA_Sleep/PKA_Sleep/',
                 R_filename = 'final_frailty_model_withMAZT.R',
                 run_bootstrap = True, run_ph_test = True, run_linearity = False,
                 return_data = False, verbose=True):

    assert len(sleep_duration_vals) == len(pka_sp)

    data_dict = {'animal_id': [],
                'start': [],
                'stop': [],
                'pka_sp': [],
                'bout_id': [],
                'event': [],
                'microarousals':[],
                'zt':[]}
    for i in range(len(sleep_duration_vals)):
        data_dict['animal_id'].append(animal_list[i][:-1])
        data_dict['start'].append(sleep_duration_vals[i][:-1])
        data_dict['stop'].append(sleep_duration_vals[i][1:])
        data_dict['pka_sp'].append(pka_sp[i][1:])
        data_dict['bout_id'].append(bout_ID[i][1:])
        data_dict['event'].append(event[i][1:])
        data_dict['microarousals'].append(MA_count[i][1:])
        data_dict['zt'].append(ZT_time[i][1:])

    for k in data_dict.keys():
        data_dict[k] = np.concatenate(data_dict[k])
    df = pd.DataFrame(data_dict)

    df["bout_id"]   = df["bout_id"].astype(int)
    df["event"]     = df["event"].astype(int)
    df["animal_id"] = df["animal_id"].astype(str)
    print("\n" + "="*60)
    print("RUNNING COXME FRAILTY MODELS VIA R")
    print("="*60)

    with tempfile.NamedTemporaryFile(suffix=".csv", delete=False, mode="w") as f:
        data_path = f.name
        df.to_csv(data_path, index=False)

    results_path  = os.path.join(tempfile.gettempdir(), "coxme_results.csv")
    r_script_path = os.path.join(R_file_dir, R_filename)

    # Stream R output line-by-line so progress is visible in the notebook
    proc = subprocess.Popen(
        ["Rscript", r_script_path, data_path, results_path, str(run_bootstrap), str(run_ph_test), str(run_linearity)],
        stdout  = subprocess.PIPE,
        stderr  = subprocess.PIPE,
        text    = True,
        bufsize = 1
    )
    for line in proc.stdout:
    	if verbose:
        	print(line, end='', flush=True)
    proc.wait()
    stderr_output = proc.stderr.read()

    if proc.returncode != 0:
        print("R script error:")
        print(stderr_output)
        raise RuntimeError("R script failed — see error above.")

    os.unlink(data_path)
    res      = pd.read_csv(results_path).set_index("metric")["value"]
    # zt_curve = pd.read_csv(results_path.replace(".csv", "_zt_curve.csv"))
    zt_cat   = pd.read_csv(results_path.replace(".csv", "_zt_cat.csv"))
    # zt_cat_cov   = pd.read_csv(results_path.replace(".csv", "_zt_cat_covariates.csv")).set_index("metric")["value"]
    boot_dist_path = results_path.replace(".csv", "_boot_dist.csv")
    boot_dist = pd.read_csv(boot_dist_path) if not pd.isna(res['atten_pka_boot_mean']) else None
    mart_main    = pd.read_csv(results_path.replace(".csv", "_martingale_main.csv"))  if run_linearity else None
    mart_final   = pd.read_csv(results_path.replace(".csv", "_martingale_final.csv")) if run_linearity else None
    hr_linearity = pd.read_csv(results_path.replace(".csv", "_hr_linearity.csv"))     if run_linearity else None
    out = {'res': res, 'zt_cat': zt_cat, 'boot_dist': boot_dist,
           'mart_main': mart_main, 'mart_final': mart_final, 'hr_linearity': hr_linearity}
    if return_data:
        out['df'] = df
    return out

def power_phosphoplot(pka_sp, pka_t, power, ax, filterbin_width = 40, vmin = None, vmax = None, s = 4, alpha = 0.4):
	x = uniform_filter1d(pka_sp, size=filterbin_width, mode='nearest')
	# Compute derivative
	y = np.diff(x, append=0)
	bin_starts = np.arange(0, len(pka_sp)-filterbin_width)
	bin_ends = np.arange(filterbin_width, len(pka_sp))
	slopes = []
	for ii in range(len(bin_starts)): 
	    yy_fit = pka_sp[bin_starts[ii]:bin_ends[ii]]
	    xx_fit = pka_t[bin_starts[ii]:bin_ends[ii]]
	    slopeFirst = np.polyfit(xx_fit, yy_fit, 1)
	    slopes.append(slopeFirst[0])

	for i in range(1, len(y)):
		if y[i] > 0.005 or y[i] < -0.005:
			y[i] = y[i-1]

	assert len(x) == len(power) == len(y)

	ax.scatter(pka_sp[:len(slopes)],slopes,c=power[:len(slopes)], cmap='viridis', s = s, vmin = vmin, vmax = vmax, alpha = alpha)

	return ax

def plot_binned_power_p2(P2_dict, power_dict, bin_edges, transition_type = 'NREM-Wake', norm_val = None, 
	cmap_name = 'viridis', color_list = None):
	if color_list is not None:
		color_list = graph.get_colormap(len(bin_edges), cmap_name = cmap_name)
	fig_dict = {p:plt.subplots(ncols = 2, figsize = [8, 4]) for p in power_dict['Power'].keys()}
	quant_dict = {str(bin_edges[i]) + '-' + str(bin_edges[i+1]): 
					{'Lifetime': {'Average Trace':[], 'Difference':[]},
					'Power':{'Average Trace':[], 'Difference':[]}} for i in range(len(bin_edges)-1)}	
	for i in range(len(bin_edges)-1):
		color_dict = {t:color_list[i] for t in P2_dict['Lifetime']['FLIM-mAKAR'].keys()}
		these_bins_p2 = [np.where((P2_dict['Previous Bout Length'][transition_type][b] >= bin_edges[i]) & 
			(P2_dict['Previous Bout Length'][transition_type][b] < bin_edges[i+1]))[0] 
			for b in range(len(power_dict['Experiment Name']))]

		P2_data = {}
		P2_data['Lifetime'] = {d: {k:[P2_dict['Lifetime'][d][k][ii][these_bins_p2[ii], :] 
										for ii in range(len(P2_dict['Lifetime'][d][k]))] for k in P2_dict['Lifetime'][d].keys()}
								for d in P2_dict['Lifetime'].keys()}
		P2_data['Experiment Name'] = P2_dict['Experiment Name']
		P2_data['Mouse ID'] = P2_dict['Mouse ID']
		P2_data['Time'] = {k:P2_dict['Time'][k] for k in P2_dict['Time'].keys()}

		power_data = {}
		these_bins_power = [np.where((power_dict['Previous State Duration'][transition_type][b] >= bin_edges[i]) & 
			(power_dict['Previous State Duration'][transition_type][b] < bin_edges[i+1]))[0] for b in range(len(power_dict['Experiment Name']))]
		if norm_val is not None:
			power_data['Power'] = {p: {k:[power_dict['Power'][p][k][ii][these_bins_power[ii], :]/norm_val 
									for ii in range(len(power_dict['Power'][p][k]))] for k in power_dict['Power'][p].keys()}
								for p in power_dict['Power'].keys()}
		else:
			power_data['Power'] = {p: {k:[power_dict['Power'][p][k][ii][these_bins_power[ii], :] 
					for ii in range(len(power_dict['Power'][p][k]))] for k in power_dict['Power'][p].keys()}
					for p in power_dict['Power'].keys()}
		power_data['Experiment Name'] = power_dict['Experiment Name']
		power_data['Mouse ID'] = power_dict['Mouse ID']
		power_data['Time'] = {transition_type:power_dict['Time'][transition_type]}
		if len(P2_dict['Experiment Name']) > 1:
			all_dicts, power_data_split = PKA.split_by_animal(power_data, average_function = np.nanmean, data_key = 'Power')
			all_dicts, P2_data_split = PKA.split_by_animal(P2_data, average_function = np.nanmean)
		else:
			P2_data_split = {p: {k:power_data['Power'][p][k] for k in power_dict['Power'][p].keys()} for p in power_dict['Power'].keys()} 
		for p in power_dict['Power'].keys():
			fig, ax = fig_dict[p]
			power_y1 = {transition_type: [[np.array(y[0])] for y in power_data_split[p][transition_type] if len(y[0]) > 0]}
			PKA.plot_triggered_average(power_y1, power_data['Time'], [transition_type], fig, [ax[1]], color_dict, p, average_function = np.nanmean, 
				error_function = stats.sem, y_negative = False, 
				legend_label = list(P2_data.keys())[0] + '\n(n = '+str(len(np.unique(power_data['Mouse ID']))) + ')')
			t_idx, = np.where((power_data['Time'][transition_type]>=-bin_edges[i+1]) & 
				(power_data['Time'][transition_type]<0))
			quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Power']['Average Trace'] = [t[0][t_idx] for t in power_y1[transition_type]]
			quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Power']['Difference'] = [np.nanmedian(t[-10:-5])-np.nanmedian(t[5:10]) 
																	for t in quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Power']['Average Trace']]

			PKA.plot_triggered_average(P2_data_split['FLIM-mAKAR'], P2_data['Time'], [transition_type], fig, [ax[0]], 
				color_dict, transition_type, average_function = np.nanmean, error_function = stats.sem, y_negative = False, 
				legend_label = list(P2_data.keys())[0] + '\n(n = '+str(len(np.unique(power_data['Mouse ID']))) + ')')
			t_idx, = np.where((P2_data['Time'][transition_type]>=-bin_edges[i+1]) & 
				(P2_data['Time'][transition_type]<0))
			quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Lifetime']['Average Trace'] = [t[0][t_idx] for t in P2_data_split['FLIM-mAKAR'][transition_type]
																										if len(t[0]) > 0]
			quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Lifetime']['Difference'] = [np.nanmedian(t[-10:])-np.nanmedian(t[:10]) 
																	for t in quant_dict[str(bin_edges[i]) + '-' + str(bin_edges[i+1])]['Lifetime']['Average Trace']]


	fig.tight_layout()
	return fig, ax, quant_dict







