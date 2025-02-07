% 
% 
% 
for i=1:8
    
    states=readNPY(['StatesAcq',num2str(i+6),'_hr0.npy']);
    eval(['states_',num2str(i),'h=states;']);
end
% 
% % states_all=[];
% % 
% % for i=1:24
% %     eval(['states_all=[states_all; states_',num2str(i),'h];'])
% % end
%     
% 
% 
% 
for i=1:8
    eval(['states_in_seconds_',num2str(i),'=[];']);
    for j=1:900
        eval(['states_in_seconds_',num2str(i),'((4*j-3):4*j)=states_',num2str(i),'h(j);']);
    end
end
time_all2=time;
time_all_states2=time;

for i=1:1
     eval(['this_hour=states_in_seconds_',num2str(i),';'])
    for j=1:3600
        if isnan(time_all2(j,i))==0
            if ceil(time_all2(j,i))<3600
                time_all_states2(j,i)=this_hour(ceil(time_all2(j,i)));
            else
                time_all_states2(j,i)=this_hour(3600);
            end
        end
    end
end

% Wake_lft_avg=tau_avg_all(find(time_all_states==1));
% NREM_lft_avg=tau_avg_all(find(time_all_states==2));
% REM_lft_avg=tau_avg_all(find(time_all_states==3));
% 
% empTrunc_lft_Wake=tau_empTrunc_all2(find(time_all_states2==1));
% empTrunc_lft_NREM=tau_empTrunc_all2(find(time_all_states2==2));
% empTrunc_lft_REM=tau_empTrunc_all2(find(time_all_states2==3));
% 
% sleeptime_NREM=size(empTrunc_lft_NREM,1);
% sleeptime_REM=size(empTrunc_lft_REM,1);
% sleeptime_total= sleeptime_NREM + sleeptime_REM;
% 
% intensity_Wake=photoncount_all2(find(time_all_states2==1));
% intensity_NREM=photoncount_all2(find(time_all_states2==2));
% intensity_REM=photoncount_all2(find(time_all_states2==3));
% 
% Wake_lft_avgTrunc=tau_avgTrunc_all(find(time_all_states==1));
% NREM_lft_avgTrunc=tau_avgTrunc_all(find(time_all_states==2));
% REM_lft_avgTrunc=tau_avgTrunc_all(find(time_all_states==3));
%     