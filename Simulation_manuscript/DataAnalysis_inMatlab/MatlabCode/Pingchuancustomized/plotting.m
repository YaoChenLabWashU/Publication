

% tau_empTrunc_norm=(tau_empTrunc-min(tau_empTrunc))/(range(tau_empTrunc));
% photoncount_norm=(photoncount-min(photoncount))/(range(photoncount));



% figure
% yyaxis left
% plot(time,tau_empTrunc_norm)
% yyaxis right
% plot(time,photoncount_norm)
% 
% figure
% yyaxis left
% plot(time_from_bonsai,speed)
% yyaxis right
% plot(time,photoncount_norm)
% 
% figure
% yyaxis left
% plot(time_from_bonsai,speed)
% yyaxis right
% plot(time,tau_empTrunc_norm)

figure
yyaxis left
plot(time_from_bonsai,speed,'lineWidth', 2)
yyaxis right
plot(time,photoncount, 'lineWidth', 2)

figure
yyaxis left
plot(time_from_bonsai,speed, 'lineWidth', 2)
yyaxis right
plot(time,tau_empTrunc, 'lineWidth', 2)

bin=[0:0.5:25];
bin(1)=0.1;

figure
histogram(speed,bin)
