CoreFunctions={}

-- This module does a lazy load of the Iguana Configuration file - it only loads the file once
iguanaconfig={}

function ReadFile(Filename)
   
   local F = io.open(Filename)
   local X = F:read("*all")
   F:close()
   
   return X
   
end

function iguanaconfig.config()
   local X = ReadFile('IguanaConfiguration.xml')
   return xml.parse{data=X}
end

function Load_Messages(Data)

local MessageTable = {}

   for i=1, Data.entries:childCount('entry') do

      MessageTable[Data.entries[i].key[1]:nodeValue()] = {Data.entries[i].value[1]:nodeValue()}

   end
   
   return MessageTable
end


function MessagesQueued(IguanaChannel)
   
   local url = 'http://localhost:'..iguanaconfig.config().iguana_config.web_config.port..'/status.html'
   -- We need a user login here.  Best to use a user with few
   -- permissions.
   local S = net.http.get{url=url, 
      parameters={UserName='admin',Password='L0g1d246', Format='xml'}, 
      live=true}
   
   S = xml.parse{data=S}
   
   for i=1, S.IguanaStatus:childCount('Channel') do
      
      local Channel = S.IguanaStatus:child("Channel",i)
      
      if Channel.Name:nodeValue() == IguanaChannel then
         
         local QC = tonumber(Channel.MessagesQueued:nodeValue())
         
         return QC
   
      end
      
   end  
   
end

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


-- $Revision: 1.3 $

retry={}

local function sleep(S)
   if not iguana.isTest() then
      util.sleep(S*1000)
   end
end

local function checkParam(T, List, Usage)
   if type(T) ~= 'table' then
      error(Usage,3)
   end
   for K,V in pairs(T) do
      if not List[K] then error('Unknown parameter "'..K..'"\n\n'..Usage, 3) end
   end
end
 
local Usage=[[
Retries routines repeatedly.  

The main purpose of this is for implementing retry logic in interfaces
for handling resources which might not always be available like databases.

Returns: A description of the number of retries
Accepts a table with the required entries:
   'func'  - The function to call
 These additional optional entries exist:
   'arg1'  - First argument into the function being called
   'retry' - Count of times to retry - defaults to 100
   'pause' - Delay between retries, defaults to 10 seconds
 
e.g. retry.call{'func'=DoMerge, 'arg1'=T}
]]

-- This function will call with a retry sequence - default is 100 times with a pause of 10 seconds between retries
function retry.call(P)--F, A, RetryCount, Delay)
   checkParam(P, {['func']=0, arg1=0, retry=0, pause=0}, Usage)
   if type(P.func) ~= 'function' then
      error('Missing func argument.\n\n'..Usage, 2)
   end
   
   local RetryCount = P.retry or 100
   local Delay = P.pause or 10
   local F = P.func
   local A = P.arg1
   local D = 'Will retry '..RetryCount..' times with pause of '..Delay..' seconds.'
   if iguana.isTest() then
      -- In the editor we do not call pcall so that the editor can catch errors
      local R = {pcall(F, A)}
      R[#R+1] = D
      return unpack(R,2)
   end
   
   iguana.setTimeout(3250)
   
   for i =1, RetryCount do
      local R = {pcall(F, A)}
      if R[1] then
         if i > 1 then
            iguana.setChannelStatus{color='green', text='Recovered from SMTP error'}
            print('Recovered from SMTP error.')
         end
         R[#R+1] = D
         return unpack(R,2)
      end
      local E = 'Error connecting to SMTP server. Retrying ('
      ..i..' of '..RetryCount..')...'
      iguana.setChannelStatus{color='yellow',
         text=E}
      sleep(Delay)
      print(E)
   end
   iguana.setChannelStatus{text='Was unable to recover from SMTP error.'}
   error('Unable to recover.  Stopping channel.')   
end

