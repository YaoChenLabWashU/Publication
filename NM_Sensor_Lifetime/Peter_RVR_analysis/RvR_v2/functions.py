import datetime
import pandas as pd



def Standard2ElapsedTime(timeString):
    timeElapsed = [datetime.datetime.strptime(i[:-7], '%Y-%m-%dT%H:%M:%S.%f') for i in timeString]
    timeElapsed = [(i-timeElapsed[0]).total_seconds() for i in timeElapsed]
    return timeElapsed

