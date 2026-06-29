import numpy as np
import glob
import os
from scipy import io, signal,interpolate
from datetime import datetime
from statsmodels.nonparametric.kernel_regression import KernelReg
import PKA_Sleep as PKA
import pandas as pd
import math
from neuroscience_sleep_scoring import SWS_utils
from matplotlib import mlab
from scipy.integrate import simpson as simps
import PKA_Sleep.Graphing_Utils as graph
from matplotlib import cm,patches
from copy import deepcopy
import seaborn as sns
from scipy.io import loadmat
from natsort import natsorted

#This is a library of common analysis tooks needed for most FLiP data analysis

def load_data(rawdatdir, data_filename):
	''' 
	This function is used by the __init__ function in FLiPExp_class.py to extract 
	data from MATLAB files and return it as a dictionary for further processing.
	It handles the loading and flattening of arrays from the MATLAB `.mat` files,
	and processes the "timestamps" from an optional "autonotes.mat" file.

	Parameters:
	- rawdatdir: Directory where the raw data files are stored.
	- data_filename: The MATLAB file name (including path) containing the primary data.

	Returns:
	- data_dict: A dictionary where each key corresponds to data extracted from the MATLAB file.
	'''

	# Initialize an empty dictionary to store the loaded data
	data_dict = {}

	# Load the data from the MATLAB file into the dictionary
	io.loadmat(data_filename, mdict=data_dict)

	# Remove metadata that isn't needed for further analysis
	del data_dict['__header__']
	del data_dict['__version__']
	del data_dict['__globals__']

	# Get a list of keys in the dictionary (representing the data items)
	these_keys = list(data_dict.keys())

	# Try to remove the 'histograms' key if it exists (not relevant for analysis)
	try:
		these_keys.remove('histograms')
	except ValueError: # If 'histograms' is not present, skip
		pass

	# Try to remove the 'fits' key if it exists (not relevant for analysis)		
	try:
		these_keys.remove('fits')
	except ValueError: # If 'fits' is not present, skip
		pass

	# Flatten each of the remaining data arrays so they become 1D arrays and store in output dictionary
	for k in  these_keys:
		data_dict[k] = data_dict[k].flatten()

    # Try to load an additional 'autonotes.mat' file for timestamps
	try:
		notebook_filename = os.path.join(rawdatdir, 'autonotes.mat')  # Path to the notebook file
		notebook = {}  # Initialize empty notebook dictionary
		io.loadmat(notebook_filename, mdict=notebook)  # Load the notebook data

		# If the notebook has no data, assign an empty list to 'timestamps'
		if len(notebook['notebook']) == 0:
			data_dict['timestamps'] = [[]]
		else:
			# Extract timestamp data from the notebook
			data_dict['timestamps'] = [notebook['notebook'][0][x][0][0:8] for x in np.arange(np.size(notebook['notebook'][0]))]
	# If 'autonotes.mat' file is not found, assign an empty list to 'timestamps'
	except FileNotFoundError:
		data_dict['timestamps'] = [[]]

	# Return the dictionary containing the processed data
	return data_dict

def get_all_states(rawdatdir, filename, one_acq, all_acqs = None):
	''' 
	This function is used by the __init__ function in FLPExp_class.py to concatenate all 
	state files together. It either loads a single acquisition file or combines multiple
	state files into a single array.

	Parameters:
	- rawdatdir: Directory where the raw data files are stored.
	- filename: The file name (including path) of the input data file.
	- one_acq: Boolean flag indicating whether to process a single acquisition (True)
	           or combine all acquisitions (False).

	Returns:
	- all_states: A NumPy array containing the states data from one or multiple acquisitions.
	'''
	if one_acq: # If processing a single acquisition
		# Extract the acquisition number from the filename
		acq_str = filename[filename.find('q')+1:filename.find('_analysis')]

		# Find the corresponding state file for this acquisition and return loaded array
		statefile = glob.glob(os.path.join(rawdatdir, '*_extracted_data*', 'StatesAcq'+acq_str+'_hr0.npy'))[0]
		these_states = np.load(statefile)
		acq_nums = np.full(len(these_states), int(acq_str))
		return acq_nums, these_states
    
    # If processing all acquisitions into an experimenal unit
	state_files = glob.glob(os.path.join(rawdatdir, '*_extracted_data*', 'StatesAcq*_hr0.npy'))  # Find all state files
	# Extract acquisition numbers from the file names and sort in ascending order
	ss_acqs = [int(state_files[i][state_files[i].find('q')+1:state_files[i].find('_hr0')]) for i in range(len(state_files))] 
	ss_acqs.sort()
	missing_acqs = [a for a in all_acqs if a not in ss_acqs]
	if len(missing_acqs) > 0:
		print('The following acquisisions are not sleep scored:\n'+str(missing_acqs)
			+'\nI will fill these with 0s')

	# Initialize an empty NumPy array to store all states
	all_states = np.array([0])
	acq_nums = []

	# Loop through the sorted acquisition numbers
	for a in all_acqs:
		# Find and load the state file for the current acquisition
		if a in ss_acqs:
			this_file = glob.glob(os.path.join(rawdatdir,'*_extracted_data*', 'StatesAcq' + str(a) + '_hr0.npy' ))[0]
			these_states = np.load(this_file)
		else:
			try:
				these_states
			except NameError:
				this_file = glob.glob(os.path.join(rawdatdir,'*_extracted_data*', 'StatesAcq' + str(ss_acqs[0]) + '_hr0.npy' ))[0]
				these_states = np.load(this_file)
			these_states = np.full(len(these_states), 0)

		# Pulling the acquisition that the sleep states came from
		acq_nums.append(np.full(len(these_states), int(a)))

		# Concatenate the states to the all_states array
		all_states = np.concatenate((all_states, these_states))

	# Remove the initial placeholder value (0) from the array
	all_states = np.delete(all_states, 0)
	acq_nums = np.concatenate(acq_nums)
	
	return acq_nums, all_states # Return the concatenated states array

def get_all_EEG(extract_dir, concatenate = True, EMG_flag = False, downsamp_EEG = True, chan = None,
	 specific_acqs = None, fsd = 200, fs = 400):
	'''
	Concatenates all of the EEG files in a given directory.

	Parameters:
	- extract_dir (str): The directory containing the EEG files to be concatenated.
	- concatenate (bool): If True (default), return a single concatenated array of all EEG data.
	                      If False, return a list of individual EEG arrays.

	Returns:
	- np.ndarray or list: A single concatenated array of EEG data if concatenate=True, 
	                      otherwise a list of individual EEG arrays.
	'''

	# Find and sort all EEG files by creation time.
	all_files = [] # Initialize an empty list to store EEG arrays.
	if downsamp_EEG:
		if EMG_flag:
			fns = glob.glob(os.path.join(extract_dir,'downsampEMG*.npy'))
		else:
			fns = glob.glob(os.path.join(extract_dir,'downsampEEG_*hr0.npy'))
		fns = natsorted(fns)
		if specific_acqs is not None:
			these_acqs = ['_Acq'+str(a)+'_' for a in specific_acqs]
			all_files = [np.load(f) for f in fns if any([a in f for a in these_acqs])]
		else:
			all_files = [np.load(f) for f in fns]
		acq_len = len(all_files[0])/fsd
		all_time = [np.arange((i*acq_len), (i*acq_len)+acq_len, 1/fsd) for i in range(len(all_files))]
	# Load each EEG file and append it to the list.

	else:
		if EMG_flag:
			fns = glob.glob(os.path.join(extract_dir,'AD3_*.mat'))
		else:
			fns = glob.glob(os.path.join(extract_dir,'AD'+str(chan)+'_*.mat'))		
		fns = natsorted(fns)
		fns = fns[:-1]
		if specific_acqs is not None:
			these_acqs = ['AD'+str(chan)+'_'+str(a)+'.mat' for a in specific_acqs]
			all_files = [loadmat(f)[os.path.basename(f)[:-4]][0][0][0][0]  for f in fns if any([a in f for a in these_acqs])]
		else:
			all_files = [loadmat(f)[os.path.basename(f)[:-4]][0][0][0][0] for f in fns]
		acq_len = len(all_files[0])/fs
		all_time = [np.arange((i*acq_len), (i*acq_len)+acq_len, 1/fs) for i in range(len(all_files))]

	# Return the concatenated array or the list of individual arrays based on the 'concatenate' flag.
	if concatenate:
		# Concatenate all EEG arrays into a single array.
		sig = np.concatenate(all_files)
		sig_time = np.concatenate(all_time)
		return sig_time, sig
	else:
		return all_time, all_files

def get_zeit_time(data_dict):
	'''
	Creates an array of Zeitgeber time based on timestamps and experimental time data.

	Zeitgeber time is a measure often used in circadian rhythm research, 
	indicating the number of hours since lights-on in a controlled environment.

	Parameters:
	- data_dict (dict): A dictionary containing experimental data. 
	                    Must include 'timestamps' (list) and 'time_all' (numpy array).

	Returns:
	- dict: The updated data_dict with an added 'Zeit Time' key containing the calculated Zeitgeber time array.
	'''

	# Handle case where no timestamps are available.
	if data_dict['timestamps'][0] == []:
		print('No Zeitgeiber Time calculated')
		data_dict['Zeit Time'] = []
		return data_dict
	
	ts_format = '%H:%M:%S'  # Format for parsing timestamps.
	lights_on = "06:00:00"   # Time when lights turn on (reference point for Zeitgeber time).
	lon_dt = datetime.strptime(lights_on, ts_format)
	zeit_all = []	
	for i,a in enumerate(np.unique(data_dict['Acqs_all'])):
		t2 = data_dict['timestamps'][i]
		if t2.hour > lon_dt.hour:
			t2 = data_dict['timestamps'][i].replace(year=1900, month=1, day=1)
		else:
			t2 = data_dict['timestamps'][i].replace(year=1900, month=1, day=2)
		zeit_offset = (t2-lon_dt).total_seconds()
		t = data_dict['time_all'][data_dict['Acqs_all'] == a]
		zeit_all.append(((t-t[0])+zeit_offset)/3600 %24)
	data_dict['Zeit Time'] = np.concatenate(zeit_all)
	# Convert the first timestamp in the dataset to a datetime object.
	

	# Convert the lights-on time to a datetime object for reference.

	# Calculate the offset in seconds from lights-on, adjusting for a one-hour shift.
	

	# Calculate Zeitgeber time by normalizing 'time_all' to this offset and converting to hours.
	

	# Adjust times greater than 24 hours back into the 0–24 range (circadian rhythm cycles).
	# while len(np.where(data_dict['Zeit Time']>24)[0]) > 0:
	# 	over24_idx, = np.where(data_dict['Zeit Time']>24)
	# 	data_dict['Zeit Time'][over24_idx] = data_dict['Zeit Time'][over24_idx]-24

	return data_dict

