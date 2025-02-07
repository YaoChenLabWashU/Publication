%normalize intensity data

mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
num_days=11;
output_dir='';
ch_list=[1]; %FLIM channel in use

for mouse=1:1:length(mousenamelist)
    filename = [output_dir,'analysis_',mousenamelist{mouse}];
    load(filename,'TrialData');
    
    %find max delta lifetime
    M=zeros(4);
    for d=ch_list
        for i=1:length(TrialData);
            if(length(TrialData(i).dtau_LED)>0)
                M(1,d)=max(M(1,d),max(abs(TrialData(i).dtau_LED(d,:))));
            end
            if(length(TrialData(i).dtau_zone)>0)
                M(2,d)=max(M(2,d),max(abs(TrialData(i).dtau_zone(d,:))));
            end
            if(length(TrialData(i).dtau_dispense)>0)
                M(3,d)=max(M(3,d),max(abs(TrialData(i).dtau_dispense(d,:))));
            end
            if(length(TrialData(i).dtau_receptacle)>0)
                M(4,d)=max(M(4,d),max(abs(TrialData(i).dtau_receptacle(d,:))));
            end
        end
    end
    
    %normalize dff by max amplitude
    for d=ch_list
        for i=1:length(TrialData);
            if(length(TrialData(i).dtau_LED)>0)
                TrialData(i).normalized_dtau_LED(d,:)=TrialData(i).dtau_LED(d,:)/M(1,d);
            end
            if(length(TrialData(i).dtau_zone)>0)
                TrialData(i).normalized_dtau_zone(d,:)=TrialData(i).dtau_zone(d,:)/M(2,d);
            end
            if(length(TrialData(i).dtau_dispense)>0)
                TrialData(i).normalized_dtau_dispense(d,:)=TrialData(i).dtau_dispense(d,:)/M(3,d);
            end
            if(length(TrialData(i).dtau_receptacle)>0)
                TrialData(i).normalized_dtau_receptacle(d,:)=TrialData(i).dtau_receptacle(d,:)/M(4,d);
            end
        end
    end
    
    save(filename,'TrialData','-append');
end