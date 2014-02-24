-- Useful extension string method
function string.split(s, d)		
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