def find_continuous(arr, this_state):
	'''
	Identifies continuous bouts of specified states in a given array of sleep states.

	Parameters:
	- arr (numpy array): The input array representing sleep states or similar categorical data.
	- this_state (list): A list of states to search for. Can include one or two states.

	Returns:
	- list of lists: Each inner list contains indices representing a continuous bout of the specified state(s).
	'''

	# Step 1: Identify indices where the array matches the specified state(s).
	if type(this_state) is not list:
		this_state = [this_state]
	if len(this_state) == 1:
		# If only one state is provided, find where the array equals this state or is NaN.
		these_bins, = np.where(np.logical_or(arr == this_state, np.isnan(arr)))
	elif len(this_state) == 2:
		# If two states are provided, find where the array matches either state or is NaN.
		these_bins, = np.where(np.logical_or(arr == this_state[0], arr == this_state[1], np.isnan(arr)))
	else:
		# Print a message if more than two states are provided (unsupported case).
		print('I cannot handle looking for more than 2 states at the moment')

	# Step 2: Handle the case where no indices match the desired states.
	if np.size(these_bins) == 0:
		return []  # Return an empty list as no bouts are found.

	# Step 4: Process the identified indices to group them into continuous bouts.
	cont_idx = cont_check(these_bins)
	return cont_idx

def cont_check(these_bins):
	cont_idx = []
	temp = [these_bins[0]]

	for b in these_bins[1:]:
		if (np.size(temp) == 0) or (b == temp[-1]+1):
			# If the current index is continuous with the previous one, append it to the current bout.
			temp.append(b)
		else:
			# If the current index is not continuous, save the current bout and start a new one.
			cont_idx.append(temp)
			temp = [b]
	cont_idx.append(temp)
	return cont_idx


def build_classes(experiment_names, animals, epoch_len = 4, filter_bounds = [None, None], binned = False,
	shuffle_window = 200, experimental_sensor = 'FLIM-AKAR', sleep_states = True, microarousals = False, 
	seperate_acqs = False, parent_data_directory = '/Volumes/yaochen/Active/Lizzie/FLP_data/', 
	exclude_acqs = False, gather_timestamps = True, p2 = True, outliers = True, emp_lifetime = True, MA_size = 16):
	'''
	Builds a dictionary of class objects for the listed experiments, optionally creating a class
	and optionally acquisition-level classes. It returns this dictionary.

	for each acquisition within each experiment. The dictionary includes experiment-level classes
	Args:
	    experiment_names (list): List of experiment names for which classes are to be built.
	    animals (list): List of animal names associated with the experiments.
	    epoch_len (int, optional): Epoch length in seconds. Default is 4.
	    filter_bounds (list, optional): Frequency bounds for data filtering. Default is [0.003, 0.1].
	    binned (bool, optional): Whether the data is binned. Default is False.
	    shuffle_window (int, optional): Window size for data shuffling. Default is 200.
	    experimental_sensor (str, optional): Sensor type for the experiment. Default is 'FLIM-AKAR'.
	    sleep_states (bool, optional): Whether to include sleep state information. Default is True.
	    microarousals (bool, optional): Whether to include microarousal information. Default is False.
	    seperate_acqs (bool, optional): Whether to create separate classes for each acquisition within
	                                     the experiments. Default is False.
	    parent_data_directory (str, optional): Directory path where the experiment data is located.
	                                           Default is '/Volumes/yaochen/Active/Lizzie/FLP_data/'.

	Returns:
	    dict: Dictionary containing experiment-level and optionally acquisition-level classes.
	          Structure:
	          {
	              'Experiment Classes': [list of FLiPExperiment objects],
	              'Animal Names': [list of animal names],
	              'Experiment Names': [list of experiment names],
	              'Acquisition Classes': [list of lists of FLiPExperiment objects per acquisition] (optional)
	          }
			  '''
	# Initialize dictionary to store classes
	n_experiments = len(experiment_names) # Number of experiments
	FLP_classes = {'Experiment Classes': [], # To store classes for each experiment
	'Animal Names': animals, # List of animal names
	'Experiment Names':experiment_names} # List of experiment names
	
	if seperate_acqs:
		# Initialize key for acquisition-level classes if specified
		FLP_classes['Acquisition Classes'] = []

	# Sampling frequency determined by whether the data is binned
	fs = 0.25 if binned else 1

	# Loop through all experiments to build classes
	for i in range(0, n_experiments):
		# Locate the raw data directory for the current experiment
		rawdatdir = os.path.join(parent_data_directory, experiment_names[i])

		# Pull concatenated matlab file (full experiment). Determined by whether or not data is binned
		if binned:
			concat_filename = glob.glob(os.path.join(rawdatdir, 'binned_concat*.mat'))[0]
		else:
			concat_filename = glob.glob(os.path.join(rawdatdir, 'concat*.mat'))[0]
		if exclude_acqs:
			e_acqs = exclude_acqs[i]
		else:
			e_acqs = False
		# Create an experiment-level class and append it to the dictionary
		FLP_classes['Experiment Classes'].append(PKA.FLiPExperiment(concat_filename, 
			epoch_len = epoch_len, fs =fs, filter_bounds = filter_bounds, shuffle_window = shuffle_window,
			experimental_sensor = experimental_sensor, sleep_states = sleep_states,
			gather_timestamps = gather_timestamps, microarousals = microarousals, MA_size = MA_size,
			exclude_acqs = e_acqs, p2 = p2, outliers = outliers, emp_lifetime = emp_lifetime))

		# If acquisition-level classes are required, process each acquisition
		if seperate_acqs:
			acqs = np.unique(FLP_classes['Experiment Classes'][i].AcqNum)

			# Determine file paths for acquisition-specific data
			if binned:
				analysis_files = [os.path.join(rawdatdir, f'Acq{a}_analysis_binned.mat') for a in acqs if a not in e_acqs]
			else:
				analysis_files = [os.path.join(rawdatdir, f'Acq{a}_analysis.mat') for a in acqs if a not in e_acqs]

			# Create a list of acquisition-level classes for the current experiment
			FLP_classes['Acquisition Classes'].append([PKA.FLiPExperiment(analysis_files[fn], one_acq=True, 
				epoch_len = epoch_len, fs =fs, filter_bounds = filter_bounds, shuffle_window = shuffle_window,
				experimental_sensor = experimental_sensor, sleep_states = sleep_states, 
				gather_timestamps = gather_timestamps, microarousals = microarousals, 
				p2 = p2, outliers = outliers, emp_lifetime = emp_lifetime) for fn in range(len(acqs))])

	# Return the dictionary containing all experiment and acquisition classes
	return FLP_classes

