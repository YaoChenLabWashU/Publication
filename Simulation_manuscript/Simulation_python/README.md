# Run the following to set up the Python environment:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Fill in the paths below, set up the input parameter json file (see example below), and run the following for simulation:
python ./run_simulation.py --output /path/to/output/directory --prf_path /path/to/prf.mat --autofluorescence_path /path/to/af.mat --simulation_parameters /path/to/inputs.json --num_repeats <number of repeats>

# For example, I'm running my simulation using this command line:
python ./run_simulation.py --output /Users/pingchuanma/Downloads/Simulation_python-main/Output --prf_path /Users/pingchuanma/Downloads/Simulation_python-main/data/Prf_interp1.mat --autofluorescence_path /Users/pingchuanma/Downloads/Simulation_python-main/data/Autofluorescence_info.mat --simulation_parameters /Users/pingchuanma/Downloads/Simulation_python-main/data/example_parameters.json --num_repeats 500

Simulated data (average histogram, input parameters, and individual histograms) are saved in the output folder for other analysis.

Fitting logs can be shown using --verbose_output.

# Example input parameter json file:
Example input parameter file in Simnulation_python/data/example_parameters.json