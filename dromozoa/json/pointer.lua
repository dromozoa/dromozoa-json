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

local function decode(value)
  if value == "~0" then
    return "~"
  elseif value == "~1" then
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

local function evaluate(object, key)
  if type(object) == "table" then
    local n = is_array(object)
    if n == nil then
      local v = object[key]
      if v ~= nil then
        return true, v
      end
    else
      local index = tonumber(key)
      if index ~= nil and 0 <= index and index < n then
        return true, object[index + 1]
      end
    end
  end
  return false
end

return function (path)
  local self = {
    _token = parse(path);
  }

  function self:evaluate(root, n)
    local result = true
    local object = root
    for i = 1, n do
      result, object = evaluate(object, self._token[i])
      if not result then
        return false
      end
    end
    return result, object
  end

  function self:get(root)
    return self:evaluate(root, #self._token)
  end

  function self:add(root, value)
    local m = #self._token
    if m == 0 then
      return true, value
    end
    local object = self:evaluate(root, m - 1)
    if type(object) == "table" then
      local key = self._token[m]
      local n = is_array(object)
      if n == nil then
        object[key] = value
        return true, root
      elseif n == 0 then
        if key == "-" or key == "0" then
          object[1] = value
          return true, root
        else
          object[key] = value
          return true, root
        end
      else
        if key == "-" then
          object[#object + 1] = value
          return true, root
        else
          local index = tonumber(key)
          if index ~= nil and 0 <= index and index < n then
            table.insert(object, index + 1, value)
            return true, root
          end
        end
      end
    end
  end

  function self:remove(root)
    local m = #self._token
    if m == 0 then
      return false
    end
    local object = self:evaluate(root, m - 1)
    if type(object) == "table" then
      local key = self._token[m]
      local n = is_array(object)
      if n == nil then
        object[key] = nil
        return true
      elseif n == 0 then
        return false
      else
        local index = tonumber(index)
        if index ~= nil and 0 <= index and index < n then
          table.remove(object, index + 1)
          return true
        end
      end
    else
      return false
    end
  end

  return self
end
