"""Used to generate example input .json file"""
import json
from lib.misc import get_resource_path

def main():
  data = {
    'sensor_parameters': [{'tau': 2.14, 'population': 0.9},
                          {'tau': 0.69, 'population': 0.1}],
    'sensor_counts': 300000,
    'autofluorescence_counts': 20000,
    'afterpulse_ratio': 0.01,
    'background_distribution': 10000
  }

  with open(get_resource_path('data', 'example_input.json'), 'w') as file:
    json.dump(data, file)

if __name__ == '__main__':
  main()
