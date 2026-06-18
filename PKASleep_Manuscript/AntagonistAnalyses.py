import PKA_Sleep as PKA
import PKA_Sleep.Graphing_Utils as graph
import numpy as np
import os
from datetime import datetime, timedelta
import pandas as pd
import matplotlib.pyplot as plt
from copy import deepcopy
import matplotlib.patches as patch
from scipy import stats
from matplotlib import colormaps

def get_injection_ts(ts_fn, frame):
    df = pd.read_csv(ts_fn, header = None)
    ts = df[0].loc[frame]
    return ts[:-7]
def pull_injection_datetimes(injection_info, ts_format, experiment_names):
	if type(experiment_names[0]) is list:
		experiment_names = experiment_names[0]
	injection_datetimes = {k: np.concatenate([[datetime.strptime(injection_info[b][k+' Timestamps'][i], ts_format) 
										for i in range(len(injection_info[b][k+' Timestamps']))] for b in experiment_names  if b in injection_info.keys()]) for k in ['Saline', 'Drug']}
	return injection_datetimes

def sort_injection_datetimes(injection_datetimes):
	all_injection_times = [(key, dt) for key, datetimes in injection_datetimes.items() for dt in datetimes]
	sorted_injection_times = sorted(all_injection_times, key=lambda x: x[1])
	return sorted_injection_times


def find_injection_times(sorted_injection_times, FLP_exp):
	injection_acq = np.zeros(len(sorted_injection_times))
	injection_time_acq = np.zeros(len(sorted_injection_times))
	injection_time_fromstart = np.zeros(len(sorted_injection_times))
	
	acq_list, adjusted_AcqNum = PKA.adjust_acq_nums(FLP_exp)
	adjusted_acqlist = np.arange(0, len(acq_list))
	for i,s in enumerate(sorted_injection_times):
		acq_idx, = np.where([(s[1] > FLP_exp.Timestamps[ii]) & 
			(s[1] < FLP_exp.Timestamps[ii+1]) for ii in range(len(FLP_exp.Timestamps)-1)])
		if (len(acq_idx) == 0) & (s[1] > FLP_exp.Timestamps[-1]):
			acq_idx = [-1]
		injection_acq[i] = acq_list[acq_idx[0]]
		injection_time_acq[i] = (sorted_injection_times[i][1]-FLP_exp.Timestamps[acq_idx[0]]).total_seconds()
		injection_time_fromstart[i] = FLP_exp.Time[
								(adjusted_AcqNum == adjusted_acqlist[acq_idx[0]])][0]+injection_time_acq[i]

	return injection_acq, injection_time_acq, injection_time_fromstart

def get_experimental_epochs(injection_df, FLP_exp, post_injection_buffer = 7200):
	injection_df['Epoch Number'] = (injection_df['Injection Type'] != injection_df['Injection Type'].shift()).cumsum()
	injection_types = np.unique(injection_df['Injection Type'])
	experimental_epochs = {'Time (s)': {}, 'Acquisitions': {}}
	for i in injection_types:
		experimental_epochs['Time (s)'][i] = []
		experimental_epochs['Acquisitions'][i] = []
		this_df = injection_df.loc[injection_df['Injection Type'] == i]
		# groups = np.unique(this_df['Epoch Number'])
		for g in this_df.index:
			# this_group = this_df.loc[this_df['Epoch Number'] == g]
			window = [injection_df['Injection Time (from exp start)'].loc[g],
				injection_df['Injection Time (from exp start)'].loc[g]+post_injection_buffer]
			experimental_epochs['Time (s)'][i].append(window)
			experimental_epochs['Acquisitions'][i].append(
				FLP_exp.AcqNum[(FLP_exp.Time >= window[0]) & (FLP_exp.Time < window[1])])
	return experimental_epochs

def combine_injection_info(experiment_names, injection_info):
	combined_dictionary = deepcopy(injection_info[experiment_names[0]])
	for b in experiment_names[1:]:
		for key, value in combined_dictionary.items():
			if np.isscalar(value):
				combined_dictionary[key] = [value, injection_info[b][key]]
			elif np.isscalar(injection_info[b][key]):
				combined_dictionary[key] =  value.append(injection_info[b][key])
			else:
				combined_dictionary[key] = np.concatenate([value, injection_info[b][key]])
	return combined_dictionary

