import pandas as pd
import cv2
import os
import sys
import numpy as np
import json
import glob

def find_continuous_frames(df):
	cont_idx = []
	these_bins = list(df.index)
	if len(these_bins) == 0:
		cont_idx.append(int(input("I couldn't find any unlikely frames. Please manually input a frame for storage.")))
		video_flag = False
		return video_flag, cont_idx
	temp = [these_bins[0]]
	for b in these_bins[1:]:
		if (np.size(temp) == 0) or (b == temp[-1]+1):
			temp.append(b)
		else:
			cont_idx.append(temp)
			temp = [b]
	cont_idx.append(temp)
	video_flag = True
	return video_flag, cont_idx

def check_video(vid_filename, start_frame, end_frame):
	cap = cv2.VideoCapture(vid_filename)
	for f in np.arange(start_frame, end_frame):
		cap.set(1, f)
		ret, frame = cap.read()
		if ret:
			cv2.imshow('Frame', frame)
			key = cv2.waitKey(1) & 0xFF
			if key == ord('v'):
				break
	cv2.destroyAllWindows()

def pull_unlikely_df(motion_fn, threshold = 0.1):
	f = pd.read_csv(motion_fn)
	these_cols = [s for s in f.columns if 'likelihood' in s]
	df = f[these_cols]
	df = df.fillna(0)
	low_likelihood = df[(df < threshold).all(axis=1)]
	return low_likelihood

def pulling_injection_dict(basename, exp_type, dictionary_fn):
	try:
		with open(dictionary_fn, 'rb') as file:
			injection_info = json.load(file)
	except FileNotFoundError:
		injection_info = {}
	if basename not in list(injection_info.keys()):
		injection_info = initialize_fields(injection_info, basename, exp_type)
	else:
		print("You've already added injection info about this experiment. Loading what you have now...")
	return injection_info

def initialize_fields(injection_info, basename, exp_type):
	print("This is the first time you analyzing this experiment. Let's load some metadata.")
	injection_info[basename] = {}
	injection_info[basename]['Animal Name'] = str(input('What is the aniaml name?'))
	injection_info[basename]['Drug'] = input('What drug did you use?').split()
	injection_info[basename]['Dose'] = input('And in what dose?').split()
	assert len(injection_info[basename]['Drug']) == len(injection_info[basename]['Dose'])

	if exp_type == 'injection':
		injection_info[basename]['Drug Timestamps'] = []
		injection_info[basename]['Saline Timestamps'] = []
		# video_dir = str(input('Where are your csvs and videos stored?'))
		# file_num = input('What number file was your first timestamp?')
		# injection_info[basename]['Start File'] = glob.glob(os.path.join(video_dir, '*_csv', '*_timestamp' + file_num + '.csv'))[0]
		# injection_info[basename]['Saline File'] = []
		# injection_info[basename]['Drug File'] = []
		# injection_info[basename]['Saline Frame'] = []
		# injection_info[basename]['Drug Frame'] = []
	elif exp_type == 'infusion':
		injection_info[basename]['Saline Acq'] = []
		injection_info[basename]['Drug Acq'] = []
		injection_info[basename]['Saline Timepoint'] = []
		injection_info[basename]['Drug Timepoint'] = []

	else:
		print("I don't understand the experiment type")
	return injection_info

def detect_injection_time(basename, rawdatdir):
	video_num = input("Which video number is this injection in?")
	video_fn = glob.glob(os.path.join(rawdatdir, '*_video', '*' + basename+video_num + '.mp4'))[0]
	motion_fn = glob.glob(os.path.join(rawdatdir, '*_csv', '*_motion' + video_num +'.csv'))[0]
	print("I will use this video file: " + video_fn)
	print("I will use this motion file: " + motion_fn)
	threshold = float(input('What likelihood threshold do you want to use?'))
	df = pull_unlikely_df(motion_fn, threshold = threshold)
	video_flag, cont_idx = find_continuous_frames(df)
	if not video_flag:
		v = cont_idx
	seg_count = 0
	while video_flag:
		v = cont_idx[seg_count]
		if len(v) > 1:
			check_video(video_fn, v[0], v[-1])
			video_flag = input('Is this the right segments? (y/n)') != 'y'
		seg_count = seg_count+1
	print(str(v[0]) + '-'+str(v[-1]))
	tstamp_fn = glob.glob(os.path.join(rawdatdir, '*_csv', '*_timestamp' + video_num + '.csv'))[0]
	tstamps = pd.read_csv(tstamp_fn, header = None)
	tstamp = tstamps[0].loc[v[0]][:-7]
	print("The timestamp of the detected frame is: "+ tstamp)

	return tstamp
def manual_injection_time():
	Y = input('Enter year (yyyy)')
	m = input('Enter month (mm)')
	d = input('Enter day (dd)')
	H = input('Enter hour (hh; 24-hour clock)')
	M = input('Enter minute (mm)')
	S = input("Enter second (ss); if you don't have second information, just enter 00")
	tstamp = Y + '-'+ m + '-' + d + 'T' + H + ':' + M + ':' + S
	if '.' not in tstamp:
		tstamp = tstamp + '.0'
	return tstamp

if __name__ == "__main__":
	exp_type = str(input('Which type of drug delivery? (injection, infusion)'))
	dictionary_fn = os.path.join('/Volumes/yaochen/Active/Lizzie/FLP_Data/', exp_type + '_info.json')
	basename = str(input("What is the basename of this experiment?"))
	injection_info = pulling_injection_dict(basename, exp_type, dictionary_fn)
	done_flag = False
	if exp_type == 'injection':
		video_dir = str(input('Where are your csvs and videos stored?'))
	while not done_flag:
		if exp_type == 'injection':
			print("Ok, let's collect info on the injections")
			manual_flag = input("Do you want to enter the timestamp manually? (y/n)") == 'y'
			# rawdatdir = os.path.split(os.path.split(injection_info[basename]['Start File'])[0])[0]
			if manual_flag:
				tstamp = manual_injection_time()
			else:
				tstamp = detect_injection_time(basename, video_dir)
			store_flag = input('Do you want to store this value in the injection info dictionary? (y/n)') == 'y'
			if store_flag:
				injection_type = str(input("What type of injection is this? (Drug or Saline)"))
				injection_order = int(input("What number injection was this?"))
				injection_info[basename][injection_type+' Timestamps'].insert(injection_order-1, tstamp)

				with open('/Volumes/yaochen/Active/Lizzie/FLP_Data/injection_info.json', 'w') as file:
				    json.dump(injection_info, file, indent=4)
		if exp_type == 'infusion':
			print("Ok, let's collect info on the infusions")
			injection_type = str(input("What type of infusion is this? (Drug or Saline)"))
			start_acq = int(input("What acquisition did this infusion start in?"))
			start_t = int(input("What timepoint did this infusion start?"))
			end_acq = int(input("What acquisition did this infusion end in?"))
			end_t = int(input("What timepoint did this infusion end?"))

			injection_order = int(input("What number infusion bout was this?"))
			injection_info[basename][injection_type+' Acq'].insert(injection_order-1,[start_acq, end_acq])
			injection_info[basename][injection_type+' Timepoint'].insert(injection_order-1,[start_t, end_t])
		done_flag = input('Do you have more injections from this experiment? (y/n)') != 'y'
	print("Ok, done with this experiment!")

	with open(dictionary_fn, 'w') as file:
	    json.dump(injection_info, file, indent=4)










