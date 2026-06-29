
import numpy as np
import os
from scipy import io, signal, stats
import pandas as pd
import glob
from datetime import datetime
import PKA_Sleep as PKA # Custom module for processing photometry and sleep data
from neuroscience_sleep_scoring import SWS_utils # Custom sleep scoring utilities
from copy import deepcopy
from scipy.stats import linregress
import matplotlib.pyplot as plt
# Define the main class for handling FLiP experiments
class FLiPExperiment():
	"""
	A class representing a single FLiP Experiment. 
	This class processes experimental data related to photometry and sleep states.
	"""

	def __init__(self, filename, epoch_len=4, one_acq=False, fs=1, filter_bounds=[None, None], 
		shuffle_window=200, experimental_sensor='FLIM-AKAR', sleep_states=True, 
		microarousals = False, MA_size = 16, exclude_acqs = False, gather_timestamps = True, outliers = True,
		emp_lifetime = False, p2 = True):
		"""
		Initializes the FLiPExperiment object.

		Args:
		- filename (str): Path to the experimental data matlab file.
		- epoch_len (int): Length of epoch used in sleep scoring in seconds.
		- one_acq (bool): If data is from one acquisition.
		- fs (int): Sampling frequency.
		- filter_bounds (list): Frequency bounds for filtering.
		- shuffle_window (int): Window size for shuffled photometry.
		- experimental_sensor (str): Name of the experimental sensor used.
		- sleep_states (bool): Whether to process sleep states.
		- microarousals (bool): Whether to convert short wake periods (<16s) into microarousals.
		"""
		self.Sensor = experimental_sensor  # Store the experimental sensor name
		self.filename = filename  # Store path to the input matlab data
		self.rawdatdir = os.path.dirname(filename)  # Directory containing the raw data


		# Load data from the matlab file
		data_dict = PKA.load_data(self.rawdatdir, self.filename)

		# Extract fitting parameters from loaded dictionary
		i = list(filter(lambda x: 'GWidth' in x, list(data_dict.keys())))
		self.GaussianWidth = data_dict[i[0]]

		i = list(filter(lambda x: 'chi_sq_G' in x, list(data_dict.keys())))
		self.ChiSquare = data_dict[i[0]]

		i = list(filter(lambda x: 'dpeak' in x, list(data_dict.keys())))
		self.DeltaPeakTime = data_dict[i[0]]

		i = list(filter(lambda x: 'photoncount' in x, list(data_dict.keys())))
		self.PhotonCount = data_dict[i[0]]

		# Check for potential dead time issues
		if max(self.PhotonCount * fs > 550000):
			print('WARNING: THIS EXPERIMENT COULD CONTAIN DEAD TIME ISSUES')
			self.DeadTime = True
		else:
			self.DeadTime = False

		# Extracting desired measure of phosporylation
		if p2:
			self.PhosMeasure = 'Binding Fraction'
			i = list(filter(lambda x: 'p1' in x, list(data_dict.keys())))
			self.Lifetime = 1-data_dict[i[0]]
		else:
			self.PhosMeasure = 'Lifetime (ns)'
			i = list(filter(lambda x: 'tau_fit_G' in x, list(data_dict.keys())))
			self.Lifetime = data_dict[i[0]]

		if outliers:
			self.Lifetime = PKA.remove_outliers(self.Lifetime, self.ChiSquare, num_std=3)

		# Extract empirical lifetime data and remove outliers
		if emp_lifetime:
			i = list(filter(lambda x: 'tau_emp' in x, list(data_dict.keys())))
			self.EmpLifetime = data_dict[i[0]]

		# Extract time data
		i = list(filter(lambda x: 'time' in x, list(data_dict.keys())))
		i.remove('timestamps')
		self.Time = data_dict[i[0]]

		# Apply filtering to lifetime data (if applicable)
		self.Filt = PKA.filt_lifetime(self.Lifetime, fs=fs, filt_low=filter_bounds[0], filt_high=filter_bounds[1], N=3)

		#Calculate z-scored lifetime
		self.ZScore = stats.zscore(self.Lifetime, ddof=0)

		# Store additional metadata
		self.EpochLength = epoch_len #epoch length used for sleep scoring
		if one_acq:
			idx1 = self.filename.find('Acq')+3
			idx2 = self.filename.find('_analysis')
			acq = int(self.filename[idx1:idx2])
			self.AcqNum = np.full(len(self.Lifetime), acq)
		else:
			self.AcqNum = data_dict['Acqs_all'] # Annotation for which acquisition each data point came from


		# Load in sleep states and calculate corresponding time vector if enabled
		if sleep_states:
			self.SSAcqNum, self.SleepStates = PKA.get_all_states(self.rawdatdir, self.filename, 
				one_acq, all_acqs = np.unique(self.AcqNum))
			if not one_acq:
				self.SSTime = PKA.define_SSTime(self.Time, self.SSAcqNum, self.AcqNum, self.EpochLength)
			else:
				self.SSTime = np.linspace(self.Time[0], self.Time[-1] - self.EpochLength, len(self.SleepStates))
            
			# Rescore short wake (<16s) to microarousals if enabled
			if microarousals:
				self.SleepStates = PKA.define_MAs(self.SleepStates, 5, epoch_len = self.EpochLength, cutoff_dur = MA_size)
		
		# Extract timstamps of acquisition triggers
		tt_fns = glob.glob(os.path.join(self.rawdatdir, '*trigger_times*')) # trigger time files
		# If data was collected after we started recording trigger times
		if gather_timestamps:
			if len(tt_fns) > 0:
				trigger_times = {}
				io.loadmat(tt_fns[0], mdict=trigger_times)
				self.Timestamps = [datetime(*[int(ii) for ii in i[0]]) for i in trigger_times['trigger_times'][0]]
			else:
				acqs = [f"{int(a):03d}" for a in np.unique(self.AcqNum)]
				FLIM_files = [glob.glob(os.path.join(self.rawdatdir, 
					'*FLIM' + str(a) +'.mat'))[0] for a in acqs]
				ts = [io.loadmat(fn)['spcSave']['datainfo'][0][0][0][0][11] for fn in FLIM_files]
				self.Timestamps = [datetime.strptime(s[0], '%d-%b-%Y %H:%M:%S.%f') for s in ts]				
		# Create and store Zeitgeber time vector
		if 'time_all' in data_dict.keys():
			data_dict['timestamps'] = self.Timestamps
			data_dict = PKA.get_zeit_time(data_dict)
			self.ZeitTime = data_dict['Zeit Time']

		# Store filter bounds for reference
		self.FilterBounds = filter_bounds

		# Labeling data as all from 1 experiment
		self.ClassID = np.zeros(len(self.Time))

		#Exclude certain acquisitions
		if not type(exclude_acqs) == bool:
			for a in exclude_acqs:
				remove_idx, = np.where(self.AcqNum == a)
				if sleep_states:
					SSremove_idx, = np.where(self.SSAcqNum == a)
					SS_len = len(self.SSAcqNum)
				reg_len = len(self.AcqNum)
				for key, value in vars(self).items():
					if (type(value) is list) or (type(value) is np.ndarray):
						if (len(value) == reg_len):
							# print(key)
							setattr(self, key, np.delete(value, remove_idx))
						if sleep_states:
							if (len(value) == SS_len):
								setattr(self, key, np.delete(value, SSremove_idx))
		# Generate shuffled photometry data
		self.Shuff = PKA.shuffle_photometry(self.Filt, window=shuffle_window)


	def find_transients(self, num_std = 3, FWHM_thresh = False, shuffled = False, discrete_cutoff = False):
		"""
		Identifies transients in the filtered lifetime data based on statistical thresholds.

		Args:
		- num_std (int): Number of standard deviations for thresholding.
		- FWHM_thresh (float): Minimum FWHM threshold for transients.
		- shuffled (bool): Use shuffled photometry data instead.
		- discrete_cutoff (bool): Use a fixed cutoff for transients.

		Returns:
		- Dictionary with transient information for the main and shuffled data.
		"""

		# Initialize dictionaries for storing PKA transient data
		transient_dict = {self.Sensor: {'Data': self.Filt, 'Transient Idx': [], 'FWHM': []}}
		if shuffled:
			transient_dict['Shuffled'] = {'Data': self.Shuff,'Transient Idx': [], 'FWHM': []}

		# Process each data type (main or shuffled)
		for k in list(transient_dict.keys()):
			mean_lifetime, thresh, s = PKA.transient_threshold(transient_dict[k]['Data'], num_std = num_std, 
				discrete_cutoff = discrete_cutoff)

			# Identify indices where data crosses the threshold
			thresholded_vals, = np.where(transient_dict[k]['Data'] < (mean_lifetime-thresh))

			# Group contiguous thresholded indices
			grouped_thresh_vals = []
			prev_val = thresholded_vals[0]
			temp = [prev_val]
			for v in thresholded_vals[1:]:
				if v == prev_val + 1:
					temp.append(v)
				else:
					grouped_thresh_vals.append(temp)
					temp = [v]
				prev_val = v
			grouped_thresh_vals.append(temp)

			# Merge nearby groups of continuous indices based on data continuity
			corrected_groups = []
			this_list = grouped_thresh_vals[0]
			for i in range(0,len(grouped_thresh_vals)-1):
				next_list = grouped_thresh_vals[i+1]
				in_between_idx = np.arange(this_list[-1], next_list[0])
				in_between_lifetime = transient_dict[k]['Data'][in_between_idx]
				if any(in_between_lifetime > mean_lifetime):
					corrected_groups.append(this_list)
					this_list = grouped_thresh_vals[i+1]
					if i == len(grouped_thresh_vals)-2:
						corrected_groups.append(next_list)
				else:
					combo_list = this_list + list(in_between_idx)+next_list
					this_list = combo_list

			# Get indices for PKA transients and calculate FWHM for each
			transient_idxs = [PKA.transient_window(transient_dict[k]['Data'], idx, mean_lifetime) for idx in corrected_groups]
			FWHM, time_points = PKA.transient_FWHM(transient_dict[k]['Data'], self.Time, transient_idxs)

			# Apply FWHM threshold if specified
			if FWHM_thresh:
				these_idxs, = np.where(np.array(FWHM) > FWHM_thresh)
				transient_idxs = [transient_idxs[i] for i in these_idxs]
				FWHM = [FWHM[i] for i in these_idxs]

			# Store results in output dictionary
			transient_dict[k]['FWHM'] = FWHM
			transient_dict[k]['Transient Idx'] = transient_idxs

		return transient_dict

	def ss_transition_per_transient(self, transient_dict, buffer_epochs = 4):
		"""
		Determines the type of sleep-wake transition that occurred immediately before each transient.

		Parameters:
		- transient_dict (dict): A dictionary containing transient indices and properties.
		- buffer_epochs (int): The number of epochs to look back when identifying preceding sleep states.

		Returns:
		- transition_types (ndarray): A 2D array where each row corresponds to a transient, and columns 
		  represent the pre- and post-transition states (state1, state2).
		- distance_from_transition (ndarray): A 1D array containing the time distance (in seconds) of each 
		  transient from the most recent state transition.
		"""

		# Determine if microarousals have been defined in this class
		if 5 in self.SleepStates:
			microarousals = True
		else:
			microarousals = False

		# Extract starting points of all transients based on indices.
		transient_idxs = transient_dict['Transient Idx']
		transient_starts = [t[0] for t in transient_idxs] # Corresponds to photometry data indices.

		 # Initialize arrays to store transition types and distances for each transient.
		transition_types = np.zeros([len(transient_starts), 2]) # Stores transition type. (e.g. NREM-Wake will be stored as [2,1])
		distance_from_transition = np.zeros(len(transient_starts)) # Stores distance from transition.

		# Iterate through each transient.
		for ii, i in enumerate(transient_starts):
			# Timestamp of the transient.
			t_start = self.Time[i]

			# Define the buffer range for analysis (looking backward in time to account for inconsistencies in sleep scoring).
			buffer_start = t_start-(buffer_epochs*self.EpochLength)
			buffer_idx, = np.where(np.logical_and(self.Time>=buffer_start, self.Time<=t_start)) #Indices correspond to photometry data

			# Extract sleep states within the buffer.
			these_states, these_states_idx = PKA.get_these_ss(buffer_idx, self.SleepStates, 
				self.Time, self.EpochLength) #Indexes correspond to sleep states data
			if len(these_states) == 0: # If no states are found, mark as NaN and continue.
				transition_types[ii] = [np.nan, np.nan]
				distance_from_transition[ii] = np.nan
				continue

			# If applicable, replace state 4 (Quiet Wake) with state 1 (Wake) for simpler classification.
			these_states[these_states == 4] = 1
			state_types = pd.unique(these_states)

			# Determine the transition type and time distance based on the sleep states.
			if len(state_types) == 1: # Only one state in the buffer (no transition).
				state2 = state_types[0]
				transition_idx, state1 = PKA.find_ss_transition(state2, 
					these_states_idx[0], self.SleepStates) #Indexes correspond to sleep states data
				if transition_idx < 0:
					transition_types[ii] = [np.nan, np.nan]
					distance_from_transition[ii] = np.nan
					continue				
			else: # Multiple states in the buffer indicate a transition.
				state1 = state_types[0]
				state2 = state_types[1]
				transition_idx = these_states_idx[np.where(these_states == state2)[0][0]] #Indexes correspond to sleep states data

			# Record the transition type and distance.
			transition_types[ii] = [state1, state2]
			distance_from_transition[ii] = t_start - self.SSTime[transition_idx]

		return transition_types, distance_from_transition

	def distance_from_each_transition_type(self, transient_dict):
		"""
		Calculates the time distance of each transient to all transition types.

		Parameters:
		- transient_dict (dict): A dictionary containing information about detected transients, 
		  including indices and other transient properties.

		Returns:
		- distance_dict (dict): A dictionary where keys are transition types (e.g., 'NREM-REM', 'REM-NREM'),
		  and values are lists of distances (in seconds) from each transient to the closest occurrence 
		  of that transition type.
		"""
		# Extract the start indices of transients in the photometry data.
		transient_idxs = transient_dict['Transient Idx']
		transient_starts = [t[0] for t in transient_idxs] #Indexes correspond to photometry data

		# Determine if microarousals have been defined in this class
		if 5 in self.SleepStates:
			microarousals = True
		else:
			microarousals = False

		# Get a dictionary of all transition timestamps for the various sleep/wake states.
		transition_dict = self.transition_timestamps()

		# Initialize a dictionary to store distances for each transition type.
		distance_dict = {}
		for k in list(transition_dict['Timestamps'].keys()):
			distance_dict[k] = []

		# For each transient's timestamp, compute its distance to every transition type.
		for ts in self.Time[transient_starts]:
			for k in list(distance_dict.keys()):
				# Find the indices of all transitions of type 'k' that occurred before the current transient.
				idx, = np.where(transition_dict['Timestamps'][k] < ts)
				if len(idx) > 0:
					# Compute distances from the transient to each prior transition and select the minimum.
					previous_transitions = transition_dict['Timestamps'][k][idx]
					distances = ts-previous_transitions
					distance_dict[k].append(min(distances))
		
		return distance_dict

	def transition_timestamps(self, diff_wake = False, alt_sleepstates = None):
		"""
		Identifies the timestamps of all sleep-wake state transitions and counts their occurrences.

		Parameters:
		- microarousals (bool): Whether to include microarousals as a separate transition type.
		- diff_wake (bool): Whether to differentiate between Active Wake and Quiet Wake states.

		Returns:
		- transition_dict (dict): A dictionary with the following structure:
		  - 'Timestamps': A nested dictionary where keys are transition types (e.g., 'NREM-REM') and
		    values are arrays of timestamps for each occurrence.
		  - 'Number': A dictionary where keys are transition types and values are the number of 
		    occurrences of that transition type.
		"""

		# Define transition types based on whether diff_wake is enabled.
		if alt_sleepstates is not None:
			sleepstates = alt_sleepstates
		else:
			sleepstates = self.SleepStates


		transition_dict = {'NREM-REM': [2, 3], 'REM-NREM': [3, 2]}
		if diff_wake:
			transition_dict.update({
				'NREM-Active Wake': [2, 1],
				'NREM-Quiet Wake': [2, 4],
				'REM-Active Wake': [3, 1],
				'REM-Quiet Wake': [3, 4],
				'Active Wake-NREM': [1, 2],
				'Quiet Wake-NREM': [4, 2],
				'Active Wake-REM': [1, 3],
				'Quiet Wake-REM': [4, 3],
				'Active Wake-Quiet Wake': [1, 4],
				'Quiet Wake-Active Wake': [4, 1]
			})
		else:  # Combine Active Wake and Quiet Wake into a single "Wake" state.
			sleepstates[np.where(sleepstates == 4)[0]] = 1
			transition_dict.update({
				'NREM-Wake': [2, 1],
				'REM-Wake': [3, 1],
				'Wake-NREM': [1, 2],
				'Wake-REM': [1, 3]
			})

		# Initialize the output dictionary.
		output_dict = {'Timestamps':{}, 'Number':{}}
		
		# Include microarousals if they are detected
		if 5 in sleepstates:
			microarousals = True
		else:
			microarousals = False

		if microarousals:
			micros = PKA.find_continuous(sleepstates, [5])
			output_dict['Timestamps']['Microarousals'] = self.SSTime[[x[0] for x in micros]]
			output_dict['Number']['Microarousals'] = len(micros)

		# Process each transition type and compute timestamps and counts.
		for t, state_nums in transition_dict.items():
			epochs = PKA.find_continuous(sleepstates, [state_nums[1]])
			epoch_starts = [x[0] for x in epochs]
			if 0 in epoch_starts:
				epoch_starts.remove(0)
			these_transitions = [x for x in epoch_starts if sleepstates[x - 1] == state_nums[0]]
			output_dict['Timestamps'][t] = self.SSTime[these_transitions]
			output_dict['Number'][t] = len(these_transitions)

   		# Add combined Sleep-Wake and Wake-Sleep counts/timestamps if not differentiating wakes.
		if diff_wake:
			output_dict['Number']['Sleep-Wake'] = output_dict['Number']['NREM-Quiet Wake'] + output_dict['Number']['NREM-Active Wake'] + output_dict['Number']['REM-Active Wake'] + output_dict['Number']['REM-Quiet Wake']
			output_dict['Number']['Sleep-Wake'] = output_dict['Number']['Quiet Wake-NREM'] + output_dict['Number']['Active Wake-NREM'] + output_dict['Number']['Active Wake-REM'] + output_dict['Number']['Quiet Wake-REM']
			output_dict['Timestamps']['Sleep-Wake'] = np.concatenate([output_dict['Timestamps']['NREM-Quiet Wake'], output_dict['Timestamps']['NREM-Active Wake'], 
				output_dict['Timestamps']['REM-Active Wake'], output_dict['Timestamps']['REM-Quiet Wake']])
			output_dict['Timestamps']['Sleep-Wake'] = np.concatenate([output_dict['Timestamps']['Quiet Wake-NREM'], output_dict['Timestamps']['Active Wake-NREM'],
				output_dict['Timestamps']['Active Wake-REM'], output_dict['Timestamps']['Quiet Wake-REM']])


		else:
			output_dict['Number']['Sleep-Wake'] = output_dict['Number']['NREM-Wake'] + output_dict['Number']['REM-Wake']
			output_dict['Number']['Wake-Sleep'] = output_dict['Number']['Wake-NREM'] + output_dict['Number']['Wake-REM']
			output_dict['Timestamps']['Sleep-Wake'] = np.sort(np.concatenate([output_dict['Timestamps']['NREM-Wake'], output_dict['Timestamps']['REM-Wake']]))
			output_dict['Timestamps']['Wake-Sleep'] = np.sort(np.concatenate([output_dict['Timestamps']['Wake-NREM'], output_dict['Timestamps']['Wake-REM']]))

		return output_dict
		
	def ss_onset_offset(self, alt_sleepstates = None):
		"""
		Identifies when each sleep state (e.g., NREM, REM, Wake) begins and ends. 
		The output is a dataframe containing the state, onset time, and offset time.

		Returns:
			pd.DataFrame: A dataframe with columns ['State', 'Start Time', 'End Time'].
		"""
		if alt_sleepstates is not None:
			sleepstates = alt_sleepstates
		else:
			sleepstates = self.SleepStates
		state_id = [] # List to store the sleep state identifiers (e.g., 1: Wake, 2: NREM, 3: REM)
		onset_times = [] # List to store the start times of each state
		offset_times  = [] # List to store the end times of each state

		sleepstates[sleepstates == 4] = 1

		# Iterate through each time step to find state transitions
		for i, s in enumerate(sleepstates):
			if i == 0: # First time step
				curr_state = s
				state_id.append(s)
				onset_times.append(self.SSTime[i])
			elif i == np.size(sleepstates)-1: # Last time step
				offset_times.append((self.SSTime[i]+self.EpochLength))
			elif s == curr_state: # Continuation of the same state
				continue
			elif s != curr_state: # Transition to a new state
				onset_times.append(self.SSTime[i]) # Record onset time of the new state
				offset_times.append(self.SSTime[i]) # Record offset time of the previous state
				curr_state = s # Update current state
				state_id.append(s)
			else:
				print('Not sure what the other option would be?') # Should not occur

		t_starts = [np.where(self.Time >= t)[0][0] for t in onset_times]
		zeit_starts = self.ZeitTime[t_starts]	
		# Create a dataframe with state, onset, and offset information
		df = pd.DataFrame(columns = ['State', 'Start Time', 'End Time'])
		df['State'] = state_id
		df['Start Time'] = onset_times
		df['End Time'] = offset_times
		df['Duration'] = df['End Time']-df['Start Time']
		df['Zeit Start'] = zeit_starts

		return df

	def get_max_LFT_perSS(self):
		"""
		Computes the maximum fluorescence lifetime (LFT) per sleep state.

		Identifies the maximum lifetime value for each behavioral bout 
		(NREM, REM, Wake, or Microarousals).

		Returns:
		    dict: A dictionary with sleep state names as keys and lists of max LFTs as values.
		"""

		# Get the onset and offset times for all behavioral bouts
		onoff_df = self.ss_onset_offset()

		# Initialize a dictionary to store maximum LFTs for each state
		data_dict = {'NREM': [], 'REM':[], 'Microarousals':[], 'Wake':[]}

		# Map state numbers to state names
		num_ss_key = {'1':'Wake', '2':'NREM', '3':'REM', '5':'Microarousals'}

		# Iterate through each bout in the dataframe
		for state_num, start, end in zip(onoff_df['State'], onoff_df['Start Time'], onoff_df['End Time']):
			state = num_ss_key[str(int(state_num))] # Get the corresponding state name
			# Find the indices in the fluorescence lifetime data that fall within the bout
			LFT_idx, = np.where(np.logical_and(self.Time>=start, self.Time<=end))
			# Append the maximum LFT value for this bout to the corresponding state list
			data_dict[state].append(np.max(self.Lifetime[LFT_idx]))
		return data_dict

	def combine_experiments(self, additional_classes):
		combined_class = deepcopy(self)
		class_ID = np.zeros(len(self.Time))
		for ID, other in enumerate(additional_classes):
			class_ID = np.concatenate([class_ID, np.full(len(other.Time), ID+1)])
			for key, value in vars(combined_class).items():
				print(key)
				if (key == 'Time') or (key == 'SSTime'):
					setattr(combined_class, key, 
						np.concatenate([value, getattr(other, key) + value[-1]]))
				elif (key == 'Sensor') or (key == 'EpochLength'):
					combined_class.Sensor = self.Sensor
				else:
					if np.isscalar(value):
						setattr(combined_class, key, [value, getattr(other, key)])
					elif np.isscalar(getattr(other, key)):
						new_val = getattr(other, key)
						value.append(new_val)
						setattr(combined_class, key, value)
					else:
						setattr(combined_class, key, 
							np.concatenate([value, getattr(other, key)]))
		combined_class.ClassID = class_ID
		combined_class.ZScore = stats.zscore(combined_class.Lifetime, ddof=0)
		return combined_class

	def add_drug_epochs(self, injection_info, ts_format, experiment_names, exp_type, 
		post_injection_buffer = 7200):
		epoch_type_dict = {'Saline': 1, 'Drug': 2}
		epoch_ID = np.zeros(len(self.Time))
		if exp_type == 'injection':
			experiment_names = [e for e in experiment_names if e in injection_info.keys()]
			if len(experiment_names) == 0:
				print('There is no injection info for the listed experiment(s). Assuming drug epochs are 0')
				self.EpochID = epoch_ID
				return
			injection_df = PKA.make_injection_df(injection_info, ts_format, self, experiment_names)
			experimental_epochs = PKA.get_experimental_epochs(injection_df, self, 
				post_injection_buffer = post_injection_buffer)
			
			for k in epoch_type_dict.keys():
				if k in list(experimental_epochs['Time (s)'].keys()):
					for w in experimental_epochs['Time (s)'][k]:
						window_idx, = np.where((self.Time >= w[0]) & (self.Time < w[1]))
						epoch_ID[window_idx] = np.full(len(window_idx), epoch_type_dict[k])
				else:
					print('No '+k+ ' period. Moving on...')
		if exp_type == 'infusion':
			b = experiment_names[0]
			for k in epoch_type_dict.keys():
				for p in range(len(injection_info[b][k + ' Acq'])):
					idx_range = [0,0]
					for t in [0,1]:
						acq_idx, = np.where(self.AcqNum == injection_info[b][k + ' Acq'][p][t])
						adjusted_time = self.Time[acq_idx]-self.Time[acq_idx][0]
						time_idx, = np.where(adjusted_time > injection_info[b][k + ' Timepoint'][p][t])
						idx_range[t] = acq_idx[time_idx[0]]
					epoch_ID[idx_range[0]:idx_range[1]+1] = epoch_type_dict[k]
		self.EpochID = epoch_ID

	def LFT_quant_bystate(self, onoff_df, state, averaging_window = [50,100], zscore = False):
		this_idx = onoff_df.loc[onoff_df['State'] == state].index
		col_name = 'LFT Val (window = '+str(averaging_window)+')'
		onoff_df[col_name] = np.nan
		for i in this_idx:
			if state == 5:
				start_time =  onoff_df['Start Time'].loc[i] + averaging_window[0]
				end_time = onoff_df['Start Time'].loc[i] + averaging_window[1]
			else:
				if onoff_df['Duration'].loc[i] > averaging_window[1]:
					start_time =  onoff_df['Start Time'].loc[i] + averaging_window[0]
					end_time = onoff_df['Start Time'].loc[i] + averaging_window[1]
				elif onoff_df['Duration'].loc[i] > averaging_window[0]:
					start_time =  onoff_df['Start Time'].loc[i] + averaging_window[0]
					end_time = onoff_df['End Time'].loc[i]
				else:
					continue
			if zscore:
				onoff_df.loc[i, col_name] = np.mean(self.ZScore[(self.Time > start_time) & 
				(self.Time < end_time)])
			else:
				onoff_df.loc[i, col_name] = np.mean(self.Lifetime[(self.Time > start_time) & 
				(self.Time < end_time)])
		return onoff_df

	def slope_bystate(self, onoff_df, sleep_slope_win = [30,100], wake_slope_win = [0,20],
		plot_sleep = False, shuffled = False):

		for i in onoff_df.index[1:]:
			if ((onoff_df['State'].loc[i] == 2) | (onoff_df['State'].loc[i] == 3)) & (onoff_df['Duration'].loc[i] > sleep_slope_win[1]):
				data_idx, = np.where((self.Time >= onoff_df['Start Time'].loc[i]+sleep_slope_win[0]) & 
					(self.Time < onoff_df['Start Time'].loc[i]+sleep_slope_win[1]))
			elif ((onoff_df['State'].loc[i] == 1) or (onoff_df['State'].loc[i] == 5)) & (onoff_df['Duration'].loc[i] > wake_slope_win[1]):
				data_idx, = np.where((self.Time >= onoff_df['Start Time'].loc[i]+wake_slope_win[0]) & 
					(self.Time < onoff_df['Start Time'].loc[i]+wake_slope_win[1]))
			else:
				continue
			if shuffled:
				linreg = linregress(self.Time[data_idx], self.Shuff[data_idx])
			else:
				linreg = linregress(self.Time[data_idx], self.Lifetime[data_idx])
			onoff_df.loc[i, 'Slope'] = linreg.slope
			if plot_sleep:
				if onoff_df['State'].loc[i] == 2:
					fig, ax = plt.subplots()
					if shuffled:
						ax.scatter(self.Time[data_idx], self.Lifetime[data_idx], color = 'k')
					else:
						ax.scatter(self.Time[data_idx], self.Shuff[data_idx], color = 'k')
					ax.plot(self.Time[data_idx], linreg.slope*self.Time[data_idx] + linreg.intercept,
						color = 'r')
		return onoff_df
	def split_by_circadian(self, shuffle_window = 200, outliers = True):
		light_idx, = np.where((self.ZeitTime >= 0) & (self.ZeitTime < 12))
		dark_idx, = np.where((self.ZeitTime >= 12) & (self.ZeitTime < 24))
		light_acqs, light_counts = np.unique(self.AcqNum[light_idx], return_counts = True)
		dark_acqs, dark_counts = np.unique(self.AcqNum[dark_idx], return_counts = True)

		overlap_idx = np.intersect1d(light_acqs, dark_acqs)
		for i in overlap_idx:
			if light_counts[light_acqs == i] < dark_counts[dark_acqs == i]:
				delete_idx, = np.where(light_acqs == i)
				light_acqs = np.delete(light_acqs, delete_idx)
				light_counts = np.delete(light_counts, delete_idx)

			elif light_counts[light_acqs == i] > dark_counts[dark_acqs == i]:
				delete_idx, = np.where(dark_acqs == i)
				dark_acqs = np.delete(dark_acqs, delete_idx)
				dark_counts = np.delete(dark_counts, delete_idx)

		dark_class = PKA.FLiPExperiment(self.filename, epoch_len=self.EpochLength, 
			fs=1/round(np.mean(np.diff(self.Time))), filter_bounds = self.FilterBounds, 
			shuffle_window=shuffle_window, experimental_sensor=self.Sensor, 
			sleep_states='SleepStates' in vars(self).keys(), microarousals = 5 in self.SleepStates,
			exclude_acqs = light_acqs, gather_timestamps = 'Timestamps' in vars(self).keys(), 
			outliers = True, emp_lifetime = 'EmpLifetime'in vars(self).keys(), 
			p2 = (self.PhosMeasure == 'Binding Fraction'))
		
		light_class = PKA.FLiPExperiment(self.filename, epoch_len=self.EpochLength, 
			fs=1/round(np.mean(np.diff(self.Time))), filter_bounds = self.FilterBounds, 
			shuffle_window=shuffle_window, experimental_sensor=self.Sensor, 
			sleep_states='SleepStates' in vars(self).keys(), microarousals = 5 in self.SleepStates,
			exclude_acqs = dark_acqs, gather_timestamps = 'Timestamps' in vars(self).keys(), 
			outliers = True, emp_lifetime = 'EmpLifetime'in vars(self).keys(), 
			p2 = (self.PhosMeasure == 'Binding Fraction'))

		return dark_class, light_class

	def add_EEG(self, downsamp_EEG = True, get_EMG = False, chan = None):
		if downsamp_EEG:
			extract_dir = os.path.join(self.rawdatdir, 
				os.path.split(self.rawdatdir)[1]+'_extracted_data','AD'+str(chan)+'_downsampled')
			chan = None
		else:
			extract_dir = self.rawdatdir
		print(extract_dir)
		self.EEGTime, self.EEG = PKA.get_all_EEG(extract_dir, concatenate = True, EMG_flag = False, downsamp_EEG = downsamp_EEG, 
			chan = chan, specific_acqs = np.unique(self.AcqNum))
		self.EEGTime = self.EEGTime + self.Time[0]

		if get_EMG:
			self.EMG = PKA.get_all_EEG(extract_dir, concatenate = True, EMG_flag = True, downsamp_EEG = downsamp_EEG, chan = chan, 
				specific_acqs = np.unique(self.AcqNum))















