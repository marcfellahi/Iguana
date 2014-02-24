-- $Revision: 1.5 $
-- $Date: 2012-12-06 17:11:49 $

--
-- The retry module
-- Copyright (c) 2011-2012 iNTERFACEWARE Inc. ALL RIGHTS RESERVED
-- iNTERFACEWARE permits you to use, modify, and distribute this file in accordance
-- with the terms of the iNTERFACEWARE license agreement accompanying the software
-- in which it is used.
--

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
   checkParam(P, {['func']=0, arg1=0, arg2=0,arg3={},arg4=0, retry=0, pause=0}, Usage)
   if type(P.func) ~= 'function' then
      error('Missing func argument.\n\n'..Usage, 2)
   end
   
   local RetryCount = P.retry or 100
   local Delay = P.pause or 10
   local F = P.func

   local A1=P.arg1
   local A2=P.arg2
   local A3=P.arg3
   local A4=P.arg4
   
   trace(F,A3)
   
   local D = 'Will retry '..RetryCount..' times with pause of '..Delay..' seconds.'
   if iguana.isTest() then
      -- In the editor we do not call pcall so that the editor can catch errors
      local R = {pcall(F, A1,A2,A3,A4)}
      R[#R+1] = D
      return unpack(R,2)
   end
   for i =1, RetryCount do
      local R = {pcall(F, A1,A2,A3,A4)}
      if R[1] then
         if i > 1 then
            iguana.setChannelStatus{color='green', text='Recovered from smtp error'}
            print('Recovered from smtp error.')
         end
         R[#R+1] = D
         return unpack(R,2)
      end
      local E = 'Error connecting to smtp. Retrying ('
      ..i..' of '..RetryCount..')...'
      iguana.setChannelStatus{color='yellow',
         text=E}
      sleep(Delay)
      print(E)
   end
   iguana.setChannelStatus{text='Was unable to recover from smtp error.'}
   error('Unable to recover.  Stopping channel.')   
end