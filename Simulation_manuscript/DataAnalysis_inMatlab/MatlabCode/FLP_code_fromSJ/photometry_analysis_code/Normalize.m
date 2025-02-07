function data_normalized = Normalize(data,data_list,num_days)
%UNTITLED2 Summary of this function goes here
%   Normalize the data across days and trials
%data: intensity data 4-D array: # of days X data number X trial number X time
%d: AD channel number

%find maximum intensity df/f across trials and days
M=zeros(1,length(data_list));
for d=data_list
    for i=1:num_days
        for j=1:size(data,3)
            M(d)=max(M(d),max(data(i,d,j,:)));
        end
    end
end
  
%normalize data df/f using the maximum
data_normalized=[];
for d=data_list
    for i=1:num_days
        for j=1:size(data,3)
            data_normalized(i,d,j,:)=data(i,d,j,:)/M(d);
        end
    end
end

end