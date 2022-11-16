import pandas as pd
import tkinter as tk
from tkinter import filedialog
from tkinter.filedialog import askopenfilename


class SaveOptions():
    def __init__(self, initialOptions):
        self.options = initialOptions
        self.root = tk.Tk()
        self.root.geometry("1000x700")  
        self.root.title("Choose Figures to Save")
        self.entries = self.make_form(self.root) 
        b1 = tk.Button(self.root, text='Update',
                        command=(lambda e=self.entries: self.fetch(e)))
        b1.grid(row = len(initialOptions)+2, column = 0)
        b2 = tk.Button(self.root, text='Load Data', 
                       command=(lambda r=self.root: self.load(r)))
        b2.grid(row = len(initialOptions)+2, column = 1)
        b3 = tk.Button(self.root, text='Save Settings As', command=self.save)
        b3.grid(row = len(initialOptions)+2, column = 2)
        b4 = tk.Button(self.root, text='Close', command=self.root.destroy)
        b4.grid(row = len(initialOptions)+2, column = 3) 
        self.root.lift()
        tk.mainloop()
        #self.root.destroy()

    def make_form(self, root):
        entries = []
        option_idx = 1
        for option in self.options:
            lab = tk.Label(root, text=option, anchor='w')
            lab.grid(row = option_idx, column = 0)
            var = tk.IntVar()
            c1 = tk.Checkbutton(root, variable = var)
            if self.options[option]:
                c1.select()
            c1.grid(row = option_idx, column = 1)
            entries.append((option, var))
            option_idx+=1
        return entries

    def fetch(self, entries):
        for entry in entries:
            option = entry[0]
            val  = entry[1].get()
            print('%s: "%s"' % (option, val)) 
            self.options[option] = val


    def save(self):
        f = filedialog.asksaveasfile(initialfile = 'SaveOptions.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        
        with open(f.name, 'w') as file:
            for key in self.options.keys():
                file.write("%s, %s\n" % (key, self.options[key]))
    
    def load(self, root):
        path = askopenfilename()
        df = pd.read_csv(path, header = None)
        new_params = dict(zip(df[0], df[1]))
        self.root.destroy()
        del self.root
        self.__init__ (new_params)
