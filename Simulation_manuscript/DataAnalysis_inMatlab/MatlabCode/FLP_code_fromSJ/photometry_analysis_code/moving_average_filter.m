function [output] = moving_average_filter(input,averaging_bin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    output=zeros(1,length(input));
    for i=averaging_bin:length(input)
        output(i)=mean(input(i-averaging_bin+1:i));
    end
end

