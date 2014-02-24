function findtextinfile(file,stringmatch)

   local filefind                = ''
   local fileread                = ''
   local stringextract           = ''
   local stringstart, stringend  = 0
   
   filefind = assert(io.open(file, "r"), "Could not open file: "..file)   
   
   if filefind ~= nil then
   
      for line in filefind:lines() do 
         
         stringstart, stringend = line:find(stringmatch)
         
         if stringstart ~= nil then 
            
            --print('Found shipment code at: ', stringstart, ' - shipment code is: ', line:sub(stringend+1))
            stringextract = line:sub(stringend+1)
            
            io.close(filefind)
            
            return stringextract
            
         end
            
      end
            
      io.close(filefind)
                  
   end
      
   return nil
   
end