-- Module which contains several functions that handle strings

-- sqlEscape example
-- Example usage:
-- local E = sqlescape.EscapeFunction(db.MY_SQL)
-- local V = E("This data contains quote ' characters")

-- Note: All functions returned by this module surround the given input string
-- with a pair of single quotes. As such, when using one of these functions on
-- a string literal to be used in a SQL command, you should not surround the
-- ouptut of the function with an additional pair of quotes as this may cause
-- your SQL command to fail.

--[[
Notes:
- In the context of this function, the first argument to gsub (not counting
the calling string), is a set of characters which will be replaced when
matched. The character class "%z" represents the character with value 0.
- The second argument defines a table with key/value pairs which will be
used for replacement of the characters in the first argument.
]]

sqlescape={}
string={}

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


function string.zfill(self,n)
   local R = n
   local L = #self
   if L < R then 
      self = '0'..self
      self:zfill(R)
   else
      z = self   
   end

   return z
end


local function validate(r,i,s)
   if r:find("%s",-lastWordTollerance) == nil then
      return r,lineLength
   
   else
      local a,b=r:find("%s",-lastWordTollerance)        
      return r:sub(1,a-1),a-1
   end
end


function string.chunk(s)
   local r={}  
   local i=1
   
   while i<#s do
      local si=s:sub(i,i+lineLength-1) 
      local ri,j=validate(si,i,s)
      r[#r+1]=ri:trimWS()  
      i=i+j
   end
 
   return r
end


function string.split(s,d)
   local t = {}
   local i = 0
   local f
   local match = '(.-)' .. d .. '()'
   if string.find(s, d) == nil then
      return {s}
   end
   for sub, j in string.gfind(s, match) do
         i = i + 1
         t[i] = sub
         f = j
   end
   if i~= 0 then
      t[i+1]=string.sub(s,f)
   end
   return t
end

-- Used to round decimals or money fields 
function round(num, idp) 
  local mult = 10^(idp or 0) 
  return math.floor(num * mult + 0.5) / mult 
end 

-- Trims white space on both sides.
function string.trimWS(self)  
   local L, R
   L = #self
   while _isWhite(self:byte(L)) and L > 1 do
      L = L - 1
   end
   R = 1
   while _isWhite(self:byte(R)) and R < L do
      R = R + 1
   end     
   return self:sub(R, L)
end

-- Trims white space on right side.
function string.trimRWS(self)
   local L
   L = #self
   while _isWhite(self:byte(L)) and L > 0 do
      L = L - 1
   end
   return self:sub(1, L)
end

-- Trims white space on left side.
function string.trimLWS(self)
   local R = 1
   local L = #self
   while _isWhite(self:byte(R)) and R < L do
      R = R + 1
   end
   return self:sub(R, L)
end

function _isWhite(byte) 
   return byte == 32 or byte == 9
end

-- This routine will replace multiple spaces with single spaces 
function string.compactWS(self) 
   return self:gsub("%s+", " ") 
end

-- This routine capitalizes the first letter of the string
-- and returns the rest in lower characters
function string.capitalize(self)
   local R = self:sub(1,1):upper()..self:sub(2):lower()
   return R
end

function node:S()
   return tostring(self)
end
