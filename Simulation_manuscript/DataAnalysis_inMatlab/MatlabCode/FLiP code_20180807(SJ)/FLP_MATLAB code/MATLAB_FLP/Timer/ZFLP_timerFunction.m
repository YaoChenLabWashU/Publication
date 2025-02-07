function ZFLP_timerFunction()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%disp('called')
global state spc
global FLPdata_time FLPdata_lifetimes FLPdata_counter FLPdata_tau FLPdata_pc;
global FLIMchannels
global startTime;
global testTimer;
global tauplot photoncountplot;
global h_tauplot h_photoncountplot;
%global FLPdata_fits;
global t_data;

mReady=[];

%disp('------------- new loop')

if timerGetPackageStatus('zFLP')==0 %if aborted stop measurement
    stop(testTimer);
    return;
end

for m=state.spc.acq.modulesInUse
    s=FLIM_test_state(m);
    status=uint16(s);
    
    if state.FLP.sequencer==0
        if(bitget(status,13)==1) %0x1000: wait for external trigger
            disp('module waiting for external trigger');
        elseif(bitget(status,8)==1) %0x80: measurement in progress (current bank)
            %disp('module collecting data');
        else
            disp([num2str(m) ' module - data ready']);
            mReady(end+1)=m;
        end
    else
        if(bitget(status,13)==1) %0x1000: wait for external trigger
            disp('module waiting for external trigger');
        elseif(bitget(status,7)==1) %0x40: measurement active
            disp('module collecting data');
        else
            FLIM_StartMeasurement(m);  %flips the reading memory bank and the data collecting memory bank in sequencing mode
            FLIM_getParameters(m);
            display(['memory bank: ',num2str(state.spc.acq.SPCdata{2}.mem_bank)])
            mReady(end+1)=m;
        end
    end
    
    %     if (bitget(status,8)==1 && state.FLP.sequencer==0) || (bitget(status,7)==1 && state.FLP.sequencer==1)
    %         disp([num2str(m) ' module - data not ready']);
    %         if(bitget(status,13)==1)
    %             disp('module waiting for external trigger');
    %         else
    %             disp('collecting data');
    %         end
    %     else
    %         disp([num2str(m) ' module - data ready']);
    %         if state.FLP.sequencer==1 %continuous aquistion mode using sequencer (data reading interval is determined by the memory filling time for one memory bank)
    %             FLIM_StartMeasurement(m);  %flips the reading memory bank and the data collecting memory bank in sequencing mode
    %             FLIM_getParameters(m);
    %             display(['memory bank: ',num2str(state.spc.acq.SPCdata{2}.mem_bank)])
    %         end
    %         mReady(end+1)=m;
    %     end
end

if isempty(mReady)
    %disp('no modules are ready for reading')
    return
end

