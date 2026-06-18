import numpy as np
import glob
import os
import PKA_Sleep as PKA
import pandas as pd
import PKA_Sleep.Graphing_Utils as graph
from matplotlib import cm,patches
import matplotlib.pyplot as plt
import matplotlib.ticker as plticker
from copy import deepcopy
from scipy import stats, signal
from neuroscience_sleep_scoring import SWS_utils
import math
from sklearn.metrics import auc

def plot_transient_detection_fig(FLP_classes, experiment_names, savedir = False, fig_ext = '.png', 
	overlay_window = 50, num_std = False, discrete_cutoff = 0.01, FWHM_thresh = False, dont_display = False):
	fig_dict = {}
	graph.make_bigandbold(xticksize = 16, yticksize = 16, axeslabelsize = 20)
	for exp,b in zip(FLP_classes, experiment_names):
		filter_type, filt_bound_str = get_filter_type(exp.FilterBounds)
		if FWHM_thresh:
			transient_detection_fig, transient_detection_ax = plt.subplots(nrows = 4, ncols = 1, figsize = (12,7))
		else:
			transient_detection_fig, transient_detection_ax = plt.subplots(nrows = 3, ncols = 1, figsize = (12,7))
		transient_detection_fig, transient_detection_ax = graph.thick_axes(transient_detection_fig, transient_detection_ax)
		transient_overlay_fig, transient_overlay_ax = plt.subplots(nrows = 1, ncols = 1, figsize = (5,5))
		transient_overlay_fig, transient_overlay_ax = graph.thick_axes(transient_overlay_fig, transient_overlay_ax)
		
		fig_dict[b] = [(transient_detection_fig, transient_detection_ax), (transient_overlay_fig, transient_overlay_ax)]

		transient_detection_ax[0].plot(exp.Time, -exp.Lifetime, linewidth = 0.5, color = 'k')
		transient_detection_ax[1].plot(exp.Time, -exp.Filt, linewidth = 0.5, color = 'k')
		transient_detection_ax[2].plot(exp.Time, -exp.Filt, linewidth = 0.5, color = 'k')
		if FWHM_thresh:
			transient_detection_ax[3].plot(exp.Time, -exp.Filt, linewidth = 0.5, color = 'k')
		transient_dict = exp.find_transients(num_std = num_std, discrete_cutoff = discrete_cutoff, FWHM_thresh = False)
		cmap = cm.get_cmap('plasma',len(transient_dict[exp.Sensor]['Transient Idx']))
		win = overlay_window
		for i,t in enumerate(transient_dict[exp.Sensor]['Transient Idx']):
			if any(np.asarray(t) < 0):
				delete = np.asarray(t)[np.where(np.asarray(t) < 0)[0]]
				t.remove(delete)
			c = cmap.colors[i]
			x = exp.Time[t]
			win_start = x[0]-win
			win_end = x[-1]+win
			if win_end > exp.Time[-1]:
			    win_end = exp.Time[-1]
			if win_start < exp.Time[0]:
			    win_start = exp.Time[0]
			window_idx, = np.where(np.logical_and(exp.Time>win_start, exp.Time<=win_end))
			x = exp.Time[window_idx]-exp.Time[window_idx[0]]
			y = exp.Lifetime[window_idx]-exp.Lifetime[t[0]]
			if not FWHM_thresh:
				transient_overlay_ax.plot(x, -y, color = c, linewidth = 1) 
				transient_overlay_ax.axvline(win, linestyle = '--', color = 'k')
			transient_detection_ax[2].plot(exp.Time[t], -exp.Filt[t], linewidth = 0.5, color = 'r')
		if FWHM_thresh:
			transient_dict = exp.find_transients(num_std = num_std, discrete_cutoff = discrete_cutoff, FWHM_thresh = FWHM_thresh)
			for i,t in enumerate(transient_dict[exp.Sensor]['Transient Idx']):
				if any(np.asarray(t) < 0):
					delete = np.asarray(t)[np.where(np.asarray(t) < 0)[0]]
					t.remove(delete)
				c = cmap.colors[i]
				x = exp.Time[t]
				win_start = x[0]-win
				win_end = x[-1]+win
				if win_end > exp.Time[-1]:
					win_end = exp.Time[-1]
				if win_start < exp.Time[0]:
					win_start = exp.Time[0]
				window_idx, = np.where(np.logical_and(exp.Time>win_start, exp.Time<=win_end))
				x = exp.Time[window_idx]-exp.Time[window_idx[0]]
				y = exp.Lifetime[window_idx]-exp.Lifetime[t[0]]
				transient_overlay_ax.plot(x, -y, color = c, linewidth = 1) 
				transient_overlay_ax.axvline(win, linestyle = '--', color = 'k')
				transient_detection_ax[3].plot(exp.Time[t], -exp.Filt[t], linewidth = 0.5, color = 'r')
		transient_overlay_fig, transient_overlay_ax = graph.thick_axes(transient_overlay_fig, transient_overlay_ax)

		graph.label_axes(transient_detection_ax[0], title = 'Experiment: ' + b, title_fontsize = 25)
		graph.label_axes(transient_detection_ax[1], y = '-'+r'$\Delta$'+ ' Lifetime (ns)', 
			title = 'Filtered ('+filter_type+filt_bound_str+')', title_fontsize = 20)
		if num_std:
			graph.label_axes(transient_detection_ax[2], x = 'Time (s)', 
				title = 'Amplitude Threshold ('+str(num_std) + ' StDev)', title_fontsize = 20)
		else:
			graph.label_axes(transient_detection_ax[2], x = 'Time (s)', 
				title = 'Amplitude Threshold ('+str(discrete_cutoff) + ' ns)', title_fontsize = 20)
		if FWHM_thresh:
			graph.label_axes(transient_detection_ax[3],x = 'Time (s)', y = '-'+r'$\Delta$'+ ' Lifetime (ns)', 
				title = 'FWHM Threshold ('+str(FWHM_thresh) + ' ns)', title_fontsize = 20)
		for a in transient_detection_ax:
			a.set_xlim([0, exp.Time[-1]])
		yticks = np.linspace(round(transient_detection_ax[1].get_ylim()[0], 3), round(transient_detection_ax[1].get_ylim()[1], 3), 4)
		yticks = [round(y, 3) for y in yticks]
		for a in transient_detection_ax[1:]:
			a.set_yticks(yticks)

		transient_overlay_ax.set_xticks(np.arange(0, 250, 75))
		transient_overlay_ax.set_xlim([0, 250])
		transient_overlay_ax.set_xticklabels(np.arange(0, 250, 75)-win)
		graph.label_axes(transient_overlay_ax, x = 'Time from Transient (s)', y = '-'+r'$\Delta$'+ ' Lifetime (ns)', title = 'Experiment: ' + b, 
			title_fontsize = 16)  
		transient_overlay_fig.tight_layout()
		transient_detection_fig.tight_layout()
		if savedir:
			try:
				os.mkdir(os.path.join(savedir,b,'Transient_detection_figs'))
			except FileExistsError:
				pass
			if 'binned' in exp.filename:
				savefilename_detection = os.path.join(savedir,b,'Transient_detection_figs','transient_detection_binned'+fig_ext)
				savefilename_overlay = os.path.join(savedir,b,'Transient_detection_figs','transient_overlay_binned'+fig_ext)
			else:
				savefilename_detection = os.path.join(savedir,b,'Transient_detection_figs','transient_detection'+fig_ext)
				savefilename_overlay = os.path.join(savedir,b,'Transient_detection_figs','transient_overlay'+fig_ext)
			transient_detection_fig.savefig(savefilename_detection)
			transient_overlay_fig.savefig(savefilename_overlay)
		if dont_display:
			plt.close('all')

	return fig_dict
