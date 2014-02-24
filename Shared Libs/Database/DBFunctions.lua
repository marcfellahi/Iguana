-- $Revision: 1.16 $
-- $Date: 2012/07/13 14:11:14 $

dbc = {}

local function trace(a,b,c,d) return end

local function sleep(x)
   if not iguana.isTest() then
      util.sleep(x*1000) -- yields time in seconds
   end
end

local function safeCall(F, T)
   local Success, A, B, C = pcall(F, T)
   if not Success then
      if A.message then
         error(A.message, 3)
      else
         error(A, 3)
      end
   end
   return A, B, C
end

local function checkString(Arg, Usage)
   if type(Arg) ~= 'string' then
      error('Argument should be a string\n\n'..Usage,3)
   end
end

local function checkBoolean(Arg, Usage)
   if type(Arg) ~= 'boolean'  and type(Arg) ~= 'nil' then
      error('Argument should be a boolean\n\n'..Usage,3)
   end   
end

local QueryUsage=[[
Executes an SQL query against a database and returns the results in a tree. 
Insert or update statements are not allowed (for these, use db.execute).

By default queries run Live in the editor, you can change this by setting
the second parameter to false (to disable slow queies while editing code).

Returns: nothing.
Requires one parameter:
   * A SQL string to query against the database.
Has one optional parameter:
   * A boolean, if false, the Query will not be executed in the editor.
     Note: the boolean defaults to true so by default the Query will run.

Examples:
   local R = DB:query("SELECT * FROM Patient WHERE Id = 1")
   DB:query('SELECT * FROM patient', false)
]]

local function query(P, Sql, Live)
   checkString(Sql, QueryUsage)
   -- default Live to true
   if Live == nil then Live = true end
   local A, B =  safeCall(db.query,{sql=Sql, api=P.api, 
         name=P.name, user=P.user, password=P.password,
         use_unicode=P.use_unicode, live=Live})
   return A, B
end

local CloseUsage=[[
Close the connection identified by the given parameters, if it exists.

Returns: nothing.
Has one optional parameter:
   * A boolean, if true, the Close connection will be executed in the editor.

Example:
   DB:close(true)
]]

local function close(P, Live)
   -- never retry close (rollback or commit)
   checkBoolean(Live, CloseUsage)
   local A, B =  safeCall(db.close,{api=P.api,
         name=P.name, user=P.user, password=P.password,
         use_unicode=P.use_unicode, timeout=P.timeout,
         live=Live})
end

local function checkTable(T, Usage)
   if type(T) ~= 'userdata'
    or T:nodeType() ~= 'table_collection' then
      error('1st parameter must be node table tree created using db.tables\n\n'..Usage,3)
   end
end

local MergeUsage=[[
Merges table records created by db.tables() into the specified database.

Returns: nothing.
Requires one parameter:
   * A node table tree created using db.tables
Has one optional parameter: 
   * A boolean, if true, the Merge will be executed in the editor.

Example:
   DB:merge(Out, true)
]]

local function merge(P, T, Live)
   checkTable(T, MergeUsage)
   checkBoolean(Live, MergeUsage)
   local A, B =  safeCall(db.merge,{data=T, api=P.api, 
         name=P.name, user=P.user, password=P.password,
         use_unicode=P.use_unicode, transaction=P.transaction,
         bulk_insert=P.bulk_insert, timeout=P.timeout,
         live=Live})
   return A, B
end

local ExecuteUsage=[[
Executes an ad hoc SQL statement that can alter the database.

Returns:
   * The first is the result set as a data tree, if the SQL statement is a query.
   * A complete collection of all result sets from the statement's queries
     is returned as the second return value.
Requires one parameter:
   * A SQL string to execute against the database.
Has one optional parameter:
   * A boolean, if true, the SQL statement will be executed in the editor.

Example:
   local R = DB:execute("DELETE FROM Patient WHERE Id = 1", true)
]]
local function execute(P, Sql, Live)
   checkString(Sql, ExecuteUsage)
   checkBoolean(Live, ExecuteUsage)   
   local A, B = safeCall(db.execute, {sql=Sql, api=P.api,
         name=P.name, user=P.user, password=P.password,
         use_unicode=P.use_unicode, timeout=P.timeout,
         live=Live})
   return A,B
end

local function checkTable(T,Usage)
   if type(T) ~= 'table' then
      error(Usage,3)
   end
end

local function checkParam(T, List, Usage)
   for i=1, #List do
      if not T[List[i]] then
         if not (T["api"]==db.SQLITE and (List[i]=="user" or List[i]=="password")) then
            error('Missing parameter "'..List[i]..'"\n'..Usage, 3) 
         end
      end
   end
end

local Usage=[[
Creates a Connection object to interact conveniently with databases.

Returns: A database connection object.
Requires one parameter - a table with the following required entries:
   'api'      - set to the database type (e.g., db.MY_SQL or db.SQL_SERVER)
   'name'     - database name/address. For db.SQLITE, this is the database file name
   'user'     - user name (not used or required for db.SQLITE)
   'password' - password (not used or required for db.SQLITE)
Has these optional entries:
   'use_unicode' - if true, Unicode will be used when communicating (Iguana 5.0.9+)
   'timeout   - maximum time in seconds allowed for the query (0 for infinite).
                Timeout is supported only for ODBC connections. Defaults to 5 minutes.
   'live'     - if true the command is executed in the editor.
                Note: query defaults to true (but can be set to false).
Has these optional entries - only for db.merge:
   'bulk_insert' - if set to true, use bulk insert logic (MySQL and SQL Server only).
   'transaction' - if true all rows will be inserted/updated as a single transaction.

Examples:
   local DB = dbc.Connection{api=db.MY_SQL, name='test@localhost', user='root', password='secret'}
   local R = DB:query("SELECT * FROM PATIENT WHERE ID = 1")
   DB:execute("DELETE FROM PATIENT WHERE ID = 2", true)
   DB:merge(T,true)

   NOTE: for SQLite the user and password may be omitted (if included they are ignored).
   local DB = dbc.Connection{api=db.SQLITE, name='sqlite_db'}
]]

function dbc.Connection(Param)
   checkTable(Param, Usage)
   checkParam(Param, {'name','user', 'password', 'api'}, Usage)
   Param.query = query
   Param.merge = merge
   Param.execute = execute
   Param.close = close
   return Param
end

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