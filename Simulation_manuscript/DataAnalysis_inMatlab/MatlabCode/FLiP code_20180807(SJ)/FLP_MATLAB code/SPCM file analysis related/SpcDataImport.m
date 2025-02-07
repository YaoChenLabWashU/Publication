function A = SpcDataImport(name,time)
% First, open the files and create a matrix with it.

filename = [name,'_1.asc'];
display(filename);

delimiterIn=' ';
headerlinesIn=10;
New = importdata(filename,delimiterIn,headerlinesIn);
for counter=2:time
    filename=sprintf('%s_%d.asc',filename,counter);
    display(filename);
    NewFile=importdata(filename); % Load the files and create a matrix.
    New.data=cat(1, New.data, NewFile.data);
end

figure(1);
plot(New.data(:,1),New.data(:,2));
A=New.data;

end