def pull_experiment_names(filename = 
	'/Users/lizzie/Library/CloudStorage/Box-Box/ChenLab/Lizzie/FLiP_Experiment_Summary.xlsx', 
 		cluster_flag = False, change_raw_dat_dir = False):
	'''
	Reads an Excel spreadsheet documenting FLiP experiments and filters it based on user inputs.
	The filtered data is returned as a pandas DataFrame.

	Args:
	    filename (str, optional): Filepath of the Excel spreadsheet containing the experiment summary.
	                              Default is a specific path.

	Returns:
	    pandas.DataFrame: A filtered DataFrame containing relevant experiment data.
	'''

	# Load the Excel file into a pandas DataFrame
	experiment_df = pd.read_excel(filename)
	# Step 1: Filter by experiment type (EEG/EMG inclusion)
	exp_type = input('Do you want experiments without EEG/EMG? (y/n)') == 'n'
	if exp_type:
		# Filter for experiments containing "EEGEMG" in their name		
		focused_df = experiment_df.loc[experiment_df['Experiment Name'].str.contains("EEGEMG", case=False, na=False)]
	else:
		focused_df = experiment_df
	if change_raw_dat_dir:
		focused_df['Raw Data Directory'] = focused_df['Raw Data Directory'].str.replace('/Volumes/yaochen/Active',change_raw_dat_dir)
	# Step 2: Filter by genotype
	genotypes = list(focused_df['Genotype'].unique()) # List unique genotypes
	print('Here are the available genotypes:')
	print(genotypes,flush=True)
	genotype_str = input('Please list the genotypes you want, seperating each genotype with a comma. If you want all, type "all"')
	genotype_str = genotype_str.replace(',','|') # Prepare for regex filtering
	if genotype_str != 'all':
		if '|' in genotype_str:
			focused_df = focused_df.loc[focused_df['Genotype'].astype(str).str.contains(genotype_str, case=False)]
		else:
			focused_df = focused_df.loc[focused_df['Genotype'] == genotype_str]

	# Step 3: Filter by implant location
	implant_loc = list(focused_df['Implant Location'].unique()) # List unique implant locations
	print('Here are the available implant locations:')
	print(implant_loc,flush=True)
	loc_str = input('Please list the locations you want, seperating each location with a comma. If you want all, type "all"')
	loc_str = loc_str.replace(',','|') # Prepare for regex filtering
	if loc_str != 'all':
		if '|' in loc_str:
			focused_df = focused_df.loc[focused_df['Implant Location'].astype(str).str.contains(loc_str, case=False)]
		else:
			focused_df = focused_df.loc[focused_df['Implant Location'] == loc_str]
	# Step 4: Filter by dataset
	datasets = list(focused_df['Dataset'].unique()) # List unique datasets
	print('Here are the available datasets:')
	print(datasets,flush=True)
	dataset_str = input('Please list the datasets you want, seperating each dataset with a comma. If you want all, type "all"')
	dataset_str = dataset_str.replace(',','|') # Prepare for regex filtering
	if dataset_str != 'all':
		if '|' in dataset_str:
			dataset_str = dataset_str.replace('(','\\(')
			dataset_str = dataset_str.replace(')','\\)')
			focused_df = focused_df.loc[focused_df['Dataset'].astype(str).str.contains(dataset_str, case=False)]
		else:
			focused_df = focused_df.loc[focused_df['Dataset'] == dataset_str]
	else:
		focused_df = focused_df.loc[~focused_df['Dataset'].isnull()]

	# Step 5: Filter by sex
	sex = input('What sex do you want? (M/F/both)')
	if sex != 'both':
		focused_df = focused_df.loc[focused_df['Sex'] == sex]

	# Step 6: Filter by recording length
	recording_len_min = int(input('What is the minimum number of acquisitions you want?'))
	recording_len_max = int(input('What is the maximum number of acquisitions you want?'))
	# Filter based on acquisition count
	if cluster_flag:
		for i in focused_df['Raw Data Directory'].index:
			focused_df[i, "Raw Data Directory"] = focused_df['Raw Data Directory'].loc[i].replace('/Volumes','/storage1/fs1')

	focused_df['# Acquisitions'] = [len(glob.glob(os.path.join(focused_df['Raw Data Directory'].loc[i], 
										'*AD0*.mat')))-1 for i in focused_df.index]
	focused_df = focused_df.loc[focused_df['# Acquisitions']>recording_len_min]
	focused_df = focused_df.loc[focused_df['# Acquisitions']<recording_len_max]

	# Step 7: Filter by animal name
	animals = list(focused_df['Mouse ID'].unique())
	print('Here are the available animals:') # List unique animal IDs
	print(animals,flush=True)
	animal_ID = input('Please list the animals you want to EXCLUDE, seperating each animal with a comma. If you want all, type "all"')
	animal_ID = animal_ID.replace(',','|') # Prepare for regex filtering
	if animal_ID != 'all':
		focused_df = focused_df.drop(focused_df.loc[focused_df['Mouse ID'].astype(str).str.contains(animal_ID, case=False)].index)

	# Step 8: option to remove anything without baseline data
	remove_flag = input('Are you using these for baseline data only? (y/n)') == 'y'
	if remove_flag:
		focused_df = focused_df[(~focused_df['Baseline Start'].isnull()) & (~focused_df['Baseline End'].isnull())]

	# Step 9: Filter by sleep scoring completion
	focused_df['# Acq Sleep Scored'] = [len(glob.glob(os.path.join(focused_df['Raw Data Directory'].loc[i], 
		'*'+focused_df['Experiment Name'].loc[i]+ '*','*States*.npy'))) for i in focused_df.index]
	sleepstate_flag = input('Do you need sleep states? (y/n)') == 'y'
	if sleepstate_flag:
		sleep_score_check = focused_df['# Acq Sleep Scored'] > 0
		print('The following experiments fit all the criteria, but need to be sleep scored: ' + str(list(focused_df.loc[~sleep_score_check]['Experiment Name'])))
		focused_df = focused_df.loc[sleep_score_check]

	# Step 10: Filter by photometry analysis completion
	focused_df['Photometry Analysis'] = [len(glob.glob(os.path.join(focused_df['Raw Data Directory'].loc[i], 
										'*concat*.mat'))) > 0 for i in focused_df.index]
	removed_experiments = list(focused_df.loc[~focused_df['Photometry Analysis']]['Experiment Name'])
	print('The following experiments fit all the criteria, but needs the FLiP pipeline run: ' + str(removed_experiments))
	flip_flag = input('Do you need the FLiP pipeline to be complete? (y/n)') == 'y'
	if flip_flag:
		focused_df = focused_df.loc[focused_df['Photometry Analysis']]

	# Display the filtered experiments for review
	print(focused_df[['Experiment Name', 'Comments']],flush=True)
	# Step 11: Exclude specific experiments
	exclude_experiment = input(
		'Please list the experiments you want to EXCLUDE, seperating each experiments with a comma. If you want all, type "all"')
	exclude_experiment = exclude_experiment.replace(',','|') # Prepare for regex filtering
	if exclude_experiment != 'all':
		focused_df = focused_df.drop(focused_df.loc[focused_df['Experiment Name'].astype(str).str.contains(exclude_experiment, case=False)].index)

	# Final review of filtered experiments
	print(focused_df[['Experiment Name', 'Comments']],flush=True)


	# Return the final filtered DataFrame
	return focused_df


def filt_lifetime(lifetime, fs = 1, filt_low = None, filt_high = None, N = 3):
	'''
	Filters photometry data based on cutoff frequencies and filter type.

	Args:
	    lifetime (numpy.ndarray): Input signal to be filtered.
	    fs (float, optional): Sampling frequency of the signal. Default is 1 Hz.
	    filt_low (float, optional): Low cutoff frequency for filtering. If `None`, no lower bound is applied.
	    filt_high (float, optional): High cutoff frequency for filtering. If `None`, no upper bound is applied.
	    N (int, optional): Order of the Butterworth filter. Default is 3.

	Returns:
	    numpy.ndarray: The filtered signal (`lifetime_filt`).
	'''
	# Calculate the Nyquist frequency (half the sampling frequency)
	nyq = fs*0.5

    # Determine filter type and create the corresponding filter coefficients
	if (filt_low is not None) and (filt_high is not None):
		# Bandpass filter: allows frequencies between `filt_low` and `filt_high`
		# print('Using a bandpass')
		Wn = [filt_low / nyq, filt_high / nyq]  # Normalized cutoff frequencies
		B, A = signal.butter(N, Wn, btype='bandpass', output='ba')  # Design bandpass Butterworth filter
	elif (filt_low is not None) and (filt_high is None):
		# Highpass filter: allows frequencies above `filt_low`
		# print('Using a highpass')
		Wn = filt_low / nyq  # Normalized cutoff frequency
		B, A = signal.butter(N, Wn, btype='highpass', output='ba')  # Design highpass Butterworth filter
	elif (filt_low is None) and (filt_high is not None):
		# Lowpass filter: allows frequencies below `filt_high`
		# print('Using a lowpass')
		Wn = filt_high / nyq  # Normalized cutoff frequency
		B, A = signal.butter(N, Wn, btype='lowpass', output='ba')  # Design lowpass Butterworth filter
	else:
		# No filter values provided; return the input signal unaltered
		# print('You didn\'t put any filter values')
		lifetime_filt = lifetime
		return lifetime_filt

    # Apply the designed filter to the input signal using zero-phase filtering
	lifetime_filt = signal.filtfilt(B,A, lifetime)
	return lifetime_filt

def transient_threshold(filtered_liftime, num_std, discrete_cutoff=False):
	'''
	Computes a threshold for identifying transients in a signal based on statistical properties 
	(mean and standard deviation) or a discrete cutoff value.

	Args:
	    filtered_liftime (numpy.ndarray): The input signal, typically a filtered version of lifetime data.
	    num_std (float or int): The number of standard deviations above the mean to use as the threshold.
	        If `None`, the `discrete_cutoff` is used instead.
	    discrete_cutoff (float or bool, optional): A manually defined threshold value. 
	        If set to `False` (default), the threshold is calculated using `num_std`.

	Returns:
	    tuple: A tuple containing:
	        - m (float): The mean of the input signal.
	        - thresh (float): The calculated threshold value.
	        - s (float): The standard deviation of the input signal.
	'''
	# Calculate the standard deviation of the input signal
	s = np.std(filtered_liftime)

	# Calculate the mean of the input signal
	m = np.mean(filtered_liftime)

	# Determine the threshold:
	# If `num_std` is provided, use it to calculate the threshold as a multiple of the standard deviation.
	# Otherwise, use the `discrete_cutoff` value as the threshold.
	if num_std:
		thresh = s * num_std
	else:
		thresh = discrete_cutoff

	# Return the mean, threshold, and standard deviation
	return m, thresh, s

def transient_amplitudes(lifetime, transient_idxs):
	'''
	Calculates the amplitudes of transients in a signal, along with their starting values and troughs.

	Args:
	    lifetime (numpy.ndarray): The input signal (e.g., lifetime data).
	    transient_idxs (list of lists): A list of lists where each inner list contains indices corresponding
	        to a transient event within the `lifetime` array.

	Returns:
	    tuple: A tuple containing:
	        - amplitudes (list): The calculated amplitudes of each transient, defined as the difference 
	          between the starting value and the trough.
	        - start_vals (list): The starting values of each transient.
	        - troughs (list): The minimum value (trough) of each transient.
	'''

	# Initialize lists to store the computed values
	amplitudes = []  # Holds the amplitude of each transient
	start_vals = []  # Holds the starting value of each transient
	troughs = []     # Holds the minimum value (trough) of each transient
    
    # Loop through each transient defined by its indices
	for t in transient_idxs:
		# Extract the current transient using its indices
		this_transient = lifetime[t]
		# Calculate the starting value of the transient as the average of the two points before its start
		start_val = (lifetime[t[0]]+lifetime[t[0]-1])/2
		# Find the minimum value (trough) within the transient
		trough = np.min(this_transient)
		# Store the starting value and trough
		start_vals.append(start_val)
		troughs.append(trough)
		# Calculate and store the amplitude as the difference between the starting value and the trough
		amplitudes.append(start_val-trough)

	# Return the computed values as a tuple
	return amplitudes, start_vals, troughs

