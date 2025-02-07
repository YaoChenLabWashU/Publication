%dataname={'AD1_','AD2_','AD3_'};
filelist=[1 2 3 4 5 6 7 8 9 10 11 13];
mousenamelist = {'SJ270_1','SJ270_2','SJ270_3','SJ270_4','SJ270_5','SJ270_6','SJ271_7','SJ271_8','SJ271_9','SJ271_10','SJ271_11','SJ271_13'};

n=length(filelist);
timebin=20; %timebin of 50ms per data point
slider=5; %sliding average of 5s prior to data point is used as fo value
duration=101; %analysis duration of 30s
ITI=120; %intertrial interval of 200s
inputrate=1000; %1000Hz
idx=slider*inputrate/timebin;
cc_range=1;
baseline_duration=21; %baseline_duration: duration of the baseline used for the df/f calculation in
delay=50; %delay (ms) between ethovision time and DAQ aquisition time (DAQ acquisition time precedes ethovision time)
num_days=11; %number of days for all trials
output_dir=[''];

% analyze the intensity signal using the behavioral event timestamps
timestamp=[0:timebin/1000:duration];

for i=1:1:n
    dff_LED=[];     raw_LED=[];
    dff_zone=[];    raw_zone=[];
    dff_dispense=[];    raw_dispense=[];
    dff_receptacle=[];  raw_receptacle=[];
    for day=1:num_days
        %directory for photometry data
        input_dir=[''];
        %directory for behavioral data
        input_dir2=[''];
        
        for d=1:length(dataname)
            %reading behavior data
            filename2=[input_dir2,'raw data - day',num2str(day),'-trial ',num2str(filelist(i)),'.mat'];
            load(filename2,'cuetime');
            
            %reading raw photometry data
            filename=[input_dir,dataname{d},num2str(filelist(i)),'.mat'];
            load(filename,[dataname{d},num2str(filelist(i))]);
            x=eval([dataname{d},num2str(filelist(i))]);
            
            %baseline fiber autofluorescence subtraction
            x.data=x.data-baseline(d);
            
            %moving average filter
            b = (1/windowSize)*ones(1,windowSize);
            a = 1;
            y=filter(b,a,x.data);
            y=y(windowSize+1:end);
            
            %detrending of bleaching effect
            %f=fit([1:1:length(y)]',y','exp1');
            %figure(2);plot([1:1:length(y)],f.a*exp(f.b*[1:1:length(y)]),'r'); hold off;
            coeff = polyfit([1:1:length(y)],y,1);
            if(coeff(1)<0)
                for k=1:length(y)
                    y(k)=y(k)-coeff(1)*k;
                end
            end
            
            %calculate the reference intensity value
            for j=1:length(cuetime)
                fo(j)=calculate_reference(data,(cuetime(j)+delay/1000),baseline_duration,inputrate,timebin);
            end
            
            %aligning data to the LED on time
            cmap=hsv(length(cuetime));
            for j=1:length(cuetime)
                [x,y]=align_intensity_signal(data,(cuetime(j)+delay/1000),duration,baseline_duration,inputrate,timebin,fo(j));
                raw_LED(day,d,j,:)=x;
                dff_LED(day,d,j,:)=y;
                
                %                 figure(1);
                %                 plot(timestamp,squeeze(raw_LED(d,j,:)),'color',cmap(j,:));
                %                 hold on;
                %                 figure(2);
                %                 plot(timestamp,squeeze(dff_LED(d,j,:)),'color',cmap(j,:));
                %                 hold on;
            end
        end
    end
    
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    save(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
end

clear all;
%delete(findall(0,'Type','figure'));
%plot([timebin/1000:timebin/1000:40],mean(dfoverf,1));
%confplot(timestamp(1,:),m,U,L,'color',[1 0 0],'LineWidth',2);
return;
