import numpy as np
filepath='/Volumes/PcSSDA/FLP/0408AchsensorHPC004/extracted_data/'
for i in range(10,33):
	filename=filepath+'StatesAcq'+str(i)+'_hr0.npy'
	filename_csv=filepath+'hour_'+str(i)+'.csv'
	States=np.load(filename)
	np.savetxt(filename_csv,States,delimiter=',')


