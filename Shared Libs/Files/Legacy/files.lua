files = {}

function files.isFile(fname)
   local f = io.open(fname,'rb')
   if (f and f:read()) then 
      io.close(f) 
      return true 
   end
end

function files.remove(fname)
   local Result, ErrorString = os.remove(fname)
   if not Result then
      iguana.Logerror(ErrorString)
      return false
   else 
      return true
   end
end

function files.rename(src,dst)
   local Result, ErrorString = os.rename(src,dst)
   if not Result then
      iguana.Logerror(ErrorString)
      return false
   else 
      return true
   end
end

function files.findFile(path, fname)
   return myExecute('dir /S /B "'..path..'" | find "'..fname..'"')
end


function files.dir(Dirname, FileName)
   local TmpName = os.tmpname()
   TempFileName = string.sub (TmpName, 2)..".tmp"
   f=os.execute("dir /B /TW "..Dirname.."\\"..FileName.." > "..TempFileName)
 
   local f = io.open(TempFileName, "r")
   
   if f == nil then
      return nil
   end
   
   local rv = f:read("*all")
   f:close()
   os.remove(TempFileName)

   return rv:split("\n")   
end


function files.read(fname)
   local f = io.open(fname, "r")
   local rv = f:read("*all")
   f:close()
   return rv:split("\n")
end


function files:md5(fname)
   return util.md5(fname)
end


function files.append(fname,data)
   f=io.open(fname,'a+')
   f:write(data)
   f:close()
end
   
   
function string.split (Data, Delimiter)
   local Tabby = {}
   local From  = 1
   local DelimFrom, DelimTo = string.find( Data, Delimiter, From )
   while DelimFrom do
      local FileName = string.sub (Data, From, DelimFrom-1)
      -- Do not add the temp file we just created
      table.insert( Tabby, string.sub( Data, From , DelimFrom-1 ) )
      From  = DelimTo + 1
      DelimFrom, DelimTo = string.find( Data, Delimiter, From  )
   end
   table.insert( Tabby, string.sub( Data, From) )
   -- delete blank last row (from trailing delimiter)
   if Tabby[#Tabby]=="" then Tabby[#Tabby]=nil end
   return Tabby
end

-- split qualified string to table
function string.splitQ (Data, Delimiter, Qualifier)
   if Qualifier==nil or Qualifier=='' then
      return string.split (Data, Delimiter)
   end
   local s=Data
   local d=Delimiter
   local q=Qualifier
   s=s..d              -- ending delimiter
   local t = {}        -- table to collect fields
   local fieldstart = 1
   repeat
      -- next field is qualified? (start with q?)
      if string.find(s, '^'..q, fieldstart) then
         local a, c
         local i  = fieldstart
         repeat
            -- find closing qualifier
            a, i, c = string.find(s, q..'('..q..'?)', i+1)
         until c ~= q    -- qualifier not followed by qualifier?
         if not i then error('unmatched '..q) end
         local f = string.sub(s, fieldstart+1, i-1)
         table.insert(t, (string.gsub(f, q..q, q)))
         fieldstart = string.find(s, ',', i) + 1
      else               -- unqualified - find next delimeter
         local nexti = string.find(s, d, fieldstart)
         table.insert(t, string.sub(s, fieldstart, nexti-1))
         fieldstart = nexti + 1
      end
   until fieldstart > string.len(s)
   return t
end