-- $Revision: 1.13 $
-- $Date: 2012/06/26 21:30:14 $

-- Module which can be used to get a SQL escape function for a given database
-- Example usage:
-- local E = sqlescape.EscapeFunction(db.MY_SQL)
-- local V = E("This data contains quote ' characters")

-- Note: All functions returned by this module surround the given input string
-- with a pair of single quotes. As such, when using one of these functions on
-- a string literal to be used in a SQL command, you should not surround the
-- ouptut of the function with an additional pair of quotes as this may cause
-- your SQL command to fail.

sqlescape = {}

--[[
Notes:
- In the context of this function, the first argument to gsub (not counting
the calling string), is a set of characters which will be replaced when
matched. The character class "%z" represents the character with value 0.
- The second argument defines a table with key/value pairs which will be
used for replacement of the characters in the first argument.
]]
local function MySQLEscape(Value)
   return Value:gsub('["\'\\%z]', {
         ['"']  = '\\"', ['\0'] = '\\0',
         ["'"]  = "\\'", ['\\'] = '\\\\',
      })
end

local function SingleQuoteEscape(Value)
   return Value:gsub("'", "''")
end

local function PostgresEscape(Value)
   return Value:gsub("['\\]", {["'"] = "''", ["\\"] = "\\\\"})
end

local function AddQuotes(Value)
   return "'" .. Value .. "'"
end

-- The default function used for escaping.
local DEFAULT_ESCAPE_FUNCTION = SingleQuoteEscape

local ESCAPE_FUNCTIONS = {
   [db.MY_SQL]      = MySQLEscape,
   [db.ORACLE_OCI]  = SingleQuoteEscape,
   [db.ORACLE_ODBC] = SingleQuoteEscape,
   [db.SQLITE]      = SingleQuoteEscape,
   [db.SQL_SERVER]  = SingleQuoteEscape,
   [db.POSTGRES]    = PostgresEscape,
   [db.DB2]         = SingleQuoteEscape,
   [db.INFORMIX]    = SingleQuoteEscape,
   [db.INTERBASE]   = SingleQuoteEscape,
   [db.FILEMAKER]   = SingleQuoteEscape,
   [db.SYBASE_ASA]  = SingleQuoteEscape,
   [db.SYBASE_ASE]  = SingleQuoteEscape,
   [db.ACCESS]      = SingleQuoteEscape
}

function sqlescape.EscapeFunction(DatabaseType)
   -- If the database type given is not recognized then provide the most
   -- commonly used escaping function instead.
   local EscapeFunc = ESCAPE_FUNCTIONS[DatabaseType] or DEFAULT_ESCAPE_FUNCTION
   
   -- Return a composition of functions that uses the escaping method for
   -- the given database and adds a pair of single quotes to the output.
   return function(Value)
      return AddQuotes(EscapeFunc(Value))
   end
end
