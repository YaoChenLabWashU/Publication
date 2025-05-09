"""
Main function to load the simulation parameters, run simulations, and analyze the simulated data
"""
import shutil
import os
import datetime
import argparse
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from lib.ideal_photon_population import IdealPhotonPopulation, population
from lib.photon_population import PhotonPopulation
from lib.misc import get_resource_path

IDEAL_POPULATION_PEAK = 1000000
IDEAL_POPULATION_CHANNELS = 512
IDEAL_POPULATION_TIME_RANGE = 25

def parse_input():
  """Parse input args"""
  parser = argparse.ArgumentParser()
  parser.add_argument('--prf_path', help='path to prf', type = str,
                      default=get_resource_path('data', 'prf.mat'))
  parser.add_argument('--autofluorescence_path', help='path to AF file', type = str,
                      default=get_resource_path('data', 'autofluorescence.mat'))
  parser.add_argument('--simulation_parameters', help = 'input json file', type=str,
                      default=get_resource_path('data', 'example_parameters.json'))
  parser.add_argument('--output', help = 'ouptut path', type=str, default='')
  parser.add_argument('--num_repeats', help = 'Number of repeats. Default=1', type=int,
                      default=1)
  parser.add_argument('--verbose_output', help = 'display verbose output',
                      default=False, action='store_true')
  return parser.parse_args()

def read_input_json(filepath):
  """Read input filepath"""
  with open(filepath, 'r') as file:
    data = json.load(file)
  return data

def summarize_simulation(fitted_tau, fitting_results, empirical_lifetimes, histograms, output_path, verbose = False):
  """Summarize simulation repeats"""
  # Display Simulation Summary
  simulation_summary = {'repeat': list(range(len(fitted_tau))),
                        'empirical_lifetime': empirical_lifetimes,
                        'fitted_tau': fitted_tau}
  print('\n************** Simulation Sumary **************')
  print(f'Mean Empirical Lifetime: {np.nanmean(empirical_lifetimes)}')
  print(f'Mean Fitted Tau: {np.nanmean(fitted_tau)}')
  print('Mean Fitting Population Fractions:')
  for term in range(1, len(fitting_results[0])+1):
    mean_tau = np.nanmean([df.iloc[term-1]['tau'] for df in fitting_results])
    mean_frac = np.nanmean([df.iloc[term-1]['fraction'] for df in fitting_results])
    simulation_summary[f'p{term}_tau'] = [df.iloc[term-1]['tau'] for df in fitting_results]
    simulation_summary[f'p{term}_frac'] = [df.iloc[term-1]['fraction'] for df in fitting_results]
    print(f"  Population {term}: tau={mean_tau}; frac = {mean_frac}")

  # Calculate averaged histogram
  mean_counts = [hist['counts'] for hist in histograms]
  mean_counts = [sum(x) for x in zip(*mean_counts)]
  averaged_hist = pd.DataFrame({'time_channel': histograms[0]['time_channel'],'counts': mean_counts})

  if verbose:
    fig, axs = plt.subplots(1, 2)
    axs[0].plot(averaged_hist['time_channel'], averaged_hist['counts'])
    plt.show()

  if output_path:
    averaged_hist.to_csv(os.path.join(output_path, 'averaged_histogram.csv'))
    pd.DataFrame(simulation_summary).to_csv(os.path.join(output_path, 'simulation_sumary.csv'))

def main():
  # Read inputs
  args = parse_input()
  simulation_parameters = read_input_json(args.simulation_parameters)

  # Generate output destination
  if args.output:
    args.output = os.path.join(
        args.output,f'{datetime.datetime.now().strftime("%Y-%m-%d_%H_%M_%S")}_photon_simulation')
    os.makedirs(args.output, exist_ok=True)

  # Copy parameters
  shutil.copy(args.simulation_parameters, args.output) 

  # Generate ideal populations
  ideal_population_terms = \
      [population(term['population'], term['tau']) \
       for term in simulation_parameters['sensor_parameters']]
  ideal_photon_population = IdealPhotonPopulation( \
      IDEAL_POPULATION_PEAK,
      ideal_population_terms,
      time_range = IDEAL_POPULATION_TIME_RANGE,
      num_channels = IDEAL_POPULATION_CHANNELS)

  fitting_results = []
  fitted_taus = []
  empirical_lifetimes = []
  histograms = []
  if args.output:
    raw_curve_dest = os.path.join(args.output, 'raw_curves')
    os.makedirs(raw_curve_dest, exist_ok=True)
  for repeat in range(args.num_repeats):
    print(f'\n************** Simulation Repeat{repeat} **************')
    # Simulate photon population
    sampled_population = PhotonPopulation(\
      ideal_photon_population, simulation_parameters,
      args.prf_path, args.autofluorescence_path)

    # Generate outputs
    empirical_lifetimes.append(\
      sampled_population.calc_empirical_lifetime())
    fitted_tau, population_fractions = \
      sampled_population.calc_fitted_lifetime( \
        2, fixed_variables = {'p1_tau': 2.14, 'p2_tau':0.69},
        verbose = args.verbose_output)
    fitting_results.append(population_fractions)
    fitted_taus.append(fitted_tau)

     # Dump histogram to .csv
    if args.output:
      histogram_destination = \
          os.path.join(raw_curve_dest, f'simulation_{repeat}.csv')
      histograms.append(\
        sampled_population.dump_histogram(histogram_destination))

  # Generate summary
  summarize_simulation(fitted_taus, fitting_results, empirical_lifetimes, histograms, args.output)


if __name__ == "__main__":
  main()
