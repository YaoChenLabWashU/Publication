
time_csv=[filename,'_time.csv'];
intensity_csv=[filename,'_intensity.csv'];
lft_fit_csv=[filename,'_tau_fitting.csv'];
lft_emp_csv=[filename,'_tau_emp.csv'];

csvwrite(time_csv,time);
csvwrite(intensity_csv,photoncount);
csvwrite(lft_fit_csv,tau_avg);
csvwrite(lft_emp_csv,tau_empTrunc);


states_serial_csv=[filename,'states.csv'];
time_csv=[filename,'time.csv'];
lft_csv=[filename,'lft.csv'];
lft_DC_csv=[filename,'lft_DC.csv'];

csvwrite(states_serial_csv,states_hour_9);
csvwrite(time_csv,time_hour_9);
csvwrite(lft_csv,tau_empTrunc_hour_9);
csvwrite(lft_DC_csv,emp_DC);


