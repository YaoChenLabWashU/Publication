# Run the following to set up the Python environment:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Fill in the paths below, set up the input parameter json file (see example below), and run the following for simulation:
python ./run_simulation.py --output /path/to/output/directory --prf_path /path/to/prf.mat --autofluorescence_path /path/to/af.mat --simulation_parameters /path/to/inputs.json --num_repeats <number of repeats>

Fitting logs can be shown using --verbose_output.

# Example input parameter json file:
Example input parameter file in Simnulation_python/data/example_parameters.json