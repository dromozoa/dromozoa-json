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

local is_array = require "dromozoa.json.is_array"

local function array_index(key)
  if key == "0" then
    return 1
  elseif key:match("^[1-9]%d*$") then
    return tonumber(key) + 1
  else
    return 0
  end
end

local function decode(v)
  if v == "~0" then
    return "~"
  elseif v == "~1" then
    return "/"
  else
    error "could not decode"
  end
end

local function parse(path)
  if #path == 0 then
    return {}
  else
    if not path:match("^/") then
      error "could not parse"
    end
    local result = {}
    for i in path:gmatch("/([^/]*)") do
      result[#result + 1] = i:gsub("~.", decode)
    end
    return result
  end
end

local function copy(v)
  local t = type(v)
  if t == "table" then
    local result = {}
    for k, v in pairs(v) do
      result[k] = v
    end
    return result
  else
    return v
  end
end

local function test(a, b, depth)
  if depth > 16 then
    error "too much recursion"
  end

  local t = type(a)
  if t == type(b) then
    if t == "table" then
      for k, v in pairs(a) do
        local u = b[k]
        if u == nil then
          return false
        end
      end
      for k, v in pairs(b) do
        local u = a[k]
        if u == nil or not test(u, v, depth + 1) then
          return false
        end
      end
      return true
    else
      return a == b
    end
  else
    return false
  end
end

return function (path)
  local self = {
    _token = parse(path);
  }

  function self:evaluate(root, n)
    local token = self._token
    local v = root[1]
    for i = 1, n do
      if type(v) == "table" then
        local key = token[i]
        local size = is_array(v)
        if size == nil then
          v = v[key]
          if v == nil then
            return false
          end
        else
          local index = array_index(key)
          if 1 <= index and index <= size then
            v = v[index]
          else
            return false
          end
        end
      else
        return false
      end
    end
    return true, v
  end

  function self:get(root)
    return self:evaluate(root, #self._token)
  end

  function self:test(root, value)
    local r, v = self:get(root)
    if r then
      return test(v, value, 0)
    else
      return false
    end
  end

  function self:add(root, value)
    local token = self._token
    local n = #token
    if n == 0 then
      local save = root[1]
      root[1] = value
      return true, save
    end
    local r, v = self:evaluate(root, n - 1)
    if type(v) == "table" then
      local key = self._token[n]
      local size = is_array(v)
      if size == nil then
        local save = v[key]
        v[key] = value
        return true, save
      elseif size == 0 then
        if key == "-" or key == "0" then
          v[1] = value
          return true
        else
          local save = v[key]
          v[key] = value
          return true, save
        end
      else
        local index
        if key == "-" then
          index = size + 1
        else
          index = array_index(key)
        end
        if 1 <= index and index <= size + 1 then
          for i = size, index, -1 do
            v[i + 1] = v[i]
          end
          v[index] = value
          return true
        else
          return false
        end
      end
    else
      return false
    end
  end

  function self:remove(root)
    local token = self._token
    local n = #token
    if n == 0 then
      local save = root[1]
      root[1] = nil
      return true, save
    end
    local r, v = self:evaluate(root, n - 1)
    if type(v) == "table" then
      local key = self._token[n]
      local size = is_array(v)
      if size == nil then
        local save = v[key]
        if save == nil then
          return false
        end
        v[key] = nil
        return true, save
      else
        local index = array_index(key)
        if 1 <= index and index <= size then
          local save = v[index]
          for i = index, size - 1 do
            v[i] = v[i + 1]
          end
          v[size] = nil
          return true, save
        else
          return false
        end
      end
    else
      return false
    end
  end

  function self:replace(root, value)
    local result = self:remove(root)
    if result then
      return self:add(root, value)
    else
      return false
    end
  end

  function self:move(root, from)
    local result, value = from:remove(root)
    if result then
      local a, b = self:add(root, value)
      if not a then
        assert((from:add(root, value)))
        return false
      end
      return a, b
    else
      return false
    end
  end

  function self:copy(root, from)
    local result, value = from:get(root)
    if result then
      return self:add(root, copy(value))
    else
    end
  end

  return self
end
