import numpy as np 
from pydub import AudioSegment
import glob
import os
import pandas as pd
from datetime import datetime
from scipy.signal import butter, lfilter, resample_poly
from scipy import stats
from neuroscience_sleep_scoring import SWS_utils
import PKA_Sleep as PKA
import matplotlib.pyplot as plt
import PKA_Sleep.Graphing_Utils as graph

def filter_and_downsample_audio(audio_dir, cutoff_freqs = [8000, 8005], fsd = 400):
	try:
		os.mkdir(os.path.join(audio_dir, audio_dir.split('/')[-2]+'_downsampled'))
	except FileExistsError:
		print('Seems like a downsampled audio folder has already been made. These files already exist:')
		print(glob.glob(os.path.join(audio_dir, '*downsampled*','*.npy')))
		continue_flag = input('Do you want to run this again? (y/n)')
		if continue_flag == 'y':
			print('Ok, running it again')

		else:
			print('Ok, quitting')
			return
	audio_files = glob.glob(os.path.join(audio_dir, '*audio*'))
	audio_files = [a for a in audio_files if '.csv' not in a]
	audio_files = [a for a in audio_files if 'downsampled' not in a]
	for a_fn in audio_files:
		print('Loading ' + a_fn + '...')
		audio = AudioSegment.from_file(a_fn)
		samples = np.array(audio.get_array_of_samples())
		sample_rate = audio.frame_rate
		if sample_rate > fsd:
			print('Filtering ' + a_fn + '...')
			b, a = butter_filter(cutoff_freq=cutoff_freqs, sample_rate=sample_rate, order=2)
			filtered_samples = apply_filter(samples, b, a)

			print('Downsampling ' + a_fn + '...')
			downsampled_samples = resample_poly(filtered_samples, up=fsd, down=sample_rate)
		else:
			downsampled_samples = samples
		savename = os.path.join(audio_dir, audio_dir.split('/')[-2]+'_downsampled', 
			(os.path.splitext(a_fn)[0]).split('/')[-1]+'_downsampled.npy')

		print('Saving as ' + savename + '...')
		np.save(savename, downsampled_samples)

def save_as_array(audio_dir):
	try:
		os.mkdir(os.path.join(audio_dir, audio_dir.split('/')[-2]+'_downsampled'))
	except FileExistsError:
		print('Seems like a downsampled audio folder has already been made. These files already exist:')
		print(glob.glob(os.path.join(audio_dir, '*downsampled*','*.npy')))
		continue_flag = input('Do you want to run this again? (y/n)')
		if continue_flag == 'y':
			print('Ok, running it again')

		else:
			print('Ok, quitting')
			return
	audio_files = glob.glob(os.path.join(audio_dir, '*audio*'))
	audio_files = [a for a in audio_files if '.csv' not in a]
	for a_fn in audio_files:
		print('Loading ' + a_fn + '...')
		audio = AudioSegment.from_file(a_fn)
		samples = np.array(audio.get_array_of_samples())
		savename = os.path.join(audio_dir, audio_dir.split('/')[-2]+'_downsampled', a_fn.split('/')[-1]+'_downsampled.npy')
		np.save(savename, samples)