def make_injection_df(injection_info, ts_format, FLP_exp, experiment_names):
	injection_datetimes = pull_injection_datetimes(injection_info, ts_format, experiment_names)
	sorted_injection_times = sort_injection_datetimes(injection_datetimes)
	injection_df = pd.DataFrame(columns = ['Injection Type', 'Injection Datetime'], data = sorted_injection_times)
	injection_df['Acquisition'], injection_df['Injection Time (from acq start)'], injection_df['Injection Time (from exp start)'] = find_injection_times(
	    sorted_injection_times, FLP_exp)
	return injection_df

def get_experimental_periods(epoch_IDs):
	# Find group boundaries
	changes = np.diff(epoch_IDs) != 0
	indices = np.where(changes)[0] + 1

	# Add start and end boundaries
	start_indices = np.concatenate(([0], indices))
	end_indices = np.concatenate((indices, [len(epoch_IDs)]))

	# Extract groups
	group_idxs = [(epoch_IDs[start], start, end) for start, end in zip(start_indices, end_indices)]
	
	return group_idxs
def choose_periods(group_idxs, period_idx, period_string):
	epoch_types = [g[0] for g in group_idxs]
	if epoch_types.count(period_idx) > 1:
		pos, = np.where(np.asarray(epoch_types) == period_idx)
		keep = input('There are ' + str(epoch_types.count(period_idx)) + 
			' ' + period_string + ' periods. Which do you want to include? (all, none, or any of these positions: ' + str(pos) + ')').split()
		if keep[0] == 'all':
			return []
		elif keep[0] == 'none':
			return pos
		else:
			remove_list = [p for p in pos if str(p) not in keep]
			# remove_list.remove([int(s) for s in keep])
	else:
		remove_list = []
	return remove_list

