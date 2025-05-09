"""
Create population of lifetimes based on ideal bi-exp decay

Assumptions:
  Convolution is distributive
  512 channels spanning 25 ns
  After IRF convolution, the final simulated histogram will be 256 channels spanning 12.5 channels
  PRF has same number of time channels
"""
from collections import namedtuple
import math
import numpy as np

population = namedtuple('population', ['fraction', 'tau'])

class IdealPhotonPopulation:
  def __init__(self, num_photons_peak, populations,
               time_range = 12.5, num_channels = 256) -> None:
    """
    Ideal photon population from a double exponential decay

    Args:
      num_photons_peak (int): Total photons at the peak
      populations (list): List of populations. Represents decay terms
      time_range (float): time range
      num_channels (int): number of time channels
      time_channels (arr): list of time channels. Assigned time corresponds to 
                           left channel edge, NOT channel center.
    """
    self.num_photons_peak = num_photons_peak
    self.populations = populations
    self.time_range = time_range
    self.num_channels = num_channels
    self.time_channel_edges = np.linspace(0, self.time_range, self.num_channels+1)
    self.time_channel_starts = self.time_channel_edges[:-1]
    self.time_channel_centers = \
      [(time + self.time_channel_edges[idx+1])/2 for idx, time in enumerate(self.time_channel_edges[:-1])]
    self.check_populations()

    self.photon_counts = None
    self.arrival_times = None
    self.simulate_population()

  def simulate_population(self):
    """Simulate the ideal population"""
    # Generate ideal exponential decay
    self.photon_counts = np.zeros(self.num_channels)
    for term in self.populations:
      term_photons = [term.fraction*math.exp(-time/term.tau) for time in self.time_channel_starts]
      self.photon_counts = np.add(self.photon_counts, term_photons)

  def check_populations(self):
    """Make sure the fractions add to 1"""
    if sum([population.fraction for population in self.populations]) != 1:
      raise ValueError('Population fractions must add up to 1')