def transient_FWHM(lifetime, time, transient_idxs):
	'''
	Calculates the Full Width at Half Maximum (FWHM) for transients in a signal, along with the time indices 
	corresponding to the points where the transient crosses half its maximum amplitude.

	Args:
	    lifetime (numpy.ndarray): The input signal (e.g., lifetime data).
	    time (numpy.ndarray): The time array corresponding to the `lifetime` signal.
	    transient_idxs (list of lists): A list of lists where each inner list contains indices corresponding
	        to a transient event within the `lifetime` array.

	Returns:
	    tuple: A tuple containing:
	        - FWHM (list): The calculated FWHM values for each transient.
	        - time_points (list of lists): A list of [t1, t2] pairs, where t1 and t2 are the time indices 
	          corresponding to the points where the transient crosses half its maximum amplitude.
	'''

	# Initialize lists to store the computed FWHM values and time points
	FWHM = []          # Holds the FWHM for each transient
	time_points = []   # Holds the time indices (t1, t2) for each transient's FWHM
	# Loop through each transient defined by its indices
	for i, t in enumerate(transient_idxs):
		# Extract the current transient using its indices
		this_transient = lifetime[t]

		# Calculate the half-max value: midpoint between the starting value and the minimum value (trough)
		half_max = (this_transient[0]+(np.min(this_transient)))/2

		# Find the index of the first point crossing below the half-max value
		ii = 0
		while this_transient[ii]>half_max:
			ii += 1
		
		# Find the index of the last point crossing above the half-max value
		ee = len(t)-1
		while this_transient[ee]>half_max:
			ee -= 1

		# Translate the indices to time values
		t1 = t[ii]  # Time index of the first crossing
		t2 = t[ee]  # Time index of the last crossing

		# Compute the FWHM as the difference in time between the two crossings
		FWHM.append(time[t2] - time[t1])
		# Store the time indices corresponding to the half-max points
		time_points.append([t1, t2])

	# Return the computed FWHM values and time indices
	return FWHM,time_points

def transient_window(filtered_liftime, idx, m):
	'''
	Determines the start and end points of a transient event within a signal. The function 
	identifies where the signal crosses back above the mean value (`m`) on either side of 
	the transient trough.

	Args:
	    filtered_liftime (numpy.ndarray): The filtered signal array (e.g., processed lifetime data).
	    idx (list): A list containing the index of the transient trough. Typically a single-element list, 
	        e.g., `[trough_index]`.
	    m (float): The mean value of the signal, used as the threshold for determining the transient window.

	Returns:
	    list: A list of unique indices that define the window around the transient where the signal 
	    is below the mean value.
	'''
	# Initialize the starting point of the backwards search to the given transient trough index
	i = idx[0]
	# Look backward to find where the signal crosses the mean
	while filtered_liftime[i] < m:
		# Prepend the current index to the transient index list
		idx.insert(0, i)
		# Move one step back
		i = i - 1
		# Stop if the index goes out of bounds
		if i < 1:
			break
	# Store the trasient starting idx
	idx.insert(0, i)
	#look forward for crossing mean
	i = idx[-1]
	while filtered_liftime[i]<m:
		idx.append(i)
		i = i+1
		if i >= np.size(filtered_liftime)-1:
			break

	# Store the trasient ending idx
	idx.insert(0, i)

	# Ensure indices are unique and return them as a sorted list
	return list(np.unique(idx))

def get_these_ss(ss_idx, time, sleep_states, state_time):
	'''
	Maps photometry indices to their corresponding sleep states and sleep state indices. 
	The function identifies which sleep states occur during the specified photometry data 
	time segments.

	Args:
	    ss_idx (list or array): Indices of the photometry data to analyze.
	    sleep_states (numpy.ndarray): Array of sleep states, typically representing different 
	        stages like wake, NREM, REM, etc.
	    time (numpy.ndarray): Array of timestamps corresponding to the photometry data.
	    state_time (numpy.ndarray): Array of timestamps corresponding to the sleep states data.

	Returns:
	    tuple:
	        - these_states (numpy.ndarray): Sleep states corresponding to the photometry indices.
	        - these_states_idx (numpy.ndarray): Indices of the sleep states data that match 
	          the photometry time segments.
	'''
	# Initialize lists to hold sleep states and their corresponding indices
	these_states = []
	these_states_idx = []

	# Get the timestamps corresponding to the photometry indices
	time_seg = time[ss_idx]  # Extract photometry timestamps using `ss_idx`

	# Iterate over consecutive pairs of timestamps in `time_seg`
	for tt in np.arange(np.size(time_seg) - 1):
		# Identify sleep state indices that fall within the current time segment
		this_state_idx, = np.where(np.logical_and(
			state_time >= time_seg[tt], # State timestamps fall after the start of the segment
			state_time < time_seg[tt+1])) # State timestamps fall before the end of the segment
		# Get the corresponding sleep states using the identified indices
		this_state = sleep_states[this_state_idx]

		# Append the current sleep state and its indices to the lists
		these_states.append(this_state)
		these_states_idx.append(this_state_idx) #Indexes correspond to sleep states data

	# Concatenate the lists into arrays if possible	
	try:
		these_states = np.concatenate(these_states)  # Combine all identified sleep states
		these_states_idx = np.concatenate(these_states_idx)  # Combine all corresponding indices
	except ValueError:
		# If concatenation fails (e.g., empty lists), retain the original lists
		pass
	# Return the sleep states and their indices
	return these_states, these_states_idx

def find_ss_transition(this_state, this_state_idx, sleep_states):
	'''
	Identifies the transition point from a given sleep state to a previous state by iterating 
	backwards through the sleep states array.

	Args:
	    this_state (int): The current sleep state (e.g., Wake = 1, NREM = 2, etc.).
	    this_state_idx (int): The index of the current state in the `sleep_states` array.
	    sleep_states (numpy.ndarray): Array of sleep states, typically representing stages like 
	        Wake, NREM, REM, etc.

	Returns:
	    tuple:
	        - i+1 (int): The index where the transition to a different state occurs.
	        - s (int): The previous sleep state found during the backward traversal.
	'''
	# Combine "Quiet Wake" (4) into "Wake" (1) to simplify transitions
	sleep_states[sleep_states == 4] = 1
	# Initialize the state and index for backward traversal
	s = this_state
	i = this_state_idx  # Index corresponding to the current sleep state

	# Traverse backward until a different state is encountered
	while s == this_state:
		i = i - 1  # Move one step back in the `sleep_states` array
		s = sleep_states[i]  # Update the state at the new index
	# Return the index and the state where the transition occurred
	return i + 1, s  # Add 1 to `i` to point to the last index of the original state

def transient_property_per_sstype(transition_types, values, labels):
	'''
	Organizes a given transient property (e.g., timing, amplitude) into a dictionary based on transition types.
	The transition types are specified by a list of state changes (e.g., NREM to Wake) and the associated values (e.g., timing).

	Args:
	    transition_types (numpy.ndarray): A 2D array where each row represents a state transition (e.g., NREM to Wake).
	    values (numpy.ndarray): Array of values corresponding to each transition type (e.g., the timing of the transition).
	    labels (list of str): List of labels representing the keys for the output dictionary (such as sleep stage transitions).

	Returns:
	    dict: A dictionary where keys are transition types (e.g., 'NREM-Wake', 'Wake-REM') and values are lists of 
	          corresponding transient property values.
	'''
	# Initialize an empty dictionary to store lists for each transition type
	data_dict = {}

	# Add labels as keys to the dictionary, each associated with an empty list
	for i in labels:
		data_dict[i] = []
	# Iterate over all rows of transition_types
	for ii in np.arange(0, np.shape(transition_types)[0]):
		# Check the transition type and append the corresponding value to the appropriate key in the dictionary
		if (transition_types[ii] == [2, 1]).all():  # Transition: NREM -> Wake
			data_dict['NREM-Wake'].append(values[ii])
		elif (transition_types[ii] == [3, 1]).all():  # Transition: REM -> Wake
			data_dict['REM-Wake'].append(values[ii])
		elif (transition_types[ii] == [2, 3]).all():  # Transition: NREM -> REM
			data_dict['NREM-REM'].append(values[ii])
		elif (transition_types[ii] == [1, 3]).all():  # Transition: Wake -> REM
			data_dict['Wake-REM'].append(values[ii])
		elif (transition_types[ii] == [3, 2]).all():  # Transition: REM -> NREM
			data_dict['REM-NREM'].append(values[ii])
		elif (transition_types[ii] == [1, 2]).all():  # Transition: Wake -> NREM
			data_dict['Wake-NREM'].append(values[ii])
		else:  # If no known transition type, classify as 'Unknown'
			data_dict['Unknown'].append(values[ii])

	# Return the populated dictionary with transition types as keys and lists of values as corresponding entries
	return data_dict