def sort_transition_activity(FLP_exp, lifetime_dict, injection_info, 
	ts_format, exp_type, long_short_wake = False, long_short_NREM = False, NREM_cutoff = 70, wake_cutoff = 70,
	diff_wake = False):
	transition_dict = FLP_exp.transition_timestamps(diff_wake = diff_wake)
	group_idxs = PKA.get_experimental_periods(FLP_exp.EpochID)
	print(lifetime_dict['Experiment Name'])
	noinjection_remove = choose_periods(group_idxs, 0, 'no injection')
	saline_remove = choose_periods(group_idxs, 1, 'saline')
	drug_remove = choose_periods(group_idxs, 2, 'drug')

	remove_all = np.concatenate([saline_remove, drug_remove, noinjection_remove])
	group_idxs = [group_idxs[i] for i in range(len(group_idxs)) if i not in remove_all]

	these_keys = [d for d in lifetime_dict['Time'].keys() if ('Long' not in d) & ('Short' not in d)]

	no_injection_vals = {'Experiment Name': lifetime_dict['Experiment Name'],
						'Mouse ID': lifetime_dict['Mouse ID'],
						'Lifetime': {g: {key: [] for key in these_keys} for g in lifetime_dict['Lifetime'].keys()},
						'Time': deepcopy(lifetime_dict['Time']),
						'Time From Injection': {key: [] for key in these_keys}, 
						'Previous Bout Length': {'NREM-Wake': [], 'Wake-NREM': []}}
	saline_vals = {'Experiment Name': lifetime_dict['Experiment Name'],
						'Mouse ID': lifetime_dict['Mouse ID'],
						'Lifetime': {g: {key: [] for key in these_keys} for g in lifetime_dict['Lifetime'].keys()},
						'Time': deepcopy(lifetime_dict['Time']),
						'Time From Injection': {key: [] for key in these_keys},
						'Previous Bout Length': {'NREM-Wake': [], 'Wake-NREM': []}}
	drug_vals = {'Experiment Name': lifetime_dict['Experiment Name'],
						'Mouse ID': lifetime_dict['Mouse ID'],
						'Lifetime': {g: {key: [] for key in these_keys} for g in lifetime_dict['Lifetime'].keys()},
						'Time': deepcopy(lifetime_dict['Time']),
						'Time From Injection': {key: [] for key in these_keys},
						'Previous Bout Length': {'NREM-Wake': [], 'Wake-NREM': []}}
	if exp_type == 'injection':
		injection_df = make_injection_df(injection_info, ts_format, FLP_exp, lifetime_dict['Experiment Name'])
	datadict_list = [no_injection_vals, saline_vals, drug_vals]

	for g in group_idxs:
		data_dict = datadict_list[int(g[0])]
		for k in these_keys:
			idx, = np.where((transition_dict['Timestamps'][k] >= FLP_exp.Time[g[1]]) & 
						(transition_dict['Timestamps'][k] < FLP_exp.Time[g[2]-1]))
			for i in idx:
				data_dict['Lifetime'][FLP_exp.Sensor][k].append(
									lifetime_dict['Lifetime'][FLP_exp.Sensor][k][0][i])
				if 'Shuffled' in lifetime_dict['Lifetime'].keys():
					data_dict['Lifetime']['Shuffled'][k].append(
										lifetime_dict['Lifetime']['Shuffled'][k][0][i])
				if (k == 'NREM-Wake') or (k == 'Wake-NREM'):
					try:
						data_dict['Previous Bout Length'][k].append(lifetime_dict['Previous Bout Length'][k][0][i])
					except IndexError:
						pass
			if int(g[0]) != 0:
				if g[2] >= len(FLP_exp.Time):					
					these_inj_times = list(injection_df['Injection Time (from exp start)'].loc[(injection_df['Injection Time (from exp start)'] >= FLP_exp.Time[g[1]-2]) & 
						(injection_df['Injection Time (from exp start)'] < FLP_exp.Time[-1])])
				else:
					these_inj_times = list(injection_df['Injection Time (from exp start)'].loc[(injection_df['Injection Time (from exp start)'] >= FLP_exp.Time[g[1]-2]) & 
						(injection_df['Injection Time (from exp start)'] < FLP_exp.Time[g[2]])])

				these_inj_times.append(FLP_exp.Time[g[2]-1])
				split_by_injection = [np.where((transition_dict['Timestamps'][k][idx] >= these_inj_times[ii]) & (transition_dict['Timestamps'][k][idx] < these_inj_times[ii+1]))[0]
				 for ii in range(len(these_inj_times)-1)]
				time_from_injection = [transition_dict['Timestamps'][k][idx][split_by_injection[i]]-these_inj_times[i] 
				for i in range(len(split_by_injection)) if len(split_by_injection[i]) > 0]
				if len(idx) > 0:
					assert len(np.concatenate(time_from_injection)) == len(idx)
					data_dict['Time From Injection'][k].append(np.concatenate(time_from_injection))
				else:
					data_dict['Time From Injection'][k].append(time_from_injection)
	for d in datadict_list:
		for k in these_keys:
			try:
				d['Time From Injection'][k] = np.concatenate(d['Time From Injection'][k])
			except ValueError:
				pass
		if long_short_NREM:
			long_NREM_idx, = np.where(np.asarray(d['Previous Bout Length']['NREM-Wake']) >= NREM_cutoff)
			short_NREM_idx, = np.where(np.asarray(d['Previous Bout Length']['NREM-Wake']) < NREM_cutoff)
			# Verify that all transitions are assigned to one of the two groups.
			assert len(long_NREM_idx)+len(short_NREM_idx) == len(d['Previous Bout Length']['NREM-Wake']) 

			d['Lifetime'][FLP_exp.Sensor]['NREM-Wake Long'] = np.asarray(d['Lifetime'][FLP_exp.Sensor]['NREM-Wake'])[long_NREM_idx]
			d['Lifetime'][FLP_exp.Sensor]['NREM-Wake Short'] = np.asarray(d['Lifetime'][FLP_exp.Sensor]['NREM-Wake'])[short_NREM_idx]
			if len(d['Time From Injection']['NREM-Wake']) > 0:
				d['Time From Injection']['NREM-Wake Long'] = np.asarray(d['Time From Injection']['NREM-Wake'])[long_NREM_idx]
				d['Time From Injection']['NREM-Wake Short'] = np.asarray(d['Time From Injection']['NREM-Wake'])[short_NREM_idx]

		if long_short_wake:
			long_wake_idx, = np.where(np.asarray(d['Previous Bout Length']['Wake-NREM']) >= wake_cutoff)
			short_wake_idx, = np.where(np.asarray(d['Previous Bout Length']['Wake-NREM']) < wake_cutoff)
			# Verify that all transitions are assigned to one of the two groups.
			assert len(long_wake_idx)+len(short_wake_idx) == len(d['Previous Bout Length']['Wake-NREM']) 

			d['Lifetime'][FLP_exp.Sensor]['Wake-NREM Long'] = np.asarray(d['Lifetime'][FLP_exp.Sensor]['Wake-NREM'])[long_wake_idx]
			d['Lifetime'][FLP_exp.Sensor]['Wake-NREM Short'] = np.asarray(d['Lifetime'][FLP_exp.Sensor]['Wake-NREM'])[short_wake_idx]
			if len(d['Time From Injection']['NREM-Wake']) > 0:
				d['Time From Injection']['Wake-NREM Long'] = np.asarray(d['Time From Injection']['Wake-NREM'])[long_wake_idx]
				d['Time From Injection']['Wake-NREM Short'] = np.asarray(d['Time From Injection']['Wake-NREM'])[short_wake_idx]

	return no_injection_vals, saline_vals, drug_vals