def transient_triggered_state_plot(FLP_classes, experiment_names, savedir = False, num_std = False, discrete_cutoff = 0.01,
	FWHM_thresh = False, fig_ext = '.png', shuffled = True, plot_type = 'both', grouped_name = None, window = 120):
	fig_dict = {}
	data_dict = {}
	color_dict = graph.SW_colordict('numbers')
	graph.make_bigandbold(xticksize = 16, yticksize = 16, axeslabelsize = 20)
	if plot_type == 'individual' or plot_type == 'both':
		fig_dict['Individual'] = []
	for exp,b in zip(FLP_classes, experiment_names):
		if data_dict == {}:
			data_dict[exp.Sensor] = {'SS Data': []}
			if shuffled:
				data_dict['Shuffled'] = {'SS Data': []}

		transient_dict = exp.find_transients(num_std = num_std, discrete_cutoff = discrete_cutoff, 
			FWHM_thresh = FWHM_thresh, shuffled = shuffled)
		if plot_type == 'individual' or plot_type == 'both':
			stateplot_ind_fig, stateplot_ind_ax = plt.subplots(ncols = len(list(data_dict.keys())), figsize = [len(list(data_dict.keys()))*5,6])
			if len(list(data_dict.keys())) == 1:
				stateplot_ind_ax = [stateplot_ind_ax]
		for di,d in enumerate(list(transient_dict.keys())):
			transient_starts = [t[0] for t in transient_dict[d]['Transient Idx']]
			ss_bins = PKA.transient_associated_ss(transient_starts, window, exp)
			data_dict[d]['SS Data'].append(ss_bins)

			if (plot_type == 'individual' or plot_type == 'both'):
				x_stateplot = np.arange(0, np.shape(ss_bins)[1])
				x_stateplot = (x_stateplot-np.shape(ss_bins)[1]/2)*exp.EpochLength
				all_distance = np.zeros(np.shape(ss_bins)[0]-1)
				for aa in np.arange(0, np.size(all_distance)):
					counter = 0
					idx = -1
					before_idx, = np.where(x_stateplot<=0)
					zero_idx, = np.where(x_stateplot==0)
					wake_idx, = np.where(np.logical_or(ss_bins[aa,before_idx] == 1, ss_bins[aa,before_idx] == 4))
					distance = zero_idx-wake_idx
					try:
						while distance[idx] == counter:
							counter = counter+1
							idx = idx - 1
					except IndexError:
						pass
					all_distance[aa] = counter
				sorted_idx = np.argsort(all_distance)

				for i, ii in enumerate(sorted_idx):
					for state in [1,2,3,4,5]:
						cont_state = PKA.find_continuous(ss_bins[ii, :], [state])
						if len(cont_state)>0:
							for s in cont_state:
								x_pos = x_stateplot[s][0]
								w = ((x_stateplot[s[-1]]-x_stateplot[s][0]))+exp.EpochLength
								rect1 = patches.Rectangle((x_pos,i), w, 1, facecolor = color_dict[str(int(state))], 
								                          alpha = 1, edgecolor = None, zorder = 0)
								stateplot_ind_ax[di].add_patch(rect1)
				stateplot_ind_ax[di].axvline(0, linestyle = '--', color = 'k')
				stateplot_ind_ax[di].set_xlim([x_stateplot[0], x_stateplot[-3]])
				stateplot_ind_ax[di].set_ylim([0, np.shape(ss_bins)[0]-1])
				stateplot_ind_fig.suptitle(b, fontweight = 'bold', fontsize = 30)
				graph.label_axes(stateplot_ind_ax[di], x = 'Time (s)', y = 'Transition ID', title = d)

			stateplot_ind_fig.tight_layout()
			if savedir:
				try:
					os.mkdir(savedir)
				except FileExistsError:
					pass
				savefilename_stateplot_ind = os.path.join(savedir,b+'_stateplot'+fig_ext)
				stateplot_ind_fig.savefig(savefilename_stateplot_ind)
				fig_dict['Individual'].append((stateplot_ind_fig, stateplot_ind_ax))
	if (plot_type == 'both' or plot_type == 'grouped'):
		state_names = ['Wake', 'NREM', 'REM', 'Wake', 'Microarousal']
		stateplot_group_fig, stateplot_group_ax = plt.subplots(ncols = len(list(data_dict.keys())),figsize = (len(list(data_dict.keys()))*4,8))
		if len(list(data_dict.keys())) == 1:
			stateplot_group_ax  = [stateplot_group_ax]
		for gi, genotype in enumerate(list(data_dict.keys())):
			data = np.concatenate(data_dict[genotype]['SS Data'], axis = 0)
			all_distance = np.zeros(np.shape(data)[0]-1)
			for aa in np.arange(0, np.size(all_distance)):
				counter = 0
				idx = -1
				before_idx, = np.where(x_stateplot<=0)
				zero_idx, = np.where(x_stateplot==0)
				wake_idx, = np.where(np.logical_or(data[aa,before_idx] == 1, data[aa,before_idx] == 4))
				#         wake_idx, = np.where(data[aa,before_idx] == 3)
				distance = zero_idx-wake_idx
				try:
					while distance[idx] == counter:
						counter = counter+1
						idx = idx - 1
				except IndexError:
					pass
				all_distance[aa] = counter
			sorted_idx = np.argsort(all_distance)
			#     num_wake
			for i, ii in enumerate(sorted_idx):
				for state in [1,2,3,4,5]:
					cont_state = PKA.find_continuous(data[ii, :], [state])
					if len(cont_state)>0:
						for s in cont_state:
							x_pos = x_stateplot[s][0]
							w = ((x_stateplot[s[-1]]-x_stateplot[s][0]))+exp.EpochLength
							rect1 = patches.Rectangle((x_pos,i), w, 1, facecolor = color_dict[str(int(state))], 
							                          edgecolor = None, zorder = 0, label = state_names[state-1])
							stateplot_group_ax[gi].add_patch(rect1)
			stateplot_group_ax[gi].axvline(0, linestyle = '--', color = 'k', linewidth = 1)
			stateplot_group_ax[gi].set_xlim([x_stateplot[0], x_stateplot[-1]])
			stateplot_group_ax[gi].set_ylim([0, np.shape(data)[0]-1])
			stateplot_group_ax[gi].set_xlabel('Time from Transient\nOnset (s)')
			stateplot_group_ax[gi].set_xlim([-70, 100])
			if gi == 0:
				stateplot_group_ax[gi].set_ylabel('Transient ID')
			stateplot_group_ax[gi].set_xticks([-40,0,40,80])
			h,l = stateplot_group_ax[gi].get_legend_handles_labels()
			try:
				legend_idx = [l.index(label) for label in ['NREM', 'REM', 'Wake', 'Microarousal']]
			except ValueError:
				legend_idx = [l.index(label) for label in ['NREM', 'Wake']]
			these_labels = list(np.asarray(l)[legend_idx])
			these_handles = list(np.asarray(h)[legend_idx])
			stateplot_group_ax[gi].set_title(genotype, fontsize = 20, fontweight= 'bold')
		stateplot_group_fig.legend(labels = these_labels, handles = these_handles, fontsize = 16, 
			loc="upper center", ncols = 4)
		stateplot_group_fig.subplots_adjust(wspace=0.3)

		if savedir:
			try:
				os.mkdir(savedir)
			except FileExistsError:
				pass
			savefilename_stateplot_group = os.path.join(savedir,grouped_name+fig_ext)
			stateplot_group_fig.savefig(savefilename_stateplot_group)
			fig_dict['Grouped'] = (stateplot_group_fig, stateplot_group_ax)
	return fig_dict, data_dict
