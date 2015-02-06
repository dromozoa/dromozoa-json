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
local floor = math.floor
local format = string.format

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

local function stack()
  local self = {
    _data = {};
    _size = 0;
  }

  function self:push(value)
    self._size = self._size + 1
    self._data[self._size] = value
  end

  function self:pop()
    assert(self._size > 0)
    local value = self._data[self._size]
    self._size = self._size - 1
    return value
  end

  function self:top()
    assert(self._size > 0)
    return self._data[self._size]
  end

  function self:size()
    return self._size
  end

  return self
end


local function decoder(s)
  local self = {
    _s = s;
    _i = 1;
    _stack = stack();
  }

  function self:match(pattern)
    local i, j = self._s:find("^" .. pattern, self._i)
    if j == nil then
      return false
    else
      self._i = j + 1
      return true
    end
  end

  function self:ignore_whitespace()
    return self:match("[ \t\n\r]+")
  end

  function self:decode_literal()
    if self:match("true") then
      self._stack:push(true)
    elseif self:match("false") then
      self._stack:push(false)
    elseif self:match("null") then
      self._stack:push(nil)
    else
      return false
    end
    self:ignore_whitespace()
    return true
  end

  function self:decode_object()
    if self:match("{") then
      self._stack:push({})
      while self._i < #self._s do
        self:ignore_whitespace()
        assert(self:decode_string())
        self:ignore_whitespace()
        assert(self:match(":"))
        self:ignore_whitespace()
        assert(self:decode_value())
        self:ignore_whitespace()
        if self:match(",") then
          local v = self._stack:pop()
          local n = self._stack:pop()
          local t = self._stack:top()
          t[n] = v
        elseif self:match("}") then
          local v = self._stack:pop()
          local n = self._stack:pop()
          local t = self._stack:top()
          t[n] = v
          return true
        else
          error "invalid"
        end
      end
      error "invalid"
    else
      return false
    end
  end

  function self:decode_array()
    if self:match("%[") then
      self._stack:push({})
      local i = 1
      while self._i < #self._s do
        self:ignore_whitespace()
        assert(self:decode_value())
        self:ignore_whitespace()
        if self:match(",") then
          local v = self._stack:pop()
          local t = self._stack:top()
          t[i] = v
          i = i + 1
        elseif self:match("%]") then
          local v = self._stack:pop()
          local t = self._stack:top()
          t[i] = v
          i = i + 1
          return true
        else
          error "invalid"
        end
      end
      error "invalid"
    else
      return false
    end
  end

  function self:decode_number()
    local i = self._i
    if self:match("%-?0") or self:match("%-?[1-9]%d*") then
      self:match("%.%d*")
      self:match("[eE][%+%-]?%d+")
      self._stack:push(tonumber(self._s:sub(i, self._i - 1)))
      return true
    else
      return false
    end
  end

  function self:decode_string()
    return false
    -- error "not implemented"
  end

  function self:decode_value()
    self:ignore_whitespace()
    if self:decode_literal() then
    elseif self:decode_object() then
    elseif self:decode_array() then
    elseif self:decode_number() then
    elseif self:decode_string() then
    else error("invalid " .. self._i) end
    return true
  end

  function self:top()
    assert(self._stack:size() == 1)
    return self._stack:top()
  end

  return self
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

local function decode(s)
  local decoder = decoder(s)
  decoder:decode_value()
  return decoder:top()
end

local function encode(value)
  local encoder = encoder()
  encoder:encode(value, 0)
  return concat(encoder:buffer())
end

return {
  decode = decode;
  encode = encode;
  version = function () return "1.0" end;
}
