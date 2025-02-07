function [date_cell] = date_gen(date, added_days)
%Input a string of numbers into date in format YYYYMMDD and indicate how
%many experimental days were performed. Function returns a cell containing
% output dates

dispcount = 0;

year = date(1:4); year = str2num(year);
month = date(5:6); month = str2num(month);
day = date(7:8); day = str2num(day);

%parameters to months and leapyears
leapyearlist = [2020:4:2100];
day31 = [1 3 5 7 8 10 12];
day30 = [4 6 9 11];
day28 = [2];

date_cell = cell(length(added_days));

for i = [1:added_days]
    
    %adds additional 0 to string if month/day is <10
    if month<10
        monthstr = ['0' num2str(month)];
    else
        monthstr = num2str(month);
    end
    if day<10
        daystr = ['0' num2str(day)];
    else
        daystr = num2str(day);
    end
           
    date_cell{i} = [num2str(year), monthstr , daystr];
    
    if any(ismember(month, day31))
        dayinmonth = 31;
    elseif any(ismember(month, day30))
        dayinmonth = 30;
    elseif any(ismember(month, day28))
            if any(ismember(year, leapyearlist))
                if dispcount == 0
                    display('Year is identified as leapyear and days in Feb are set as 29')
                    dispcount =1;
                end
                    dayinmonth = 29;
            else
                dayinmonth = 28;
            end
    end
    if day == dayinmonth
        month = month+1;
        if month == 13
            month = 1;
        end
        day = 1;
    else
        day = day+1;
    end
    
end