def shuffle_photometry(lifetime, window = 400):
	'''
	Shuffles the photometry data (`lifetime`) within a specified window size, maintaining the overall structure
	of the data. This can be used for generating control data by randomizing the order of epochs without altering
	the data's overall characteristics.

	Args:
	    lifetime (numpy.ndarray): A 1D array of photometry data (e.g., signal over time).
	    window (int, optional): The size of the window (in number of data points) used to reshape and shuffle the data. 
	                            Default is 400.

	Returns:
	    numpy.ndarray: A 1D array of the shuffled photometry data.
	'''
	# Determine how many full windows (of the specified size) can be made from the 'lifetime' data
	reshape_dimension = math.floor(len(lifetime)/window)

	# Calculate the remainder of data that doesn't fit into a full window
	remainder = len(lifetime) % window

	# Reshape 'lifetime' data into 2D, excluding any remainder if necessary to ensure complete windows
	if remainder > 0:
		lifetime_reshape = np.reshape(lifetime[:-remainder], [int(reshape_dimension), -1])
	else:
		lifetime_reshape = np.reshape(lifetime, [int(reshape_dimension), -1])
	# Create an array of indices representing the windows
	shuffling_order = np.arange(0, reshape_dimension)

	# Shuffle the window indices randomly
	np.random.shuffle(shuffling_order)

	# Initialize a list to store the shuffled windows

	# Append the shuffled windows to the result list
	shuffled_lifetime = []
	for i in shuffling_order:
		shuffled_lifetime.append(lifetime_reshape[int(i)])
	# Add any remaining data (remainder) back to the shuffled list, keeping it intact
	if remainder > 0:
		shuffled_lifetime.append(lifetime[-remainder:])
	
	# Concatenate all the shuffled windows and remaining data into a single 1D array
	shuffled_lifetime = np.concatenate(shuffled_lifetime)
	
	return shuffled_lifetime

def get_epochs(sleep_states, diff_wake = False, diff_MAs = False):
	'''
	This function identifies and organizes the continuous epochs of different sleep states from a 
	given sequence of sleep states. It uses the `find_continuous` function to extract continuous 
	segments of each state and stores them in a dictionary. Additionally, it offers options for 
	distinguishing between different types of wake states and microarousals.

	Args:
	    sleep_states (numpy.ndarray): A 1D array containing the sleep states data (e.g., 1 = Wake, 2 = NREM, 3 = REM, 4 = Quiet Wake, 5 = Microarousals).
	    diff_wake (bool, optional): If True, distinguishes between 'Active Wake' and 'Quiet Wake'. If False, combines them into a single 'Wake' category.
	    diff_MAs (bool, optional): If True, splits the microarousals based on whether they occur during REM or NREM sleep.

	Returns:
	    dict: A dictionary where keys are sleep state categories (e.g., 'NREM', 'REM', 'Wake', 'Microarousals') and 
	          values are lists of continuous epochs (indices) of each state.
	'''
    
    # Create a dictionary to store the continuous epochs for each sleep state
	epoch_dict = {
	    'NREM': find_continuous(sleep_states, [2]),    # Find continuous NREM epochs
	    'REM': find_continuous(sleep_states, [3]),     # Find continuous REM epochs
	    'Microarousals': find_continuous(sleep_states, [5])  # Find continuous Microarousals epochs
	}
	# If 'diff_wake' is True, distinguish between 'Active Wake' and 'Quiet Wake'
	if diff_wake:
		epoch_dict['Active Wake'] = find_continuous(sleep_states, [1])  # Find continuous Active Wake epochs
		epoch_dict['Quiet Wake'] = find_continuous(sleep_states, [4])   # Find continuous Quiet Wake epochs
	else:
		# If 'diff_wake' is False, treat Quiet Wake as part of Active Wake by setting Quiet Wake (4) to 1
		sleep_states[np.where(sleep_states == 4)[0]] = 1  # Combine Quiet Wake into Active Wake
		epoch_dict['Wake'] = find_continuous(sleep_states, [1])  # Find continuous Wake epochs (Active + Quiet Wake)
	# If 'diff_MAs' is True, differentiate between Microarousals occurring during REM and NREM
	if diff_MAs:
		REM_idxs, NREM_idxs = get_diff_MA_idx(sleep_states)  # Get indices for REM and NREM associated Microarousals
		epoch_dict['REM-Microarousals'] = [epoch_dict['Microarousals'][i] for i in REM_idxs]  # Microarousals during REM
		epoch_dict['NREM-Microarousals'] = [epoch_dict['Microarousals'][i] for i in NREM_idxs]  # Microarousals during NREM

	# Return the dictionary containing the epochs for each state
	return epoch_dict

def previous_epoch_length(current_epochs, previous_epochs, scoring_epoch):
	'''
	This function calculates the length of the previous behavioral epochs (e.g., NREM bouts) 
	before a transition, based on the indices of the previous epochs and the "current epochs". 
	For example, if you wanted to calculate the length of all the NREM bouts before a NREM-Wake 
	transition, the current epochs would represent the indices of the waking epochs, and 
	the previous epochs would represent the indices of the NREM epochs.

	Args:
	    current_epochs (list of lists): A list of lists, where each inner list contains the indices of epochs for a specific sleep state (e.g., wake epochs).
	    previous_epochs (list of lists): A list of lists, where each inner list contains the indices of epochs for a previous sleep state (e.g., NREM epochs).
	    scoring_epoch (float): The length of one epoch in seconds (e.g., duration of each epoch).

	Returns:
	    list: A list of the lengths (in seconds) of the previous epochs (e.g., NREM bouts) for each current epoch (e.g., waking epochs).
	          If no valid previous epoch is found, `np.nan` is returned for that epoch.
	'''
	# Get the starting index of each current epoch (e.g., waking epochs)
	current_starts = [w[0] for w in current_epochs]

	# Get the ending index of each previous epoch (e.g., NREM epochs)
	previous_ends = [s[-1] for s in previous_epochs]

	previous_lengths = []  # Initialize a list to store the lengths of previous epochs
	# Iterate through each start index of the current epochs
	for i in current_starts:
		if i > 0:  # Ensure that the current epoch is not the very first epoch
			try:
				# Try to find the previous epoch that ends right before the current epoch starts
				idx = previous_ends.index(i-1)
				# Append the length of the previous epoch, which is the number of indices in that epoch multiplied by the scoring epoch length
				previous_lengths.append(len(previous_epochs[idx]) * scoring_epoch)
			except ValueError:
				# If no previous epoch ends just before the current epoch, skip to the next
				continue
		else:
			# If no valid previous epoch exists (e.g., the very first epoch), append NaN
			previous_lengths.append(np.nan)
	# Return the list of previous epoch lengths
	return previous_lengths

def transient_frequency_by_transition(exp, transient_dict, indices, microarousals = True):
	'''
	This function calculates the frequency of transients over specific sleep state transitions during a given time window.
	The frequency is computed for each type of transition, with indices referring to the photometry data (time window) over which the transient frequency is calculated.

	Args:
	    exp (object): An experiment object that contains attributes such as SleepStates, SSTime, Time, etc., which are necessary for analyzing sleep transitions.
	    transient_dict (dict): A dictionary containing information about transient events, including 'Transient Idx' (start times of transients).
	    indices (array-like): The indices of the photometry data points corresponding to the time window over which transient frequencies should be calculated.
	    microarousals (bool, optional): Whether to include microarousals in the analysis. Default is True.

	Returns:
	    dict: A dictionary (`frequency_dict`) that contains the frequency of transients per type of transition.
	    dict: A dictionary (`num_transitions`) that contains the number of transitions for each type of sleep state transition.
	'''
	# Extract relevant time information from the experiment object
	ss_time = exp.SSTime  # Sleep state time
	time = exp.Time[indices]  # Time corresponding to the given indices
	ss_idx, = np.where(np.logical_and(ss_time >= time[0], ss_time < time[-1]))  # Find the indices of the sleep states within the time window
	sleep_states = exp.SleepStates[ss_idx]  # Extract the sleep states for the given time window

	# Get the number of transitions for each state (Wake, NREM, REM, etc.)
	num_transitions = number_of_transitions(sleep_states, exp.EpochLength, microarousals=microarousals)

	# Get the transition types and distance from transition for each transient event
	transition_types, distance_from_transition = exp.ss_transition_per_transient(transient_dict, buffer_epochs=2, microarousals=microarousals)

	# Extract the start times of the transients
	transient_starts = [t[0] for t in transient_dict['Transient Idx']]

	# Find the intersection between the indices of the photometry data and transient start times
	vals, comm1, these_transients = np.intersect1d(indices, transient_starts, return_indices=True)

	# Define the state labels for mapping transitions to their corresponding numerical codes
	state_labels = {'Wake': 1, 'NREM': 2, 'REM': 3, 'Microarousal': 5}

	# Initialize dictionaries to hold transition indices and frequency results
	tt_indices = {}  # Holds the indices of transitions for each transition type
	frequency_dict = {}  # Holds the frequency of transients for each transition type

	# Iterate over the different transition types to calculate their frequencies
	for t in ['NREM-Wake', 'REM-Wake', 'NREM-REM', 'Wake-NREM', 'Microarousal', 'REM-NREM']:
		if t == 'Microarousal':
			# For 'Microarousal', directly find the transitions where state 5 (microarousal) is involved
			tt_indices['Microarousal'] = np.where([any(x == 5) for x in transition_types[these_transients]])[0]
		else:
			# For other transitions, map the transition types to numerical state codes
			num_code = [state_labels[t[:int(t.find('-'))]], state_labels[t[int(t.find('-'))+1:]]]
			# Find the indices of transitions matching the current transition type
			tt_indices[t] = np.where([np.array_equal(x, num_code) for x in transition_types[these_transients]])[0]
			if num_transitions[t]>0:
				# Calculate the frequency as the number of matching transitions divided by the total number of transitions
				frequency_dict[t] = np.size(tt_indices[t])/num_transitions[t]
			else:
				frequency_dict[t] = 0
	# Special case for 'Sleep-Wake' transition (combines both NREM-Wake and REM-Wake)
	frequency_dict['Sleep-Wake'] = (np.size(tt_indices['NREM-Wake']) + np.size(tt_indices['REM-Wake'])) / (num_transitions['NREM-Wake'] + num_transitions['REM-Wake'])

	# Special case for 'Wake-Sleep' transition (identical to Wake-NREM)
	frequency_dict['Wake-Sleep'] = frequency_dict['Wake-NREM']

	# Calculate the frequency of microarousals
	frequency_dict['Microarousal'] = np.size(tt_indices['Microarousal']) / num_transitions['Microarousals']

	# Combine the indices of NREM-Wake and REM-Wake into a single 'Sleep-Wake' category
	tt_indices['Sleep-Wake'] = np.concatenate([tt_indices['NREM-Wake'], tt_indices['REM-Wake']])

	# Set 'Wake-Sleep' transition indices to be the same as 'Wake-NREM'
	tt_indices['Wake-Sleep'] = tt_indices['Wake-NREM']

	# Return the frequency dictionary and the number of transitions dictionary
	return frequency_dict, num_transitions

