These are the functions, scripts, and example demo for FLiSimBA: Fluorescence Lifetime Simulation for Biological Applications.

Details of the folders:
Simulation_inMatlab: Functions used for simulation in FLiSimBA, written in MATLAB.
          GenPop512_FLIM_v2: generation of double exponential decay population;
          FlIMsim512_v2: sampling a number of photons from the exponential decay population and convolving with an instrument response function (IRF);
          AutoFluo_sim_v2: sampling of photons based on an empirically determined photon distribution of brain tissue without any fluorescent sensor expression; this function could be used for simulation of empirically determined autofluorescence and background;
          GenPop512_exp1_v2: generation of single exponential decay population.
	Simulation_demo: This folder includes the script with detailed annotation and instructions, as well as example data needed to run FLiSimBA. Please read the 'Demo_Instruction.md' file in the folder for more instruction.

DataAnaysis_inMatlab: Functions used for FLIM data acquisition and analysis (fitting functions and empirical lifetime calculation).

SimulationAnalysis_inPython: Functions used for simulation in FLiSimBA, written in Python. Also includes functions for analysis (fitting and empirical lifetime calculation)




