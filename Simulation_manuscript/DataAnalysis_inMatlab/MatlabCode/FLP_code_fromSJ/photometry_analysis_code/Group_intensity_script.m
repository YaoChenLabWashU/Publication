clear all;

datalist=[1 2 3];
filelist = [1 2 3];
mousenamelist = {'SJ163','SJ164','SJ165'};
num_days=11;
input_variable_name={'dff_LED_normalized','dff_zone_normalized','dff_dispense_normalized','dff_receptacle_normalized'};

initial=[1 2 3];
intermediate=[4 5 6 7 8];
expert=[9 10 11];

n=length(filelist);

%% group data into 3 groups: initial, intermediate, expert
output_dir=['\\research.files.med.harvard.edu\neurobio\MICROSCOPE\SJ\Combined Data\20180618 JRCaMP + DA sensor mice - summary\'];
for i=1:1:n
    outputfilename = [output_dir,'analysis_',mousenamelist{i}];
    for j=1:length(input_variable_name)
        load(outputfilename,input_variable_name{j});
        data{j}=eval(input_variable_name{j});
        
        outputdata(j).name=input_variable_name{j};
        
        if(length(size(data{j}))==4)
            counter=0;
            for day=1:size(data{j},1)
                if(day==intermediate(1) || day==expert(1)) %restart counter for each category
                    counter=0;
                end
                
                for trial=1:size(data{j},3)
                    if(data{j}(day,1,trial,1)~=0)
                        counter=counter+1;
                        for d=1:size(data{j},2)
                            if day<=length(initial)
                                outputdata(j).initial(d,counter,:)=data{j}(day,d,trial,:);
                            elseif day>initial(end) && day<=intermediate(end)
                                outputdata(j).intermediate(d,counter,:)=data{j}(day,d,trial,:);
                            else
                                outputdata(j).expert(d,counter,:)=data{j}(day,d,trial,:);
                            end
                        end
                    end
                end
            end
        end
    end
    
    grouped_data=outputdata;
    save(outputfilename,'grouped_data','-append');
end