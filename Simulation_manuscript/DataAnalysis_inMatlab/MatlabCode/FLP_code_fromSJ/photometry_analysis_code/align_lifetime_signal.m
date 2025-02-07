%normalize lifetime data

datalist=[1];
mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
num_days=11;
output_dir='';
for i=1:1:length(mousenamelist)
    filename = [output_dir,'analysis_',mousenamelist{i}];
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