def find_behavior_length(epoch_dict, state, starttime, sleep_states, sleep_state_time, epoch_len):
	'''
	This function calculates the length of a behavior bout given the start time of the behavior bout.
	The bout is defined as a continuous period during which the animal is in a particular sleep state (e.g., Wake, NREM, REM).

	Args:
	    epoch_dict (dict): A dictionary that contains the indices of continuous periods for each sleep state.
	                       Each state (e.g., 'NREM', 'Wake', 'REM') maps to a list of indices representing the time epochs when that state was observed.
	    state (str): The sleep state for which the behavior bout length is to be calculated (e.g., 'NREM', 'Wake').
	    starttime (float): The start time of the behavior bout in the sleep state (in seconds).
	    sleep_states (array-like): The array of sleep states over time, where each element corresponds to a sleep state at a specific time.
	    sleep_state_time (array-like): An array of times corresponding to the sleep states, used to map indices to actual time.
	    epoch_len (float): The length of each epoch (in seconds) in the sleep states data.

	Returns:
	    tuple: A tuple containing:
	        - `behavior_len` (float): The length of the behavior bout (duration of time spent in the specified sleep state).
	        - `endtime` (float): The end time of the behavior bout (the time when the bout ends).
	'''

	# Extract the start times of the behavior bout for the specified state
	state_starts = [sleep_state_time[s[0]] for s in epoch_dict[state]]  # Start times of each bout in the specified state

	# Extract the end times of the behavior bout for the specified state
	state_ends = [sleep_state_time[s[-1]] for s in epoch_dict[state]]  # End times of each bout in the specified state

	# Find the index of the bout that starts at the specified start time
	epoch_idx = state_starts.index(starttime)  # Find the index where the start time matches the given start time

	# Calculate the length of the bout by subtracting the start time from the end time
	behavior_len = state_ends[epoch_idx] - state_starts[epoch_idx]  # Duration of the bout

	# Return the behavior length and the end time of the bout
	return (behavior_len, state_ends[epoch_idx])  # Return a tuple: behavior length and the end time of the bout

def determine_transient_notransient(epoch_dict, transient_dict, exp):
	'''
	This function evaluates each sleep-wake transition and determines whether a transient event occurred or not. 
	It compares the times of the sleep-wake transitions with the times of the transients to identify confirmed 
	transient events and transitions with no transients.

	Args:
	    epoch_dict (dict): A dictionary that contains information on sleep-wake epochs (states), with keys like 'Wake', 'NREM', etc. Each state corresponds to a list of epochs where that state occurs.
	    transient_dict (dict): A dictionary that contains information about transient events, with keys like 'Transient Idx' mapping to the indices of transients in the dataset.
	    exp (object): An experiment object that contains the data (e.g., `Time`, `SSTime`, `SleepStates`) related to the experiment.

	Returns:
	    tuple: A tuple containing two lists:
	        - `no_transient_idx`: Indices of the sleep-wake transitions where no transient occurred.
	        - `transient_idx`: Indices of the sleep-wake transitions where a transient was confirmed to have occurred.
	'''

	outcome_list = []  # List to store results for each sleep-wake transition (whether a transient occurred or not)

	# Iterate through each 'Wake' state epoch in epoch_dict
	for i, e in enumerate(epoch_dict['Wake']):
		transient_tracker = []  # List to track whether a transient occurs during each sleep-wake transition

		# Iterate through each transient in the transient_dict
		for ti,t in enumerate(transient_dict['Transient Idx']):
			t_time = exp.Time[t]  # Get the time of the current transient from the experiment object

			# Check if the transient time occurs within the current sleep-wake transition
			if e[-1] + 2 < len(exp.SSTime):  # If the end of the epoch does not exceed the time length
				temp = [x for x in t_time if exp.SSTime[e[0]] <= x <= exp.SSTime[e[-1] + 2]]
			else:
				temp = [x for x in t_time if exp.SSTime[e[0]] <= x <= exp.SSTime[e[-1]]]
            
			# If no transient occurs within the current epoch, append False to transient_tracker
			if len(temp) == 0:
				transient_tracker.append(False)
			else:  # If a transient occurs, append True to transient_tracker
				transient_tracker.append(True)
        # If no transients occurred for this epoch, append None to outcome_list
		if not any(transient_tracker):
			outcome_list.append(None)

		else:  # If at least one transient occurs, find the closest transient to the sleep-wake transition
			if len(np.where(transient_tracker)[0]) > 1:  # If there are multiple transients
				transient_times = [exp.Time[transient_dict['Transient Idx'][ii]] for ii in np.where(transient_tracker)[0]]
				epoch_time = exp.SSTime[e]
				distances = [abs(tt[0] - epoch_time[0]) for tt in transient_times]  # Calculate distance between transient and sleep-wake transition
				outcome_list.append(int(np.where(transient_tracker)[0][np.argmin(distances)]))  # Append the index of the closest transient
			else:
				outcome_list.append(int(np.where(transient_tracker)[0][0]))  # If only one transient, append its index
	
	# Extract indices of confirmed transient events (those where a transient was found)
	transient_idx = [outcome_list.index(x) for x in outcome_list if isinstance(x, int)]
	transient_idx = list(dict.fromkeys(transient_idx))  # Remove duplicate indices

	# Extract indices of transitions with no transients (those where None is appended)
	no_transient_idx, = np.where(np.array(outcome_list) == None)
	no_transient_idx = list(dict.fromkeys(no_transient_idx))  # Remove duplicate indices

	return no_transient_idx, transient_idx # Return both lists of indices

def power_by_behavior_bout(FLP_exp, freq_dict, window_length = 10, noverlap = 9, window_type = None, 
	state_key = {'1':'Wake', '2':'NREM', '3': 'REM', '5': 'Microarousal'}):
	'''
	This function calculates the power spectral density (PSD) for different frequency bands for each behavior bout 
	(e.g., Wake, NREM, REM, Microarousals) based on the provided EEG data. It computes the total power and power 
	within specified frequency bands, with options for normalization and scaling.

	Args:
	    epoch_dict (dict): A dictionary where keys are sleep states (e.g., 'Wake', 'NREM', etc.) and values are lists of 
	                        behavior bout epochs (start and end indices) corresponding to the state.
	    fsd (float): Sampling frequency of the EEG data.
	    freq_dict (dict): A dictionary where keys are frequency band names (e.g., 'Delta', 'Theta', 'Alpha', etc.), 
	                      and values are tuples with lower and upper frequency limits for the band.
	    exp (object): An experiment object containing EEG data and other relevant information (e.g., `SSTime`).
	    b (array): The raw EEG signal data.
	    NFFT_sec (int, optional): The length of the FFT window in seconds. Default is 10.
	    scale_by_freq (bool, optional): Whether to scale the PSD by frequency. Default is True.
	    norm (bool, optional): Whether to normalize the power within each frequency band by the total power. Default is True.

	Returns:
	    dict: A dictionary where each key is a behavior state (e.g., 'Wake', 'NREM', etc.) and the corresponding value is 
	          a list of dictionaries containing the total power and the power within each frequency band for each bout.
	'''

	fs = round(1/(FLP_exp.EEGTime[1]-FLP_exp.EEGTime[0]))
	minfreq = np.concatenate(list(freq_dict.values())).min()
	maxfreq = np.concatenate(list(freq_dict.values())).max()
	if maxfreq < 16:
		maxfreq = 16
	power_dict = SWS_utils.bandPower(FLP_exp.EEG, fs, freq_dict = freq_dict, minfreq = minfreq, 
		maxfreq = maxfreq, window_length = window_length, noverlap = noverlap, window_type = window_type)
	power_dict['Bins'] = power_dict['Bins'] + FLP_exp.Time[0]
	
	state_powers_dict = {'Time': {k:[] for k in state_key.values()},
						'Powers': {k:{f:[] for f in power_dict.keys()} for k in state_key.values()}}  # Initialize dictionary to store power results for each behavior state

	onoff_df = FLP_exp.ss_onset_offset()
	for i in onoff_df.index:
		this_bout = onoff_df.loc[i]
		if this_bout['State'] > 0:
			power_idx, = np.where((power_dict['Bins'] >= this_bout['Start Time']) & (power_dict['Bins'] < this_bout['End Time']))
			state_powers_dict['Time'][state_key[str(int(this_bout['State']))]].append(power_dict['Bins'][power_idx])
			for f in power_dict.keys():
				state_powers_dict['Powers'][state_key[str(int(this_bout['State']))]][f].append(power_dict[f][power_idx])

	return state_powers_dict # Return the dictionary containing power data for all behavior states

