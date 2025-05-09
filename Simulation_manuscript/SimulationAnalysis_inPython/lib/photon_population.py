"""
Photon population

Processes:
  ------
  Simulations:
  Drawing samples from ideal population with 512 channels
  Convolution is distributive
  PRF has same number of time channels
  PRF convolution -> Wrap around after 256 channels -> Only take the first 256 channels as final simulated sensor data
  Add autofluorescence
  Add afterpulse
  Add background
  ------
  Analysis:
  Fitting and empirical lifetime calculation
"""
import random
import numpy as np
import pandas as pd
import scipy.io
import matplotlib.pyplot as plt
from lmfit import Model

DEFAULT_AF_COUNTS = 20000
DEFAULT_AFTERPULSE_RATIO = 0.01

INITIAL_Y0 = 13.8845*256
INITIAL_SHG = 36.7354
NUM_CHANNELS_LIFETIME_CALCULATIONS = 256

class PhotonPopulation():
  """
  Photon population
  """
  def __init__(self, ideal_population, simulation_parameters,
               prf_path, autofluorescence_path) -> None:
    self.ideal_population = ideal_population
    self.simulation_parameters = simulation_parameters
    self.time_channels = ideal_population.time_channel_starts
    self.num_channels = ideal_population.num_channels
    self.time_channel_edges = ideal_population.time_channel_edges
    self.time_range = ideal_population.time_range
    self.num_channels_lifetime_calculations = NUM_CHANNELS_LIFETIME_CALCULATIONS
    self.counts_per_channel_ideal = None # Simulated counts/channel using ideal_population.num_channels
    self.counts_per_channel = None # Simulated counts/channel using NUM_CHANNELS_LIFETIME_CALCULATIONS
    self.measured_photon_arrival_times = []
    self.photon_distribution = []
    self.prf = None
    self.simulate_photon_population(ideal_population, prf_path, autofluorescence_path)

  def simulate_photon_population(self, ideal_population, prf_path, autofluorescence_path):
    """Simulate a photon population
    Args:
      ideal_population (IdealPhotonPopulation): Ideal double exponential population to draw from
    """
    # Using the num of photons/channel in the ideal decay, randomly sample from the time channels
    # Distribution is the real photon arrival time
    self.photon_distribution = np.random.choice(
        self.time_channels,
        size=self.simulation_parameters['sensor_counts'],
        p=np.array(ideal_population.photon_counts) / np.sum(ideal_population.photon_counts)
    ).tolist()
    self.calc_population_counts()

    # PRF Convolution
    self.prf_conv(prf_path)

    #Add afterpulse
    if self.simulation_parameters['afterpulse_ratio'] > 0:
      self.add_afterpulse()

    # Add Dark Counts
    if self.simulation_parameters['background_distribution'] > 0:
      self.add_dark_counts()

    # # PRF Convolution
    # self.prf_conv(prf_path)

    # Add autofluorescence
    if self.simulation_parameters['autofluorescence_counts'] > 0:
      self.add_AF(autofluorescence_path)

  def calc_population_counts(self):
    """Build photon population based on time channel centers"""
    # Calculate counts/time channel
    arr, _ = np.histogram(self.photon_distribution, bins = self.time_channel_edges)
    self.counts_per_channel_ideal = pd.DataFrame({'time_channel': self.time_channels, 'counts': list(arr)})

    if self.num_channels_lifetime_calculations == self.num_channels:
      self.counts_per_channel = self.counts_per_channel_ideal
    elif self.num_channels/self.num_channels_lifetime_calculations>=2:
      # Wrap channels around
      time_channels_for_lifetime_calculations = \
          self.time_channels[:self.num_channels_lifetime_calculations]
      counts_for_lifetime_calculations = \
          arr[:self.num_channels_lifetime_calculations] + \
          arr[self.num_channels_lifetime_calculations:2*self.num_channels_lifetime_calculations]
      self.counts_per_channel = \
          pd.DataFrame({'time_channel': time_channels_for_lifetime_calculations,
                        'counts': counts_for_lifetime_calculations})
    else:
      raise ValueError(\
          f'Error while calculating wrap wround for num_channels={self.num_channels} to',
          f'{self.num_channels_lifetime_calculations}')

    # Generate list of photon arrival times
    # This differs from photon distribution time if the ideal distribution is oversampled.
    #   In this case self.photon_distribution represents the actual arrival time
    #   and self.measured_photon_arrival_times represents the recorded time channel
    self.measured_photon_arrival_times = np.repeat(self.time_channels, arr).tolist()

  def add_afterpulse(self):
    """Add a % of randomly distributed photons

    afterpulse_ratio is a fraction of total photons
    """
    num_photons = round(
        len(self.measured_photon_arrival_times)*self.simulation_parameters['afterpulse_ratio'])
    self.add_random_photons(num_photons)

  def add_random_photons(self, num):
    """Add num random photons"""
    if num>0:
      rand_photons = random.choices(self.time_channels, k = num)
      self.photon_distribution.extend(rand_photons)
      self.calc_population_counts()

  def add_dark_counts(self, range = (0.95, 1.05)):
    """Add Dark Counts"""
    photon_multiplier = random.uniform(range[0], range[1])
    photon_num = round(self.simulation_parameters['background_distribution']*photon_multiplier)
    self.add_random_photons(int(photon_num))

  def prf_conv(self, prf_path):
    #Load PRF
    mat = scipy.io.loadmat(prf_path)
    self.prf = list(mat['prf'][0])
    self.photon_distribution = \
      self.perform_convolution(self.photon_distribution, self.prf)
    self.calc_population_counts()

  def perform_convolution(self, a, b):
    """Perform Convolution"""
    # Calculate Cumulative Sum and Normalize
    cum_sum = np.cumsum(b)
    cum_sum /= cum_sum[-1]

    # Generate random numbers for each photon
    random_values = np.random.random(len(a))

    # Find random time channels
    bin_indices = np.searchsorted(cum_sum, random_values, side='right')
    time_vals = bin_indices * (self.time_range / self.num_channels)

    # Add to each photon arrival time
    a = np.array(a) + time_vals

    # Calculate Wrap-around
    time_lim = self.time_range
    a = np.where(a >= time_lim, a - time_lim, np.where(a < 0, a + time_lim, a))

    return a.tolist()

  def add_AF(self, AF_path, range = (0.95, 1.05)):
    """Add autofluorescence"""
    # Load AF
    mat = scipy.io.loadmat(AF_path)
    autofluorescence = np.array(mat['Autofluroescence_distribution'][0])

    # Sample Autofluorescence curve
    photon_multiplier = random.uniform(range[0], range[1])
    photon_num = round(self.simulation_parameters['autofluorescence_counts']*photon_multiplier)
    autofluorescence_photons = \
        np.random.choice(self.time_channels[:self.num_channels_lifetime_calculations],
                         size=photon_num,
                         p=autofluorescence / autofluorescence.sum())

    # Add to each photon arrival time
    self.photon_distribution.extend(autofluorescence_photons.tolist())

    # Recalculate population distribution
    self.calc_population_counts()

  def display_counts(self):
    """Display Counts"""
    plt.semilogy(self.counts_per_channel['time_channel'], self.counts_per_channel['counts'])
    plt.show()

  def dump_histogram(self, filepath):
    """Dump histogram to filepath"""
    dataframe = pd.DataFrame({'time_channel': self.counts_per_channel['time_channel'],
                              'counts': self.counts_per_channel['counts']})
    dataframe.to_csv(filepath)
    return dataframe

  def fit(self, terms, fixed = {}, verbose = False):
    """
    Fit the current photon population
    Args:
      terms: number of exponential terms
      fixed: Dictionary of fixed values, can fix tau or population based on which exponential term
              Eg. p1_tau or p1_amp. Can also fix constant term key = 'y0'
    """
    wWeights=np.array([1/np.sqrt(count) if count>0 else 1 for count in self.counts_per_channel['counts']])

    # Assign the model for fitting
    mod = None
    for i in range(terms):
      if mod is None:
        mod = Model(self.exp_model, independent_vars=['x', 'irf'], prefix=f'p{i+1}_')
      else:
        mod = mod + Model(self.exp_model, independent_vars=['x', 'irf'], prefix=f'p{i+1}_')

    # Add SHG term
    mod = mod + Model(self.shg_model, independent_vars=['x', 'irf'], prefix=f'shg_')

    # Add constant term
    mod = mod + Model(self.const_model)

    # Initialize the parameters 
    # If fixed, fill with fixed value
    # otherwise starting conditions are amp = 5000, tau = 1
    pars = mod.make_params(y0=INITIAL_Y0, shg_y0 = INITIAL_SHG)
    pars['shg_y0'].min = 0
    pars['y0'].min = 0
    for term in range(terms):
      if f"p{term+1}_amp" in fixed.keys():
        pars.add(f"p{term+1}_amp", value=fixed[f"p{term+1}_amp"])
      else:
        pars.add(f"p{term+1}_amp", value=5000, min = 0)
      if f"p{term+1}_tau" in fixed.keys():
        pars.add(f"p{term+1}_tau", value=fixed[f"p{term+1}_tau"])
      else:
        pars.add(f"p{term+1}_tau", value=1, min = 0)

    # Fix parameters
    for var in fixed.keys():
      pars[var].vary = False

    # fit this model with weights, initial parameters
    counts = self.counts_per_channel['counts']
    channels = self.counts_per_channel['time_channel']
    result = mod.fit(counts, params=pars,
                     weights=wWeights, method='leastsq', 
                     x=channels,
                     irf=self.prf)
    variable_fits = result.summary()['best_values']
    if verbose:
      print(result.fit_report())
      print('\nBest Fitting Parameters:')
      print(variable_fits)
      # plot results
      _, axs = \
        plt.subplots(2, 1, figsize=(8,9), gridspec_kw={'height_ratios': [2.5, 1]})
  
      axs[0].semilogy(self.counts_per_channel['time_channel'],
                      self.counts_per_channel['counts'], 'r-',
                      self.counts_per_channel['time_channel'],
                      result.best_fit,'b')
      axs[0].set_title('Histogram')
      axs[0].set_xlabel('Time (ns)')
      axs[0].set_ylabel('Counts')

      axs[1].plot(self.counts_per_channel['time_channel'],
                  result.residual)
      axs[1].set_xlabel('Time (ns)')
      axs[1].set_title('Residuals')
      plt.tight_layout()
      plt.show()

    # best_fit = pd.DataFrame({'Time Channel': self.counts_per_channel['time_channel'],
    #                          'Counts': result.best_fit})
    return variable_fits

  def calc_empirical_lifetime(self, channel_range = (37, 236)):
    """Calculate Empirical Lifetime.

    channel_range (tuple): [start, stop) index to use for lifetime calculation
                           Channel channel_range[0] will be time 0
    """
    start_time_channel = self.time_channels[channel_range[0]]
    end_time_channel = self.time_channels[channel_range[1]]

    # Use NumPy for filtering and calculations
    arrival_times = np.array(self.measured_photon_arrival_times)
    filtered_times = arrival_times[(arrival_times >= start_time_channel) & (arrival_times < end_time_channel)]
    adjusted_times = filtered_times - start_time_channel

    lifetime = np.mean(adjusted_times)
    print(f"Empirical Lifetime: {lifetime}")
    return lifetime

  def calc_fitted_lifetime(self, terms, fixed_variables = {}, verbose = False):
    """Calculates the fitted lifetime using (P1*t1^2+P2+t2^2...)/(P1*t1+p2*t2...)"""
    variable_fits = self.fit(terms, fixed = fixed_variables, verbose = verbose)

    num = 0
    denom = 0
    for term in range(1, terms+1):
      num += variable_fits[f"p{term}_amp"]*(variable_fits[f"p{term}_tau"]**2)
      denom += variable_fits[f"p{term}_amp"]*variable_fits[f"p{term}_tau"]

    print(f"Fitted Tau: {num/denom}")
    print('Fitting Population Fractions:')
    population_sum = sum([variable_fits[f"p{term}_amp"] for term in range(1, terms+1)])
    population_fractions = {'term': [], 'tau': [], 'fraction': []}
    for term in range(1, terms+1):
      print(f"  Population {term}: tau={variable_fits[f'p{term}_tau']}; frac = {variable_fits[f'p{term}_amp']/population_sum}")
      population_fractions['term'].append(term)
      population_fractions['tau'].append(variable_fits[f'p{term}_tau'])
      population_fractions['fraction'].append(variable_fits[f"p{term}_amp"]/population_sum)

    return num/denom, pd.DataFrame(population_fractions)

  # Exponential decay convolved with IRF
  def exp_model(self, x, tau, amp, irf):
    """Exponential Model"""
    ymodel=np.zeros(x.size) 
    ymodel = amp*np.exp(-(x)/tau)
    z=self.Convol(ymodel,irf)
    return z

  def const_model(self, x, y0):
    """Constant Model"""
    ymodel = np.zeros(x.size) 
    ymodel = np.add(ymodel, y0)
    return ymodel

  def shg_model(self, x, y0, irf):
    """SHG Model"""
    ymodel = np.zeros(x.size) 
    ymodel[0] = y0
    return self.Convol(ymodel,irf)

  # Convolution using fft (x and h of equal length)
  def Convol(self, x,h):
    """Convolution"""
    X=np.fft.fft(x)
    H=np.fft.fft(h)
    xch=np.real(np.fft.ifft(X*H))
    return xch
