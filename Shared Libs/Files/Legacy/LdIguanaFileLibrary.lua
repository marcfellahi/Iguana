require ("StringFunctions")

function fileExists(File)
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

function listFiles(Folder, Pattern)
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

function readFile(File)
   if File == nil then
      return false
   end
   print("Reading file "..File..".")
   local fileContent = ""
   if fileExists(File) then
      local fileId = io.open(File)
      fileContent = fileId:read("*all")
      fileId:close()
   end
   return fileContent
end

function writeToFile(File, Data, Mode)
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

function moveFile(Source, Destination)
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

function copyFile(Source, Destination)
   if Source == nil or Destination == nil then
      return false
   end
   print("Copying file "..Source.." to "..Destination..".")
   if fileExists(Source) then
      local fileContent = readFile(Source)
      writeToFile(Destination, fileContent, "w")
      print("Copying file succeeded.")
      return true
   else
      return false
   end
end
   
function removeFile(File)
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