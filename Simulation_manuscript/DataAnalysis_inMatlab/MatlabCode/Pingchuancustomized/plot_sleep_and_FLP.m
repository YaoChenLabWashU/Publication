
% states_in_seconds_all=[];
% for i=1:24
%     eval(['states_in_seconds=states_in_seconds_',num2str(i)]);
%     states_in_seconds_all=[states_in_seconds_all states_in_seconds];
% end

% Acq_num=18;
% eval(['states_for_plot=states_in_seconds_',num2str(Acq_num),';']);
% 
% figure
% yyaxis left
% plot(time_sleep, states_for_plot, 'lineWidth', 5)
% yyaxis right
% plot(time_all2(:,Acq_num),tau_avgTrunc_all2(:,Acq_num), 'lineWidth', 3)
% 
% figure
% yyaxis left
% plot(time_sleep, states_for_plot, 'lineWidth', 5)
% yyaxis right
% plot(time_all2(:,Acq_num),photoncount_all2(:,Acq_num), 'lineWidth', 3)

states_for_plot=states_in_seconds_all;
time_sleep_all=1:1:86400;
% 
% figure
% yyaxis left
% plot(time_sleep_all, states_for_plot, 'lineWidth', 5)
% yyaxis right
% plot(time_all2(:,Acq_num),tau_avgTrunc_all2(:,Acq_num), 'lineWidth', 3)
% 
% figure
% yyaxis left
% plot(time_sleep_all, states_for_plot, 'lineWidth', 5)
% yyaxis right
% plot(time_all2(:,Acq_num),photoncount_all2(:,Acq_num), 'lineWidth', 3)

figure
yyaxis left
plot(time_sleep_all, states_for_plot, 'lineWidth', 1)
yyaxis right
plot(tau_avgTrunc_all, 'lineWidth', 1)

figure
yyaxis left
plot(time_sleep_all, states_for_plot, 'lineWidth', 1)
yyaxis right
plot(photoncount_all, 'lineWidth', 1)