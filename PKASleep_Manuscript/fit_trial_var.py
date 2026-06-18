import importlib
from scipy.signal import savgol_filter
import os
import PKA_Sleep as PKA
import numpy as np
import matplotlib.pyplot as plt
# from PKA_Sleep import twomodel
from PKA_Sleep import twomodel
import time
import json
import random
import sys

def run_batch_fitting(experiment_names, mouse_names, num_runs, run_start):
    epoch_len = 4
    filter_bounds = [None, None]
    binned = False
    shuffle_window = 200
    experimental_sensor = 'FLIM-mAKAR'
    sleep_states = True
    microarousals = True
    seperate_acqs = False
    emp_lifetime = False
    gather_timestamps = False
    parent_data_directory = '/Volumes/yaochen/Active/Lizzie/FLP_data/'
    baseline_only = False

    raw_datadirs = [os.path.join(parent_data_directory, e) for e in experiment_names]
    if baseline_only:
        baseline_idxs = [(start,end) for start, end in zip(df['Baseline Start'], df['Baseline End'])]
        excluded_acqs = PKA.choose_excluded_acqs(raw_datadirs, first_acqs = 3, specific_acqs = False, 
                                                  pull_baseline = True, baseline_idxs = baseline_idxs)
    else:
        excluded_acqs = PKA.choose_excluded_acqs(raw_datadirs, first_acqs = 3, specific_acqs = False, pull_baseline = False)
       
    FLP_classes_dict = PKA.build_classes(experiment_names, mouse_names, epoch_len = epoch_len, 
                                         filter_bounds = filter_bounds, binned = binned, 
                                         shuffle_window = shuffle_window, experimental_sensor = experimental_sensor, 
                                         sleep_states = sleep_states, microarousals = microarousals, 
                                         seperate_acqs = seperate_acqs, emp_lifetime = False,
                                         parent_data_directory = parent_data_directory, gather_timestamps = True, 
                                          exclude_acqs = excluded_acqs)
    for FLP_exp, b in zip(FLP_classes_dict['Experiment Classes'], FLP_classes_dict['Experiment Names']):
        savedir = os.path.join(parent_data_directory, b, 'par_variability')
        os.makedirs(savedir,exist_ok=True)
        clipped_time_idx = PKA.clip_wake(FLP_exp.SleepStates, slide = 1, thresh = 0.2, max_length = int(900*4))
        clipped_time_range = [FLP_exp.SSTime[clipped_time_idx[0]], FLP_exp.SSTime[clipped_time_idx[-1]-1]]
        fit_LFT = FLP_exp.Lifetime[(FLP_exp.Time >= clipped_time_range[0]) & (FLP_exp.Time < clipped_time_range[1])]
        runs = np.arange(run_start, num_runs)
        for n in runs:
            savedir = os.path.join(parent_data_directory, b, 'par_variability')
            start = time.time()
            pars, opt, bounds, (grid, grid_losses) = PKA.fit_animal(savgol_filter(fit_LFT, 11, 2), 
                                                     n_global=2048, top_k=32, loss_kind="huber")
            pars['Fit Range'] = clipped_time_range
            end = time.time()
            print(f"Time taken: {end - start:.2f} seconds")
            print('Baseline: ' + str(pars))
            file_saved = False
            while not file_saved:
                try:
                    np.save(os.path.join(savedir,'pars_baseline_'+str(n)),pars)
                    print('Saving '+os.path.join(savedir,'pars_saline_'+str(n)))
                    file_saved = True
                except PermissionError:
                    savedir = os.path.join(parent_data_directory, b)
                    np.save(os.path.join(savedir,'pars_baseline_'+str(n)),pars)
                    print('Saving '+os.path.join(savedir,'pars_baseline_'+str(n)))
if __name__ == "__main__":
    args = sys.argv
    with open(args[1], 'r') as f:
        d = json.load(f)
    run_batch_fitting(d['experiment_names'], d['mouse_names'], d['num_runs'], d['run_start'])