def add_drug_timing(parameter_df, FLP_exp):
	group_idxs = PKA.get_experimental_periods(FLP_exp.EpochID)
	epoch_labels = ['No Injections', 'Saline', 'Drug']

	for g, start, end in group_idxs:
		parameter_df.loc[(parameter_df['Start Time'] >= FLP_exp.Time[start]) & 
		(parameter_df['Start Time'] < FLP_exp.Time[end-1]), 
			'Experimental Phase'] = epoch_labels[int(g)]

	return parameter_df

def sleep_structure_per_period(full_exp, start_time, end_time, exclude_microarousals = True):
	ss = full_exp.SleepStates[(full_exp.SSTime >= start_time) & (full_exp.SSTime < end_time)]
	ss_dict = PKA.get_sleep_structure(ss, full_exp.EpochLength, exclude_microarousals = exclude_microarousals)

	return ss_dict

def plot_BasicAcqs(FLP_classes_dict, parent_data_directory, injection_info, ts_format,
	epoch_colors = {'No Injections': '#a5a391', 'Saline': '#8f99fb', 'Drug': '#f8481c'}, 
	save_plots = True, post_injection_buffer = 7200):
	
	for b, FLP_exp in zip(FLP_classes_dict['Experiment Names'], FLP_classes_dict['Experiment Classes']):
	    injection_df = PKA.make_injection_df(injection_info, ts_format, FLP_exp, [b])
	    experimental_epochs = get_experimental_epochs(injection_df, FLP_exp, 
	    	post_injection_buffer = post_injection_buffer)
	    
	    for a in np.unique(FLP_exp.AcqNum):
	        rect = None
	        fig, (bar_ax,ax) = plt.subplots(nrows = 2, figsize = [12, 3], height_ratios = [1,6])
	        EEG_fn = os.path.join(parent_data_directory, b, b+'_extracted_data', 'AD0_downsampled','downsampEEG_Acq'+str(a)+'_hr0.npy')
	        acq_idx, = np.where(FLP_exp.AcqNum == a)
	        t = FLP_exp.Time[acq_idx]-FLP_exp.Time[acq_idx][0]
	        LFT = FLP_exp.Lifetime[acq_idx]
	        ax_LFT = PKA.plot_lifetime_EEG_fig(ax, EEG_fn, FLP_exp, LFT, t, fsd = 200, minfreq = 1, 
	                                  maxfreq = 16, window_length = 10, vmin = None, vmax = None)
	        ax.set_xlim([t[0], t[-1]])
	        for k in experimental_epochs['Acquisitions'].keys():
	            for ii in range(len(experimental_epochs['Acquisitions'][k])):
	                if a in experimental_epochs['Acquisitions'][k][ii]:
	                    epoch_acqs = experimental_epochs['Acquisitions'][k][ii]
	                    if a == epoch_acqs[0]:
	                        inj_point = injection_df['Injection Time (from acq start)'].loc[injection_df['Acquisition'] == a].iloc[0]
	                        rect = patch.Rectangle((t[0],0), inj_point-t[0], 1, color = epoch_colors['No Injections'], alpha = 0.3, edgecolor = None)
	                        bar_ax.add_patch(rect)
	                        rect = patch.Rectangle((inj_point,0), t[-1]-inj_point, 1, color = epoch_colors[k], alpha = 0.3, edgecolor = None)
	                        bar_ax.add_patch(rect)
	                    elif a == epoch_acqs[-1]:
	                        end_point = len(np.where(experimental_epochs['Acquisitions'][k][ii] == 30)[0])
	                        if end_point == len(t):
	                            end_point = -1
	                        rect = patch.Rectangle((t[0],0), t[end_point]-t[0], 1, color = epoch_colors[k], alpha = 0.3, edgecolor = None)
	                        bar_ax.add_patch(rect)
	                        rect = patch.Rectangle((t[end_point],0), t[-1]-t[end_point], 1, color = epoch_colors['No Injections'], alpha = 0.3, edgecolor = None)
	                        bar_ax.add_patch(rect)                    
	                    else:
	                        rect = patch.Rectangle((t[0],0), t[-1]-t[0], 1, color = epoch_colors[k], alpha = 0.3, edgecolor = None)
	                        bar_ax.add_patch(rect) 
	                if a in list(injection_df['Acquisition'].loc[injection_df['Injection Type'] == k]):
	                    bar_ax.axvline(injection_df['Injection Time (from acq start)'].loc[injection_df['Acquisition'] == a].iloc[0], 
	                                   linestyle = '--', 
	                                   color = epoch_colors[injection_df['Injection Type'].loc[injection_df['Acquisition'] == a].iloc[0]])
	        if not rect:
	            rect = patch.Rectangle((t[0],0), t[-1]-t[0], 1, color = epoch_colors['No Injections'], alpha = 0.3, edgecolor = None)
	            bar_ax.add_patch(rect)
	        ax_LFT.set_ylim([-1.5, -1.35])
	        bar_ax.set_xlim([t[0], t[-1]])        
	        bar_ax.set_axis_off()
	        graph.label_axes(bar_ax, title = b + ' Acquisition ' + str(a) + '\n' + 
	                         'Inhibitor = ' + injection_info[b]['Drug'] + ' (' + injection_info[b]['Dose'] + ')')
	        fig.tight_layout()
	        if save_plots:
		        savedir = os.path.join(parent_data_directory, b, 'EEG_LFT_InjTimes')
		        os.makedirs(savedir, exist_ok = True)
		        fig.savefig(os.path.join(savedir, b+'acq'+str(a)+injection_info[b]['Drug']+'.png'))