def get_sound_timestamps(audio_dir, FLP_exp, ts_format = '%m/%d/%Y %H:%M:%S.%f'):
	sound_timestamp_csv = glob.glob(os.path.join(audio_dir, '*audio*.csv'))[0]
	sound_timestamp_df = pd.read_csv(sound_timestamp_csv, names = ['Logged Timestamp Strings'])
	sound_timestamp_df['Logged Datetime Objects'] = [datetime.strptime(dt_str, ts_format) for dt_str in sound_timestamp_df['Logged Timestamp Strings']]
	for i, idx in enumerate(np.arange(0, len(sound_timestamp_df), 2)):
		sound_timestamp_df.loc[idx, 'Logged Datetime Objects'] = FLP_exp.Timestamps[i]
	sound_timestamp_df['Seconds From Exp Start'] = [(dt-sound_timestamp_df['Logged Datetime Objects'].loc[0]).total_seconds() for dt in sound_timestamp_df['Logged Datetime Objects']]
	for i in np.arange(1, sound_timestamp_df.index[-1]+1, 2):
		sound_timestamp_df.loc[i, 'Seconds From Acq Start (Logged)'] = (sound_timestamp_df['Logged Datetime Objects'].loc[i]-sound_timestamp_df['Logged Datetime Objects'].loc[i-1]).total_seconds()
		sound_timestamp_df.loc[i, 'File Number'] = (i-1)/2
		sound_timestamp_df.loc[i-1, 'File Number'] = (i-1)/2
	sound_timestamp_df = sound_timestamp_df.loc[~sound_timestamp_df['Seconds From Acq Start (Logged)'].isnull()]
	sound_timestamp_df = sound_timestamp_df.reset_index(drop = True)
	return sound_timestamp_df

def find_photometry_audio_offset(acq_starts, audio_dir, bonsai_timestamp_dir, adjust = True):

	acq_start_df = pd.DataFrame(data = acq_starts, columns = ['Acquisition Datetime Objects'])
	audio_files = glob.glob(os.path.join(audio_dir, '*audio*'))
	audio_files = [a for a in audio_files if 'downsampled' not in a]
	audio_files = [a for a in audio_files if 'timestamps' not in a]
	

	for i in np.arange(0, len(audio_files)):
		audiofile = os.path.join(audio_dir, audio_dir+str(i))
		bonsaifile = os.path.join(bonsai_timestamp_dir, bonsai_timestamp_dir.split('/')[-2]+'_timestamp'+str(i)+'.csv') 
		bonsai_timestamp_df = SWS_utils.timestamp_extracting(bonsaifile, adjust = adjust)
		acq_start_df.loc[i, 'Audio File Name'] = audiofile
		acq_start_df.loc[i, 'Audio File Start Datetime Objects'] = bonsai_timestamp_df.loc[0, 'Timestamps']

	acq_start_df['Audio File-Acquisition Offset'] = [(a-b).total_seconds() for a,b in zip(acq_start_df['Acquisition Datetime Objects'], acq_start_df['Audio File Start Datetime Objects'])]
	acq_start_df.loc[0, 'Audio File-Acquisition Offset'] = 0

	return acq_start_df

def butter_filter(cutoff_freq, sample_rate, order=5, filter_type='bandpass'):
	nyquist = 0.5 * sample_rate
	normal_cutoff = [cutoff_freq[0] / nyquist, cutoff_freq[1] / nyquist]
	b, a = butter(order, normal_cutoff, btype=filter_type, analog=False)
	return b, a

def apply_filter(data, b, a):
    return lfilter(b, a, data)