def count_repeat_vals(arr):
	'''
	This function counts how many consecutive values in an array (or list) are the same, i.e., how many times 
	the values "repeat" consecutively. It is primarily used to investigate "flat-lining" issues, where the data 
	remains constant for extended periods, which could indicate a problem.

	Args:
	    arr (list or array-like): An array or list of values to be checked for consecutive repeats.

	Returns:
	    int: The number of consecutive repeated values in the array.
	'''
	count = 0  # Initialize the count of repeated values to zero
	ref = arr[0]  # Set the first value as the reference for comparison

	# Iterate through the array starting from the second element
	for a in arr[1:]:
		if a == ref:  # If the current value is equal to the previous value (ref)
			count += 1  # Increment the count of consecutive repeats
		ref = a  # Update the reference to the current value

	return count  # Return the total count of consecutive repeated values

def remove_outliers(lifetime, chi_sq, num_std = 3):
	'''
	This function removes outliers from the `lifetime` array by identifying points in the `chi_sq` array that 
	exceed a threshold defined by the mean and standard deviation of `chi_sq`. The outlier points in `lifetime` 
	are replaced with the previous value to smooth the data.

	Args:
	    lifetime (array-like): An array containing the lifetime values to be processed.
	    chi_sq (array-like): An array of Chi-Square values used to detect outliers in the `lifetime` data.
	    num_std (int, optional): The number of standard deviations used to calculate the threshold for outliers. 
	                              Defaults to 3, meaning outliers are any values greater than the mean + 3*std.

	Returns:
	    array-like: The `lifetime` array with outliers replaced by the previous values.
	'''
	avg = np.mean(chi_sq)  # Compute the mean of the Chi-Square values
	std = np.std(chi_sq)  # Compute the standard deviation of the Chi-Square values
	thresh = avg + (num_std * std)  # Set the threshold for outliers (mean + num_std * std)

	# Identify the indices where the Chi-Square values exceed the threshold (outliers)
	outliers, = np.where(chi_sq > thresh)

	# Replace the lifetime values corresponding to outliers with the previous lifetime value
	for o in outliers:
		lifetime[o] = lifetime[o-1]  # Replace the outlier value with the previous value

	return lifetime  # Return the modified lifetime array with outliers removed


def define_SSTime(FLPTime, SSAcqNum, AcqNum, epoch_len):
	''' 
	This function is used by the __init__ function in FLPExp_class.py to build the time vector for sleep states.

	It constructs a time vector (SSTime) based on the FLPTime and the acquisition numbers (AcqNum) provided. 
	It also loads the state data for each acquisition and associates the correct time range with it.

	Parameters:
	- FLPTime: Array of time points corresponding to the photometry data.
	- AcqNum: Array of acquisition numbers.
	- rawdatdir: Directory where the extracted state data files are located.
	- epoch_len: Length of the epoch (in time units) to be used for the state time vectors.

	Returns:
	- SSTime: A concatenated array of time points corresponding to the sleep states.
	'''

	# Array of acquisitions numbers as pulled from the sleep state acquisition number array of the FLP class
	ss_acqs = [s for s in np.unique(SSAcqNum) if s in np.unique(AcqNum)]

	# Initialize an empty list to store the sleep state times
	SSTime = []

	# Loop through each acquisition number and load the corresponding state data
	for a in ss_acqs:
		# Find the indices in AcqNum that correspond to the current acquisition number
		acq_idx, = np.where(AcqNum == a)
		ss_acq_idx, = np.where(SSAcqNum == a)

		# Generate the time vector for this acquisition and append it to the SSTime list
		SSTime.append(np.linspace(FLPTime[acq_idx[0]], FLPTime[acq_idx[-1]] - epoch_len, len(ss_acq_idx)))
    
	# Concatenate all the time vectors for each acquisition into a single array and return it
	return np.concatenate(SSTime)

def get_crosscorr(y1, x1, y2, x2):
	''' 
	Computes the cross-correlation between two signals (y1, x1) and (y2, x2) after aligning their time series.
	The function first interpolates `y1` onto the time points of `x2`, then calculates the cross-correlation 
	between the two signals.

	Parameters:
	- y1: First signal values (e.g., photometry data or other time series).
	- x1: Time points corresponding to the `y1` signal.
	- y2: Second signal values to compare with `y1`.
	- x2: Time points corresponding to the `y2` signal.

	Returns:
	- correlation: The cross-correlation between the two signals.
	- lags: The corresponding lag times for the cross-correlation.
	'''
    # Ensure that the time series x2 is aligned with x1 by trimming the ends
	if x2[-1] > x1[-1]: # If x2 ends after x1, truncate the end of x2 to match the range of x1
		x2 = x2[:-1]
	if x2[0] < x1[0]: # If x2 starts before x1, truncate the start of x2 to match the range of x1
		x2 = x2[1:]

	# Interpolate y1 onto the time points of x2 to ensure both signals are on the same time axis
	y_int = interpolate_photometry(y1, x1, x2)

	# Compute the cross-correlation between the two signals (y_int and y2)
	# Subtract the mean of each signal for zero-mean normalization
	correlation = signal.correlate(y_int-np.mean(y_int), 
		y2 - np.mean(y2), mode="full")

	# Normalize the correlation by dividing by its maximum value (to scale it between -1 and 1)
	correlation /= max(correlation)

	# Calculate the lags corresponding to the cross-correlation
	lags = signal.correlation_lags(len(y_int), len(y2), mode="full")

	# Return the correlation and the lags
	return correlation, lags


def plot_sleepstate_colors(ax, ss_vector, time_vector, alpha=1):
	"""
	Plots colored background bands on a given axis to represent different sleep states.

	Parameters:
	    ax (matplotlib.axes.Axes): The axis object on which the sleep states will be plotted.
	    ss_vector (array-like): A vector containing sleep state values (e.g., 1 for Wake, 2 for NREM, etc.).
	    time_vector (array-like): A vector of time values corresponding to the sleep states.
	    
	Returns:
	    matplotlib.axes.Axes: The axis object with sleep state colors added.
	"""

	# Get the current vertical limits of the axis
	y_low, y_high = ax.get_ylim()
	# Retrieve a dictionary mapping sleep state numbers to colors
	color_dict = graph.SW_colordict('numbers')

	# Iterate through the sleep states to identify continuous segments for each state
	for state in [1, 2, 3, 4, 5]:  # Example states: 1=Wake, 2=NREM, 3=REM, 4=Quiet Wake, 5=Microarousal
		cont_state = PKA.find_continuous(ss_vector, [state])  # Find continuous segments of the current state
		
		if len(cont_state) > 0: # Check if any segments exist for this state
			# Iterate through each segment for the current state
			if len(cont_state[0])>0:
				# Iterate through each segment for the current state
				for s in cont_state:
					# Handle the start of the segment
					if s[0] == 0: # If the segment starts at the beginning of the vector
						x = time_vector[s[0]] # Offset to ensure proper visualization
						if x < 0: # Ensure x is non-negative
							x = 0
					else:
						x = time_vector[s[0]-1] # Set the starting x-coordinate

					# Calculate the width of the rectangle for this segment
					w = (time_vector[s[-1]]-x)
					# Create a rectangle patch with the appropriate color and dimensions
					rect = patches.Rectangle((x,y_low), w, y_high-y_low, 
						facecolor = color_dict[str(int(state))], alpha = alpha, edgecolor = None, zorder = 0)
					ax.add_patch(rect) # Add the rectangle to the axis
	return ax # Return the modified axis
	
def get_diff_MA_idx(sleep_states):
	"""
	Categorizes microarousals (MAs) into those occurring during NREM or REM sleep, 
	based on the sleep state immediately preceding each microarousal.

	Parameters:
	    sleep_states (array-like): A vector representing the sequence of sleep states. 
	                               Each value corresponds to a specific sleep state (e.g., 
	                               1=Wake, 2=NREM, 3=REM, 5=Microarousal).

	Returns:
	    tuple:
	        REM_idxs (list): Indices of microarousals that are preceded by REM sleep.
	        NREM_idxs (list): Indices of microarousals that are preceded by NREM sleep.
	"""
	# Initialize empty lists to store indices for REM and NREM microarousals
	REM_idxs = []
	NREM_idxs = []

	# Find continuous segments of microarousals (state=5)
	MAs = find_continuous(sleep_states, [5])

	# Iterate over each microarousal segment
	for i,m in enumerate(MAs):
		# Check if the state preceding the microarousal is NREM (state=2)
		if sleep_states[m[0]-1] == 2:
			NREM_idxs.append(i)
	    # Check if the state preceding the microarousal is REM (state=3)
		if sleep_states[m[0]-1] == 3:
			REM_idxs.append(i)

	return REM_idxs, NREM_idxs # Return categorized indices

# def nested_ttest(data, animal_ID, group, experiment_names):
# 	assert len(data) == len(group)
# 	assert sum([len(d) for d in data]) == sum([len(a) for a in animal_ID])

# 	animal_ID_col = []
# 	data_col = []
# 	group_col = []
# 	experiment_col = []

# 	for gi,g in enumerate(group):
# 		group_col.append(np.full(len(np.concatenate(data[gi])),g))
# 		for ai,a in enumerate(animal_ID[gi]):
# 			animal_ID_col.append(np.full(len(data[gi][ai]),a))
# 			data_col.append(data[gi][ai])
# 			experiment_col.append(np.full(len(data[gi][ai]),experiment_names[gi][ai]))

# 	assert len(np.concatenate(animal_ID_col)) == len(np.concatenate(group_col)) == len(np.concatenate(data_col)) == len(np.concatenate(experiment_col))


# 	data_df = pd.DataFrame({'Data':np.concatenate(data_col),
# 							'Animal ID':np.concatenate(animal_ID_col),
# 							'Group': np.concatenate(group_col),
# 							'Experiment Name':np.concatenate(experiment_col)})

