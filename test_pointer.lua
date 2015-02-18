local json = require "dromozoa.json"
local pointer = require "dromozoa.json.pointer"

local root = {
  [ [[foo]] ] = { "bar", "baz" };
  [ [[]]    ] = 0;
  [ [[a/b]] ] = 1;
  [ [[c%d]] ] = 2;
  [ [[e^f]] ] = 3;
  [ [[g|h]] ] = 4;
  [ [[i\j]] ] = 5;
  [ [[k"l]] ] = 6;
  [ [[ ]]   ] = 7;
  [ [[m~n]] ] = 8;
}

local data = {
  { "",   nil, true,  nil };
  { "/",  nil, false, nil };
  { "//", nil, false, nil };
  { "/",  {},  false, nil };
  { "//", {},  false, nil };
  { "/0", { 17, nil, 23 }, true,  17 };
  { "/1", { 17, nil, 23 }, true,  nil };
  { "/2", { 17, nil, 23 }, true,  23 };
  { "/3", { 17, nil, 23 }, false, nil};

  -- RFC 6901 - 5. JSON String Representation
  { [[]],       root, true, root };
  { [[/foo]],   root, true, root.foo };
  { [[/foo/0]], root, true, "bar" };
  { [[/]],      root, true, 0 };
  { [[/a~1b]],  root, true, 1 };
  { [[/c%d]],   root, true, 2 };
  { [[/e^f]],   root, true, 3 };
  { [[/g|h]],   root, true, 4 };
  { [[/i\j]],   root, true, 5 };
  { [[/k"l]],   root, true, 6 };
  { [[/ ]],     root, true, 7 };
  { [[/m~0n]],  root, true, 8 };
}

for i = 1, #data do
  local v = data[i]
  local doc = { v[2] }
  local a, b = pointer(v[1]):get(doc)
  assert(a == v[3])
  assert(b == v[4])
end

-- RFC 6902 - A.8. Testing a Value: Success
local root = { baz = "qux"; foo = { "a", 2, "c" } }
local doc = { root }
assert(pointer("/baz"):test(doc, "qux"))
assert(pointer("/foo/1"):test(doc, 2))

-- RFC 6902 - A.9. Testing a Value: Error
local root = { baz = "qux" }
local doc = { root }
assert(not pointer("/baz"):test(doc, "bar"))

-- RFC 6902 - A.14. ~ Escape Ordering
local root = { ["/"] = 9; ["~1"] = 10 }
local doc = { root }
assert(pointer("/~01"):test(doc, 10))

-- RFC 6902 - A.15. Comparing Strings and Numbers
local root = { ["/"] = 9; ["~1"] = 10 }
local doc = { root }
assert(not pointer("/~01"):test(doc, "10"))

local data = {
  { "", { foo = 17 }, 23, true, 23 };
  { "", { foo = 17 }, "bar", true, "bar" };
  { "", { foo = 17 }, { bar = 23 }, true, { bar = 23 } };
  { "", { foo = 17 }, { 17, nil, 23 }, true, { 17, nil, 23 } };
  { "/-", {}, 17, true, { 17 } };
  { "/0", {}, 17, true, { 17 } };
  { "/1", {}, 17, true, { ["1"] = 17 } };
  { "/x", {}, 17, true, { x = 17 } };
  { "/-", { foo = 17 }, 23, true, { foo = 17; ["-"] = 23 } };
  { "/0", { foo = 17 }, 23, true, { foo = 17; ["0"] = 23 } };
  { "/x", { foo = 17 }, 23, true, { foo = 17; ["x"] = 23 } };
  { "/-", { 17, nil, 23 }, 37, true, { 17, nil, 23, 37 } };
  { "/0", { 17, nil, 23 }, 37, true, { 37, 17, nil, 23 } };
  { "/1", { 17, nil, 23 }, 37, true, { 17, 37, nil, 23 } };
  { "/2", { 17, nil, 23 }, 37, true, { 17, nil, 37, 23 } };
  { "/3", { 17, nil, 23 }, 37, true, { 17, nil, 23, 37 } };
  { "/4", { 17, nil, 23 }, 37, false };
  { "/x", { 17, nil, 23 }, 37, false };
  { "/x/y", { x = {} }, 17, true, { x = { y = 17 } } };
  { "/x/y/z", { x = { y = {} } }, 17, true, { x = { y = { z = 17 } } } };

  -- RFC 6902 - A.1. Adding an Object Member
  { "/baz", { foo = "bar" }, "qux", true, { baz = "qux"; foo = "bar" } };

  -- RFC 6902 - A.2. Adding an Array Element
  { "/foo/1", { foo = { "bar", "baz" } }, "qux", true, { foo = { "bar", "qux", "baz" } } };

  -- RFC 6902 - A.10. Adding a Nested Member Object
  { "/child", { foo = "bar" }, { grandchild = {} }, true, { foo = "bar"; child = { grandchild = {} } } };

  -- RFC 6902 - A.12. Adding to a Nonexistent Target
  { "/baz/bat", { foo = "bar" }, "qux", false };

  -- RFC 6902 - A.16. Adding an Array Value
  { "/foo/-", { foo = { "bar" } }, { "abc", "def" }, true, { foo = { "bar", { "abc", "def" } } } };
}

for i = 1, #data do
  local v = data[i]
  local doc = { v[2] }
  local a, b = pointer(v[1]):add(doc, v[3])
  if v[4] then
    assert(a)
    assert(pointer(""):test(doc, v[5]))
  else
    assert(not a)
  end
end

local data = {
  { "", { foo = 17 }, true, nil, { foo = 17 } };
  { "/foo", { foo = 17 }, true, {}, 17 };
  { "/bar", { foo = 17 }, false };
  { "/-", {}, false };
  { "/0", {}, false };
  { "/-", { 17, nil, 23 }, false };
  { "/0", { 17, nil, 23 }, true, { nil, 23 }, 17 };
  { "/1", { 17, nil, 23 }, true, { 17, 23 }, nil };
  { "/2", { 17, nil, 23 }, true, { 17 }, 23 };
  { "/3", { 17, nil, 23 }, false };

  -- RFC 6902 - A.3. Removing an Object Member
  { "/baz", { baz = "qux"; foo = "bar" }, true, { foo = "bar" }, "qux" };

  -- RFC 6902 - A.4. Removing an Array Element
  { "/foo/1", { foo = { "bar", "qux", "baz" } }, true, { foo = { "bar", "baz" } }, "qux" };
}

for i = 1, #data do
  local v = data[i]
  local doc = { v[2] }
  local a, b = pointer(v[1]):remove(doc)
  if v[3] then
    assert(a)
    assert(pointer(""):test(doc, v[4]))
    assert(pointer(""):test({ b }, v[5]))
  else
    assert(not a)
  end
end

-- RFC 6902 - A.5. Replacing a Value
local root = { baz = "qux"; foo = "bar" }
local doc = { root }
assert(pointer("/baz"):replace(doc, "boo"))
assert(pointer(""):test(doc, { baz = "boo"; foo = "bar" }))

-- RFC 6902 - A.6. Moving a Value
local root = {
  foo = {
    bar = "baz";
    waldo = "fred";
  };
  qux = {
    corge = "grault";
  };
}
local doc = { root }
assert(pointer("/qux/thud"):move(doc, pointer("/foo/waldo")))
assert(pointer(""):test(doc, {
  foo = {
    bar = "baz";
  };
  qux = {
    corge = "grault";
    thud = "fred";
  };
}))

-- RFC 6902 - A.7. Moving an Array Element
local root = { foo = { "all", "grass", "cows", "eat" } }
local doc = { root }
assert(pointer("/foo/3"):move(doc, pointer("/foo/1")))
assert(pointer(""):test(doc, { foo = { "all", "cows", "eat", "grass" } }))

local root = { a = { b = { c = 17 } } }
local doc = { root }
assert(not pointer("/a/b/c"):move(root, pointer("/a/b")))
assert(pointer(""):test(doc, { a = { b = { c = 17 } } }))

local root = { a = { b = { c = 17 } } }
local doc = { root }
assert(pointer("/a/b/c"):copy(doc, pointer("/a/b")))
assert(pcall(json.encode, doc[1]))

local root = {}
root.foo = root
local doc = { root }

local result, message = pcall(function () pointer(""):test(doc, doc[1]) end)
assert(not result)
assert(message:match("too much recursion"))

local result, message = pcall(function () pointer("/bar"):copy(doc, pointer("/foo")) end)
assert(not result)
assert(message:match("too much recursion"))

local root = { foo = 17 }
local doc = { root }
assert(pointer("/bar"):copy(doc, pointer("")))
assert(pointer(""):test(doc, { foo = 17; bar = { foo = 17 } }))

local data = {
  { "", { foo = 17 }, 23, true, 23 };
  { "", { foo = 17 }, "bar", true, "bar" };
  { "", { foo = 17 }, { bar = 23 }, true, { bar = 23 } };
  { "", { foo = 17 }, { 17, nil, 23 }, true, { 17, nil, 23 } };
  { "/-", {}, 17, true, { ["-"] = 17 } };
  { "/0", {}, 17, true, { 17 } };
  { "/1", {}, 17, true, { ["1"] = 17 } };
  { "/x", {}, 17, true, { x = 17 } };
  { "/-", { foo = 17 }, 23, true, { foo = 17; ["-"] = 23 } };
  { "/0", { foo = 17 }, 23, true, { foo = 17; ["0"] = 23 } };
  { "/x", { foo = 17 }, 23, true, { foo = 17; ["x"] = 23 } };
  { "/-", { 17, nil, 23 }, 37, false };
  { "/0", { 17, nil, 23 }, 37, true, { 37, nil, 23 } };
  { "/1", { 17, nil, 23 }, 37, true, { 17, 37, 23 } };
  { "/2", { 17, nil, 23 }, 37, true, { 17, nil, 37 } };
  { "/3", { 17, nil, 23 }, 37, true, { 17, nil, 23, 37 } };
  { "/4", { 17, nil, 23 }, 37, false };
  { "/x", { 17, nil, 23 }, 37, false };
  { "/x/y/z", nil, 17, true, { x = { y = { z = 17 } } } };
  { "/x/y/z", {}, 17, true, { x = { y = { z = 17 } } } };
  { "/x/y/z", { x = {} }, 17, true, { x = { y = { z = 17 } } } };
  { "/x/y/z", { x = { y = {} } }, 17, true, { x = { y = { z = 17 } } } };
  { "/0/0/0", nil, 17, true, { { { 17 } } } };
  { "/0/0/0", {}, 17, true, { { { 17 } } } };
  { "/0/0/0", { {} }, 17, true, { { { 17 } } } };
  { "/0/0/0", { { {} } }, 17, true, { { { 17 } } } };
  { "/1/2/3", nil, 17, true, { ["1"] = { ["2"] = { ["3"] = 17 } } } };
}

for i = 1, #data do
  local v = data[i]
  local doc = { v[2] }
  for j = 1, 2 do -- check idempotency
    local a = pointer(v[1]):put(doc, v[3])
    if v[4] then
      assert(a)
      assert(pointer(""):test(doc, v[5]))
    else
      assert(not a)
    end
  end
end