def get_epoch_dictionaries(FLP_classes, experiment_names, mouseID, injection_info, ts_format, exp_type,
	window = [50, 120], these_transitions = ['NREM-Wake','REM-Wake', 'Microarousals', 'Wake-NREM','NREM-REM'], 
	intensity = False, diff_wake = False, shuffled = True, long_short_wake = True,
	long_short_NREM = False, NREM_cutoff = 50, wake_cutoff = 100, raw_lifetime = False, zscore = False, remove_short = True):

	lifetime_dicts = [PKA.transition_triggered_lifetime(FLP_exp, [b], m, window = window, 
			these_transitions = these_transitions, intensity = intensity, diff_wake = diff_wake, 
			shuffled = shuffled, long_short_wake = long_short_wake, remove_short = remove_short,
			long_short_NREM = long_short_NREM, NREM_cutoff = NREM_cutoff, wake_cutoff = wake_cutoff, 
			raw_lifetime = raw_lifetime, just_dictionary = True, zscore = zscore) 
			for FLP_exp, b, m in zip(FLP_classes, experiment_names, mouseID)]

	sep_lifetime_dicts = [sort_transition_activity(FLP_classes[i], lifetime_dicts[i], injection_info, 
							ts_format, exp_type, long_short_wake = long_short_wake, long_short_NREM = long_short_NREM, 
							NREM_cutoff = NREM_cutoff, wake_cutoff = wake_cutoff, diff_wake = False)
							 for i in range(len(FLP_classes)) if any([lifetime_dicts[i]['Experiment Name'][0][ii] in injection_info.keys() 
							 	for ii in range(len(lifetime_dicts[i]['Experiment Name'][0]))])]
	sep_lifetime_dicts = list(zip(*sep_lifetime_dicts))

	saline_vals = {key:{} for key in sep_lifetime_dicts[0][0].keys()}
	drug_vals = {key:{} for key in sep_lifetime_dicts[0][0].keys()}
	no_injection_vals = {key:{} for key in sep_lifetime_dicts[0][0].keys()}

	dict_list = [no_injection_vals, saline_vals, drug_vals]
	for d, d_new in zip(sep_lifetime_dicts, dict_list):
		checked_dicts = [di for di in d if not all(list(value) == [] for value in di['Lifetime'][FLP_classes[0].Sensor].values())]
		if len(checked_dicts) == 0:
			continue
		for k1 in d_new.keys():
			if (k1 == 'Experiment Name') or (k1 == 'Mouse ID'):
				d_new[k1] = [checked_dicts[i][k1][0] for i in range(len(checked_dicts))]
			elif k1 == 'Lifetime':
				for k2 in checked_dicts[0][k1].keys():
					d_new[k1][k2] = {key: [checked_dicts[i][k1][k2][key] for i in range(len(checked_dicts))] 
					for key in checked_dicts[0][k1][k2].keys()}
					# d_new[k1][k2] = {key: [d_new[k1][k2][key][i] for i in range(len(checked_dicts)) if len(d_new[k1][k2][key][i]) > 0]
					# for key in d_new[k1][k2].keys()}
			elif k1 == 'Time':
				d_new[k1] = {key: checked_dicts[0][k1][key] for key in checked_dicts[0][k1].keys()}
			else:
				d_new[k1] = {key: [checked_dicts[i][k1][key] for i in range(len(checked_dicts))] 
				for key in checked_dicts[0][k1].keys()}


	return no_injection_vals, saline_vals, drug_vals

