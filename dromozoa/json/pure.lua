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

local function decoder()
  local self = { _stack = {} }

  function self:decode(value)
    local i = 1
    local n = 0
    local stack = {}
    local state = {}

    local function find(pattern)
      local a, b = value:find("^" .. pattern, i)
      if b == nil then
        return false
      else
        i = b + 1
        return true
      end
    end

    local function push(value)
      n = n + 1
      stack[n] = value
    end

    local function pop()
      assert(n > 0)
      local value
      value, stack[n] = stack[n], nil
      n = n - 1
      return value
    end

    local function top()
      assert(n > 0)
      return stack[n]
    end

    while i <= #value do
      local j = i
      if find("[ \t\n\r]+") then
        -- noop
      elseif find("%-?0") or find("%-?[1-9]%d*") then
        find("%.%d*")
        find("[eE][%+%-]?%d+")
        print("n", j, i, value:sub(j, i - 1))
        push(tonumber(value:sub(j, i - 1)))
      elseif find("\"") then
        error "unsupported"
      elseif find("true") then
        push(true)
      elseif find("false") then
        push(false)
      elseif find("null") then
        push(nil)
      elseif find("%[") then
        push({})
        state[#state + 1] = "array"
      elseif find("%]") then
        assert(state[#state] == "array")
        local v = pop()
        local a = top()
        a[#a + 1] = v -- [FIXME]
        state[#state] = nil
      elseif find("{") then
        push({})
        state[#state + 1] = "object"
      elseif find("%:") then
        assert(state[#state] == "object")
        assert(type(top()) == "string")
      elseif find("}") then
        assert(state[#state] == "object")
        local v = pop()
        local n = pop()
        local o = top()
        o[n] = v
        state[#state] = nil
      elseif find(",") then
        assert(state[#state])
        if state[#state] == "array" then
          local v = pop()
          local a = top()
          a[#a + 1] = v -- [FIXME]
        else
          local v = pop()
          local n = pop()
          local o = top()
          o[n] = v
        end
      else
        error(string.format("invalid %d:%q", i, value:sub(i)))
      end
    end
    assert(n == 1)
    return stack[1]
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

local function decode(value)
  local decoder = decoder()
  return decoder:decode(value)
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
