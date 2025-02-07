clear all;


dataname={'AD3_'};
%dataname='AD2_';
filelist = [1 2 3 4];
mousenamelist = {'139','141','117','118'};
n=length(filelist);
n_trial = 10;
timebin=50; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=30; %acquistion duration of 30s
ITI=120; %intertrial interval of 200s
first_time=120-10; %first pellet dropped at 120s, analyze starting 20s before pellet dropping
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
total_duration=1321; %2400s
cc_range=1;
dispense_time=10; %pellet dispensed at 10s

titlelabel=['pellet dispensed at 10s, '];


%% analyze the raw signal
cmap = colormap(hsv(n_trial));
f=[];
timestamp=[0:timebin/1000:duration];
dfoverf=[];
dfoverf2=[];
raw_f=[];
legendlabel={};

for i=1:n_trial
    legendlabel{i}=['trial ',num2str(i)];
end

for i=1:1:n
    for d=1:length(dataname)
        filename=[dataname{d},num2str(filelist(i)),'.mat'];
        load(filename,[dataname{d},num2str(filelist(i))]);
        x=eval([dataname{d},num2str(filelist(i))]);
        data=[];
        for k=1:floor(total_duration*inputrate/timebin)
            data(k) = sum(x.data(timebin*(k-1)+1:timebin*k));
        end
        temp=sort(data);
        fo_5 = mean(temp(1:round(length(temp)*0.05)));
        clear temp;
        
        for k=1:n_trial
            %data=x.data((first_time+(k-1)*ITI)*inputrate:(first_time+(k-1)*ITI+duration)*inputrate);
            f=data((first_time+(k-1)*ITI)*inputrate/timebin:(first_time+(k-1)*ITI+duration)*inputrate/timebin);
            
            % plotting baseline standard deviation
            %     SD = std(dfoverf(i,:))*ones(size(f));
            %     x = [timestamp,fliplr(timestamp)];
            %     inBetween=[SD,-fliplr(SD)];
            %     s = fill(x,inBetween,cmap(i,:));
            %     alpha(s,.2);
            %     plot(timestamp,SD,'color',cmap(i,:));
            %     hold on;
            %     plot(timestamp,-SD,'color',cmap(i,:));
            %     hold off;
            
            %using fo = average of first 10s
            fo = mean(f(1:10000/timebin));
            dfoverf1(k,1:length(f))=(f-fo)/fo*100;
            figure(1+(i-1)*10);
            plot(timestamp,dfoverf1(k,:),'color',cmap(k,:));
            title(['df/f (%) vs. time (s):',titlelabel,' fo=avg of first 10s, ',num2str(n_trial),' trials']);
            legend(legendlabel);
            xlabel('time (s)');
            ylabel('df/f (%)');
            hold on;
            
            %using fo = average of lowest 5%
            dfoverf2(k,1:length(f))=(f-fo_5)/fo_5*100;
            figure(2+(i-1)*10);
            plot(timestamp,dfoverf2(k,:),'color',cmap(k,:));
            title(['df/f (%) vs. time (s):',titlelabel,' fo=avg of lowest 5%, ',num2str(n_trial),' trials']);
            legend(legendlabel);
            xlabel('time (s)');
            ylabel('df/f (%)');
            hold on;
            
            figure(3+(i-1)*10);
            raw_f(k,:)=f;
            plot(timestamp,raw_f(k,:),'color',cmap(k,:));
            title(['raw fluorescence (AU) vs. time (s):',titlelabel,num2str(n_trial),' trials']);
            legend(legendlabel);
            xlabel('time (s)');
            ylabel('raw fluorescence (AU)');
            hold on;
        end
        
        figure(4+(i-1)*10);
        stderror=std(dfoverf1,0,1)/sqrt(n);
        confplot(timestamp,mean(dfoverf1),stderror,stderror,'color',[1 0 0],'LineWidth',2);
        title(['df/f (%) vs. time (s):', titlelabel,', fo=avg of first 10s, ',num2str(n_trial),' trials']);
        xlabel('time (s)');
        ylabel('df/f (%)');
        avg_dff(i,:)=mean(dfoverf1);
        ste_dff(i,:)=stderror;
        
        figure(5+(i-1)*10);
        stderror=std(dfoverf2,0,1)/sqrt(n);
        confplot(timestamp,mean(dfoverf2),stderror,stderror,'color',[1 0 0],'LineWidth',2);
        title(['df/f (%) vs. time (s):',titlelabel,' fo=avg of lowest 5%, ',num2str(n_trial),' trials']);
        xlabel('time (s)');
        ylabel('df/f (%)');
        
        figure(6+(i-1)*10);
        stderror=std(raw_f,0,1)/sqrt(n);
        confplot(timestamp,mean(raw_f),stderror,stderror,'color',[1 0 0],'LineWidth',2);
        title(['raw fluorescence (AU) vs. time (s):',titlelabel, num2str(n_trial),' trials']);
        xlabel('time (s)');
        ylabel('raw fluorescence (AU)');
        
        figure(1+(i-1)*10);hold off;
        savefig(['dfoverf_ind_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        figure(2+(i-1)*10);hold off;
        savefig(['dfoverf2_ind_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        figure(3+(i-1)*10);hold off;
        savefig(['raw_f_ind_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        
        figure(4+(i-1)*10);hold off;
        savefig(['dfoverf_avg_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        figure(5+(i-1)*10);hold off;
        savefig(['dfoverf2_avg_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        figure(6+(i-1)*10);hold off;
        savefig(['raw_f_avg_SJ',mousenamelist{i},'_side',num2str(d),'.fig']);
        
        filename2=['analysis_SJ',mousenamelist{i},'_side',num2str(d),'.mat'];
        save(filename2,'dfoverf1','dfoverf2','raw_f')
        
        dff(d,:,:)=dfoverf1;
    end
    
%     %cross correlation between two sides (higher resolution of 50ms)
%     figure(1);
%     l=cc_range*1000/timebin;
%     time=[wrev(-timestamp(1:l+1)),timestamp(2:l+1)];
%     cc=[];
%     for k=1:n_trial
%         x=squeeze(dff(1,k,:));
%         y=squeeze(dff(2,k,:));
%         cc(k,:)=xcorr(x,y);
%         figure(1);
%         plot(time,cc(k,ceil(length(cc)/2)-l:ceil(length(cc)/2)+l),'color',cmap(k,:));
%         hold on;
%     end
%     title(['Cross correlation between df/f of side 1 and side 2: SJ',mousenamelist{i}]);
%     legend(legendlabel);
%     ymax=get(gca,'ylim');
%     %plot([length(cc)/2,length(cc)/2],ymax,'k');
%     plot([0 0],ymax,'k');
%     hold off;
%     savefig(['cross  correlation_SJ',mousenamelist{i}]);
% 
%     %cross correlation between two sides
%     figure(2);
%     time=[wrev(-timestamp),timestamp(2:end)];
%     cc=[];
%     for k=1:n_trial
%         x=squeeze(dff(1,k,:));
%         y=squeeze(dff(2,k,:));
%         cc(k,:)=xcorr(x,y);
%         plot(time,cc(k,:),'color',cmap(k,:));
%         hold on;
%     end
%     figure(2);
%     title(['Cross correlation between df/f of side 1 and side 2: SJ',mousenamelist{i}]);
%     legend(legendlabel);
%     ymax=get(gca,'ylim');
%     plot([0 0],ymax,'k');
%     hold off;
%     savefig(['cross  correlation2_SJ',mousenamelist{i}]);
%     
%     %plotting df/f of one side vs. the other
%     figure(3);
%     x=[]; y=[];
%     for k=1:n_trial
%         x=[x,squeeze(dff(1,k,:))'];
%         y=[y,squeeze(dff(2,k,:))'];
%     end
%     plot(x,y,'.');
%     title(['df/f of side 1 vs. side 2: SJ',mousenamelist{i}]);
%     figure(2);
%     savefig(['two side comparison of dff_SJ',mousenamelist{i}]);
    
    %R square calculation from the linear fit 
%     p1 = 0.52211
%     p2 = 0.25418
%     ye=p1*x+p2;
%     rsq=1-sum((y-ye).^2)/sum((y-mean(y)).^2)
    

end

delete(findall(0,'Type','figure'));
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;

figure(1);
cmap=hsv(9);
for i=1:5
    plot(timestamp,avg_dff(i+4,:),'color',cmap(i+4,:));
    hold on;
end

%% analyze the food stimulus evoked DA signal peak
mousenamelist = {'139'};

for i=1:length(mousenamelist)
    filename=['analysis_SJ',mousenamelist{i},'_side1.mat'];
    load(filename);
    data1=dfoverf1;
    
    filename=['analysis_SJ',mousenamelist{i},'_side2.mat'];
    load(filename);
    data2=dfoverf1;
    
    %half width calculation
    halfwidth1=[];
    halfwidth2=[];
    for j=1:size(data1,1)
        halfwidth1(j)=cal_halfwidth(data1(j,:),timebin);
        halfwidth2(j)=cal_halfwidth(data2(j,:),timebin);
    end
    
    %amplitude calculation
    amplitude_interval = mean([halfwidth1,halfwidth2]); %halfwidth for amplitude averaging duration
    amplitude1=[];
    amplitude2=[];
    amplitude3=[];
    x=[];
    y=[];
    
    for j=1:size(data1,1)
        amplitude1(j)=cal_amplitude(data1(j,:),timebin,amplitude_interval);
        
        %locating the peak of the other side near the peak of the side 1
        idx=find(data1(j,:)==max(data1(j,dispense_time*inputrate/timebin:end)),1);
        idx_start=max(idx-round(amplitude_interval*inputrate/timebin),1);
        idx_end=min(idx+round(amplitude_interval*inputrate/timebin),length(data1));
        amplitude2(j)=cal_amplitude(data2(j,idx_start-1:idx_end+1),timebin,amplitude_interval);
        
        %average amplitude of the other trials at the same time point
        temp=zeros(1,19);
        temp_counter=0;
        for l=1:size(data,1)
            if(l~=j)
                temp_counter=temp_counter+1;
                temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,halfwidth(k));
            end
        end
        amplitude3(j)=mean(temp);
        
        x=[x,amplitude1(j)*ones(1,length(temp))];
        y=[y,temp];
        
        figure(1);
        plot(data1(j,:),'b');
        hold on;
        plot(idx,data1(j,idx),'.r');
        hold off;
        
        figure(2);
        plot(data2(j,:),'b');
        hold on;
        plot(idx,data2(j,idx),'.r');
        hold off;
        
        display(idx);
    end
    
    figure(3);
    plot(amplitude1,amplitude2,'.');
    title('Evoked DA signal peak amplitude of two sides (df/f %)');
    
    %linear_fit=fitlm(amplitude1,amplitude2,'Intercept',false)
    linear_fit=fitlm(amplitude1,amplitude2)
    
%     figure(4);
%     plot(amplitude1,amplitude3,'.');
%     title('peak amplitude of side 1 vs. side2 in the different trials');
%     linear_fit=fitlm(amplitude1,amplitude3)

    figure(4);
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
end

return
%     
%% analyze the spontaneous DA signal peak
halfwidth=[];
halfwidth2=[];
M=0;
peak=[];
idx_peak=[];
baseline=[];
baseline_duration=10; %10s

for i=1:length(mousenamelist)
    counter=0;
    amplitude_mini1=[];
    amplitude_mini2=[];
    amplitude_mini3=[];
    x=[];
    y=[];
    
    filename=['analysis_SJ',mousenamelist{i},'_side1.mat'];
    load(filename);
    data=dfoverf1;
   
    filename=['analysis_SJ',mousenamelist{i},'_side2.mat'];
    load(filename);
    data2=dfoverf1;
    
    idx_end=baseline_duration*inputrate/timebin;
    baseline=[];
    for k=1:size(data,1)
        baseline(i,(k-1)*idx_end+1:k*idx_end)=data(1:idx_end);
    end
    SD(i) = std(baseline(i,:));

    %finding spontaneous peaks during the baseline before the food reward stimulus
    
    for j=1:size(data,1)       
        %only look at +1s ~ baseline duration -1s time duration for mini peaks
        r=0.5;
        range=[0,0];
        range(1)=r*2*inputrate/timebin;
        range(2)=(baseline_duration-r*2)*inputrate/timebin;
        idx_peak=[];
        halfwidth=[];
        
        %preliminary peaks with the range of 0.5
        idx_peak=find_peaks(data(j,:),SD(i),range,r,timebin,inputrate)

        if(length(idx_peak)>0)
            for k=1:length(idx_peak)
                halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
            end
            
            %updated peaks with the range of preliminary halfwidths
            r=max(halfwidth);
            halfwidth=[];
            
            idx_peak=find_peaks(data(j,:),SD(i),range,r,timebin,inputrate)
            
            for k=1:length(idx_peak)
                halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
                idx_start=max(idx_peak(k)-round(halfwidth(k)*inputrate/timebin),1);
                idx_end=min(idx_peak(k)+round(halfwidth(k)*inputrate/timebin),length(data));
                
                counter=counter+1;
                amplitude_mini1(counter)=cal_amplitude(data(j,idx_start:idx_end),timebin,halfwidth(k));
                amplitude_mini2(counter)=cal_amplitude(data2(j,idx_start:idx_end),timebin,halfwidth(k));
                
                %average amplitude of the other trials at the same time point
                temp=zeros(1,19);
                temp_counter=0;
                for l=1:size(data,1)
                    if(l~=j)
                        temp_counter=temp_counter+1;
                        temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,halfwidth(k));
                    end
                end
                amplitude_mini3(counter)=mean(temp);
                
                x=[x,amplitude_mini1(counter)*ones(1,length(temp))];
                y=[y,temp];
            end
            
%             figure(1);
%             plot(data(j,:),'b');
%             hold on;
%             plot(idx_peak(:),data(j,idx_peak(:)),'.r');
%             hold off;
%             display(idx_peak);
%             
%             figure(2);
%             plot(data2(j,:),'b');
%             hold on;
%             plot(idx_peak(:),data2(j,idx_peak(:)),'.r');
%             hold off;
%             display(idx_peak);
        end
    end 
    figure(3);
    plot(amplitude_mini1,amplitude_mini2,'.');
    title('spontaneous peak amplitude of side 1 vs. side2');
    linear_fit=fitlm(amplitude_mini1,amplitude_mini2)
    
    figure(4);
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
    
%     figure(4);
%     plot(amplitude_mini1,amplitude_mini3,'.');
%     title('peak amplitude of side 1 vs. side2 in the different trials');
%     linear_fit=fitlm(amplitude_mini1,amplitude_mini3)
end

return;

%% analyze all peaks above 2SD of the baseline (10s before food) including the food evoked and the spontaneous DA signal peaks
halfwidth=[];
halfwidth2=[];
M=0;
peak=[];
idx_peak=[];
baseline=[];
baseline_duration=10; %10s

for i=1:length(mousenamelist)
    counter=0;
    amplitude_1=[];
    amplitude_2=[];
    amplitude_3=[];
    x=[];
    y=[];
    
    filename=['analysis_SJ',mousenamelist{i},'_side1.mat'];
    load(filename);
    data=dfoverf1;
   
    filename=['analysis_SJ',mousenamelist{i},'_side2.mat'];
    load(filename);
    data2=dfoverf1;
    
    idx_end=baseline_duration*inputrate/timebin;
    %idx_end=60*inputrate/timebin;
    baseline=[];
    for k=1:size(data,1)
        baseline(i,(k-1)*idx_end+1:k*idx_end)=data(1:idx_end);
    end
    SD(i) = std(baseline(i,:));

    %finding spontaneous peaks during the baseline before the food reward stimulus
    for j=1:size(data,1)
        %only look at +1s ~ end ITI-1s time duration for mini peaks
        r=0.5;
        range=[0,0];
        range(1)=r*2*inputrate/timebin;
        range(2)=(duration-r*2)*inputrate/timebin;
        idx_peak=[];
        halfwidth=[];
        
        %preliminary peaks with the range of 0.5
        idx_peak=find_peaks(data(j,:),SD(i),range,r,timebin,inputrate)
        for k=1:length(idx_peak)
            halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
        end
        
        %updated peaks with the range of preliminary halfwidths
        r=max(halfwidth);
        range(1)=2*r*inputrate/timebin;
        range(2)=(duration-2*r)*inputrate/timebin;
        halfwidth=[];
        
        idx_peak=find_peaks(data(j,:),SD(i),range,r,timebin,inputrate)
        for k=1:length(idx_peak)
            halfwidth(k)=cal_halfwidth(data(j,max(idx_peak(k)-r*inputrate/timebin,1):min(idx_peak(k)+r*inputrate/timebin,length(data))),timebin);
            idx_start=max(idx_peak(k)-round(halfwidth(k)*inputrate/timebin),1);
            idx_end=min(idx_peak(k)+round(halfwidth(k)*inputrate/timebin),length(data));
            
            counter=counter+1;
            amplitude1(counter)=cal_amplitude(data(j,idx_start:idx_end),timebin,halfwidth(k));
            amplitude2(counter)=cal_amplitude(data2(j,idx_start:idx_end),timebin,halfwidth(k));
            
            %average amplitude of the other trials at the same time point
            temp=zeros(1,19);
            temp_counter=0;
            for l=1:size(data,1)
                if(l~=j)
                    temp_counter=temp_counter+1;
                    temp(temp_counter)=cal_amplitude(data2(l,idx_start:idx_end),timebin,halfwidth(k));
                end
            end
            amplitude3(counter)=mean(temp);
            x=[x,amplitude1(counter)*ones(1,length(temp))];
            y=[y,temp];
            
%             if(amplitude1(counter)<0 || amplitude2(counter)<0)
%                 display(idx_peak(k));
%                 
%                 figure(1);
%                 plot(data(j,:),'b');
%                 hold on;
%                 plot(idx_peak(:),data(j,idx_peak(:)),'.r');
%                 hold off;
%                 display(idx_peak);
%                 
%                 figure(2);
%                 plot(data2(j,:),'b');
%                 hold on;
%                 plot(idx_peak(:),data2(j,idx_peak(:)),'.r');
%                 hold off;
%                 display(idx_peak);
%             end
        end
        
        figure(1);
        plot(data(j,:),'b');
        hold on;
        plot(idx_peak(:),data(j,idx_peak(:)),'.r');
        hold off;
        display(idx_peak);
        
        figure(2);
        plot(data2(j,:),'b');
        hold on;
        plot(idx_peak(:),data2(j,idx_peak(:)),'.r');
        hold off;
        display(idx_peak);        
        
    end 
    figure(3);
    plot(amplitude1,amplitude2,'.');
    title('peak amplitude of side 1 vs. side2 in the same trial');
    linear_fit=fitlm(amplitude1,amplitude2)
    
    figure(4);
%     plot(amplitude1,amplitude3,'.');
%     title('peak amplitude of side 1 vs. side2 in the different trials');
%     linear_fit=fitlm(amplitude1,amplitude3)
    plot(x,y,'.');
    title('peak amplitude of side 1 vs. side2 in the different trials');
    linear_fit=fitlm(x,y)
    
    c=0;
    for i=1:counter
        if(length(find(amplitude1(i)==amplitude1)) >1 || length(find(amplitude2(i)==amplitude2)) >1)
            list=find(amplitude1(i)==amplitude1);
            for j=1:length(list)-1
                if(list(j)==list(j+1))
                    c=c+1;
                    find(amplitude1(i)==amplitude1)
                    find(amplitude2(i)==amplitude2)
                end
            end
            
            list=find(amplitude2(i)==amplitude2);
            for j=1:length(list)-1
                if(list(j)==list(j+1))
                    c=c+1;
                    find(amplitude1(i)==amplitude1)
                    find(amplitude2(i)==amplitude2)
                end
            end
        end
    end
    display(c);
end