def transition_triggered_average_drug(plotting_vals, phos_measure, savedir = False, 
	these_transitions = ['NREM-Wake','REM-Wake', 'Microarousals', 'Wake-NREM','NREM-REM'], 
	axes_width = 1.25, long_short_NREM = False, long_short_wake = False, raw_lifetime = False, zscore = False, error_function = stats.sem,
	epoch_colors = {'No Injections': '#a5a391', 'Saline': '#8f99fb', 'Drug': '#f8481c'}, average_function = np.nanmean, 
	epoch_type_dict = {0: 'No Injections', 1: 'Saline', 2: 'Drug'}, fig = False, ax = False):
	
	if phos_measure == 'Lifetime (ns)':
		y_negative = True
	elif phos_measure == 'Binding Fraction':
		y_negative = False
	try:
		experimental_sensor = list(plotting_vals[0]['Lifetime'].keys())[0]
	except IndexError:
		try:
			experimental_sensor = list(plotting_vals[1]['Lifetime'].keys())[0]
		except IndexError:
			experimental_sensor = list(plotting_vals[2]['Lifetime'].keys())[0]
	if long_short_NREM:
		for d in plotting_vals:
			options_list = [s for s in d['Lifetime'][experimental_sensor].keys()
			if 'NREM-Wake' in s]
			if len(options_list) > 0:
				continue
		print(options_list)
		NREM_Wake_plot_option = input('Which of the above conditions do you want to plot?')
	else:
		NREM_Wake_plot_option = 'NREM-Wake'
	# If enabled, create and store figure and axes objects for split wake plot
	if long_short_wake:
		for d in plotting_vals:
			options_list = [s for s in d['Lifetime'][experimental_sensor].keys()
			if 'Wake-NREM' in s]
			if len(options_list) > 0:
				continue
		print(options_list)
		Wake_NREM_plot_option = input('Which of the above conditions do you want to plot?')
	else:
		Wake_NREM_plot_option = 'Wake-NREM'

	if raw_lifetime:
		y_label = phos_measure
	elif zscore:
		y_label = 'Z-Score '+ phos_measure
	else:
		y_label = r'$\Delta$'+ phos_measure
	if not fig: 
		fig, ax = plt.subplots(nrows = 1, ncols = len(these_transitions), 
			figsize = [4*len(these_transitions), 4])

	for i, d in enumerate(plotting_vals):
		transition_colors = {}
		for k in d['Lifetime'][experimental_sensor].keys():
			transition_colors[k] = epoch_colors[epoch_type_dict[i]]
		new_transitions = deepcopy(these_transitions)
		new_transitions[new_transitions.index('Wake-NREM')] = Wake_NREM_plot_option
		new_transitions[new_transitions.index('NREM-Wake')] = NREM_Wake_plot_option
		if len(d['Experiment Name']) > 1:
			all_dicts, y_data = PKA.split_by_animal(d, average_function = np.nanmean)
		else:
			y_data = d['Lifetime']
		fig, ax = PKA.plot_triggered_average(y_data[experimental_sensor], d['Time'], new_transitions, 
			fig, ax, transition_colors, y_label, average_function = average_function, error_function = error_function,
			y_negative = y_negative, legend_label = epoch_type_dict[i])
	graph.thick_axes(fig, ax, width = axes_width)
	fig.tight_layout()

	if savedir:
		fig.savefig(savedir)
	return fig, ax

