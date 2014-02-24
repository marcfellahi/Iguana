require('CoreFunctions')
require('StringFunctions')

local message = {}

function message.resubmit(T)
   local Url = T.url
   local User = T.user
   local Password = T.password
   local RefId = T.refid
   local Channel = T.channel
   local Message = T.message
   local Live = T.live or false
   if not Url or not User or not Password or
      not RefId or not Channel or not Message then
      error('Parameters url, user, password, refid, channel and message are required.',2)
   end

   -- We login first
   local Success,Result, _, Headers = pcall(net.http.get,{url=Url..'login.html', 
      parameters={username=User, password=Password },live=true})
   if not Success then
      error(Result, 2)
   end
   -- That gives us our session cookie which we use for our
   -- login credentials.  The login interface was not quite
   -- meant for an API - but the problem is solvable.
   local SessionId = Headers["Set-Cookie"]
   if not SessionId then
      error('Username and/or password wrong',2)
   end
   SessionId = Split(SessionId,' ')[1]
   trace(SessionId)

   local Success, Result = pcall(net.http.post, {url=Url..'resubmit_message', 
                   parameters={Message=Message, 
                               RefMsgId=RefId, 
                               RequestId=1, 
                               Destination=Channel},
                   headers={Cookie=SessionId}, live=Live})
   if not Success then
      error(Report, 2)
   end
   if not Live then 
      return 'Not running in editor - pass in live=true'
   end
   return Result
end

local resubmitStatusHelp = {
       Title="resubmit.resubmit",
       Usage=[[resubmit.resubmit{url=&lt;value&gt;, user=&lt;value&gt;, password=&lt;value&gt;,
   refid=&lt;value&gt;, message=&lt;value&gt;, channel=&lt;value&gt; [, live=&lt;value&gt;]}]],
       Desc=[[This function utilizes an existing Iguana web service API call to resubmit a message to a specific channel.
   Code using this function should expect that this web service call may periodically fail since it's going over the network.]],
       Returns={
          {Desc="The response data from the HTTP request (string)."},
       },
       ParameterTable=true,
       Parameters={
           {url={Desc='The root URL for the target Iguana server. i.e. http://localhost:6543/'}},
           {user={Desc='User name to login with.'}},
           {password={Desc='Password to login with.'}},
           {refid={Desc='Unique log reference ID of the message you are resubmitting.'}},
           {message={Desc='Value of the message to be resubmitted.'}},
           {channel={Desc='Unique name of the channel you are resubmitting to.'}},
           {live={Desc='Resubmit the message while in the editor.', Opt=true}},
       },
       Examples={
           [[local Result = resubmit.resubmit{url='http://localhost:6543/', user='admin', password='password'}
       refid='20130310-14420', message='Some message', channel='Some channel'}]]
       },
       SeeAlso={
           {
               Title="Resubmit module",
               Link="http://wiki.interfaceware.com/1362.html"
           }
       }
   }

help.set{input_function=message.resubmit, help_data=resubmitStatusHelp}
return message

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

