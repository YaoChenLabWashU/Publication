"""Misc"""
import importlib.resources

def get_resource_path(package, resource):
  """Gets the file path of a resource within a package."""
  return str(importlib.resources.files(package) / resource)
