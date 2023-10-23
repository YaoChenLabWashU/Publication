from cmath import exp
from re import X
import tkinter as tk
import pandas as pd
from tkinter import N, NW, SW, W, filedialog
from tkinter import ttk
import numpy as np
import matplotlib.pyplot as plt
import statistics
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import (
    FigureCanvasTkAgg, NavigationToolbar2Tk)


class OutputDisplay():
    def __init__(self, datasets, dataParams):
        self.datasets = datasets
        self.root = tk.Tk()

        self.height = self.root.winfo_screenheight()
        self.width = self.root.winfo_screenwidth()
        self.root.geometry(f'{int(self.width*0.95)}x{int(self.height*0.87)}')  
        self.root.title("Results")
        
        self.dataParams = dataParams

        self.dataChoice = tk.StringVar()
        self.dataOptions = [dataset.dataParameters['Basename'] for dataset in self.datasets]
        self.dataOptions.append('Grouped')
        self.dataChoice.set(self.dataOptions[0])
        dataDrop = tk.OptionMenu( self.root , self.dataChoice , *self.dataOptions )
        dataDrop.pack(side = 'top')
    
        self.figureChoice = tk.StringVar()
        figureOptions = ["Raw Data (stacked)",
                    "Raw Data (overlay)",
                    "Raw Data (overlay + indicators)",
                    "Highpass (stacked)",
                    "Highpass (overlay)",
                    "Highpass (overlay + indicators)",
                    "Lowpass (stacked)",
                    "Lowpass (overlay)",
                    "Lowpass (overlay + indicators)",
                    "Running Definition",
                    "Baseline Definition", 
                    "Scatter Plot (Raw)",
                    "Scatter Plot (Highpass)", 
                    "Scatter Plot (Lowpass)",
                    "Box Plot (Raw)",
                    "Box Plot (Highpass)",
                    "Box Plot (Lowpass)", 
                    "ETA"]
        self.figureChoice.set( figureOptions[0] )
        figureDrop = tk.OptionMenu( self.root , self.figureChoice , *figureOptions )
        figureDrop.pack(side = 'top')


        button1 = tk.Button( self.root , text = "Refresh" , command = self.show ).pack(side = 'top')
        button2 = tk.Button( self.root , text = "Grab Data" , command = self.grab_data ).pack(side = 'bottom')
        button3 = tk.Button( self.root , text = "Save Parameters" , command = self.save_parameters ).pack(side = 'bottom')
        
        # Execute tkinter
        self.root.lift()
        self.root.mainloop()
        self.root.destroy()

    def save_parameters(self):
        f = filedialog.asksaveasfile(initialfile = 'dataParameters_ALL.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        self.dataParams.to_csv(f.name, index = False)
        f = filedialog.asksaveasfile(initialfile = 'analysisParameters_ALL.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        self.datasets[0].analysisParameters
        with open(f.name, 'w') as file:
            for key in self.datasets[0].analysisParameters.keys():
                file.write("%s, %s\n" % (key, self.datasets[0].analysisParameters[key]))
    
    def grab_data(self):
        try:
            f = filedialog.asksaveasfile(initialfile = self.data.dataParameters['Basename']+self.graph +'.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])
        except:
            f = filedialog.asksaveasfile(initialfile = self.graph +'_grouped.csv', defaultextension=".csv",filetypes=[("CSV","*.csv")])

        self.dataOut.to_csv(f.name, index = False)

    def show(self):
        x = np.arange(1,10)

        if self.dataChoice.get() == 'Grouped':
            self.data = self.dataChoice.get()
        else:
            self.data = self.datasets[self.dataOptions.index(self.dataChoice.get())]
        self.graph = self.figureChoice.get()
        self.clear_all()

        if self.graph == "Raw Data (stacked)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotStackData(self.data.speedTimeBinned, self.data.speedBinned, 
                                self.data.rawData['Time'].tolist(), self.data.rawData['Intensity'].tolist(), 
                                self.data.rawData['Time'].tolist(), self.data.rawData['Fit Lifetime'].tolist(), 
                                self.data.rawData['Time'].tolist(), self.data.rawData['Empirical Lifetime'].tolist())
        elif self.graph == "Raw Data (overlay)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotOverlayPanel(self.data.speedTimeBinned, self.data.speedBinned, 'Speed (cm/s)', 
                                    [self.data.rawData['Time'].tolist(), self.data.rawData['Time'].tolist(),  self.data.rawData['Time'].tolist()],
                                    [self.data.rawData['Intensity'].tolist(), self.data.rawData['Fit Lifetime'].tolist(), self.data.rawData['Empirical Lifetime'].tolist()], 
                                    ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'])

        elif self.graph == "Raw Data (overlay + indicators)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotIndicatorPanel(self.data.speedTimeBinned, self.data.baselineDef, self.data.runningDef, 
                                        [self.data.rawData['Time'].tolist(), self.data.rawData['Time'].tolist(),  self.data.rawData['Time'].tolist()],
                                        [self.data.rawData['Intensity'].tolist(), self.data.rawData['Fit Lifetime'].tolist(), self.data.rawData['Empirical Lifetime'].tolist()],
                                        ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'], 
                                        [self.data.runningDict['Intensity'], self.data.runningDict['Fit Lifetime'], self.data.runningDict['Empirical Lifetime']],
                                        [self.data.baselineDict['Intensity'], self.data.baselineDict['Fit Lifetime'], self.data.baselineDict['Empirical Lifetime']])

        elif self.graph == "Highpass (stacked)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotStackData(self.data.speedTimeBinned, self.data.speedBinned, 
                                self.data.AC_Data['Time'].tolist(), self.data.AC_Data['Intensity'].tolist(), 
                                self.data.AC_Data['Time'].tolist(), self.data.AC_Data['Fit Lifetime'].tolist(), 
                                self.data.AC_Data['Time'].tolist(), self.data.AC_Data['Empirical Lifetime'].tolist())
        elif self.graph == "Highpass (overlay)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotOverlayPanel(self.data.speedTimeBinned, self.data.speedBinned, 'Speed (cm/s)', 
                                    [self.data.AC_Data['Time'].tolist(), self.data.AC_Data['Time'].tolist(),  self.data.AC_Data['Time'].tolist()],
                                    [self.data.AC_Data['Intensity'].tolist(), self.data.AC_Data['Fit Lifetime'].tolist(), self.data.AC_Data['Empirical Lifetime'].tolist()], 
                                    ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'])
        elif self.graph == "Highpass (overlay + indicators)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotIndicatorPanel(self.data.speedTimeBinned, self.data.baselineDef, self.data.runningDef, 
                                        [self.data.AC_Data['Time'].tolist(), self.data.AC_Data['Time'].tolist(),  self.data.AC_Data['Time'].tolist()],
                                        [self.data.AC_Data['Intensity'].tolist(), self.data.AC_Data['Fit Lifetime'].tolist(), self.data.AC_Data['Empirical Lifetime'].tolist()],
                                        ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'], 
                                        [self.data.runningDict['IntensityAC'], self.data.runningDict['Fit LifetimeAC'], self.data.runningDict['Empirical LifetimeAC']],
                                        [self.data.baselineDict['IntensityAC'], self.data.baselineDict['Fit LifetimeAC'], self.data.baselineDict['Empirical LifetimeAC']])
        elif self.graph == "Lowpass (stacked)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotStackData(self.data.speedTimeBinned, self.data.speedBinned, 
                                self.data.DC_Data['Time'].tolist(), self.data.DC_Data['Intensity'].tolist(), 
                                self.data.DC_Data['Time'].tolist(), self.data.DC_Data['Fit Lifetime'].tolist(), 
                                self.data.DC_Data['Time'].tolist(), self.data.DC_Data['Empirical Lifetime'].tolist())
        elif self.graph == "Lowpass (overlay)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotOverlayPanel(self.data.speedTimeBinned, self.data.speedBinned, 'Speed (cm/s)', 
                                    [self.data.DC_Data['Time'].tolist(), self.data.DC_Data['Time'].tolist(),  self.data.DC_Data['Time'].tolist()],
                                    [self.data.DC_Data['Intensity'].tolist(), self.data.DC_Data['Fit Lifetime'].tolist(), self.data.DC_Data['Empirical Lifetime'].tolist()], 
                                    ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'])
        elif self.graph == "Lowpass (overlay + indicators)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotIndicatorPanel(self.data.speedTimeBinned, self.data.baselineDef, self.data.runningDef, 
                                        [self.data.DC_Data['Time'].tolist(), self.data.DC_Data['Time'].tolist(),  self.data.DC_Data['Time'].tolist()],
                                        [self.data.DC_Data['Intensity'].tolist(), self.data.DC_Data['Fit Lifetime'].tolist(), self.data.DC_Data['Empirical Lifetime'].tolist()],
                                        ['Intensity (Counts/s)', 'Fit Lifetime (ns)', 'Empirical Lifetime (ns)'], 
                                        [self.data.runningDict['IntensityDC'], self.data.runningDict['Fit LifetimeDC'], self.data.runningDict['Empirical LifetimeDC']],
                                        [self.data.baselineDict['IntensityDC'], self.data.baselineDict['Fit LifetimeDC'], self.data.baselineDict['Empirical LifetimeDC']])
        elif self.graph == "Running Definition":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotOverlayData(self.data.speedTimeBinned, self.data.speedBinned, 'Speed (cm/s)', self.data.speedTimeBinned, self.data.runningDef, 'Running Definition')
        elif self.graph == "Baseline Definition":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.plotOverlayData(self.data.speedTimeBinned, self.data.speedBinned, 'Speed (cm/s)',self. data.speedTimeBinned, self.data.baselineDef, 'Baseline Definition')
        elif self.graph == "Scatter Plot (Raw)":
            if self.data =='Grouped':
                self.data = self.group_scatter_data('')
                self.plotScattersGrouped(self.data)
            else:
                self.plotScatters(self.data, '')
        elif self.graph == "Scatter Plot (Highpass)":
            if self.data =='Grouped':
                self.data = self.group_scatter_data('AC')
                self.plotScattersGrouped(self.data)
            else:
                self.plotScatters(self.data, 'AC')
        elif self.graph == "Scatter Plot (Lowpass)":
            if self.data =='Grouped':
                self.data = self.group_scatter_data('DC')
                self.plotScattersGrouped(self.data)
            else:
                self.plotScatters(self.data, 'DC')
        elif self.graph == "Box Plot (Raw)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.boxPlots(self.data, '')
        elif self.graph == "Box Plot (Highpass)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.boxPlots(self.data, 'AC')
        elif self.graph == "Box Plot (Lowpass)":
            if self.data =='Grouped':
                print('Not Applicable for Grouped Data')
            else:
                self.boxPlots(self.data, 'DC')
        elif self.graph == "ETA":
            if self.data =='Grouped':
                self.combinedETA = self.combine_eta()
                self.plotOverlayPanel(self.combinedETA['Time'], self.combinedETA['Speed'], 'Speed cm/s',
                                      [self.combinedETA['Time'], self.combinedETA['Time'], self.combinedETA['Time']],
                                      [self.combinedETA['Intensity'], self.combinedETA['Fit Lifetime'], self.combinedETA['Empirical Lifetime']], 
                                      ['Intensity', 'Fit Lifetime', 'Empirical Lifetime'],
                                      [self.combinedETA['Speed STDEV'], self.combinedETA['Intensity STDEV'], self.combinedETA['Fit Lifetime STDEV'], self.combinedETA['Empirical Lifetime STDEV']])
            else:
                self.plotOverlayPanel(self.data.ETA['Speed Bins'], self.data.ETA['Speed'], 'Speed cm/s',
                                    [self.data.ETA['FLP Bins'], self.data.ETA['FLP Bins'], self.data.ETA['FLP Bins']],
                                    [self.data.ETA['Intensity'], self.data.ETA['Fit Lifetime'], self.data.ETA['Empirical Lifetime']],
                                    ['Intensity', 'Fit Lifetime', 'Empirical Lifetime'], 
                                    [self.data.ETA['Speed STDEV'], self.data.ETA['Intensity STDEV'], self.data.ETA['Fit Lifetime STDEV'], self.data.ETA['Empirical Lifetime STDEV']],
                                    [self.data.ETA_Windows['Speed Time'], self.data.ETA_Windows['Speed'], self.data.ETA_Windows['Intensity'], 
                                     self.data.ETA_Windows['Fit Lifetime'], self.data.ETA_Windows['Empirical Lifetime']])
        else:
            pass


    #Takes in data and generates 4 plots stacked with speed, intensity, empLFT, fitLFT over time
    def plotStackData(self, x1, y1, x2, y2, x3, y3, x4, y4):  
        self.frame = [None]
        self.canvas = [None]
        self.fig = [None]

        self.fig[0], (ax1, ax2, ax3, ax4) = plt.subplots(4, figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.85))
        ax1.plot(x1, y1, color='black')
        ax1.set_ylabel('Speed (cm/s)', fontsize=9)
        ax1.set_xlim(0,max(x1[-1], x2[-1],  x3[-1], x4[-1]))
        ax2.plot(x2, y2, color='black')
        ax2.set_ylabel('Intensity (Counts/s)', fontsize=9)
        ax2.set_xlim(0,max(x1[-1], x2[-1], x3[-1], x4[-1]))
        ax3.plot(x3, y3, color='black')
        ax3.set_ylabel('Fit Lifetime (ns)', fontsize=9)
        ax3.set_xlim(0,max(x1[-1], x2[-1], x3[-1], x4[-1]))
        ax4.plot(x4, y4, color='black')
        ax4.set_ylabel('Empirical Lifetime (ns)', fontsize=9)
        ax4.set_xlim(0,max(x1[-1], x2[-1], x3[-1], x4[-1]))
        plt.xlabel('Time (Seconds)', fontsize=12)
        self.fig[0].tight_layout()

        data_out = {'Speed Time':x1,
                    'Speed': y1, 
                    'FLP Time': x2,
                    'Intensity':y2, 
                    'Fit Lifetime': y3, 
                    'Empirical Lifetime': y4}
        self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T


        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        self.canvas[0] = FigureCanvasTkAgg(self.fig[0], master = self.frame[0])  
        self.canvas[0].draw()
        self.toolbar = NavigationToolbar2Tk(self.canvas[0], self.frame[0])
        self.toolbar.update()

        self.canvas[0].get_tk_widget().pack()


    def plotIndicatorPanel(self, x_ref, y_baseline, y_running, x_all, y_all, y_all_label, runningPTS, baselinePTS):
        self.frame = [None]*len(y_all_label)
        self.canvas = [None]*len(y_all_label)
        self.fig = [None]*len(y_all_label)

        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        data_out = {'Speed Time': x_ref,
                    'Running Definition': y_running,
                    'Baseline Definition': y_baseline}
        
        for subplot in range(len(y_all_label)):
            data_out['Time '+ y_all_label[subplot]] = x_all[subplot]
            data_out[y_all_label[subplot]] = y_all[subplot]
            self.fig[subplot], ax1 = plt.subplots(figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.25))
            color = 'tab:red'
            plt.xlim(0,max(x_ref[-1], x_all[subplot][-1]))

            ax1.set_xlabel('time (s)', fontsize=12)
            ax1.set_ylabel('State', color=color, fontsize=9)
            ax1.title.set_text(y_all_label[subplot])
            ax1.plot(x_ref, y_baseline, color = 'black', label = 'Resting')
            ax1.plot(x_ref, y_running, color = 'red', label = 'Running')
            ax1.tick_params(axis='y', labelcolor=color)

            ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
            color = 'tab:blue'
            ax2.set_ylabel(y_all_label[subplot], color=color, fontsize=9)  
            ax2.plot(x_all[subplot], y_all[subplot], color=color, label = y_all_label[subplot])
            ax2.tick_params(axis='y', labelcolor=color)

            baselineDataIDX = self.extract_scatter_points(baselinePTS[subplot], self.data.analysisParameters['Baseline Analysis Method'])

            scatter_x = [x_all[subplot][i] for i in baselineDataIDX]
            scatter_y = [y_all[subplot][i] for i in baselineDataIDX]
            ax2.scatter(scatter_x, scatter_y, c = 'black')
            data_out[y_all_label[subplot] + ' baseline Time points'] = scatter_x
            data_out[y_all_label[subplot] + ' baseline points'] = scatter_y

            runningDataIDX = self.extract_scatter_points(runningPTS[subplot], self.data.analysisParameters['Running Analysis Method'])

            scatter_x = [x_all[subplot][i] for i in runningDataIDX]
            scatter_y = [y_all[subplot][i] for i in runningDataIDX]
            ax2.scatter(scatter_x, scatter_y, c = 'red')
            data_out[y_all_label[subplot] + ' running time points'] = scatter_x
            data_out[y_all_label[subplot] + ' running points'] = scatter_y

            self.fig[subplot].legend(loc="upper left",  fontsize=6)
            self.fig[subplot].tight_layout()  # otherwise the right y-label is slightly clipped

            self.frame[subplot] = tk.Frame(self.root)
            self.frame[subplot].pack()
            self.canvas[subplot] = FigureCanvasTkAgg(self.fig[subplot], master = self.frame[subplot])  
            self.canvas[subplot].draw()

            
            self.canvas[subplot].get_tk_widget().pack()
            toolbar = NavigationToolbar2Tk(self.canvas[subplot],
                                        self.frame[subplot])
            toolbar.update()
            self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T




        
    def plotOverlayPanel(self, x_ref, y_ref, y_ref_label, x_all, y_all, y_all_label, outputVars = 0, outputWindows = 0):
        self.frame = [None]*len(y_all_label)

        self.canvas = [None]*len(y_all_label)
        self.fig = [None]*len(y_all_label)
        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        data_out = {'Speed Time': x_ref,
                    y_ref_label: y_ref}
        if outputVars!=0:
            data_out[y_ref_label + ' STDEV'] = outputVars[0]    
        
        for subplot in range(len(y_all_label)):
            data_out['Time '+ y_all_label[subplot]] = x_all[subplot]
            data_out[y_all_label[subplot]] = y_all[subplot]
            if outputVars !=0:
                data_out[y_all_label[subplot] + ' STDEV'] = outputVars[subplot+1]
            else:
                pass

            self.fig[subplot], ax1 = plt.subplots(figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.25))
            color = 'tab:red'
            plt.xlim(0,max(x_ref[-1], x_all[subplot][-1]))
            ax1.set_xlabel('time (s)', fontsize=12)
            ax1.set_ylabel(y_ref_label, color=color, fontsize=9)
            ax1.title.set_text(y_all_label[subplot])
            ax1.plot(x_ref, y_ref, color=color, label = y_ref_label)
            ax1.tick_params(axis='y', labelcolor=color)
            ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
            color = 'tab:blue'
            ax2.set_ylabel(y_all_label[subplot], color=color, fontsize=9)  
            ax2.plot(x_all[subplot], y_all[subplot], color=color, label = y_all_label[subplot])
            ax2.tick_params(axis='y', labelcolor=color)
            self.fig[subplot].legend(loc="upper left",  fontsize=6)
        
            self.fig[subplot].tight_layout()  # otherwise the right y-label is slightly clipped

            self.frame[subplot] = tk.Frame(self.root)
            self.frame[subplot].pack()
            self.canvas[subplot] = FigureCanvasTkAgg(self.fig[subplot], master = self.frame[subplot])  
            self.canvas[subplot].draw()

            
            self.canvas[subplot].get_tk_widget().pack()
            toolbar = NavigationToolbar2Tk(self.canvas[subplot],
                                        self.frame[subplot])
            toolbar.update()

        if outputWindows!=0:
            for trace in range(len(outputWindows[0])):
                data_out['Speed Trace ' + str(trace)] = outputWindows[1][trace]
                data_out['Speed Time Trace ' + str(trace)] = outputWindows[0][trace]
                for subplot in range(len(y_all_label)):
                    data_out[y_all_label[subplot] + ' Trace ' + str(trace)] = outputWindows[subplot+2][trace]
        else:
            pass
        self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T

            

    def plotOverlayData(self, x1, y1, y1_label, x2, y2, y2_label):
        self.frame = [None]
        self.canvas = [None]
        self.fig = [None]

        self.fig[0], ax1 = plt.subplots(figsize=(self.root.winfo_width()/50, 3))
        color = 'tab:red'
        plt.xlim(0,max(x1[-1], x2[-1]))
        ax1.set_xlabel('time (s)', fontsize=12)
        ax1.set_ylabel(y1_label, color=color, fontsize=12)
        ax1.title.set_text(y2_label)
        ax1.plot(x1, y1, color=color, label = y1_label)
        ax1.tick_params(axis='y', labelcolor=color)
        ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
        color = 'tab:blue'
        ax2.set_ylabel(y2_label, color=color, fontsize=12)  
        ax2.plot(x2, y2, color=color, label = y2_label)
        ax2.tick_params(axis='y', labelcolor=color)
        self.fig[0].legend(loc="upper left", bbox_to_anchor=(0.05, 0.9), fontsize=6)
        self.fig[0].tight_layout()

        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()
        self.canvas[0] = FigureCanvasTkAgg(self.fig[0], master = self.frame[0])  
        self.canvas[0].draw()
        
        toolbar = NavigationToolbar2Tk(self.canvas[0],
                                    self.frame[0])
        toolbar.update()
        
        
        self.canvas[0].get_tk_widget().pack()
        self.scroll_x = tk.Scrollbar(self.frame[0], orient="horizontal", command=self.canvas[0].get_tk_widget().xview)
        self.scroll_x.pack()
        data_out = {'Time ' + y1_label :x1,
                    y1_label: y1, 
                    'Time ' + y2_label: x2,
                    y2_label:y2}
        self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T

    def clear_all(self):
        if hasattr(self, 'fig'):
            for frame in self.frame:
                frame.pack_forget()
                frame.destroy()


    def plotScatters(self, data, type):  
        self.frame = [None]
        self.canvas = [None]
        self.fig = [None]
        self.fig[0], ax = plt.subplots(1,3, figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.5))
        i = 0
        data_out = {}
        for col in data.rawData:
            if col != 'Time':
                baselineTemp = self.extract_scatter_data(data.baselineDict[col+type], data.analysisParameters['Baseline Analysis Method'])
                runningTemp = self.extract_scatter_data(data.runningDict[col+type], data.analysisParameters['Running Analysis Method'])
                resting = [0]*len(baselineTemp)
                ax[i].scatter(data.maxSpeeds, runningTemp, c = 'black')
                ax[i].scatter(resting, baselineTemp, c = 'black')
                ax[i].title.set_text(col)
                if col == 'Intensity':
                    y = 'Intensity (çounts/s)'
                else:
                    y = col + ' (ns)'
                ax[i].set(xlabel = 'Speed (cm/s)', ylabel = y)
                data_out['speed_' + 'running_'+ col] = data.maxSpeeds
                data_out['running_'+ col] = runningTemp
                data_out['speed_' + 'resting_'+ col] = resting
                data_out['resting_'+ col] = baselineTemp
                i+=1
        self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T
        self.fig[0].tight_layout()
        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        self.canvas[0] = FigureCanvasTkAgg(self.fig[0], master = self.frame[0])  
        self.canvas[0].draw()
        self.toolbar = NavigationToolbar2Tk(self.canvas[0], self.frame[0])
        self.toolbar.update()

        self.canvas[0].get_tk_widget().pack()

    def extract_scatter_data(self, data, method):
        dataExtracted = []
        for point in data:
            if method == 'Max':
                dataExtracted.append(max([point[0][1], point[1][1], point[2][1]]))
            elif method == 'Median':
                if len(point)==1:
                    dataExtracted.append(point[0][1])
                else:
                    dataExtracted.append((point[0][1] + point[1][1])/2)            
        return dataExtracted

    def extract_scatter_points(self, data, method):
        dataExtracted = []
        for point in data:
            if method == 'Max':
                dataExtracted.extend([point[0][0], point[1][0], point[2][0]])
            elif method == 'Median':
                if len(point)==1:
                    dataExtracted.extend([point[0][0]])
                else:
                    dataExtracted.extend([point[0][0], point[1][0]])
        return dataExtracted

    def boxPlots(self, data, dtype):
        self.frame = [None]
        self.canvas = [None]
        self.fig = [None]
        self.fig[0], ax = plt.subplots(1,3, figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.5))
        i = 0
        data_out = {}
        for col in data.rawData:
            if col != 'Time':
                baselineTemp = self.extract_scatter_data(data.baselineDict[col+dtype], data.analysisParameters['Baseline Analysis Method'])
                runningTemp = self.extract_scatter_data(data.runningDict[col+dtype], data.analysisParameters['Running Analysis Method'])
                ax[i].boxplot([baselineTemp, runningTemp])
                ax[i].title.set_text(col)
                if col == 'Intensity':
                    y = 'Intensity (çounts/s)'
                else:
                    y = col + ' (ns)'
                ax[i].set(xlabel = 'Speed (cm/s)', ylabel = y)
                data_out['running_'+ col] = runningTemp
                data_out['resting_'+ col] = baselineTemp
                i+=1

        self.dataOut = pd.DataFrame.from_dict(data_out, orient = 'index').T
        self.fig[0].tight_layout()
        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        self.canvas[0] = FigureCanvasTkAgg(self.fig[0], master = self.frame[0])  
        self.canvas[0].draw()
        self.toolbar = NavigationToolbar2Tk(self.canvas[0], self.frame[0])
        self.toolbar.update()

        self.canvas[0].get_tk_widget().pack()


    def group_scatter_data(self, dtype):
        data_out = {'Dataset':[], 'Mouse ID':[], 'Laser':[],
                    'Speed': [], 'Intensity':[], 'Fit Lifetime':[], 'Empirical Lifetime':[]}

        for dataset in self.datasets:
            data_out['Speed']
            for col in dataset.rawData:
                if col != 'Time':
                    baselineTemp = self.extract_scatter_data(dataset.baselineDict[col+dtype], dataset.analysisParameters['Baseline Analysis Method'])
                    runningTemp = self.extract_scatter_data(dataset.runningDict[col+dtype], dataset.analysisParameters['Running Analysis Method'])
                    resting = [0]*len(baselineTemp)
                    runningSpeeds = dataset.maxSpeeds

                    data_out[col].extend(baselineTemp)
                    data_out[col].extend(runningTemp)
            data_out['Speed'].extend(resting)
            data_out['Speed'].extend(runningSpeeds)
            data_out['Dataset'].extend([dataset.dataParameters['Basename']]*(len(resting)+len(runningSpeeds)))
            data_out['Mouse ID'].extend([dataset.dataParameters['Mouse ID']]*(len(resting)+len(runningSpeeds)))
            data_out['Laser'].extend([dataset.dataParameters['Laser Power']]*(len(resting)+len(runningSpeeds)))
        return data_out

    def plotScattersGrouped(self, data):
        self.frame = [None]
        self.canvas = [None]
        self.fig = [None]
        self.fig[0], ax = plt.subplots(1,3, figsize=(self.root.winfo_width()/100, (self.root.winfo_height()/100)*0.5))
        i = 0
        for key in ['Intensity', 'Fit Lifetime', 'Empirical Lifetime']:
            ax[i].scatter(data['Speed'], data[key])
            if key == 'Intensity':
                y = 'Intensity (çounts/s)'
            else:
                y = key + ' (ns)'
            ax[i].set(xlabel = 'Speed (cm/s)', ylabel = y)
            ax[i].title.set_text(key)
            i+=1
        self.dataOut = pd.DataFrame(data)
        self.fig[0].tight_layout()
        self.frame[0] = tk.Frame(self.root)
        self.frame[0].pack()

        self.canvas[0] = FigureCanvasTkAgg(self.fig[0], master = self.frame[0])  
        self.canvas[0].draw()
        self.toolbar = NavigationToolbar2Tk(self.canvas[0], self.frame[0])
        self.toolbar.update()

        self.canvas[0].get_tk_widget().pack()

    def combine_eta(self):
        windows = {'Speed Bins':[], 'Speed':[],
                   'FLP Bins':[], 'Intensity':[], 
                   'Fit Lifetime':[], 'Empirical Lifetime':[]}
        lengths = []
        for dataset in self.datasets:
            lengths.append(dataset.ETA['Speed Bins'][-1])
            for key in dataset.ETA:
                if key.endswith('STDEV'):
                    pass
                else:
                    windows[key].append(dataset.ETA[key])
                    

        speedBins = self.datasets[lengths.index(max(lengths))].ETA['Speed Bins']
        
        #Average the traces
        speed, speedSTDEV = self.avg_speed(windows, speedBins)
        if self.datasets[0].analysisParameters['ETA Method'] == 'Interpolate':
            intensityAVG, intensitySTDEV = self.interp_avg(windows['Intensity'], windows['FLP Bins'], speedBins)
            empAVG, empSTDEV = self.interp_avg(windows['Empirical Lifetime'], windows['FLP Bins'], speedBins)
            fitAVG, fitSTDEV = self.interp_avg(windows['Fit Lifetime'], windows['FLP Bins'], speedBins)
        elif self.datasets[0].analysisParameters['ETA Method'] == 'Average':
            pass
        else:
            print('Error: Averaging method Invalid')

        combinedETA = {'Time': speedBins, 'Speed': speed, 'Speed STDEV':speedSTDEV,
                       'Intensity': intensityAVG, 'Intensity STDEV': intensitySTDEV,
                       'Fit Lifetime':fitAVG, 'Fit Lifetime STDEV': fitSTDEV,
                       'Empirical Lifetime':empAVG, 'Empirical Lifetime STDEV': empSTDEV}
        return combinedETA

    def avg_speed(self, windows, speedBins):
        speed = [None]*len(speedBins)
        speedSTDEV = [None]*len(speedBins) 
        for bin in range(len(speedBins)):
            binVal = []
            for window in range(len(windows['Speed Bins'])):
                try:
                    binVal.append(windows['Speed'][window][bin])
                except:
                    pass
            speed[bin] = sum(binVal)/len(binVal)
            speedSTDEV[bin] = statistics.pstdev(binVal)
        return speed, speedSTDEV


    def interp_avg(self, windows, timeWindows, speedBins):
        dataBinned = [None]*len(speedBins)
        dataSTDEV = [None]*len(speedBins)
        for bin in range(len(speedBins)):
            binVals = []
            for window in range(len(windows)):
                if bin == 0:
                    binVals.append(windows[window][self.find_nearest(timeWindows[window], 0)])
                else:
                    if timeWindows[window][-1]<speedBins[bin]:
                        pass
                    else:
                        points = self.find_nearest2(windows[window], timeWindows[window], speedBins[bin])
                        binVals.append(np.interp(speedBins[bin], [i[0] for i in points], [i[1] for i in points]))

            dataBinned[bin] = sum(binVals)/len(binVals)
            dataSTDEV[bin] = statistics.pstdev(binVals)
    
        return dataBinned, dataSTDEV    

    #finds 2 points (time, data), (time, data) closest to time value given
    def find_nearest2(self, array, arrayTime, value):
        arrayTime = np.asarray(arrayTime)
    
        idx = np.argpartition((np.abs(arrayTime - value)), 2).tolist()[0:2]
        points = [[arrayTime[idx[0]], array[idx[0]]], [arrayTime[idx[1]], array[idx[1]]]]
        return points
                            

    def find_nearest(self, array, value):
        array = np.asarray(array)
        idx = (np.abs(array - value)).argmin()
        return idx
            

        