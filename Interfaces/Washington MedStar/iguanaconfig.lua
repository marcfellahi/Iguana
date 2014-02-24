-- This module does a lazy load of the Iguana Configuration file - it only loads the file once
iguanaconfig={}

-- We open the configuration file once at compile time
local F = io.open('IguanaConfiguration.xml', 'r')
local C = F:read('*a')

function iguanaconfig.config()
   return xml.parse{data=C}
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
      parameters={UserName='admin',Password='password', Format='xml'}, 
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