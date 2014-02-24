throttled = {}

local function IsWeekday(Day)
   -- Sunday == 1, Saturday == 7
   return Day ~= 1 or Day ~= 7
end
 
local function IsPeakTime(Hours, Minutes)   
   
   -- assuming peak time is 10:30 am (10:30) to 3:30 pm (15:30)
   if Hours >= 19 and Hours <= 23 then
      return true
   else 
      return false
   end
   --return  (Hours > 02 and Hours < 04) or
   --        (Hours > 08 and Hours < 11) or
          --((Hours == 21 and Minutes >= 30) and 
          -- (Hours == 23 and Minutes <= 00))
   --        (Hours >= 21 and Hours <= 22)

end   

-- The definition of "peak period" will be dependent on the situation.
-- Thus this code will be unique for each user.
function IsPeakPeriod()
   local Date = os.date("*t")
   
   local IsWeekdayValue = IsWeekday(Date.wday) -- wday range is (1-7)
   local IsPeakTimeValue = IsPeakTime(Date.hour, Date.min) -- hour range is (0-23)
                                                           -- min range is (0-59)
   if IsWeekdayValue and IsPeakTimeValue
   then
      return true
   else
      return false   
   end    
end 