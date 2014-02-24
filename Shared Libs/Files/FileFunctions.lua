-- Module that groups all functions for file handling
-- Marc Fellahi  2014-02-21  9:04am

-- Two string functions are included in this library.  They will not be part of the 
-- StringFunctions library.  They will be included in this library but will have 
-- a unique name to avoid any confusion or problem

-- Since we merged many libraries together, some functions may need tweaking.
-- be sure to update the main library once you tweak it on a customer site
-- Marc fellahi  2014-02-21  9:20am

files = {}


function files.append(fname,data)
   f=io.open(fname,'a+')
   f:write(data)
   f:close()
end


function files.copyFile(Source, Destination)
   if Source == nil or Destination == nil then
      return false
   end
   print("Copying file "..Source.." to "..Destination..".")
   if files.fileExists(Source) then
      local fileContent = readFile(Source)
      files.writeToFile(Destination, fileContent, "w")
      print("Copying file succeeded.")
      return true
   else
      return false
   end
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

   return rv:splitfile("\n")   
end


function files.fileExists(File)
   if File == nil then
      return false
   end
   print("Checking if "..File.." exists.")
   local fileId = io.popen('dir "'..File..'" /B')
   local fileContent = fileId:read('*all')
   local fileList = fileContent:split('\n')
   if #fileList > 1 then
      print(File.." exists.")
      return true
   else
      print(File.." does not exist.")
      return false
   end
end



function files.findFile(path, fname)
   return myExecute('dir /S /B "'..path..'" | find "'..fname..'"')
end


function files.isFile(fname)
   local f = io.open(fname,'rb')
   if (f and f:read()) then 
      io.close(f) 
      return true 
   end
end


function files.listFiles(Folder, Pattern)
   if Folder == nil then
      return "", 0
   end
   Pattern = Pattern or "*.*"
   print("Searching for "..Pattern.." in "..Folder..".")
   local fileId = io.popen('dir "'..Folder..Pattern..'" /B')
   local fileList = fileId:read('*a')
   local fileTable = fileList:split('\n')
   local fileCount = #fileTable-1
   print("File(s) found: \n"..fileList.."File(s) count: "..fileCount..".")
   return fileTable, fileCount
end


function files:md5(fname)
   return util.md5(fname)
end


function files.moveFile(Source, Destination)
   if Source == nil or Destination == nil then
      return false
   end
   print("Moving file "..Source.." to "..Destination..".")
   if fileExists(Source) then
      if fileExists(Destination) then
         removeFile(Destination)
      end
      local result, error = os.rename(Source, Destination)
      if not result then
         print("Moving file failed with the following error: "..error)
         return false
      end
   else
      return false
   end
   print("Moving file succeeded.")
   return true
end


function files.read(fname)
   local f = io.open(fname, "r")
   local rv = f:read("*all")
   f:close()
   return rv:splitfile("\n")
end


function files.readFile(File)
   if File == nil then
      return false
   end
   print("Reading file "..File..".")
   local fileContent = ""
   if files.fileExists(File) then
      local fileId = io.open(File)
      fileContent = fileId:read("*all")
      fileId:close()
   end
   return fileContent
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

function files.removeFile(File)
   if File == nil then
      return false
   end
   print("Removing file "..File..".")
   if fileExists(File) then
      local result, error = os.remove(File)
      if not result then
         print("Removing file failed with the following error: "..error)
         return false
      end
   else
      return false
   end
   print("Removing file succeeded.")
   return true
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

function files.writeToFile(File, Data, Mode)
   if File == nil then
      return false
   end
   Mode = Mode or "w"
   print("Writing "..Data.." to "..File.." using mode "..Mode..".")
   if Mode ~= "w" and Mode ~= "a" then
      print("Writing to file mode not valid. Must be either \"w\" or \"a\".")
      return false
   end
   local fileId = io.open(File, Mode)
   fileId:write(Data)
   fileId:close()
   return true
end

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

   
   
function string.splitfile (Data, Delimiter)
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
      return string.splitfile (Data, Delimiter)
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