for m=mReady
    acqTime=etime(clock, startTime);
    
    %     global timearray;
    %     timearray(end+1)=acqTime;
    
    if state.FLP.sequencer==1 %continuous aquistion mode using sequencer (data reading interval is determined by the memory filling time for one memory bank)
        display(acqTime);
        spc_readPageFLP_sequencer(acqTime); %read the disarmed memory bank
        if(spc.errCode~=0)
            display('error in reading data from spc_module');
        end
        FLIM_FillMemory(m,-1);  %clear the memory bank that was just read, -1 is for all pages
        gapTime=FLIM_ReadGapTime(1);
        
        maxpage=state.spc.acq.SPCMemConfig{m+1}.maxpage;
        if FLPdata_counter==maxpage %first reading
            timerProcess_zFLP; %initialize spc before fitting starts
        end
        
        %fitting the exponential curve to each lifetime curves from this data reading session
        %         for ch=FLIMchannels
        %             for i=FLPdata_counter-maxpage+1:10:FLPdata_counter %fit every 10 lifetime curves to reduce operation time
        %                 spc.lifetimes{ch}=FLPdata_lifetimes{i,ch};
        %                 %spc_fitexp2gaussGY(ch);
        %                 %spc_fitexpgaussGY(ch);
        %                 FLPdata_fits{i,ch}=spc.fits{ch};
        %                 figure(tauplot);
        %                 plot(FLPdata_time(i,ch),FLPdata_fits{i,ch}.beta2,'.');
        %             end
        %         end
        
        %fitting the exponential curve only to the last slice of the read data
        %             for ch=FLIMchannels
        %                 spc.lifetimes{ch}=FLPdata_lifetimes{FLPdata_counter,ch};
        %                 %spc_fitexp2gaussGY_noplot(ch);
        %                 spc_fitexpgaussGY_noplot(ch);
        %                 FLPdata_fits{FLPdata_counter,ch}=spc.fits{ch};
        %                 figure(h);
        %                 plot(FLPdata_time(FLPdata_counter,ch),FLPdata_fits{FLPdata_counter,ch}.beta2,'.');
        %             end
        display(acqTime);
        display(gapTime);
        display('-----------');
        
        %         FLIM_StartMeasurement(m);  %flips the reading memory bank and the data collecting memory bank in sequencing mode
        %         FLIM_getParameters(m);
        %         display(['memory bank: ',num2str(state.spc.acq.SPCdata{2}.mem_bank)])
    else %continuous aquistion mode without using sequencer
        display(acqTime);
        
        tic;
        spc_readPageFLP;
        t_data(FLPdata_counter+1,1)=toc;
        
        if(FLPdata_counter==0)
            timerProcess_zFLP; %initialize spc construct for fitting purpose
        end
        
        FLPdata_counter = FLPdata_counter+1;
        for ch=FLIMchannels
            spc_drawLifetime(ch,1); %draw the lifetime of this slice

            %spc_fitexp2gaussGY(ch); %double exponential fit
            %spc_fitexpgaussGY(ch); %singe exponential fit
            %spc_fitexp2prfGY(ch); %double exponential fit
            
            tic;
            FLPdata_time(FLPdata_counter,ch)=acqTime;
            FLPdata_lifetimes(FLPdata_counter,ch,:)=spc.lifetimes{ch};
            t_data(FLPdata_counter,2)=toc;
            
            tic;
            FLPdata_pc(FLPdata_counter,ch)= sum(FLPdata_lifetimes(FLPdata_counter,ch,:));
            t_data(FLPdata_counter,3)=toc;
            
            tic;
            FLPdata_tau(FLPdata_counter,ch)=spc_calculateAvgTau(ch); %avg_tau estimation by population avg not double exponential fitting
            t_data(FLPdata_counter,4)=toc;
            
            tic;
            %updating lifetime and photoncount vs. time plot
            if(FLPdata_counter==1)
                figure(tauplot);
                h_tauplot=plot(FLPdata_time(FLPdata_counter,ch),FLPdata_tau(FLPdata_counter,ch),'.');
                
                figure(photoncountplot);
                h_photoncountplot=plot(FLPdata_time(FLPdata_counter,ch), FLPdata_pc(FLPdata_counter,ch),'.');
            else
                set(h_tauplot,'XData',FLPdata_time(1:FLPdata_counter,ch),'YData',FLPdata_tau(1:FLPdata_counter,ch));
                set(h_photoncountplot,'XData',FLPdata_time(1:FLPdata_counter,ch),'YData',FLPdata_pc(1:FLPdata_counter,ch));
            end
            t_data(FLPdata_counter,5)=toc;
        end
        
        tic;
        %restart the measurement
        FLIM_FillMemory(m,0);  %clear page=0
        FLIM_StartMeasurement(m);  % arms the module, start the measurement
        t_data(FLPdata_counter,6)=toc;
    end
end

if(etime(clock, startTime) > state.FLP.totalAcqTime)
    stop(testTimer);
    for m=state.spc.acq.modulesInUse
        FLIM_StopMeasurement(1);
    end
    zFLP_DoProcessWork;
    %this has to be on if zFLP package is the only package that is being
    %used
%     if(state.files.autoSave==1)
%         state.files.lastAcquisition=state.files.lastAcquisition+1;
%     end
end
end