def transitions_by_injection_timing(lifetime_vals, condition_label, y_type,
	savedir = False, filename_start = False, fig_ext = '.png',
	these_transitions = ['NREM-Wake','REM-Wake', 'Microarousals', 'Wake-NREM','NREM-REM'], 
	raw_lifetime = False, axes_width = 1.25, color_map = 'jet'):

	experimental_sensor = list(lifetime_vals['Lifetime'].keys())[0]

	if 'NREM-Wake Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'NREM-Wake' in s])
		NREM_Wake_plot_option = input('Which of the above conditions do you want to plot?')
	if 	'Wake-NREM Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'Wake-NREM' in s])
		Wake_NREM_plot_option = input('Which of the above conditions do you want to plot?')

	new_transitions = deepcopy(these_transitions)
	new_transitions[new_transitions.index('Wake-NREM')] = Wake_NREM_plot_option
	new_transitions[new_transitions.index('NREM-Wake')] = NREM_Wake_plot_option

	y_label = y_type
	if not raw_lifetime:
		y_label = r'$\Delta$'+y_label

	fig, ax = plt.subplots(nrows = 1, ncols = len(new_transitions), 
		figsize = [4*len(new_transitions), 4])
	c_map = colormaps[color_map]
	for ii, s in enumerate(new_transitions):
		x_vals = lifetime_vals['Time'][s]
		y_vals = np.concatenate(lifetime_vals['Lifetime'][experimental_sensor][s], axis = 0)
		hue_vals = np.concatenate(lifetime_vals['Time From Injection'][s], axis = 0)
		colors = c_map(hue_vals/max(hue_vals))
		zorder = np.arange(0, len(y_vals))
		zorder = np.flip(zorder)
		for y,c,z in zip(y_vals, colors,zorder):
			if y_type == 'Binding Fraction':
				ax[ii].plot(x_vals, y, color = c, linewidth = 1, alpha = 0.3, zorder = z)
			else:
				y_label = '-'+y_label
				ax[ii].plot(x_vals, -y, color = c, linewidth = 1, alpha = 0.3, zorder = z)
		graph.label_axes(ax[ii], y = y_label, x = 'Time From\nTransition', 
			title = s, fontweight = 'normal')
		ax[ii].axvline(0, color = 'k', linestyle = '--', zorder = max(zorder)+1)
		ax[ii].set_xlim([x_vals[0], x_vals[-1]])
	graph.thick_axes(fig, ax, width = axes_width)
	graph.match_yaxes(ax)
	sm = plt.cm.ScalarMappable(cmap=color_map)
	sm.set_array([])
	plt.colorbar(sm, ax=ax[-1])
	fig.suptitle(condition_label, fontsize = 25)
	fig.tight_layout()
	if savedir:
		fig.savefig(os.path.join(savedir, filename_start + condition_label+'traces_over_time'+fig_ext))
	return fig, ax

def plot_early_late(lifetime_vals, condition_label, early_period = [0, 3600], late_period = [3600, 7200],
	savedir = False, filename_start = False, fig_ext = '.png',
	these_transitions = ['NREM-Wake','REM-Wake', 'Microarousals', 'Wake-NREM','NREM-REM'], 
	raw_lifetime = False, axes_width = 1.25):

	if raw_lifetime:
		y_label = '-Lifetime (ns)'
	else:
		y_label = '-'+r'$\Delta$'+ ' Lifetime (ns)'

	fig, ax = plt.subplots(nrows = 1, ncols = len(these_transitions), figsize = [4*len(these_transitions), 4])
	experimental_sensor = list(lifetime_vals['Lifetime'].keys())[0]

	if 'NREM-Wake Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'NREM-Wake' in s])
		NREM_Wake_plot_option = input('Which of the above conditions do you want to plot?')
	if 	'Wake-NREM Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'Wake-NREM' in s])
		Wake_NREM_plot_option = input('Which of the above conditions do you want to plot?')

	new_transitions = deepcopy(these_transitions)
	new_transitions[new_transitions.index('Wake-NREM')] = Wake_NREM_plot_option
	new_transitions[new_transitions.index('NREM-Wake')] = NREM_Wake_plot_option

	if raw_lifetime:
		y_label = '-Lifetime (ns)'
	else:
		y_label = '-'+r'$\Delta$'+ ' Lifetime (ns)'

	for ii, s in enumerate(new_transitions):
		y_data = np.concatenate(lifetime_vals['Lifetime'][experimental_sensor][s], axis = 0)
		x = lifetime_vals['Time'][s]
		time_from_injection = np.concatenate(lifetime_vals['Time From Injection'][s], axis = 0)
		early_idx, = np.where((time_from_injection >= early_period[0]) & (time_from_injection < early_period[1]))
		late_idx, = np.where((time_from_injection >= late_period[0]) & (time_from_injection < late_period[1]))

		y_early = np.nanmean(y_data[early_idx], axis = 0)
		y_late = np.nanmean(y_data[late_idx], axis = 0)

		err_early = stats.sem(y_data[early_idx], axis = 0, nan_policy='omit')
		err_late = stats.sem(y_data[late_idx], axis = 0, nan_policy='omit')

		# Plot data with error bars.
		ax[ii] = graph.linegraph_w_error(ax[ii], x, -y_early, err_early, color = plt.cm.PiYG(0.15), label = s, linewidth = 1,
		    alpha = 0.3)
		ax[ii] = graph.linegraph_w_error(ax[ii], x, -y_late, err_late, color = plt.cm.PiYG(.85), label = s, linewidth = 1,
		    alpha = 0.3)

		graph.label_axes(ax[ii], y = '-'+r'$\Delta$'+ ' Lifetime (ns)', x = 'Time From\nTransition', 
			title = s, fontweight = 'normal')
		ax[ii].axvline(0, color = 'k', linestyle = '--')
		graph.thick_axes(fig, ax, width = 0.75)
		fig.tight_layout()     
	graph.thick_axes(fig, ax, width = 0.75)
	graph.match_yaxes(ax)
	fig.suptitle(condition_label, fontsize = 30, fontweight = 'bold')
	fig.tight_layout()
	if savedir:
		fig.savefig(os.path.join(fig_savedir, filename_start + condition_label+ 'early_late.png'))
	return fig, ax

