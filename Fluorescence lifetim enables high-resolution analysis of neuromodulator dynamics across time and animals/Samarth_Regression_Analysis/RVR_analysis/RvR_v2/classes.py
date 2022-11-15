import numpy as np
import pandas as pd
from functions import *
from GUI.AnalysisParameters import AnalysisParameters
import os
from scipy import signal
from scipy.signal import butter, lfilter, freqz, filtfilt
from statistics import mean
import statistics
import math

class dataset():
    def __init__(self,dataParameters, analysisParameters, saveOptions):
        self.dataParameters = dataParameters
        self.analysisParameters = analysisParameters
        self.saveOptions = saveOptions

        #Speed Processing
        self.rawSpeedTime, self.rawSpeed = self.load_speed()
        self.speedTimeBinned, self.speedBinned = self.bin_speed()
        self.runningDef, self.baselineDef = self.find_Activity()

        #FLP Processing
        flpTime, intensity, fitLFT, empLFT = self.load_FLP()
        self.rawData = pd.DataFrame({'Time': flpTime, 'Intensity': intensity, 'Fit Lifetime': fitLFT, 'Empirical Lifetime': empLFT})
        self.AC_Data, self.DC_Data = self.filter_data()

        #Analyze Baseline Data
        self.baselineDict = self.baseline_analysis()

        #Analyze Running Data
        self.runningDict, self.ETA, self.ETA_Windows = self.running_analysis()
        self.maxSpeeds = [max(win) for win in self.dataWindows['Speed']]




    def load_speed(self):
        path = os.path.join(self.dataParameters['Path'], self.dataParameters['Experiment'] + '_speed.csv').replace('\\', "/")
        Data = pd.read_csv (path)
        time = Standard2ElapsedTime(Data['Timestamp'].tolist())
        speed = Data['Speed'].tolist()
        return time, speed   

    def load_FLP(self):
        path = os.path.join(self.dataParameters['Path'], self.dataParameters['Experiment'] + '_FLP.csv').replace('\\', "/")
        data = pd.read_csv (path)
        time = data['time'].tolist()
        intensity = data['intensity'].tolist()
        fit = data['tau_fit'].tolist()
        emp = data['tau_empirical'].tolist()
        #data = data[0].dropna().tolist()
        return time, intensity, fit, emp

    def filter_data(self):
        #Lowpass
        nyquist = 0.5 * self.analysisParameters['FLP Sampling Frequency']

        normalizedCutoff = self.analysisParameters['Filter Cutoff_Low'] / nyquist
        b, a = butter(self.analysisParameters['Filter Order'], normalizedCutoff, btype='low', analog=False)
        intensity_DC = filtfilt(b, a, self.rawData['Intensity'])
        fit_DC = filtfilt(b, a, self.rawData['Fit Lifetime'])
        emp_DC = filtfilt(b, a, self.rawData['Empirical Lifetime'])
        DC = pd.DataFrame({'Time': self.rawData['Time'], 'Intensity': intensity_DC, 'Fit Lifetime': fit_DC, 'Empirical Lifetime': emp_DC})

        #Highpass
        normalizedCutoff = self.analysisParameters['Filter Cutoff_High'] / nyquist
        b, a = butter(self.analysisParameters['Filter Order'], normalizedCutoff, btype='high', analog=False)
        intensity_AC = filtfilt(b, a, self.rawData['Intensity'])
        fit_AC = filtfilt(b, a, self.rawData['Fit Lifetime'])
        emp_AC = filtfilt(b, a, self.rawData['Empirical Lifetime'])
        AC = pd.DataFrame({'Time': self.rawData['Time'], 'Intensity': intensity_AC, 'Fit Lifetime': fit_AC, 'Empirical Lifetime': emp_AC})
        return AC, DC

    # takes in time series data/time relative to start time and bin size in seconds, outputs data averaged over bin 
    # and corresponding time data
    def bin_speed(self): 
        numBins = int(self.rawSpeedTime[-1]//self.analysisParameters['Speed Bin Size'])+1
        timeBinRef = [self.rawSpeedTime[0]+(self.analysisParameters['Speed Bin Size']*i) for i in range(numBins)]
        dataBinned = [self.rawSpeed[0]]
        placeHolder = 0
        for bin in range(1,len(timeBinRef)):
            windowSum = []
            for time in range(placeHolder, len(self.rawSpeedTime)):
                if self.rawSpeedTime[time]>timeBinRef[bin-1] and self.rawSpeedTime[time]<=timeBinRef[bin]:
                    windowSum.append(self.rawSpeed[time])
                    placeHolder = time-1
                elif self.rawSpeedTime[time]>timeBinRef[bin]:
                    break
                else:
                    pass
            dataBinned.append(mean(windowSum))
        return timeBinRef, dataBinned

    def binarizeData(self, data, threshold, direction):
        if direction == 'over':
            binary = [1 if abs(i)>=threshold else 0 for i in data]
        elif direction == 'under':
            binary = [1 if abs(i)<threshold else 0 for i in data]
        else:
            pass

        return binary

    def find_Activity(self):
        running = self.binarizeData(self.speedBinned, self.analysisParameters['Running Threshold'], 'over')
        baseline = self.binarizeData(self.speedBinned, self.analysisParameters['Resting Threshold'], 'under')
        idx = 0
        while idx<len(running):
            #If running, find out for how long
            if running[idx]:
                start = idx
                while idx<len(running):
                    if running[idx]:
                        idx+=1
                    else:
                        #if any of next three points are running, regard this as noise and classify all as running
                        if abs(self.speedBinned[idx+1]) > self.analysisParameters['Running Threshold']:
                            running[idx]=1
                            idx+=1
                        elif abs(self.speedBinned[idx+2]) > self.analysisParameters['Running Threshold']:
                            running[idx]=1
                            running[idx+1] = 1
                            idx+=2
                        elif abs(self.speedBinned[idx+3]) > self.analysisParameters['Running Threshold']:
                            running[idx]=1
                            running[idx+1] = 1
                            running[idx+2] = 1
                            idx+=3
                        else:
                            break
                end = idx

                #Check length of running, if under threshold, omit
                if end == len(running):
                    end = end-1
                    if (self.speedTimeBinned[end]-self.speedTimeBinned[start])>=self.analysisParameters['Threshold Length']:
                        break 
                    else:
                        running[start:end] = [0]*(end-start)
                        break
                elif self.speedTimeBinned[end]-self.speedTimeBinned[start] < self.analysisParameters['Threshold Length']:
                    running[start:end] = [0]*(end-start) 
                else:
                    pass
            else:
                idx+=1
                
        running = self.ensureRestingPreceding(running, self.speedTimeBinned, self.analysisParameters['Preceding Rest']) 
        return running, baseline

    
    #takes in binary speed data, run at end of find_Activity. Makes sure preceding period is resting
    def ensureRestingPreceding(self, data, time, precedingTime):
        idx = 0
        while idx < len(data):
            if data[idx]:
                rangeStart = self.find_nearest(time, time[idx]-precedingTime)
                precedingRange = [*range(rangeStart, idx)]
                precedingRange_binary = [data[t] for t in precedingRange]
                precedingSpeeds = [abs(self.speedBinned[t]) for t in precedingRange]
                #If it is not all rest before the running epoch, omit the epoch
                if any(precedingRange_binary) or time[idx]<precedingTime or mean(precedingSpeeds)>self.analysisParameters['Running Threshold']:
                    while data[idx]:
                        if idx>=len(data):
                            break
                        data[idx] = 0
                        idx+=1
                else:
                    while idx<len(data) and data[idx]:
                        if idx>=len(data):
                            break
                        idx+=1
            else:
                idx+=1
        return data

    def find_nearest(self, array, value):
        array = np.asarray(array)
        idx = (np.abs(array - value)).argmin()
        return idx


    #Checks for length of epochs, trims ends of epochs. 
    def assess_baseline(self):
        idx = 0
        while idx<len(self.baselineDef):
            #if there is a running epoch, remove the preceding buffer period from the resting definition
            if self.baselineDef[idx] == 0:
                pre = self.find_nearest(self.speedTimeBinned, self.speedTimeBinned[idx]-self.analysisParameters['Baseline Buffer'])
                self.baselineDef[pre:idx] = [0]*(idx-pre) 
                #skip to the end of the running epoch
                while idx<len(self.baselineDef) and self.baselineDef[idx]==0:
                    idx+=1
                end = idx
                if idx == len(self.baselineDef):
                    break
                else:  
                    post = self.find_nearest(self.speedTimeBinned, self.speedTimeBinned[end]+self.analysisParameters['Baseline Buffer'])
                    #if the buffer period after running is all "resting", omit the buffer from the resting definition. 
                    if all(self.baselineDef[end:post]):
                        self.baselineDef[end:post] = [0]*(post-end)
                    #if there is more running during the buffer period after running, continue shifting window until all rest, and omit all from resting def
                    else:
                        testStart = end
                        testEnd = post
                        while testEnd<len(self.baselineDef) and all(self.baselineDef[testStart:testEnd])!= True:
                            lastOcc = max(idx for idx, val in enumerate(self.baselineDef[end:post]) if val==0)
                            testEnd = testEnd+lastOcc+1
                            testStart +=lastOcc+1
                        if testEnd>=len(self.baselineDef):
                            testEnd = len(self.baselineDef)-1
                        self.baselineDef[end:testEnd] = [0]*(testEnd-end)
                        post = testEnd
                    idx = post
            else:
                idx+=1 
        idx = 0
        #Check for epoch length. This can be more concise. 
        while idx<len(self.baselineDef):
            if self.baselineDef[idx]:
                start = idx
                while idx<len(self.baselineDef) and self.baselineDef[idx]:
                    idx+=1
                end = idx
                if idx == len(self.baselineDef):
                    end = end-1
                    if (self.speedTimeBinned[end]-self.speedTimeBinned[start])>=self.analysisParameters['Baseline Length']:
                        break 
                    else:
                        self.baselineDef[start:end] = [0]*(end-start)
                        self.baselineDef[end] = 0
                        break
                elif (self.speedTimeBinned[end]-self.speedTimeBinned[start]) < self.analysisParameters['Baseline Length']:  
                    self.baselineDef[start:end] = [0]*(end-start) 
                else:
                    pass
            else:
                idx+=1       
        return self.baselineDef
        

    def baseline_analysis(self):
        self.baselineDef = self.assess_baseline()

        #break long baseline chunks up
        changes, changes_IDX = self.stateChanges(self.baselineDef, self.speedTimeBinned) 

        change = 0
        while change < len(changes):
            if changes[change][1]-changes[change][0] > self.analysisParameters['Baseline Chunks']:
                changes[change:change] = [[changes[change][0], self.rawData['Time'][self.find_nearest(self.rawData['Time'], changes[change][0]+self.analysisParameters['Baseline Chunks'])]],
                                [self.rawData['Time'][self.find_nearest(self.rawData['Time'], changes[change][0]+self.analysisParameters['Baseline Chunks'])], changes[change][1]]]
                changes.remove(changes[change+2])
            elif changes[change][1]-changes[change][0] < 3:
                changes.remove(changes[change])
            else:
                pass
            change+=1

        baselineDict = {}
        for change in range(len(changes)):
            windowStart = self.find_nearest(self.rawData['Time'], changes[change][0])
            windowEnd = self.find_nearest(self.rawData['Time'], changes[change][1])

            for data in self.rawData:
                if data != 'Time':
                    if change == 0:
                        baselineDict[data] = []
                        baselineDict[data+'AC'] = []
                        baselineDict[data+'DC'] = []
                    if self.analysisParameters['Baseline Analysis Method'] == 'Median':
                        baselineDict[data].append(self.arg_median(np.array(self.rawData[data][windowStart:windowEnd]), windowStart))
                        baselineDict[data+'AC'].append(self.arg_median(np.array(self.AC_Data[data][windowStart:windowEnd]), windowStart))
                        baselineDict[data+'DC'].append(self.arg_median(np.array(self.DC_Data[data][windowStart:windowEnd]), windowStart))
                    elif self.analysisParameters['Baseline Analysis Method'] == 'Max':
                        baselineDict[data].append(self.max_2_surround(self.rawData[data][windowStart:windowEnd], windowStart))
                        baselineDict[data+'AC'].append(self.max_2_surround(self.AC_Data[data][windowStart:windowEnd], windowStart))
                        baselineDict[data+'DC'].append(self.max_2_surround(self.DC_Data[data][windowStart:windowEnd], windowStart))
                    else:
                        pass

                else:
                    pass
        
    
        return baselineDict


    def stateChanges(self, data, time):
        currState = data[0]
        if currState:
            temp = [time[0]]
            temp_IDX = [0]
        changes = []
        changes_IDX = []
        for i in range(len(data)):
            if data[i] != currState:
                currState = data[i]
                if currState:
                    temp = [time[i]]
                    temp_IDX = [i]
                else:
                    temp.append(time[i])
                    temp_IDX.append(i)
                    changes.append(temp)
                    changes_IDX.append(temp_IDX)
            elif data[i] and i == (len(data)-1):
                    temp.append(time[i])
                    temp_IDX.append(i)
                    changes.append(temp)
                    changes_IDX.append(temp_IDX)
            else:
                pass
        return changes, changes_IDX

    def arg_median(self, a, idx):
        if len(a) % 2 == 1:
            return [(np.where(a == np.median(a))[0][0]+idx, np.median(a))]
        else:
            l,r = len(a) // 2 - 1, len(a) // 2
            left = np.partition(a, l)[l]
            right = np.partition(a, r)[r]
            return [(np.where(a == left)[0][0]+idx, a[np.where(a == left)[0][0]]), 
                    (np.where(a == right)[0][0]+idx, a[np.where(a == right)[0][0]])]
    def max_2_surround(self, data, idx):
        data = data.to_list()
        maxVal = max(data)
        max_idx = data.index(maxVal)
        if max_idx == 0:
            out = [[max_idx+idx, maxVal], 
                  [max_idx+1+idx, data[max_idx+1]],
                  [max_idx+2+idx, data[max_idx+2]]]
        elif max_idx+1 >= len(data):
            out = [[max_idx-2+idx, data[max_idx-2]],
                  [max_idx-1+idx, data[max_idx-1]], 
                  [max_idx+idx, maxVal]]
        else:
            out = [[max_idx-1+idx, data[max_idx-1]], 
                  [max_idx+idx, maxVal], 
                  [max_idx+1+idx, data[max_idx+1]]]

        return out
    def running_analysis(self):
        changes, changes_IDX = self.stateChanges(self.runningDef, self.speedTimeBinned)
        self.dataWindows = {'Speed Time':[], 'Speed':[], 'Speed Binary':[], 'FLP Time': [], 
                            'Intensity':[], 'Fit Lifetime':[], 'Empirical Lifetime': []}

        ETA_Changes = [[change[0], change[1]] for change in changes] 
        ETA_Changes_IDX = [[idx[0], idx[1]] for idx in changes_IDX]
        runningDict = {}
        for change in range(len(ETA_Changes)):
            ETA_Changes[change][0] = ETA_Changes[change][0]-self.analysisParameters['ETA Before']
            ETA_Changes_IDX[change][0] = self.find_nearest(self.speedTimeBinned, ETA_Changes[change][0])
            if ETA_Changes[change][0] < 0:
                ETA_Changes[change][0] = 0
                ETA_Changes_IDX[change][0] = 0

            #adding data to Windows for ETA analysis
            self.dataWindows['Speed Time'].append(self.speedTimeBinned[ETA_Changes_IDX[change][0]: ETA_Changes_IDX[change][1]])
            self.dataWindows['Speed'].append(self.speedBinned[ETA_Changes_IDX[change][0]: ETA_Changes_IDX[change][1]])
            self.dataWindows['Speed Binary'].append(self.runningDef[ETA_Changes_IDX[change][0]: ETA_Changes_IDX[change][1]])
            
            windowStart = self.find_nearest(self.rawData['Time'], ETA_Changes[change][0])
            windowEnd = self.find_nearest(self.rawData['Time'], ETA_Changes[change][1])

            self.dataWindows['FLP Time'].append(self.rawData['Time'][windowStart:windowEnd].tolist())
            self.dataWindows['Intensity'].append(self.rawData['Intensity'][windowStart:windowEnd].tolist())
            self.dataWindows['Empirical Lifetime'].append(self.rawData['Empirical Lifetime'][windowStart:windowEnd].tolist())
            self.dataWindows['Fit Lifetime'].append(self.rawData['Fit Lifetime'][windowStart:windowEnd].tolist())

            #Analyze Running Epochs
            windowStart = self.find_nearest(self.rawData['Time'], changes[change][0]-self.analysisParameters['Time Before Transition'])
            windowEnd = self.find_nearest(self.rawData['Time'], changes[change][1]+self.analysisParameters['Time After Transition'])

            #Make this a method
            for data in self.rawData:
                if data != 'Time':
                    if change == 0:
                        runningDict[data] = []
                        runningDict[data+'AC'] = []
                        runningDict[data+'DC'] = []
                    if self.analysisParameters['Running Analysis Method'] == 'Median':
                        runningDict[data].append(self.arg_median(np.array(self.rawData[data][windowStart:windowEnd]), windowStart))
                        runningDict[data+'AC'].append(self.arg_median(np.array(self.AC_Data[data][windowStart:windowEnd]), windowStart))
                        runningDict[data+'DC'].append(self.arg_median(np.array(self.DC_Data[data][windowStart:windowEnd]), windowStart))
                    elif self.analysisParameters['Running Analysis Method'] == 'Max':
                        runningDict[data].append(self.max_2_surround(self.rawData[data][windowStart:windowEnd], windowStart))
                        runningDict[data+'AC'].append(self.max_2_surround(self.AC_Data[data][windowStart:windowEnd], windowStart))
                        runningDict[data+'DC'].append(self.max_2_surround(self.DC_Data[data][windowStart:windowEnd], windowStart))
                    else:
                        pass
                else:
                    pass
            
        #Average Traces
        ETA, ETA_windows = self.AverageTraces()

        return runningDict, ETA, ETA_windows


    #Takes time windows and cleans the data, makes acquisitions the same length/lines up transitions, and calculates the event triggered average. 
    def AverageTraces(self):
        #Time relative to speedWindowStarts
        firstSpeed = [window[0] for window in self.dataWindows['Speed Time']]
        flpTimeWindows = [[num - firstSpeed[self.dataWindows['FLP Time'].index(window)] for num in window] for window in self.dataWindows['FLP Time']]  
        speedTimeWindows = [[num-window[0] for num in window] for window in self.dataWindows['Speed Time']]

        speedWindows = [None]*len(speedTimeWindows)
        intensityWindows = [None]*len(speedTimeWindows)
        empLFTWindows = [None]*len(speedTimeWindows)
        fitLFTWindows = [None]*len(speedTimeWindows)

        long = False
        longest = 0

        maxWin = self.analysisParameters['ETA After']+self.analysisParameters['ETA Before']

        #cut windows longer than a threshold
        for window in range(len(speedTimeWindows)): 
            length = flpTimeWindows[window][-1]
            
            if length >= maxWin:
                long = True
                longest = maxWin
                speedTimeWindows[window] = [num if num <= maxWin else np.nan for num in speedTimeWindows[window]]
                flpTimeWindows[window] = [num if num <= maxWin else np.nan for num in flpTimeWindows[window]]
            elif length>longest and long == False:
                longest = length
            else:
                pass

            speedWindows[window] = [num if math.isnan(speedTimeWindows[window][self.dataWindows['Speed'][window].index(num)]) == False else np.nan for num in self.dataWindows['Speed'][window]]
            intensityWindows[window] = [num if math.isnan(flpTimeWindows[window][self.dataWindows['Intensity'][window].index(num)]) == False else np.nan for num in self.dataWindows['Intensity'][window]]
            empLFTWindows[window] = [num if math.isnan(flpTimeWindows[window][self.dataWindows['Empirical Lifetime'][window].index(num)]) == False else np.nan for num in self.dataWindows['Empirical Lifetime'][window]]
            fitLFTWindows[window] = [num if math.isnan(flpTimeWindows[window][self.dataWindows['Fit Lifetime'][window].index(num)]) == False else np.nan for num in self.dataWindows['Fit Lifetime'][window]]


        #Average the traces
        if self.analysisParameters['ETA Method'] == 'Interpolate':
            speedBins, speedAVG, speedSTDEV, speedWindows_clean = self.binData_AVG (speedWindows, speedTimeWindows, longest)
            flpBins, intensityAVG, intensitySTDEV, intensityWindows_clean = self.interp_AVG (intensityWindows, flpTimeWindows, longest)
            flpBins, empAVG, empSTDEV, empWindows_clean = self.interp_AVG (empLFTWindows, flpTimeWindows, longest)
            flpBins, fitAVG, fitSTDEV, fitWindows_clean = self.interp_AVG (fitLFTWindows, flpTimeWindows, longest)

        elif self.analysisParameters['ETA Method'] == 'Average':
            speedBins, speedAVG, speedSTDEV, speedWindows_clean = self.binData_AVG (speedWindows, speedTimeWindows, longest)
            flpBins, intensityAVG, intensitySTDEV, intensityWindows_clean = self.binData_AVG (intensityWindows, flpTimeWindows, longest)
            flpBins, empAVG, empSTDEV, empWindows_clean = self.binData_AVG (empLFTWindows, flpTimeWindows, longest)
            flpBins, fitAVG, fitSTDEV, fitWindows_clean = self.binData_AVG (fitLFTWindows, flpTimeWindows, longest)
        else:
            print('Error: Averaging method Invalid')
            
        
        ETA_Results = {'Speed Bins': speedBins, 'Speed': speedAVG, 'Speed STDEV': speedSTDEV, 'FLP Bins': flpBins, 
                       'Intensity': intensityAVG, 'Intensity STDEV': intensitySTDEV,
                       'Empirical Lifetime': empAVG, 'Empirical Lifetime STDEV': empSTDEV,
                        'Fit Lifetime': fitAVG, 'Fit Lifetime STDEV': fitSTDEV}
        ETA_Windows = {'Speed Time': speedWindows_clean['time'], 'Speed': speedWindows_clean['data'], 'FLP Bins': speedBins,
                       'Intensity': intensityWindows_clean, 'Empirical Lifetime': empWindows_clean,
                       'Fit Lifetime': fitWindows_clean}
        return ETA_Results, ETA_Windows

    #ETA with interpolation
    def interp_AVG(self, data, dataTime, length):
        binSize = self.analysisParameters['ETA Bin Size']
        #Make data same Length
        timeBinRef = [x * binSize for x in range(0, int(round(length*(1.0/binSize)))+1)]
        dataBinned = []
        dataSTDEV = []
        samples = self.FindMaxLength(data)
        windows = [None]* len(data)

        #add nan to make same length
        for i in range(len(data)):
            while len(data[i])<samples:
                data[i].append(np.nan)
                dataTime[i].append(np.nan)

        for i in range(len(timeBinRef)):
            bin = []
            for j in range(len(data)):
                if i == 0:
                    bin.append(data[j][0])
                    windows[j] = [data[j][0]]
                else:
                    if dataTime[j][-1]<timeBinRef[i]:
                        windows[j].append(np.nan)
                    else:
                        points = self.find_nearest2(data[j], dataTime[j], timeBinRef[i])
                        bin.append(np.interp(timeBinRef[i], [i[0] for i in points], [i[1] for i in points]))
                        windows[j].append(np.interp(timeBinRef[i], [i[0] for i in points], [i[1] for i in points]))
            dataBinned.append(sum(bin)/len(bin))
            dataSTDEV.append(statistics.pstdev(bin))
        timeBinRef = [i if math.isnan(dataBinned[timeBinRef.index(i)]) == False else np.nan for i in timeBinRef ]
        timeBinRef = pd.Series(timeBinRef).dropna().tolist()
        dataBinned = pd.Series(dataBinned).dropna().tolist()
        dataSTDEV = pd.Series(dataSTDEV).dropna().tolist()
        
        for i in windows:
            i = pd.Series(i).dropna().tolist()

        return timeBinRef, dataBinned, dataSTDEV, windows  


    #returns longest list of list of lists
    def FindMaxLength(self, lst):
        for lst_idx in range(len(lst)):
            lst[lst_idx] = [i for i in lst[lst_idx] if math.isnan(i) == False]
        maxLength = max(map(len, lst))
        return maxLength


    #find average of traces by binning data
    def binData_AVG (self, data, dataTime, length):
        binSize = self.analysisParameters['ETA Bin Size']

        #Make data same Length
        timeBinRef = [x * binSize for x in range(1, int(round(length*(1.0/binSize)))+1)]
        dataBinned = []
        dataSTDEV = []
        samples_data = self.FindMaxLength(data)
        samples_time = self.FindMaxLength(dataTime)
        samples = min(samples_data, samples_time)

        for i in range(len(data)):
            if len(data[i]) > samples:
                data[i] = data[i][0:samples]
                dataTime[i] = dataTime[i][0:samples]
            else:
                while len(data[i])<samples:
                    data[i].append(np.nan)
                    dataTime[i].append(np.nan)

        for timeBin in range(len(timeBinRef)):
            bin = []
            for window in range(len(data)):
                for timeVal in range(len(dataTime[window])):
                    if timeBin == 0:
                        if dataTime[window][timeVal] <= timeBinRef[timeBin]:
                            bin.append(data[window][timeVal])
                        else: 
                            pass
                    elif math.isnan(dataTime[window][timeVal]):
                        pass
                    elif timeBin>0 and dataTime[window][timeVal] <= timeBinRef[timeBin] and dataTime[window][timeVal] > timeBinRef[timeBin-1]:
                        bin.append(data[window][timeVal])
                    else:
                        pass

            if len(bin) == 0:
                dataBinned.append(np.nan)
                dataSTDEV.append(np.nan)
            else:
                dataBinned.append(sum(bin)/len(bin))
                dataSTDEV.append(statistics.pstdev(bin))

        timeBinRef = [i if math.isnan(dataBinned[timeBinRef.index(i)]) == False else np.nan for i in timeBinRef ]
        timeBinRef = pd.Series(timeBinRef).dropna().tolist()
        dataBinned = pd.Series(dataBinned).dropna().tolist()
        dataSTDEV = pd.Series(dataSTDEV).dropna().tolist()
        windows = {'data':data, 'time':dataTime}
        
        return timeBinRef, dataBinned, dataSTDEV, windows

    #finds 2 points (time, data), (time, data) closest to time value given
    def find_nearest2(self, array, arrayTime, value):
        arrayTime = np.asarray(arrayTime)
    
        idx = np.argpartition((np.abs(arrayTime - value)), 2).tolist()[0:2]
        points = [[arrayTime[idx[0]], array[idx[0]]], [arrayTime[idx[1]], array[idx[1]]]]
        return points
                            