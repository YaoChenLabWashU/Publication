from sre_constants import ANY_ALL
import tkinter as tk
import os
import pandas as pd
from tkinter import filedialog
from tkinter.filedialog import askopenfilename
import csv


class AnalysisParameters():
    def __init__(self, fields):
        self.fields = fields
        self.root = tk.Tk()
        self.root.geometry("1000x700")  
        self.root.title("Enter Analysis Parameters")
        self.entries = self.make_form(self.root)  
        b1 = tk.Button(self.root, text='Update',
                        command=(lambda e=self.entries: self.fetch(e)))
        b1.grid(row = len(fields)+1, column = 0)
        b2 = tk.Button(self.root, text='Load Data', 
                       command=(lambda r=self.root: self.load(r)))
        b2.grid(row = len(fields)+1, column = 1)
        b3 = tk.Button(self.root, text='Save Settings As', command=self.save)
        b3.grid(row = len(fields)+1, column = 2)
        b4 = tk.Button(self.root, text='Close', command=self.root.destroy)
        b4.grid(row = len(fields)+1, column = 3)
        self.root.lift()
        tk.mainloop()
        #self.root.destroy()

    def fetch(self, entries):
        for entry in entries:
            field = entry[0]
            text  = entry[1].get()
            print('%s: "%s"' % (field, text)) 
            try:
                self.fields[field] = float(text)
            except:
                self.fields[field] = text
            


    def make_form(self, root):
        entries = []
        field_idx = 1
        for field in self.fields:
            lab = tk.Label(root, text=field, anchor='w')
            lab.grid(row = field_idx, column = 0)
            ent = tk.Entry(root)
            ent.insert(tk.END, self.fields[field])
            ent.grid(row = field_idx, column = 1)
            entries.append((field, ent))
            field_idx+=1
        return entries

    def save(self):
        f = filedialog.asksaveasfile(initialfile = 'AnalysisParameters.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        
        with open(f.name, 'w') as file:
            for key in self.fields.keys():
                file.write("%s, %s\n" % (key, self.fields[key]))
    
    def load(self, root):
        path = askopenfilename()
        df = pd.read_csv(path, header = None)
        new_params = dict(zip(df[0], df[1]))
        root.destroy()
        del root
        self.__init__ (new_params)