def plot_partial_phase(lifetime_vals, time_period = [0, 3600], fig = None, ax = None,
	savedir = False, filename_start = False, fig_ext = '.png', color = '#ff9408',
	these_transitions = ['NREM-Wake','REM-Wake', 'Microarousals', 'Wake-NREM','NREM-REM'], 
	raw_lifetime = False, axes_width = 0.75):

	experimental_sensor = list(lifetime_vals['Lifetime'].keys())[0]

	if 'NREM-Wake Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'NREM-Wake' in s])
		NREM_Wake_plot_option = input('Which of the above conditions do you want to plot?')
	if 	'Wake-NREM Short' in lifetime_vals['Lifetime'][experimental_sensor].keys():
		print([s for s in lifetime_vals['Lifetime'][experimental_sensor].keys()
			if 'Wake-NREM' in s])
		Wake_NREM_plot_option = input('Which of the above conditions do you want to plot?')

	new_transitions = deepcopy(these_transitions)
	new_transitions[new_transitions.index('Wake-NREM')] = Wake_NREM_plot_option
	new_transitions[new_transitions.index('NREM-Wake')] = NREM_Wake_plot_option
	if raw_lifetime:
		y_label = '-Lifetime (ns)'
	else:
		y_label = '-'+r'$\Delta$'+ ' Lifetime (ns)'
	if fig == None:
		fig, ax = plt.subplots(nrows = 1, ncols = len(new_transitions), figsize = [4*len(new_transitions), 4])

	transition_colors = {k: color for k in lifetime_vals['Lifetime'][experimental_sensor].keys()}

	for ii, s in enumerate(new_transitions):
		y_data = np.concatenate(lifetime_vals['Lifetime'][experimental_sensor][s], axis = 0)
		x = lifetime_vals['Time'][s]
		time_from_injection = np.concatenate(lifetime_vals['Time From Injection'][s], axis = 0)
		phase_idx, = np.where((time_from_injection >= time_period[0]) & (time_from_injection < time_period[1]))
		y_early = np.nanmean(y_data[phase_idx], axis = 0)
		err_early = stats.sem(y_data[phase_idx], axis = 0, nan_policy='omit')

		# Plot data with error bars.
		ax[ii] = graph.linegraph_w_error(ax[ii], x, y_early, err_early, color = transition_colors[s], 
			label = s, linewidth = 1, alpha = 0.3)
		graph.label_axes(ax[ii], y = '-'+r'$\Delta$'+ ' Lifetime (ns)', x = 'Time From\nTransition', 
			title = s, fontweight = 'normal')
		ax[ii].axvline(0, color = 'k', linestyle = '--')
		ax[ii].set_xlim([x[0], x[-1]])
	graph.thick_axes(fig, ax, width = 0.75)
	graph.thick_axes(fig, ax, width =axes_width)
	graph.match_yaxes(ax)
	fig.tight_layout()
	if savedir:
		fig.savefig(os.path.join(fig_savedir, filename_start + str(time_period)+fig_ext))
	return fig, ax