def transient_timing(FLP_classes, experiment_names, shuffled = True, 
	these_transitions = ['NREM-Wake', 'REM-Wake', 'NREM-REM', 'Wake-NREM'], savedir = False, 
	grouped_name = False, fig_ext = '.png'):
	graph.make_bigandbold(xticksize = 16, yticksize = 16, axeslabelsize = 20)
	fig_dict = {}
	timing_data_dict = {}
	transition_labels = ['NREM-Wake', 'REM-Wake', 'NREM-REM', 'Wake-REM', 'REM-NREM', 'Wake-NREM']

	for exp,b in zip(FLP_classes, experiment_names):
		if timing_data_dict == {}:
			timing_data_dict[exp.Sensor] = {}
			if shuffled:
				timing_data_dict['Shuffled'] = {}
			for g in list(timing_data_dict.keys()):
				for i in transition_labels:
					timing_data_dict[g][i] = []
		transition_ts = exp.transition_timestamps(microarousals = True)
		epoch_dict = PKA.get_epochs(exp.SleepStates)
		for k in list(timing_data_dict.keys()):
			for t_type in transition_labels:
				second_state = t_type[t_type.find('-')+1:]
				epoch_time = [exp.SSTime[s] for s in epoch_dict[second_state]]
				epoch_starts = [s[0] for s in epoch_time]
				for t in transition_ts['Timestamps'][t_type]:
					epoch_idx, = np.where(epoch_starts == t)
					if len(epoch_time[int(epoch_idx)]) == 1:
						LFT_idx = [np.where(exp.Time >= epoch_time[int(epoch_idx)][0])[0][0]]
					else:
						LFT_idx = np.where(np.logical_and(exp.Time >= epoch_time[int(epoch_idx)][0], 
							exp.Time <= epoch_time[int(epoch_idx)][-1]))
					if k == exp.Sensor:
						trough_idx = np.argmin(exp.Filt[LFT_idx])
					if k == 'Shuffled':
						trough_idx = np.argmin(exp.Shuff[LFT_idx])
					timing_data_dict[k][t_type].append(exp.Time[LFT_idx][trough_idx]-t)
	for k in list(timing_data_dict.keys()):
		timing_data_dict[k]['Sleep-Wake'] = np.concatenate([timing_data_dict[k]['NREM-Wake'], 
			timing_data_dict[k]['REM-Wake']])


	color_dict_transitions = graph.SW_colordict('transitions')
	color_dict_transitions['Shuffled'] = '#929591'
	if shuffled:
		stats_dict_transition = {}
		stats_dict_transient = {}
		for l in these_transitions:
			stats_dict_transition[l] = {list(timing_data_dict.keys())[0]:[], list(timing_data_dict.keys())[1]:[], 'p-val':[], 'ks-stat':[]}
			stats_dict_transient[l] = {list(timing_data_dict.keys())[0]:[], list(timing_data_dict.keys())[1]:[], 'p-val':[], 'ks-stat':[]}
	graph.make_bigandbold(xticksize = 20, yticksize = 20, axeslabelsize = 25)
	transition_timing_fig, transition_timing_ax = plt.subplots(ncols = len(these_transitions), 
		figsize = (4*len(these_transitions), 6))
	transient_timing_fig, transient_timing_ax = plt.subplots(ncols = len(these_transitions), 
		figsize = (4*len(these_transitions), 6))

	for g in list(timing_data_dict.keys()):
		print('Plotting '+g)
		for ii, l in enumerate(these_transitions):
			transition_timing_ax[ii].set_xlabel('Time from Transition (s)')
			vals, bins = np.histogram(timing_data_dict[g][l], bins = np.arange(0,501,5))
			yvals = np.cumsum(vals)/np.sum(vals)
			yvals = np.insert(yvals, 0, 0)
			# print('For ' + l + ' Transitions: ' + str(yvals[np.where(bins<=10)[0][-1]]))
			if g == 'Shuffled':
				c = color_dict_transitions[g]
			else:
				c = color_dict_transitions[l]
			if shuffled:
				stats_dict_transition[l][g] = yvals
			transition_timing_ax[ii].plot(bins,yvals, color = c, label = g+'\n(n = '+ str(np.sum(vals))+')', linewidth = 4)
			graph.label_axes(transition_timing_ax[ii], title = l, x = 'Time from\nTransition (s)')
			transition_timing_ax[ii].legend()
			transition_timing_ax[ii].set_yticks([0,0.5,1])
		graph.label_axes(transition_timing_ax[0], y = 'Fraction of Total')
		graph.remove_yticks(transition_timing_fig, transition_timing_ax)
		transition_timing_fig, transition_timing_ax = graph.thick_axes(transition_timing_fig, transition_timing_ax)
		transition_timing_fig.tight_layout()

		for ii, l in enumerate(these_transitions):
			if g == 'Shuffled':
				c = color_dict_transitions[g]
			else:
				c = color_dict_transitions[l]
			vals, bins = np.histogram(-np.asarray(timing_data_dict[g][l]), bins = np.arange(-500,1,5))
			yvals = np.cumsum(vals)/np.sum(vals)
			yvals = np.insert(yvals, 0, 0)
			if shuffled:
				stats_dict_transient[l][g] = yvals
			transient_timing_ax[ii].plot(bins,yvals, color = c, label = g+'\n(n = '+ str(np.sum(vals))+')',linewidth = 4)
			transient_timing_ax[ii].axvline(0, color = 'k', linestyle = '--', linewidth = 2)
			transient_timing_ax[ii].legend()
			graph.label_axes(transient_timing_ax[ii], title = l, x = 'Time from\nTransient (s)')
		transient_timing_fig, transient_timing_ax = graph.thick_axes(transient_timing_fig, transient_timing_ax)
		graph.label_axes(transient_timing_ax[0], y = 'Fraction of Total')
		graph.remove_yticks(transient_timing_fig, transient_timing_ax)

		transient_timing_fig.tight_layout()
	if shuffled:
		for l in these_transitions:
			stats_dict_transition[l]['ks-stat'], stats_dict_transition[l]['p-val'] = stats.kstest(stats_dict_transition[l][list(timing_data_dict.keys())[0]],
				stats_dict_transition[l][list(timing_data_dict.keys())[1]])
			stats_dict_transient[l]['ks-stat'], stats_dict_transient[l]['p-val'] = stats.kstest(stats_dict_transient[l][list(timing_data_dict.keys())[0]],
				stats_dict_transient[l][list(timing_data_dict.keys())[1]])
		for i,l in enumerate(these_transitions):
			if stats_dict_transition[l]['p-val'] < 0.001:
				txt = '***'
			elif stats_dict_transition[l]['p-val'] < 0.01:
				txt = '**'
			elif stats_dict_transition[l]['p-val'] < 0.05:
				txt = '*'
			else:
				txt = ''
			x_text = transition_timing_ax[i].get_xlim()[-1]/2
			y_text = transition_timing_ax[i].get_ylim()[-1]-0.05
			transition_timing_ax[i].text(x_text, y_text, txt, fontweight= 'bold', fontsize = 20)

		for i,l in enumerate(these_transitions):
			if stats_dict_transient[l]['p-val'] < 0.001:
				txt = '***'
			elif stats_dict_transient[l]['p-val'] < 0.01:
				txt = '**'
			elif stats_dict_transient[l]['p-val'] < 0.05:
				txt = '*'
			else:
				txt = ''
			x_text = transient_timing_ax[i].get_xlim()[0]*0.25
			y_text = transient_timing_ax[i].get_ylim()[-1]-0.05
			transient_timing_ax[i].text(x_text, y_text, txt, fontweight= 'bold', fontsize = 20)
	fig_dict['Timing from Transient'] = (transient_timing_fig, transient_timing_ax)
	fig_dict['Timing from Transition'] = (transition_timing_fig, transition_timing_ax)

	if savedir:
		try:
			os.mkdir(savedir)
		except FileExistsError:
			pass

		savefilename1 = 'timing_from_transient_'
		savefilename2 = 'timing_from_transition_'
		for x in these_transitions:
			savefilename1 = savefilename1+x
			savefilename2 = savefilename2+x
		transient_timing_fig.savefig(os.path.join(savedir, savefilename1+grouped_name+fig_ext))
		transition_timing_fig.savefig(os.path.join(savedir, savefilename2+grouped_name+fig_ext))
	return fig_dict, timing_data_dict

