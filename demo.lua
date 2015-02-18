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
