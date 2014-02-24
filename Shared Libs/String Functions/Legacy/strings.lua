strings={}


function string.zfill(self,n)
   local R = n
   local L = #self
   if L < R then 
      self = '0'..self
      self:zfill(R)
   else
      z = self   
   end

   return z
end


local function validate(r,i,s)
   if r:find("%s",-lastWordTollerance) == nil then
      return r,lineLength
   
   else
      local a,b=r:find("%s",-lastWordTollerance)        
      return r:sub(1,a-1),a-1
   end
end


function string.chunk(s)
   local r={}  
   local i=1
   
   while i<#s do
      local si=s:sub(i,i+lineLength-1) 
      local ri,j=validate(si,i,s)
      r[#r+1]=ri:trimWS()  
      i=i+j
   end
 
   return r
end


function string.split(s,d)
   local t = {}
   local i = 0
   local f
   local match = '(.-)' .. d .. '()'
   if string.find(s, d) == nil then
      return {s}
   end
   for sub, j in string.gfind(s, match) do
         i = i + 1
         t[i] = sub
         f = j
   end
   if i~= 0 then
      t[i+1]=string.sub(s,f)
   end
   return t
end


