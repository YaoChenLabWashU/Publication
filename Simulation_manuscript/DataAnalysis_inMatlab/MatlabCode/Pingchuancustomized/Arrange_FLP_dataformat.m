% This script is to arrage the data format from FLP analysis and sleep
% scoring.

% time_serial=[];
% 
% for i=1:24
%     eval(['time_hour_',num2str(i),'=time_all2(:,',num2str(i),');'])
%     eval(['time_hour_',num2str(i),'(isnan(time_hour_',num2str(i),'))=[];'])
% end
% 
% for i=1:24
%     eval(['time_hour_serial=time_hour_',num2str(i),'+3600*(i-1);'])
%     time_serial=[time_serial;time_hour_serial];
% end
% 
% states_serial=[];
% 
% for i=1:24
%     eval(['states_hour_',num2str(i),'=time_all_states2(:,',num2str(i),');'])
%     eval(['states_hour_',num2str(i),'(isnan(states_hour_',num2str(i),'))=[];'])
% end
% 
% for i=1:24
%     eval(['states_hour_serial=states_hour_',num2str(i)])
%     states_serial=[states_serial;states_hour_serial];
% end
% 
% tau_empTrunc_serial=[];
% 
% for i=1:24
%     eval(['tau_empTrunc_hour_',num2str(i),'=tau_empTrunc_all2(:,',num2str(i),');'])
%     eval(['tau_empTrunc_hour_',num2str(i),'(isnan(tau_empTrunc_hour_',num2str(i),'))=[];'])
% end
% 
% for i=1:24
%     eval(['tau_empTrunc_hour_serial=tau_empTrunc_hour_',num2str(i),';'])
%     tau_empTrunc_serial=[tau_empTrunc_serial;tau_empTrunc_hour_serial];
% end
% 
% tau_avg_serial=[];
% 
% for i=1:24
%     eval(['tau_avg_hour_',num2str(i),'=tau_avg_all2(:,',num2str(i),');'])
%     eval(['tau_avg_hour_',num2str(i),'(isnan(tau_avg_hour_',num2str(i),'))=[];'])
% end
% 
% for i=1:24
%     eval(['tau_avg_hour_serial=tau_avg_hour_',num2str(i),';'])
%     tau_avg_serial=[tau_avg_serial;tau_avg_hour_serial];
% end

intensity_serial=[];

for i=1:24
    eval(['intensity_hour_',num2str(i),'=photoncount_all2(:,',num2str(i),');'])
    eval(['intensity_hour_',num2str(i),'(isnan(intensity_hour_',num2str(i),'))=[];'])
end

for i=1:24
    eval(['intensity_hour_serial=intensity_hour_',num2str(i),';'])
    intensity_serial=[intensity_serial;intensity_hour_serial];
end