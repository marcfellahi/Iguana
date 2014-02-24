require("node")
require("iguanaconfig")

queuemon = {}

local function trace(a,b,c,d) return end

local function CheckChannel(Chan, Count, Name)
   if Chan.Name:nodeValue() == Name then
      local QC = tonumber(Chan.MessagesQueued:nodeValue())
      trace(QC)
      if QC > Count then
         print('ALERT:\n Channel '..Name..' has '..QC..' messages queued.') 
      end   
   end
end

function queuemon.checkQueue(Param)
   -- We default to a queue count of 100
   if not Param then Param = {} end
   if not Param.count then Param.count = 5000 end
   if not Param.channel then Param.channel= iguana.channelName() end
   local url = 'http://localhost:'..
    iguanaconfig.config().iguana_config.web_config.port..'/status.html'
   trace(url)
   -- We need a user login here.  Best to use a user with few
   -- permissions.
   local S = net.http.get{url=url, 
      parameters={UserName='admin',Password='password', Format='xml'}, 
      live=true}
   S = xml.parse{data=S}
   
   trace(S.IguanaStatus:child("Channel", 2).MessagesQueued)

   for i = 1, S.IguanaStatus:childCount('Channel') do
      local Chan = S.IguanaStatus:child("Channel", i)
      CheckChannel(Chan, Param.count, Param.channel)
   end
   return "Checking queue of "..Param.channel..
          ' is less than '..Param.count
end