# 	data_df.mixed_anova(dv = 'Data', between = 'Group', within = 'Experiment Name', subject = 'Animal_ID')

def interpolate_photometry(rawdata, photometry_time, interp_time):
	"""
	Interpolates photometry data to match a specified time vector.

	Parameters:
	    rawdata (array-like): The original photometry data points.
	    photometry_time (array-like): The time vector corresponding to the original data.
	    interp_time (array-like): The desired time vector for interpolation.

	Returns:
	    interp_data (array-like): The interpolated photometry data aligned to `interp_time`.
	"""
	# Create a linear interpolation function based on the original data and time vector
	set_interp = interpolate.interp1d(photometry_time, rawdata, kind='linear')

	# Apply the interpolation function to the desired time vector
	interp_data = set_interp(interp_time)
	return interp_data


def get_filter_type(filter_bounds):
	"""
	Determines the type of filter (low-pass, high-pass, or bandpass) and formats the filter bounds as a string.

	Parameters:
	    filter_bounds (tuple): A tuple defining the filter range. 
	                           The first value is the low-frequency cutoff (None if no cutoff),
	                           and the second value is the high-frequency cutoff (None if no cutoff).

	Returns:
	    tuple:
	        filter_type (str): A description of the filter type ("Low Pass Filter", "High Pass Filter", or "Bandpass Filter").
	        filt_bound_str (str): A string representation of the filter bounds (e.g., "0.1Hz-10Hz").
	"""

	if filter_bounds[0] is None:  # No low-frequency cutoff
		filter_type = 'Low Pass Filter: '
		filt_bound_str = str(filter_bounds[1]) + 'Hz'  # Upper bound only
	elif filter_bounds[1] is None:  # No high-frequency cutoff
		filter_type = 'High Pass Filter: '
		filt_bound_str = str(filter_bounds[0]) + 'Hz'  # Lower bound only
	else:  # Both bounds specified
		filter_type = 'Bandpass Filter: '
		filt_bound_str = str(filter_bounds[0]) + 'Hz' + '-' + str(filter_bounds[1]) + 'Hz'

	return filter_type, filt_bound_str

def pad_array(arr_list):
	"""
	Pads arrays in a list to the same length by adding NaNs to the shorter arrays.

	Parameters:
	    arr_list (list of array-like): A list of arrays with varying lengths.

	Returns:
	    padded_arrays (ndarray): A 2D array where all rows are padded to the length of the longest array in `arr_list`.
	                             Shorter arrays are padded with NaNs equally on both sides.
	"""

	# Determine the maximum length among all arrays
	max_length = max(len(arr) for arr in arr_list)

	# Initialize a list to store padded arrays
	padded_arrays = []

	# Loop through each array in the input list
	for arr in arr_list:
		arr = np.array(arr, dtype=float)  # Ensure the array is a NumPy array of floats
		total_padding = max_length - len(arr)  # Calculate the total padding needed
		left_padding = total_padding // 2  # Calculate left padding (half of total)
		right_padding = total_padding - left_padding  # Calculate right padding
		# Add NaN padding to the left and right sides
		padded_array = np.pad(arr, (left_padding, right_padding), 'constant', constant_values=np.nan)
		padded_arrays.append(padded_array)

	# Stack the padded arrays into a 2D array
	padded_arrays = np.vstack(padded_arrays)

	return padded_arrays

def group_continuous_indices(indices):	    
	indices = sorted(indices)
	groups = []
	current_group = [indices[0]]
	    
	for i in range(1, len(indices)):
		if indices[i] == indices[i-1] + 1:
			current_group.append(indices[i])
		else:
			groups.append(current_group)
			current_group = [indices[i]]
	
	groups.append(current_group)
	return groups

def adjust_acq_nums(FLP_exp):
	start_idx = 0
	acq_list = [FLP_exp.AcqNum[start_idx]]
	adjusted_AcqNum = np.empty(len(FLP_exp.AcqNum))
	new_acq_val = 0
	for i,a in enumerate(FLP_exp.AcqNum[1:]):
		if a != acq_list[-1]:
			adjusted_AcqNum[start_idx:i] = new_acq_val
			acq_list.append(a)
			start_idx = i
			new_acq_val = new_acq_val + 1
	adjusted_AcqNum[start_idx:] = new_acq_val

	return acq_list, adjusted_AcqNum

def change_basename(rawdatdir, curr_basename, new_basename):
	files = glob.glob(os.path.join(rawdatdir, '*'+curr_basename+'*'))
	for f in files:
		fn_old = os.path.split(f)[1]
		fn_new = fn_old.replace(curr_basename, new_basename)
		os.rename(f, os.path.join(rawdatdir, fn_new))

def distance_from_transition(transition_dict, transition_type, timepoints, relation = 'after'):
	closest_transition = []
	for ts in timepoints:
		if relation == 'before':
			idx, = np.where(transition_dict['Timestamps'][transition_type] < ts)
			if len(idx) > 0:
				this_transition = idx[-1]
		elif relation == 'after':
			idx, = np.where(transition_dict['Timestamps'][transition_type] > ts)
			if len(idx) > 0:
				this_transition = idx[0]
		if len(idx) > 0:
			# Compute distances from the transient to each prior transition and select the minimum.
			transition = transition_dict['Timestamps'][transition_type][this_transition]
			distances = ts-transition
			closest_transition.append(abs(distances))
		else:
			closest_transition.append(np.nan)
	return closest_transition

def LFTvals_byState(FLP_exp, onoff_df, time_range,
	state_key = {'1': 'Wake', '2': 'NREM', '3': 'REM', '5':'Microaorusal'}, shuffled = True, 
	buffer = 0, zscore = False, shuffle_window = 1):

	short_onoff_df = onoff_df.loc[(onoff_df['Start Time'] >= time_range[0]) & (onoff_df['End Time'] <= time_range[1])]
	state_nums = [s for s in np.unique(short_onoff_df['State']) if s != 0]
	LFT_vals = {'Time': {state_key[str(int(s))]:[] for s in state_nums}, 
				'Lifetime': {FLP_exp.Sensor: {state_key[str(int(s))]:[] for s in state_nums}}}
	if shuffled:
		LFT_vals['Lifetime']['Shuffled'] = {state_key[str(int(s))]:[] for s in np.unique(short_onoff_df['State'])}

	for s in state_nums:
		this_df = short_onoff_df.loc[short_onoff_df['State'] == s]
		for i in this_df.index:
			if this_df['Duration'].loc[i] >= buffer:
				idx, = np.where((FLP_exp.Time >= this_df['Start Time'].loc[i]+buffer) & 
					(FLP_exp.Time < this_df['End Time'].loc[i]))
			else:
				continue
			if zscore:
				LFT_vals['Lifetime'][FLP_exp.Sensor][state_key[str(int(s))]].append(FLP_exp.ZScore[idx])
			else:
				LFT_vals['Lifetime'][FLP_exp.Sensor][state_key[str(int(s))]].append(FLP_exp.Lifetime[idx])
			LFT_vals['Time'][state_key[str(int(s))]].append(FLP_exp.Time[idx])
		if shuffled:
			LFT_vals['Lifetime']['Shuffled'][state_key[str(int(s))]] = shuffle_singlestate(LFT_vals['Lifetime'][FLP_exp.Sensor][state_key[str(int(s))]], 
				shuffle_window = shuffle_window)
	return LFT_vals


def trim_MA_activity(FLP_exp, trim_window = 40):
	transition_dict = FLP_exp.transition_timestamps()
	LFT = deepcopy(FLP_exp.Lifetime)
	for m in transition_dict['Timestamps']['Microarousals']:
		trimming_idx, = np.where((FLP_exp.Time >= m) & (FLP_exp.Time < m + trim_window))
		LFT[trimming_idx] = np.nan
	return LFT

def choose_excluded_acqs(rawdata_dirs, pull_baseline = False, baseline_idxs = None, 
	first_acqs = 3, specific_acqs = False):
	excluded_acqs = []
	for r in range(len(rawdata_dirs)):
		file_list = glob.glob(os.path.join(rawdata_dirs[r], 'AD0_*'))
		idxs = [(fn.find('AD0_')+4, fn.find('.mat')) for fn in file_list]
		acqs = np.sort([int(file_list[i][a:b]) for i,(a,b) in enumerate(idxs) if b-a < 3])
		if specific_acqs:
			print(rawdata_dirs[r])
			print(acqs)
			acq_str = input('Which acquisitions do you want to exclude?')
			acq_list = acq_str.split(',')
			if acq_str == '':
				e = []
			else:
				e = [int(a) for a in acq_list]
		else:
			print('You are excluding the first '+ str(first_acqs) + ' acquisitions of this experiment.')
			e = acqs[:first_acqs]
		if pull_baseline:
			baseline_acqs = np.arange(baseline_idxs[r][0], baseline_idxs[r][1]+1)
			not_baseline = [a for a in acqs if a not in baseline_acqs]
			e = np.unique(np.concatenate([e, not_baseline]))
		excluded_acqs.append(list(e))
	return excluded_acqs


def shuffle_singlestate(LFT, shuffle_window = 5):
	concatLFT = np.concatenate(LFT)
	shuff_LFT = shuffle_photometry(concatLFT, window = shuffle_window)
	reshape_idx = np.cumsum([len(l) for l in LFT])
	reshape_idx = np.insert(reshape_idx, 0, 0)
	assert len(shuff_LFT) == reshape_idx[-1]
	reshape_shuff = [shuff_LFT[reshape_idx[i]:reshape_idx[i+1]] for i in range(len(reshape_idx)-1)]
	return reshape_shuff

