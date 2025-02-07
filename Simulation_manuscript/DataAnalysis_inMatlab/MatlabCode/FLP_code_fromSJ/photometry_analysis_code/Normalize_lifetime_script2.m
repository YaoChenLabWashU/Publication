%normalize lifetime data

%% normalize with the 95% percentile value from dtau aligned to LED

mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
% mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188',...
%     'SJ130', 'SJ136', 'SJ137', 'SJ138'};
num_days=12;
output_dir='';
ch_list=[1]; %FLIM channel in use

for mouse=1:1:length(mousenamelist)
    filename = [output_dir,'analysis_',mousenamelist{mouse}];
    load(filename,'TrialData');
    
    for d=ch_list
        %find max delta lifetime
        idx=length(TrialData(1).dtau_LED);
        data=zeros(1,idx*length(TrialData));
        for i=1:length(TrialData);
            if(length(TrialData(i).dtau_LED)>0)
                if(length(TrialData(i).dtau_LED)<idx)
                    data(idx*(i-1)+1:idx*(i-1)+length(TrialData(i).dtau_LED))=TrialData(i).dtau_LED(d,:);
                    data(idx*(i-1)+length(TrialData(i).dtau_LED):idx*i)=0;
                else
                    data(idx*(i-1)+1:idx*i)=TrialData(i).dtau_LED(d,1:idx);
                end
            end
        end
        temp=sort(abs(data));
        Normalization_factor(d)=temp(round(length(data)*0.95))
        %Normalization_factor(d)=max(abs(data))
    end
    
    %normalize dtau by 95% amplitude
    for d=ch_list
        for i=1:length(TrialData);
            if(length(TrialData(i).dtau_LED)>0)
                TrialData(i).normalized_dtau_LED(d,:)=TrialData(i).dtau_LED(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dtau_zone)>0)
                TrialData(i).normalized_dtau_zone(d,:)=TrialData(i).dtau_zone(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dtau_dispense)>0)
                TrialData(i).normalized_dtau_dispense(d,:)=TrialData(i).dtau_dispense(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dtau_receptacle)>0)
                TrialData(i).normalized_dtau_receptacle(d,:)=TrialData(i).dtau_receptacle(d,:)/Normalization_factor(d);
            end
        end
    end
    
    save(filename,'TrialData','-append');
end


%% normalize with the max amplitude
% 
% mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
% num_days=11;
% output_dir='';
% ch_list=[1]; %FLIM channel in use
% 
% for i=mouse:1:length(mousenamelist)
%     filename = [output_dir,'analysis_',mousenamelist{mouse}];
%     load(filename,'TrialData');
%     
%     %find max delta lifetime
%     M=zeros(4);
%     for d=ch_list
%         for i=1:length(TrialData);
%             if(length(TrialData(i).dtau_LED)>0)
%                 M(1,d)=max(M(1,d),max(abs(TrialData(i).dtau_LED(d,:))));
%             end
%             if(length(TrialData(i).dtau_zone)>0)
%                 M(2,d)=max(M(2,d),max(abs(TrialData(i).dtau_zone(d,:))));
%             end
%             if(length(TrialData(i).dtau_dispense)>0)
%                 M(3,d)=max(M(3,d),max(abs(TrialData(i).dtau_dispense(d,:))));
%             end
%             if(length(TrialData(i).dtau_receptacle)>0)
%                 M(4,d)=max(M(4,d),max(abs(TrialData(i).dtau_receptacle(d,:))));
%             end
%         end
%     end
%     
%     %normalize dff by max amplitude
%     for d=ch_list
%         for i=1:length(TrialData);
%             if(length(TrialData(i).dtau_LED)>0)
%                 TrialData(i).normalized_dtau_LED(d,:)=TrialData(i).dtau_LED(d,:)/M(1,d);
%             end
%             if(length(TrialData(i).dtau_zone)>0)
%                 TrialData(i).normalized_dtau_zone(d,:)=TrialData(i).dtau_zone(d,:)/M(2,d);
%             end
%             if(length(TrialData(i).dtau_dispense)>0)
%                 TrialData(i).normalized_dtau_dispense(d,:)=TrialData(i).dtau_dispense(d,:)/M(3,d);
%             end
%             if(length(TrialData(i).dtau_receptacle)>0)
%                 TrialData(i).normalized_dtau_receptacle(d,:)=TrialData(i).dtau_receptacle(d,:)/M(4,d);
%             end
%         end
%     end
%     
%     save(filename,'TrialData','-append');
% end