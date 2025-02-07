function [] = zFLP_DoProcessWork()
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    global state spc
    global FLIMchannels
    global FLPdata_counter FLPdata_time FLPdata_lifetimes FLPdata_fits
    
%     if(FLPdata_counter > 1 &&  sum(spc.lifetimes{FLIMchannels})>0)
%         fitting the expotential curve for each slice
%         for i=1:FLPdata_counter
%             for ch=FLIMchannels
%                 spc.lifetimes{ch}=FLPdata_lifetimes{i,ch};    
%                 spc_fitexpprfGY(ch); 
%                 while(1)
%                     spc_fitexpgaussGY(ch); %try singe exponential fit until the appropriate fit
%                     if(spc.fits{ch}.beta2>2 && spc.fits{ch}.beta2<3)
%                         break;
%                     end
%                 end
%                 FLPdata_fits{i,ch}=spc.fits{ch};
%                 display([num2str(i),': ',num2str(spc.fits{ch}.beta2)]);
%             end
%         end
%         
        %saving the data from all slices
        filename=['continuous aquistion data_',num2str(state.files.lastAcquisition)];
        save(filename, 'FLPdata_counter', 'FLPdata_time', 'FLPdata_lifetimes', 'FLPdata_fits');
%     end
    
    if timerGetActiveStatus('zFLP')
        timerRegisterPackageDone('zFLP');
    end
end
