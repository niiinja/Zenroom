--- <h1>Debug inspection facility</h1>
--
-- The INSPECT class provides a number of functions to ease
-- development and debugging. It mainly consists of an advanced
-- @{print} function that can represent complex data structures (Lua
-- tables) and tag their encoding formats and size.  Another @{spy}
-- function prints the same as pass-through.
--
-- @module INSPECT

local inspect ={
  _VERSION = 'inspect.lua 3.1.0',
  _URL     = 'http://github.com/kikito/inspect.lua',
  _DESCRIPTION = 'human-readable representations of tables',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local tostring = tostring

inspect.KEY       = setmetatable({}, {__tostring = function() return 'inspect.KEY' end})
inspect.METATABLE = setmetatable({}, {__tostring = function() return 'inspect.METATABLE' end})

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str)
  if str:match('"') and not str:match("'") then
    return "'" .. str .. "'"
  end
  return '"' .. str:gsub('"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v"
}
local longControlCharEscapes = {} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
  local ch = string.char(i)
  if not shortControlCharEscapes[ch] then
    shortControlCharEscapes[ch] = "\\"..i
    longControlCharEscapes[ch]  = string.format("\\%03d", i)
  end
end

local function escape(str)
  return (str:gsub("\\", "\\\\")
             :gsub("(%c)%f[0-9]", longControlCharEscapes)
             :gsub("%c", shortControlCharEscapes))
end

local function isIdentifier(str)
  return type(str) == 'string' and str:match( "^[_%a][_%a%d]*$" )
end

local function isSequenceKey(k, sequenceLength)
  return type(k) == 'number'
     and 1 <= k
     and k <= sequenceLength
     and math.floor(k) == k
end

local defaultTypeOrders = {
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function sortKeys(a, b)
  local ta, tb = type(a), type(b)

  -- strings and numbers are sorted numerically/alphabetically
  if ta == tb and (ta == 'string' or ta == 'number') then return a < b end

  local dta, dtb = defaultTypeOrders[ta], defaultTypeOrders[tb]
  -- Two default types are compared according to the defaultTypeOrders table
  if dta and dtb then return defaultTypeOrders[ta] < defaultTypeOrders[tb]
  elseif dta     then return true  -- default types before custom ones
  elseif dtb     then return false -- custom types after default ones
  end

  -- custom types are sorted out alphabetically
  return ta < tb
end

-- For implementation reasons, the behavior of rawlen & # is "undefined" when
-- tables aren't pure sequences. So we implement our own # operator.
local function getSequenceLength(t)
  local len = 1
  local v = rawget(t,len)
  while v ~= nil do
    len = len + 1
    v = rawget(t,len)
  end
  return len - 1
end

local function getNonSequentialKeys(t)
  local keys = {}
  local sequenceLength = getSequenceLength(t)
  for k,_ in pairs(t) do
    if not isSequenceKey(k, sequenceLength) then table.insert(keys, k) end
  end
  table.sort(keys, sortKeys)
  return keys, sequenceLength
end

local function getToStringResultSafely(t, mt)
  local __tostring = type(mt) == 'table' and rawget(mt, '__tostring')
  local str, ok
  if type(__tostring) == 'function' then
    ok, str = pcall(__tostring, t)
    str = ok and str or 'error: ' .. tostring(str)
  end
  if type(str) == 'string' and #str > 0 then return str end
end

local function countTableAppearances(t, tableAppearances)
  tableAppearances = tableAppearances or {}

  if type(t) == 'table' then
    if not tableAppearances[t] then
      tableAppearances[t] = 1
      for k,v in pairs(t) do
        countTableAppearances(k, tableAppearances)
        countTableAppearances(v, tableAppearances)
      end
      countTableAppearances(getmetatable(t), tableAppearances)
    else
      tableAppearances[t] = tableAppearances[t] + 1
    end
  end

  return tableAppearances
end

local copySequence = function(s)
  local copy, len = {}, #s
  for i=1, len do copy[i] = s[i] end
  return copy, len
end

local function makePath(path, ...)
  local keys = {...}
  local newPath, len = copySequence(path)
  for i=1, #keys do
    newPath[len + i] = keys[i]
  end
  return newPath
end

local function processRecursive(process, item, path, visited)
    if item == nil then return nil end
    if visited[item] then return visited[item] end

    local processed = process(item, path)

    if type(processed) == 'table' then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k,v in pairs(processed) do
        processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)

        if processedKey ~= nil then
          processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
        end
      end

      local mt  = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end -- ignore not nil/table __metatable field
      setmetatable(processedCopy, mt)
      processed = processedCopy
    end
    return processed
end



-------------------------------------------------------------------

local Inspector = {}
local Inspector_mt = {__index = Inspector}

function Inspector:puts(...)
  local args   = {...}
  local buffer = self.buffer
  local len    = #buffer
  for i=1, #args do
    len = len + 1
    buffer[len] = args[i]
  end
end

function Inspector:down(f)
  self.level = self.level + 1
  f()
  self.level = self.level - 1
end

function Inspector:tabify()
  self:puts(self.newline, string.rep(self.indent, self.level))
end

function Inspector:alreadyVisited(v)
  return self.ids[v] ~= nil
end

function Inspector:getId(v)
  local id = self.ids[v]
  if not id then
    local tv = type(v)
    id              = (self.maxIds[tv] or 0) + 1
    self.maxIds[tv] = id
    self.ids[v]     = id
  end
  return tostring(id)
end