def find_sound(audio_dir, bonsai_timestamp_dir, sound_timestamp_df, acq_start_df, bonsaifile_ts_format = "%Y-%m-%dT%H:%M:%S.%f"):
	audio_files = glob.glob(os.path.join(audio_dir, '*_downsampled', '*'))
	sound_frames = []
	for iacq in np.arange(0, len(audio_files)):
		if iacq == len(audio_files)-1:
			downsampled_audio_file = glob.glob(os.path.join(audio_dir, '*_downsampled', 
			'*_audio'+str(iacq)+'_downsampled.npy'))[0]
			audio_arr = np.load(downsampled_audio_file)
			audio_t = np.linspace(0, 3600, len(audio_arr))
		else:
			downsampled_audio_file1 = glob.glob(os.path.join(audio_dir, '*_downsampled', 
				'*_audio'+str(iacq)+'_downsampled.npy'))[0]
			downsampled_audio_file2 = glob.glob(os.path.join(audio_dir, '*_downsampled', 
				'*_audio'+str(iacq)+'_downsampled.npy'))[0]
			audio_arr = np.concatenate([np.load(downsampled_audio_file1), 
				np.load(downsampled_audio_file2)])
			audio_t = np.linspace(0, 7200, len(audio_arr))
		aligned_idx, = np.where(audio_t >= acq_start_df['Audio File-Acquisition Offset'].loc[iacq])
		try:
			aligned_audio_t = audio_t[aligned_idx[0]:]-audio_t[aligned_idx][0]
		except IndexError:
			continue
		aligned_audio_arr = audio_arr[aligned_idx[0]:]
		audio_start = sound_timestamp_df['Seconds From Acq Start (Logged)'].loc[(~sound_timestamp_df['Seconds From Acq Start (Logged)'].isnull()) & 
		                (sound_timestamp_df['File Number'] == iacq)].iloc[0]
		window, = np.where(np.logical_and(aligned_audio_t > audio_start-10, aligned_audio_t < audio_start+10))
		thresh = np.percentile(abs(aligned_audio_arr[window]), 92)
		over_thresh, = np.where(abs(aligned_audio_arr[window]) > thresh)
		sound_frames.append([aligned_audio_t[window][over_thresh[0]], aligned_audio_t[window][over_thresh[-1]]])
	if len(sound_timestamp_df) > len(sound_frames):
		for ii in range(len(sound_frames),len(sound_timestamp_df)):
			print('There are more logged sound entries than audio files. Using logged entry for Acq' + str(ii))
			sound_frames.append([sound_timestamp_df['Seconds From Acq Start (Logged)'].loc[ii], sound_timestamp_df['Seconds From Acq Start (Logged)'].loc[ii]+5])

	return sound_frames

def soundframes_from_start(FLP_exp, sound_frames):
	all_acqs = np.unique(FLP_exp.AcqNum)
	adjusted_soundframes = [sound_frames[0]]
	for i in np.arange(1, len(all_acqs)):
		curr_acq, = np.where(FLP_exp.AcqNum == all_acqs[i])
		normval = FLP_exp.Time[FLP_exp.AcqNum == all_acqs[i]-1][-1]
		adjusted_tvect = FLP_exp.Time[curr_acq]-normval
		window_idx, = np.where((adjusted_tvect >= sound_frames[i][0]) & 
			(adjusted_tvect < sound_frames[i][1]))
		adjusted_soundframes.append([FLP_exp.Time[curr_acq[window_idx[0]]], FLP_exp.Time[curr_acq[window_idx[-1]]]])
	return adjusted_soundframes

def sound_result(sleep_states, time_vect, sound_frames, buffer_window = 8, merge_sleep = True):
	sound_outcome = []
	if merge_sleep:
		sleep_states[sleep_states == 3] = 2
	for s in sound_frames:
		idx, = np.where((time_vect >= s[0]-buffer_window) & (time_vect < s[1]+buffer_window))
		ss = sleep_states[idx]
		diff_states = list(dict.fromkeys(ss))
		if len(diff_states) == 1:
			sound_outcome.append([diff_states[0], diff_states[0]])
		elif len(diff_states) == 2:
			sound_outcome.append(diff_states)
		elif len(diff_states) > 2:
			sound_on_idx = np.where(time_vect >= s[0])[0][0]
			sound_outcome.append([diff_states[0], sleep_states[sound_on_idx]])
	return sound_outcome

