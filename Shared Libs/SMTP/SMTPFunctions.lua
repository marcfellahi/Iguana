-- $Revision: 3.5 $
-- $Date: 2012-12-17 15:55:58 $

--
-- The mime module
-- Copyright (c) 2011-2012 iNTERFACEWARE Inc. ALL RIGHTS RESERVED
-- iNTERFACEWARE permits you to use, modify, and distribute this file in
-- accordance with the terms of the iNTERFACEWARE license agreement
-- accompanying the software in which it is used.
--
 
-- Basic SMTP/MIME module for sending MIME formatted attachments via
-- SMTP.
--
-- An attempt is made to format the MIME parts with the correct headers,
-- and pathnames that represent non-plain-text data are Base64 encoded
-- when constructing the part for that attachment.
--
-- SMTP/MIME is a large and complicated standard; only part of those
-- standards are supported here. The assumption is that most mailers
-- and mail transfer agents will do their best to handle inconsistencies.
--
-- Example usage:
--
-- local Results = mime.send{
--    server='smtp://mysmtp.com:25', username='john', password='password',
--    from='john@smith.com', to={'john@smith.com', 'jane@smith.com'},
--    header={['Subject']='Test Subject'}, body='Test Email Body', use_ssl='try',
--    attachments={'/home/jsmith/pictures/test.jpeg'},
-- }

mime = {}
mimehelp = {}

local function trace(a,b,c,d) return end

if help then
  local mimehelp = {
       Title="mime.send";
       Usage="mime.send{server=<value> [, username=<value>] [, ...]}",
       Desc=[[Sends an email using the SMTP protocol. A wrapper around net.smtp.send.
              Accepts the same parameters as net.smtp.send, with an additional "attachments"
              parameter:
            ]];
       ["Returns"] = {
          {Desc="nothing."},
       };
       ParameterTable= true,
       Parameters= {
           {attachments= {Desc='A table of absolute filenames to be attached to the email.'}},
       };
       Examples={
           [[local Results = mime.send{
             server='smtp://mysmtp.com:25', username='john', password='password',
             from='john@smith.com', to={'john@smith.com', 'jane@smith.com'},
             header={['Subject']='Test Subject'}, body='Test Email Body', use_ssl='try',
             attachments={'/home/jsmith/pictures/test.jpeg'},
           }]],
       };
       SeeAlso={
           {
               Title="net.smtp - sending mail",
               Link="http://wiki.interfaceware.com/1039.html#send"
           },
           {
               Title="Tips and tricks from John Verne",
               Link="http://wiki.interfaceware.com/1342.html"
           }
       }
   }
end

-- Common file extensions and the corresponding
-- MIME sub-type we will probably encounter.
-- Add more as necessary.
local MIMEtypes = {
  ['pdf']  = 'application/pdf',
  ['jpeg'] = 'image/jpeg',
  ['jpg']  = 'image/jpeg',
  ['gif']  = 'image/gif',
  ['png']  = 'image/png',
  ['zip']  = 'application/zip',
  ['gzip'] = 'application/gzip',
  ['tiff'] = 'image/tiff',
  ['html'] = 'text/html',
  ['htm']  = 'text/html',
  ['mpeg'] = 'video/mpeg',
  ['mp4']  = 'video/mp4',
  ['txt']  = 'text/plain',
  ['exe']  = 'application/plain',
  ['js']   = 'application/javascript',
  ['csv']  = 'text/csv',
}

-- Most mailers support UTF-8
local defaultCharset = 'utf8'

--
-- Local helper functions
--

-- Given a filespec, open it up and see if it is a
-- "binary" file or not. This is a best guess.
-- Tweak the pattern to suit.
local function isBinary(filename)
  local input = assert(io.open(filename, "rb"))

  local isbin = false
  local chunk_size = 2^12 -- 4k bytes

  repeat
    local chunk = input.read(input, chunk_size)
    if not chunk then break end

    if (string.find(chunk, "[^\f\n\r\t\032-\128]")) then
      isbin = true
      break
    end
  until false
  input:close()

  return isbin
end

-- Read the passed in filespec into a local variable.
local function readFile(filename)
  local f = assert(io.open(filename, "rb"))
  -- We could read this in chunks, but at the end of the day
  -- we are still streaming it into a local anyway.
  local data = f:read("*a")
  f:close()

  return data
end
    
-- Based on extension return an appropriate MIME sub-type
-- for the filename passed in.
-- Return 'application/unknown' if we can't figure it out.
local function getContentType(extension)
  local MIMEtype = 'application/unknown'

  for ext, subtype in pairs(MIMEtypes) do
    if ext == extension then
      MIMEtype = subtype
    end
  end

  return MIMEtype
end

