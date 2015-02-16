local json = require "dromozoa.json"

local root = {
  foo = { "bar"; "baz" };
  [""] = 0;
  ["a/b"] = 1;
  ["c%d"] = 2;
  ["e^f"] = 3;
  ["g|h"] = 4;
  ["i\\j"] = 5;
  ["k\"l"] = 6;
  [" "] = 7;
  ["m~n"] = 8;
}

local function test_get(a, b)
  local result, object = json.pointer(a):get(root)
  assert(a)
  assert(object == b)
end

test_get("", root)
test_get("/foo", root.foo)
test_get("/foo/0", "bar")
test_get("/", 0)
test_get("/a~1b", 1)
test_get("/c%d", 2)
test_get("/e^f", 3)
test_get("/g|h", 4)
test_get("/i\\j", 5)
test_get("/k\"l", 6)
test_get("/ ", 7)
test_get("/m~0n", 8)

local root = {}
print(json.pointer("/3"):get({ 17, nil, 23 }))


--[[
local root = { foo = 17 }
local result, root = json.pointer(""):add(root, "bar")
assert(result)
assert(root == "bar")

local root = { foo = 17 }
local result, root = json.pointer(""):add(root, { bar = 23 })
assert(result)
assert(root.foo == nil)
assert(root.bar == 23)

local root = { foo = 17 }
local result, root = json.pointer(""):add(root, { 23, 37 })
assert(result)
assert(root.foo == nil)
assert(#root == 2)
assert(root[1] == 23)
assert(root[2] == 37)

local root = { foo = 17 }
assert(json.pointer("/bar"):add(root, 23))
assert(root.foo == 17)
assert(root.bar == 23)

local root = { 17, 23 }
assert(json.pointer("/-"):add(root, 37))
assert(json.pointer("/1"):add(root, 42))
assert(#root == 4)
assert(root[1] == 17)
assert(root[2] == 42)
assert(root[3] == 23)
assert(root[4] == 37)
]]
