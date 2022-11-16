import tkinter as tk
import os
import pandas as pd
from tkinter import filedialog
from tkinter.filedialog import askopenfilename


class DataParameters():
    def __init__(self, initialParameters, paths):
        self.initialParameters = initialParameters
        self.paths = paths
        fields = list(initialParameters.columns)
        fields.remove('Experiment')
        self.fields = fields
        self.sets = list(initialParameters['Experiment'])
        self.root = tk.Tk()
        self.root.geometry("1000x500")  
        self.root.title("Enter Experiment Parameters")
        self.attributes = [None]*len(self.sets)
        self.entries = [None]*len(self.sets)
        for set in range(len(self.sets)):
            self.entries[set] = self.make_form(self.root, self.fields, set, self.sets[set])  
        b1 = tk.Button(self.root, text='Update',
                        command=(lambda e=self.entries: self.fetch(e)))
        b1.grid(row = len(self.sets)+2, column = len(self.fields)-3)
        b2 = tk.Button(self.root, text='Load Data', 
                        command=(lambda r=self.root: self.load(r)))
        b2.grid(row = len(self.sets)+2, column = len(self.fields)-2)
        b3 = tk.Button(self.root, text='Save Settings As', command=self.save)
        b3.grid(row = len(self.sets)+2, column = len(self.fields)-1)
        b4 = tk.Button(self.root, text='Close', command=self.root.destroy)
        b4.grid(row = len(self.sets)+2, column = len(self.fields))
        self.root.lift()
        tk.mainloop()
        #self.root.destroy()

    def fetch(self, dataset):
        list = [None]*len(dataset)
        for entries in dataset:
            dict = {}
            for entry in entries:
                field = entry[0]
                text  = entry[1].get()
                print('%s: "%s"' % (field, text)) 
                dict[field] = text
            dict['Path'] = self.paths[dataset.index(entries)]
            dict['Experiment'] = self.sets[dataset.index(entries)]
            list[dataset.index(entries)] = dict
        self.attributes = pd.DataFrame.from_dict(list)


    def make_form(self, root, fields, setnum, setID):
        entries = []
        for field in fields:
            #row = tk.Frame(root)
            if setnum == 0:
                lab = tk.Label(root, width=15, text=field, anchor='w')
                lab.grid(row = 1, column = fields.index(field)+1)

            #set_lab = tk.Label(root, width=10, text=setID, anchor='w')
            set_lab = tk.Label(root, text=setID, anchor='w')
            set_lab.grid(row = setnum+2, column = 0)
            ent = tk.Entry(root)
            ent.insert(tk.END, self.initialParameters[field][setnum])
            ent.grid(row = setnum+2, column = fields.index(field)+1)
            
            entries.append((field, ent))
        return entries

    def save(self):
        f = filedialog.asksaveasfile(initialfile = 'DataParameters.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        self.attributes.to_csv(f.name, index = False)

    def load(self, root):
        path = askopenfilename()
        df = pd.read_csv(path)
        data_paths = self.paths
        self.root.destroy()
        self.__init__ (df, data_paths)