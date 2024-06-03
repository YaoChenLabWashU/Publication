This folder contains the example script and data for running FLiSimBA.

The script 'PKA_Sensor_FLIMAKAR.mlx' runs the generation of simulated data for PKA sensor FLIM-AKAR.
Each step of the simulation is annotated with instructions for data and functions used.

Files for running FLiSimBA of PKA sensor:

'prf_InsightBottomGreen_20231017.mat': origninal instrument response function (IRF) collected from two-photon fluorescence lifetime microscope rig.
'AKAR_baseline_fitting_parameters.mat': fitted parameters of experimental fluorescence lifetime decay histogram of FLIM-AKAR with tau1 = 2.14 ns and tau2 = 0.69 ns. Within this file the variable 'dpt' (delta peak time) is used to shift the original IRF file to match the experimental histogram data.
'Prf_interp1.mat': shifted IRF file by interpolation based on the fitting parameters of the experimental fluorescence lifetime decay histogram of FLIM-AKAR.
'Autofluo_fitting_parameters.mat': fitted parameters of empirically collected fluorescence lifetime decay histogram of autofluorescence from biological tissue. Tau1 and tau2 from fitting were used for Figure 4. Background term from the fitting was used as the background signal in simulation.
'Simulation_batch_20231208.m': batch processing script for simulation of different P1 and photon number conditions.
'Autofluo_corrected_simulation_20231201.m': batch processing script for repeated simulation of autofluorescence.
'Bkgrd_AP_simulation_20231201.m': batch processing script for repeated simulation of afterpulse and background.
