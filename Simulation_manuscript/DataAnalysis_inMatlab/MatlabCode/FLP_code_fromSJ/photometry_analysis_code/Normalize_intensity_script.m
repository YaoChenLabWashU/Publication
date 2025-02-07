%normalize intensity data

datalist=[1 2 3];
mousenamelist = {'SJ195','SJ196','SJ197','SJ198'};
num_days=11;
output_dir='';
for mouse=1:1:length(mousenamelist)
    filename = [output_dir,'analysis_',mousenamelist{mouse}];
    load(filename,'TrialData');
    
    %find max dff
    M=zeros(4,length(datalist));
    for d=datalist
        for i=1:length(TrialData);
            if(length(TrialData(i).dff_LED)>0)
                M(1,d)=max(M(1,d),max(TrialData(i).dff_LED(d,:)));
            end
            if(length(TrialData(i).dff_zone)>0)
                M(2,d)=max(M(2,d),max(TrialData(i).dff_zone(d,:)));
            end
            if(length(TrialData(i).dff_dispense)>0)
                M(3,d)=max(M(3,d),max(TrialData(i).dff_dispense(d,:)));
            end
            if(length(TrialData(i).dff_receptacle)>0)
                M(4,d)=max(M(4,d),max(TrialData(i).dff_receptacle(d,:)));
            end
        end
    end
    
    %normalize dff by max amplitude
    for d=datalist
        for i=1:length(TrialData);
            if(length(TrialData(i).dff_LED)>0)
                TrialData(i).normalized_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/M(1,d);
            end
            if(length(TrialData(i).dff_zone)>0)
                TrialData(i).normalized_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/M(2,d);
            end
            if(length(TrialData(i).dff_dispense)>0)
                TrialData(i).normalized_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/M(3,d);
            end
            if(length(TrialData(i).dff_receptacle)>0)
                TrialData(i).normalized_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/M(4,d);
            end
        end
    end
    
    save(filename,'TrialData','-append');
end

%% old script
% % %% normalize intensity data
% 
% datalist=[1 2 3];
% filelist = [1 2 3];
% mousenamelist = {'SJ163','SJ164','SJ165'};
% num_days=11;
% 
% n=length(filelist);
% 
% output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\'];


% output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\'];
% for i=1:1:n
%     outputfilename = [output_dir,'analysis_',mousenamelist{i}];
%     load(outputfilename,'raw_LED','dff_LED','raw_zone','dff_zone','raw_dispense','dff_dispense','raw_receptacle','dff_receptacle','latency_combined','latency2_combined','occupancy_combined','rewardtime_combined');
%     
%     dff_LED_normalized=Normalize(dff_LED,datalist,num_days);
%     dff_zone_normalized=Normalize(dff_zone,datalist,num_days);
%     dff_dispense_normalized=Normalize(dff_dispense,datalist,num_days);
%     dff_receptacle_normalized=Normalize(dff_receptacle,datalist,num_days);
%     
%     save(outputfilename,'dff_LED_normalized','dff_zone_normalized','dff_dispense_normalized','dff_receptacle_normalized','-append');
% end