function Inspector:putKey(k)
  if isIdentifier(k) then return self:puts(k) end
  self:puts("[")
  self:putValue(k)
  self:puts("]")
end

function Inspector:putTable(t)
  if t == inspect.KEY or t == inspect.METATABLE then
    self:puts(tostring(t))
  elseif self:alreadyVisited(t) then
    self:puts('<table ', self:getId(t), '>')
  elseif self.level >= self.depth then
    self:puts('{...}')
  else
    if self.tableAppearances[t] > 1 then self:puts('<', self:getId(t), '>') end

    local nonSequentialKeys, sequenceLength = getNonSequentialKeys(t)
    local mt                = getmetatable(t)
    local toStringResult    = getToStringResultSafely(t, mt)

    self:puts('{')
    self:down(function()
      if toStringResult then
        self:puts(' -- ', escape(toStringResult))
        if sequenceLength >= 1 then self:tabify() end
      end

      local count = 0
      for i=1, sequenceLength do
        if count > 0 then self:puts(',') end
        self:puts(' ')
        self:putValue(t[i])
        count = count + 1
      end

      for _,k in ipairs(nonSequentialKeys) do
        if count > 0 then self:puts(',') end
        self:tabify()
        self:putKey(k)
        self:puts(' = ')
        self:putValue(t[k])
        count = count + 1
      end

      if type(mt) == 'table' then
        if count > 0 then self:puts(',') end
        self:tabify()
        self:puts('<metatable> = ')
        self:putValue(mt)
      end
    end)

    if #nonSequentialKeys > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
      self:tabify()
    elseif sequenceLength > 0 then -- array tables have one extra space before closing }
      self:puts(' ')
    end

    self:puts('}')
  end
end

function Inspector:putValue(v)
  local tv = type(v)

  enc = CONF.encoding or url64
  if tv == 'string' then
    self:puts(smartQuote(escape(v)))
  elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
         tv == 'cdata' or tv == 'ctype' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:putTable(v)
  elseif iszen(tv) then
	 if tv == "zenroom.octet" then
		self:puts("octet[" .. #v .. "] " .. ZEN:export(v))
	 elseif tv == "zenroom.big" then
		local i = v:octet()
		self:puts("int[" .. #i.. "] " .. ZEN:export(i))
	 elseif tv == "zenroom.ecp" then
		local i = v:octet()
		if v == "Infinity" or v == ECP.infinity() then
		   self:puts("ecp[...] (Infinity)")
		else
		   self:puts("ecp[" .. #i.. "] " .. ZEN:export(i))
		end
	 elseif tv == "zenroom.ecp2" then
		local i = v:octet()
		if v == "Infinity" or v == ECP2.infinity() then
		   self:puts("ecp[...] (Infinity)")
		else
		   self:puts("ecp2[" ..#i.. "] ".. ZEN:export(i))
		end
	 elseif tv == "zenroom.fp12" then
		local i = v:octet()
		self:puts("fp12[" ..#i.. "] ".. ZEN:export(i))
	 elseif tv == "zenroom.ecdh" then
		local pk = v:public()
		local sk = v:private()
		if not pk and not sk then self:puts("ecdh keyring is empty\n")
		else
		   if pk then self:puts("ecdh.public["..#pk.."] ".. ZEN:export(pk).."\n") end
		   if sk then self:puts("ecdh.private["..#sk.."] ".. ZEN:export(sk).."\n") end
		end
	 else
		self:puts(ZEN:export(v:octet()))
	 end
  else
    self:puts('<',tv,' ',self:getId(v),'>')
  end
end

-------------------------------------------------------------------

function inspect.inspect(root, options)
  options       = options or {}

  local depth   = options.depth   or math.huge
  local newline = options.newline or '\n'
  local indent  = options.indent  or '    '
  local process = options.process

  if process then
    root = processRecursive(process, root, {}, {})
  end

  local inspector = setmetatable({
    depth            = depth,
    level            = 0,
    buffer           = {},
    ids              = {},
    maxIds           = {},
    newline          = newline,
    indent           = indent,
    tableAppearances = countTableAppearances(root)
  }, Inspector_mt)

  inspector:putValue(root)

  return table.concat(inspector.buffer)
end

-- conversion wrappers for zenroom types
function inspect.encode(item)
   t = type(item)
   if iszen(t) then
	  return ZEN:export(item)
   -- elseif iszen(t) then
   -- 	  if t == "zenroom.ecp" and ECP.isinf(item) then
   -- 	  	 return "Infinity"
   -- 	  else
   -- 	  	 return ZEN:export(item)
   -- 	  end
   else
	  return item
   end
end

-- apply conversion wrapper to all values of a table
function inspect.process(item)
   return processRecursive(inspect.encode, item, {}, {})
end

--- Print all contents of a table in a tree representation, works with
-- complex data structures and prints to STDOUT.
--
-- @function INSPECT.print(object)
-- @param object complex table data structure
function inspect.print(root, options)
   print(inspect.inspect(root, options))
   return root
end

--- Print all contents of a table to STDERR. Works same way as @{print}.
--
-- @function INSPECT.warn(object)
-- @param object complex table data structure
function inspect.warn(root, options)
   warn(inspect.inspect(root, options))
   return root
end

--- Print all contents of a table to STDERR and return same object as
--- passthrough. Works same way as @{print}.
--
-- @function INSPECT.spy(object)
-- @param object complex table data structure
-- @return object itself (passthrough for nesting)
inspect.spy = inspect.warn

setmetatable(inspect, { __call = function(_, ...) return inspect.print(...) end })

return inspect