def sound_triggered_lifetime(FLP_classes, experiment_names, sound_timestamp_dfs, window = [50,120],
	intensity = False, state_key = {'Wake': 1, 'Sleep': 2, 'MA': 5}, raw_lifetime = False,
	these_outcomes = ['Wake-Wake', 'Sleep-Sleep', 'Sleep-Wake', 'Sleep-MA'], color_dict = False,
	axes_width = 1.25, fig_dict = False, shuffled = True, just_dictionary = False, savedir = False, zscore = False):
	
	experimental_sensor = FLP_classes[0].Sensor
	# Initialize the dictionary to store lifetime and intensity data
	lifetime_dict = {'Experiment Name':[], 'Lifetime':{experimental_sensor: {}},
		'Time':{}}

	if intensity:
		lifetime_dict['Intensity'] = {}
	if shuffled:
		lifetime_dict['Lifetime']['Shuffled'] = {}

	for k in these_outcomes:
		lifetime_dict['Lifetime'][experimental_sensor][k] = []
		if shuffled:
			lifetime_dict['Lifetime']['Shuffled'][k] = []
		if intensity:
			lifetime_dict['Intensity'][k] = []

	for FLP_exp, b, sound_timestamp_df in zip(FLP_classes, experiment_names, sound_timestamp_dfs):
		lifetime_dict['Experiment Name'].append(b)
		print('Working on '+b+'...')
		onoff_df = FLP_exp.ss_onset_offset()
		if zscore:
			FLP_exp.Shuff = stats.zscore(FLP_exp.Shuff, ddof=0)

		fs = 0.25 if 'binned' in FLP_exp.filename else 1
		x_vect = np.arange(-window[0]+1, window[1], 1/fs)
		
		for k in these_outcomes:
			# Initialize matrices to hold aligned data.
			lifetime_dict['Time'][k] = x_vect
			str_idx = k.find('-')
			outcome = [state_key[k[:str_idx]], state_key[k[str_idx+1:]]]
			data_idx = [i for i in list(sound_timestamp_df.index) if sound_timestamp_df['Sound Outcome'].loc[i] == outcome]
			data_df = sound_timestamp_df.loc[data_idx]
			stacked_lifetime = np.empty([len(data_df), len(x_vect)])
			stacked_lifetime[:] = np.nan
			# Conditional initialization for intensity and shuffled data.
			if intensity:
				stacked_intensity = np.empty([len(data_df), len(x_vect)])
				stacked_intensity[:] = np.nan
			if shuffled:
				stacked_lifetime_shuffled = np.empty([len(data_df), len(x_vect)])
				stacked_lifetime_shuffled[:] = np.nan

			for i in np.arange(0, len(data_df)):
				this_bout = data_df.iloc[i]
				t = this_bout['Detected Sound Window (from exp start)'][0]
				trace_start = t-window[0]
				if k == 'Sleep-Wake':
					wake_dur = onoff_df['Duration'].loc[
					onoff_df['End Time'] > this_bout['Detected Sound Window (from exp start)'][0]].iloc[0]
					if wake_dur < window[1]:
						trace_end = t+wake_dur
					else:
						trace_end = t+window[1]
				else:
					trace_end = t+window[1]
				idx, = np.where((FLP_exp.Time >= trace_start) & (FLP_exp.Time <= trace_end))
				normIdx = np.where(FLP_exp.Time >= t)[0][0]
				photometry_time = FLP_exp.Time[idx] - t  # Time vector centered at the transition.
				interp_idx, = np.where(np.logical_and(x_vect >= int(photometry_time[0]), x_vect <= int(photometry_time[-1])))
				interp_time = x_vect[interp_idx]
				if raw_lifetime:
					rawdata = FLP_exp.Lifetime[idx]
				elif zscore:
					rawdata = FLP_exp.ZScore[idx]
				else:
					rawdata = FLP_exp.Lifetime[idx]-FLP_exp.Lifetime[normIdx]
				stacked_lifetime[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)
				# Normalize and interpolate shuffled data, if applicable.
				if shuffled:
					if raw_lifetime:
						rawdata = FLP_exp.Shuff[idx]
					else:
						rawdata = FLP_exp.Shuff[idx]-FLP_exp.Shuff[normIdx]
					stacked_lifetime_shuffled[i, interp_idx] = PKA.interpolate_photometry(rawdata, photometry_time, interp_time)

				# Normalize and interpolate intensity data, if applicable.
				if intensity:
					stacked_intensity[i, interp_idx] = PKA.interpolate_photometry(FLP_exp.PhotonCount[idx]-FLP_exp.PhotonCount[normIdx], photometry_time, interp_time)

			lifetime_dict['Lifetime'][experimental_sensor][k].append(stacked_lifetime)
			if intensity:
				lifetime_dict['Intensity'][k].append(stacked_intensity)
			if shuffled:
				lifetime_dict['Lifetime']['Shuffled'][k].append(stacked_lifetime_shuffled)
	
	if just_dictionary:
		return lifetime_dict

	graph.make_bigandbold(axeslabelsize = 22)
	if not fig_dict:
		# Initialize dictionary to hold plots for lifetime and optionally intensity
		fig_dict = {'Lifetime':{}}
		if intensity:
			fig_dict = {'Lifetime':{}, 'Intensity':{}}
		
		# Create and store figure and axes objects for main transitions plots
		for k in fig_dict.keys():
			fig_dict[k] = {'Figure': [], 'Axes': []}
			fig_dict[k]['Figure'], fig_dict[k]['Axes'] = plt.subplots(
				nrows = 1, ncols = len(these_outcomes), figsize = [4*len(these_outcomes), 4])

			# Add consistent styling with custom axis width
			fig_dict[k]['Figure'], fig_dict[k]['Axes'] = graph.thick_axes(
				fig_dict[k]['Figure'], fig_dict[k]['Axes'], width = axes_width)

	if raw_lifetime:
		y_label = FLP_exp.PhosMeasure
	else:
		y_label = r'$\Delta$'+ FLP_exp.PhosMeasure

	if FLP_exp.PhosMeasure == 'Lifetime (ns)':
		y_negative = True
	else:
		y_negative = False

	lifetime_fig, lifetime_ax = fig_dict['Lifetime']['Figure'], fig_dict['Lifetime']['Axes']
	lifetime_fig, lifetime_ax = PKA.plot_triggered_average(lifetime_dict['Lifetime'][experimental_sensor], lifetime_dict['Time'], 
		these_outcomes, lifetime_fig, lifetime_ax, color_dict, y_label, average_function = np.nanmean, error_function = stats.sem,
		x_label = 'Time from\nSound (s)', y_negative = y_negative)

	# If shuffled data is available, plot it using a separate color scheme
	if shuffled:
		color_dict_shuff = {k: 'k' for k in these_outcomes}
		lifetime_fig, lifetime_ax = PKA.plot_triggered_average(lifetime_dict['Lifetime']['Shuffled'], lifetime_dict['Time'], 
			these_outcomes, lifetime_fig, lifetime_ax, color_dict_shuff, y_label, average_function = np.nanmean, error_function = stats.sem,
			x_label = 'Time from\nSound (s)', y_negative = y_negative)
	# If intensity data is plot it
	if intensity:
		# Pull figure and axes objects from the figure dictionary
		intensity_fig = fig_dict['Intensity']['Figure']
		intensity_ax = fig_dict['Intensity']['Axes']

		y_label = '-'+r'$\Delta$'+ 'Photon Count (ns)'
		intensity_fig, intensity_ax = PKA.plot_triggered_average(lifetime_dict['Intensity'], lifetime_dict['Time'], 
			these_outcomes, intensity_fig, intensity_ax, color_dict, y_label, average_function = np.nanmean, error_function = stats.sem,
			x_label = 'Time from\nSound (s)', y_negative = False)

	# Save figures if a save directory is provided
	if savedir:
		lifetime_fig.savefig(savedir) # Save the main lifetime plot
		if intensity:
			idx = savedir.find(os.path.splitext(savedir)[1])
			int_savename = savedir[:idx]+'_intensity'+savedir[idx:]
			intensity_fig.savefig(int_savename) # Save the intensity plot

	return fig_dict, lifetime_dict

# def LFT_quantification_sound():
	




	