def transient_amplitude_correlations(FLP_classes, experiment_names, movement = True, starting_velocity = True, remove_MAs = True):

	correlation_dict = {'NREM-Wake':
	{'Previous Sleep Length':[], 'Current Wake Length': [], 'Amplitude of LFT Change':[]}, 
	'REM-Wake': 
	{'Previous Sleep Length':[], 'Current Wake Length': [], 'Amplitude of LFT Change':[]},
	'All Sleep-Wake':
	{'Previous Sleep Length':[], 'Current Wake Length': [], 'Amplitude of LFT Change':[]},
	'NREM-REM-Wake':
	{'Previous Sleep Length':[], 'Current Wake Length': [], 'Amplitude of LFT Change':[]}}
	if movement:
		correlation_dict['NREM-Wake']['Average Velocity'] = []
		correlation_dict['REM-Wake']['Average Velocity'] = []
		correlation_dict['All Sleep-Wake']['Average Velocity'] = []
		correlation_dict['NREM-REM-Wake']['Average Velocity'] = []
	if starting_velocity:
		correlation_dict['NREM-Wake']['Starting Velocity'] = []
		correlation_dict['REM-Wake']['Starting Velocity'] = []
		correlation_dict['All Sleep-Wake']['Starting Velocity'] = []
		correlation_dict['NREM-REM-Wake']['Starting Velocity'] = []

	for exp,b in zip(FLP_classes, experiment_names):
		if remove_MAs:
			exp.SleepStates[exp.SleepStates == 5] = 2
		ss_df = exp.ss_onset_offset()
		wake_epochs_idx = ss_df.loc[ss_df['State'] == 1].index

		for i in wake_epochs_idx:
			if i > 0:
				previous_state = ss_df['State'].loc[i-1]
			else:
				continue

			start = ss_df['Start Time'].loc[i]
			end = ss_df['End Time'].loc[i]
			if end-start < 120:
				LFT_idx, = np.where(np.logical_and(exp.Time >= start, exp.Time < end))
			else:
				LFT_idx, = np.where(np.logical_and(exp.Time >= start, exp.Time < start+120))

			if previous_state == 2:
				these_keys = ['NREM-Wake', 'All Sleep-Wake']
				for k in these_keys:
					correlation_dict[k]['Amplitude of LFT Change'].append(max(-exp.Filt[LFT_idx]))
					correlation_dict[k]['Previous Sleep Length'].append(ss_df['End Time'].loc[i-1]-ss_df['Start Time'].loc[i-1])
					correlation_dict[k]['Current Wake Length'].append(end-start)
			elif previous_state == 3:
				assert ss_df['State'].loc[i-2] == 2
				k ='REM-Wake'
				correlation_dict[k]['Amplitude of LFT Change'].append(max(-exp.Filt[LFT_idx]))
				correlation_dict[k]['Previous Sleep Length'].append(ss_df['End Time'].loc[i-1]-ss_df['Start Time'].loc[i-1])
				correlation_dict[k]['Current Wake Length'].append(end-start)

				these_keys = ['NREM-REM-Wake', 'All Sleep-Wake']
				prev_length = (ss_df['End Time'].loc[i-1]-ss_df['Start Time'].loc[i-1]) + (ss_df['End Time'].loc[i-2]-ss_df['Start Time'].loc[i-2])

				for k in these_keys:
					correlation_dict[k]['Amplitude of LFT Change'].append(max(-exp.Filt[LFT_idx]))
					correlation_dict[k]['Previous Sleep Length'].append(prev_length)
					correlation_dict[k]['Current Wake Length'].append(end-start)
	return correlation_dict		

