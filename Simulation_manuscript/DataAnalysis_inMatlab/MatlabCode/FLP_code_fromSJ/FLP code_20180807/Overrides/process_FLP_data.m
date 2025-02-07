function process_FLP_data()
global state spc
global FLIMchannels
global FLPdata_counter FLPdata_time FLPdata_lifetimes FLPdata_fits

% if(FLPdata_counter > 1 &&  sum(spc.lifetimes{FLIMchannels})>0)
%     %fitting the expotential curve for each slice
%     for i=1:FLPdata_counter
%         for ch=FLIMchannels
%             spc.lifetimes{ch}=FLPdata_lifetimes{i,ch};
%             spc_fitexpprfGY(ch);
%             while(1)
%                 spc_fitexpgaussGY(ch); %try singe exponential fit until the appropriate fit
%                 if(spc.fits{ch}.beta2>2 && spc.fits{ch}.beta2<3)
%                     if(spc.fits{ch}.beta2<2.1)
%                         spc_fitexpgaussGY(ch); %try singe exponential fit until the appropriate fit
%                         spc_fitexpgaussGY(ch);
%                     end
%                     break;
%                 end
%             end
%             FLPdata_fits{i,ch}=spc.fits{ch};
%             display([num2str(i),': ',num2str(spc.fits{ch}.beta2)]);
%         end
%     end
%     
%     %saving the data from all slices
%     filename=['continuous aquistion data_',num2str(state.files.lastAcquisition)];
%     save(filename, 'FLPdata_counter', 'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits');
% end

for i=1:length(FLPdata_time)
    tau(i)=FLPdata_fits{i,1}.beta2;
    counts(i)=sum(FLPdata_lifetimes{i,1});
end
figure(31);plot(FLPdata_time,counts,'.');
figure(30);plot(FLPdata_time,tau,'.');

mean(counts)
std(counts)
mean(tau)
std(tau)
end

