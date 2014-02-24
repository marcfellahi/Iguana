function CloseDatabaseHandling(PrintStatement, connection, messages)

   if messages == nil then
      
      messages = ''
         
   end
      
   print(PrintStatement)
   
   Status, ErrorString = pcall(SQLExecute, connection, 'ROLLBACK TRANSACTION')
   
   if not Status then

      if messages == '' then
         print("CANNOT ROLLBACK - UNKNOWN ERROR")
      else
         print(messages.Error_DBRollBack[1]..ErrorString)
      end
      
   end
   
   connection:close()
   
end

function SQLExecute(connection, SQLStatement)
   
   return connection:execute(SQLStatement)      
   
end


function SQLQuery(connection, SQLstatement)
   
   return connection:query(SQLstatement)
   
end