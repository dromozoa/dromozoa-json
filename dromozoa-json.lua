-- This file was auto-generated.
package.loaded["dromozoa/json/pure.lua"] = (function ()
-- ===========================================================================
-- dromozoa.json.pure
-- ===========================================================================
-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-json.
--
-- dromozoa-json is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-json is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-json.  If not, see <http://www.gnu.org/licenses/>.

local utf8 = require "dromozoa.utf8"

local concat = table.concat
local error = error
local floor = math.floor
local format = string.format
local next = next
local pairs = pairs
local tostring = tostring
local type = type

local function is_array(value)
  local m = 0
  local n = 0
  for k, v in pairs(value) do
    if type(k) == "number" and k > 0 and floor(k) == k then
      if m < k then m = k end
      n = n + 1
    else
      return nil
    end
  end
  if m <= n * 2 then
    return m
  else
    return nil
  end
end

local function encoder()
  local self = { _buffer = {} }

  function self:write(value)
    local buffer = self._buffer
    buffer[#buffer + 1] = value
  end

  function self:quote(value)
    local buffer = self._buffer
    buffer[#buffer + 1] = [["]]
    for p, c in utf8.codes(tostring(value)) do
      if c == 0x22 then buffer[#buffer + 1] = [[\"]]
      elseif c == 0x5C then buffer[#buffer + 1] = [[\\]]
      elseif c == 0x2F then buffer[#buffer + 1] = [[\/]]
      elseif c == 0x08 then buffer[#buffer + 1] = [[\b]]
      elseif c == 0x0C then buffer[#buffer + 1] = [[\f]]
      elseif c == 0x0A then buffer[#buffer + 1] = [[\n]]
      elseif c == 0x0D then buffer[#buffer + 1] = [[\r]]
      elseif c == 0x09 then buffer[#buffer + 1] = [[\t]]
      elseif c < 0x20 then buffer[#buffer + 1] = format([[\u%04X]], c)
      else buffer[#buffer + 1] = utf8.char(c) end
    end
    buffer[#buffer + 1] = [["]]
  end

  function self:encode(value, depth)
    if depth > 16 then
      error "too much recursion"
    end

    local t = type(value)
    if t == "number" then
      self:write(format("%.17g", value))
    elseif t == "string" then
      self:quote(value)
    elseif t == "boolean" then
      if value then
        self:write("true")
      else
        self:write("false")
      end
    elseif t == "table" then
      local n = is_array(value)
      if n == nil then
        self:write("{")
        local k, v = next(value)
        self:quote(k)
        self:write(":")
        self:encode(v, depth + 1)
        for k, v in next, value, k do
          self:write(",")
          self:quote(k)
          self:write(":")
          self:encode(v, depth + 1)
        end
        self:write("}")
      elseif n == 0 then
        self:write("[]")
      else
        self:write("[")
        self:encode(value[1], depth + 1)
        for i = 2, n do
          self:write(",")
          self:encode(value[i], depth + 1)
        end
        self:write("]")
      end
    else
      self:write("null")
    end
  end

  function self:buffer()
    return self._buffer
  end

  return self
end

local function encode(value)
  local encoder = encoder()
  encoder:encode(value, 0)
  return concat(encoder:buffer())
end

return {
  encode = encode;
  version = function () return "1.0" end;
}
-- ===========================================================================
end)()
package.loaded["dromozoa/json.lua"] = (function ()
-- ===========================================================================
-- dromozoa.json
-- ===========================================================================
-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-json.
--
-- dromozoa-json is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-json is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-json.  If not, see <http://www.gnu.org/licenses/>.

local result, json = pcall(require, "cjson")
if result then
  return json
end

local result, json = pcall(require, "dkjson")
if result then
  return json
end

return require "dromozoa.json.pure"
-- ===========================================================================
end)()
