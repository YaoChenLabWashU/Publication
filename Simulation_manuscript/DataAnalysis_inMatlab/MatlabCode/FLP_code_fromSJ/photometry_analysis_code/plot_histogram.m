global spc
range=[25 75];
baseline_period=10;
output_filename='acq_13.xlsx';
delta_peak_time=1.12;
fit_start=2;
offset_peak=1;

lifetime=spc.lifetimes{1};
nsPerPoint=spc.datainfo.psPerUnit/1000;

time_offset=delta_peak_time + fit_start - offset_peak;

figure(100);
plot(nsPerPoint*(1:length(lifetime)),lifetime);

baseline_period=sort(lifetime(range(1):range(2)));
baseline_pc=mean(baseline_period(1:10));

lifetime=lifetime-baseline_pc;
lifetime=lifetime/max(lifetime);
figure(101);
plot(nsPerPoint*(1:length(lifetime))-time_offset,lifetime);

x=nsPerPoint*(1:length(lifetime))-time_offset
y=lifetime;
output=[x',lifetime'];
xlswrite(output_filename,output);