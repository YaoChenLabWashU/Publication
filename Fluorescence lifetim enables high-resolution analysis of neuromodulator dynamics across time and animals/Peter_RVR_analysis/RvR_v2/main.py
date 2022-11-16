# from classes import *
# from functions import *
import tkinter as tk
from tkinter import filedialog
import os
from GUI import DataParameters as DP
from GUI import AnalysisParameters as AP
import pandas as pd
from GUI import DataPaths as DatPath
from GUI import SaveOptions as SO
from GUI import OutputDisplay as OD
from classes import dataset

#Grab Data
path_obj = DatPath.DataPaths()

#Initialize Dataframes
fields = 'Experiment', 'Mouse ID', 'Laser Power', 'Basename'
init_data_params = [None]*len(path_obj.expDir)
for exp in path_obj.expDir:
    init_data_params[path_obj.expDir.index(exp)] = dict(zip(fields, ['null']*len(fields)))
    init_data_params[path_obj.expDir.index(exp)]['Experiment'] = exp
    init_data_params[path_obj.expDir.index(exp)]['Basename'] = exp
init_data_params = pd.DataFrame(init_data_params)

#Grab Data parameters
dataParameters = DP.DataParameters(init_data_params, path_obj.experiment_paths)

#Grab Analysis Parameters
analysisParameters = {'Filter Order':6, 'Filter Cutoff_High':0.015, 'Filter Cutoff_Low':0.015,
                       'FLP Sampling Frequency':1, 'TLCC Lag': 10, 
                       'Speed Bin Size': 0.25, 'Running Threshold': 1, 'Resting Threshold': 1, 'Threshold Length': 3,
                       'Preceding Rest': 10, 'Time After Transition': 0, 'Time Before Transition': 0, 
                       'ETA Before': 5, 'ETA After': 5, 'ETA Bin Size': 0.5,
                       'ETA Method': 'Interpolate', 'Baseline Length': 30, 'Baseline Buffer': 30, 'Baseline Chunks': 30, 
                       'Baseline Analysis Method': 'Max', 'Running Analysis Method': 'Max'}


analysisParams = AP.AnalysisParameters(analysisParameters)

#Grab Save Settings (non-functional)
save_settings = {'Raw Stack': False, 'Highpass Stack': False, 'Lowpass Stack': False, 
                 'Raw Overlays': False, 'Highpass Overlays': False, 'Lowpass Stack': False,
                 'Baseline Definition': False, 'Running Definition': False, 'Individual Correlation': False, 
                 'Grouped Correlations': False, 'ETA Individual': False, 'ETA Grouped': False, 
                 'Scatterplots Individual': False, 'Scatterplots Grouped': False, 'Boxplots Individual': False, 
                 'Boxplots Grouped': False, 'distribution_entropy': False, 'ANOVA': False}

saveOptions = SO.SaveOptions(save_settings)

#Generate Datasets
datasets = [None]*len(dataParameters.attributes)
for setnum in dataParameters.attributes.index:
    datasets[setnum] = dataset(dataParameters.attributes.iloc[setnum], analysisParams.fields, saveOptions)

#Create output Window
t = OD.OutputDisplay(datasets, dataParameters.attributes)