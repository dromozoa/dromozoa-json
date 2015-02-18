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

local json = require "dromozoa.json.pure"
local pointer = require "dromozoa.json.pointer"

local doc = { json.decode(io.read("*a")) }

local i = 1
while i <= #arg do
  local command = arg[i]
  if command == "--get" then
    local path = arg[i + 1]
    i = i + 2
    local a, b = pointer(path):get(doc)
    assert(a)
    io.write(json.encode(b), "\n")
  elseif command == "--put" then
    local path = arg[i + 1]
    local value = arg[i + 2]
    if value == "-s" then
      value = arg[i + 3]
      i = i + 4
    else
      value = json.decode(value)
      i = i + 3
    end
    assert(pointer(path):put(doc, value))
  elseif command == "--add" then
    local path = arg[i + 1]
    local value = arg[i + 2]
    if value == "-s" then
      value = arg[i + 3]
      i = i + 4
    else
      value = json.decode(value)
      i = i + 3
    end
    assert(pointer(path):add(doc, value))
  elseif command == "--remove" then
    local path = arg[i + 1]
    i = i + 2
    assert(pointer(path):remove(doc))
  elseif command == "--replace" then
    local path = arg[i + 1]
    local value = arg[i + 2]
    if value == "-s" then
      value = arg[i + 3]
      i = i + 4
    else
      value = json.decode(value)
      i = i + 3
    end
    assert(pointer(path):replace(doc, value))
  elseif command == "--move" then
    local from = arg[i + 1]
    local path = arg[i + 2]
    i = i + 3
    assert(pointer(path):move(doc, pointer(from)))
  elseif command == "--copy" then
    local from = arg[i + 1]
    local path = arg[i + 2]
    i = i + 3
    assert(pointer(path):copy(doc, pointer(from)))
  elseif command == "--test" then
    local path = arg[i + 1]
    local value = arg[i + 2]
    if value == "-s" then
      value = arg[i + 3]
      i = i + 4
    else
      value = json.decode(value)
      i = i + 3
    end
    assert(pointer(path):test(doc, value))
  else
    error("bad argument #" .. i)
  end
end

io.write(json.encode(doc[1]), "\n")
