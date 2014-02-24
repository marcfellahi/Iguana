--[[ This module has some helpful routines when dealing with HL7.  Use these examples as a guide to making your own utilities ]]--

hl7util = {}

-- General purpose routine to iterate through a message tree
-- to find a segment matching the Filter function given.
function hl7util.findSegment(Msg, Filter)
   for i=1, #Msg do
      if (Msg[i]:nodeType() == 'segment'
          and Filter(Msg[i])) then
         return Msg[i]
      end
   end
   for i=1, #Msg do
      local T = Msg[i]:nodeType()
      if (T == 'segment_group'
         or T == 'segment_repeated') then
         local R = hl7util.findSegment(Msg[i], Filter)
         if R ~= nil then
            return R
         end
      end
   end
end