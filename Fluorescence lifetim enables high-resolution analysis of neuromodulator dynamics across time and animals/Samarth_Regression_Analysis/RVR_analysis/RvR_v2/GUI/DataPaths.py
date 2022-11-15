import tkinter as tk
import os
import pandas as pd
from tkinter import filedialog


class DataPaths():
    def __init__(self):
        self.root = tk.Tk()
        self.root.withdraw()
        self.root.lift()
        path = filedialog.askdirectory()
        self.expDir = os.listdir(path)
        self.experiment_paths = [os.path.join(path, exp).replace('\\', "/") for exp in self.expDir]
        self.clean_paths()
        self.root.deiconify()
        self.root.destroy()
    def clean_paths(self):
        idx = [self.experiment_paths.index(item) for item in self.experiment_paths if os.path.isdir(item) if self.expDir[self.experiment_paths.index(item)].lower() != 'analyzed']
        self.expDir = [item for item in self.expDir if self.expDir.index(item) in idx]
        self.experiment_paths = [item for item in self.experiment_paths if self.experiment_paths.index(item) in idx]