-- Base64 encode the content passed in. Break the encoded data
-- into reasonable lengths per RFC2821 and friends.
local function ASCIIarmor(content)
  local armored = ''
  local encoded = filter.base64.enc(content)
  
  -- SMTP RFCs suggests that 990 or 1000 is valid for most MTAs and
  -- MUAs. For debugging set this to 72 or some other human-readable
  -- break-point.
  local maxl = 990 - 2  -- Less 2 for the trailing CRLF pair
  local len = encoded:len()
  local start = 1
  local lineend = start + maxl
  while lineend <= len do
    local line = encoded:sub(start, lineend)
    armored = string.format("%s\r\n%s", armored, line)

    -- We got it all; leave now.
    if lineend == len then break end

    -- Move the counters forward
    start = lineend + 1
    lineend = start + maxl

    -- Make sure we pick up the last fragment
    if lineend > len then lineend = len end
  end

  if armored == '' then
    return encoded
  else
    return armored
  end
end

-- Similar to net.smtp.send with a single additional required parameter
-- of an array of local absolute filenames to add to the message
-- body as attachments.
--
-- An attempt is made to add the attachment parts with the right
-- MIME-related headers.
function mime.send(args)
  local server = args.server
  local to = args.to
  local from = args.from
  local header = args.header
  local body = args.body
  local attachments = args.attachments
  local username = args.username
  local password = args.password
  local timeout = args.timeout
  local use_ssl = args.use_ssl
  local live = args.live
  local debug = args.debug
   
   trace(debug)
  
  trace(args)
  -- Blanket non-optional parameter enforcement.
  if server == nil or to == nil or from == nil
      or header == nil or body == nil
         or attachments == nil then
      error("Missing required parameter.", 2)
  end

  -- Create a unique ID to use for multi-part boundaries.
  local boundaryID = util.guid(128)
  if debug then
    -- Debug hook
    boundaryID = 'xyzzy_0123456789_xyzzy'
  end
  local partBoundary = '--' .. boundaryID
  local endBoundary = '--' .. boundaryID .. '--'

  -- Append our headers, set up the multi-part message.
  header['MIME-Version'] = '1.0'
  header['Content-Type'] = 'multipart/mixed; boundary=' .. boundaryID

  -- Preload the body part.
  local msgBody =
    string.format(
      '%s\r\nContent-Type: text/plain; charset="%s"\r\n\r\n%s',
        partBoundary, defaultCharset, body)

  -- Iterate over each attachment filespec, building up the 
  -- SMTP body chunks as we go.
  for _, filespec in ipairs(attachments) do
    local path, filename, extension =
          string.match(filespec, "(.-)([^\\/]-%.?([^%.\\/]*))$")

    -- Get the (best guess) content-type and file contents.
    -- Cook the contents into Base64 if necessary.
    local contentType = getContentType(extension)
    local isBinary = isBinary(filespec)
    local content = readFile(filespec)
    if isBinary then
      content = ASCIIarmor(content)
    end
    
    -- Existing BodyCRLF
    -- Part-BoundaryCRLF
    -- Content-Type:...CRLF
    -- Content-Disposition:...CRLF
    -- [Content-Transfer-Encoding:...CRLF]
    -- contentCRLF
    local msgContentType =
      string.format('Content-Type: %s; charset="%s"; name="%s"',
        contentType, isBinary and 'B' or defaultCharset, filename)
    local msgContentDisposition =
      string.format('Content-Disposition: inline; filename="%s"',
        filename)
    -- We could use "quoted-printable" to make sure we handle
    -- occasional non-7-bit text data, but then we'd have to break
    -- the passed-in data into max 76 char lines. We don't really
    -- want to munge the original data that much. Defaulting to 
    -- 7bit should work in most cases, and supporting quoted-printable
    -- makes things pretty complicated (and increases the message
    -- size even more.)
    local msgContentTransferEncoding = isBinary and
      'Content-Transfer-Encoding: base64\r\n' or ''

    -- Concatenate the current chunk onto the entire body.
    msgBody =
      string.format('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s%s\r\n', 
        msgBody, partBoundary, msgContentType, msgContentDisposition,
        msgContentTransferEncoding, content)
  end

  -- End the message body
  msgBody = string.format('%s\r\n%s', msgBody, endBoundary)

   trace(to,username, password,body)
  if not iguana.isTest() then
      
  -- Send the message via net.smtp.send()
  net.smtp.send{
    server = server,
    to = to,
    from = from,
    header = header,
    body = msgBody,
    username = username,
    password = password,
    timeout = timeout,
    use_ssl = use_ssl,
    live = live,
    debug = debug
  }
      
  end

  -- Debug hook
  if debug then
    return msgBody, header
  end

end

-- Hook up the help, if present.
if help then
  help.set{input_function=mime.send, help_data=mimehelp}
end

return mime
