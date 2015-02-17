local json = require "dromozoa.json"
local pointer = require "dromozoa.json.pointer"

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
  { "",       root, true, root };
  { "/foo",   root, true, root.foo };
  { "/foo/0", root, true, "bar" };
  { "/",      root, true, 0 };
  { "/a~1b",  root, true, 1 };
  { "/c%d",   root, true, 2 };
  { "/e^f",   root, true, 3 };
  { "/g|h",   root, true, 4 };
  { "/i\\j",  root, true, 5 };
  { "/k\"l",  root, true, 6 };
  { "/ ",     root, true, 7 };
  { "/m~0n",  root, true, 8 };
}

for i = 1, #data do
  local v = data[i]
  local a, b = pointer(v[1]):get(v[2])
  assert(a == v[3])
  assert(b == v[4])
end

-- RFC 6902 - A.8. Testing a Value: Success
local root = { baz = "qux"; foo = { "a", 2, "c" } }
assert(pointer("/baz"):test(root, "qux"))
assert(pointer("/foo/1"):test(root, 2))

-- RFC 6902 - A.9. Testing a Value: Error
assert(not pointer("/baz"):test({ baz = "qux" }, "bar"))

-- RFC 6902 - A.14. ~ Escape Ordering
assert(pointer("/~01"):test({ ["/"] = 9; ["~1"] = 10 }, 10))

-- RFC 6902 - A.15. Comparing Strings and Numbers
assert(not pointer("/~01"):test({ ["/"] = 9; ["~1"] = 10 }, "10"))

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
  local a, b = pointer(v[1]):add(v[2], v[3])
  if v[4] then
    assert(a)
    assert(pointer(""):test(b, v[5]))
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
  local a, b, c = pointer(v[1]):remove(v[2])
  if v[3] then
    assert(a)
    assert(pointer(""):test(b, v[4]))
    assert(pointer(""):test(c, v[5]))
  else
    assert(not a)
  end
end

-- RFC 6902 - A.5. Replacing a Value
local a, b = pointer("/baz"):replace({ baz = "qux"; foo = "bar" }, "boo")
assert(a)
assert(pointer(""):test(b, { baz = "boo"; foo = "bar" }))

-- RFC 6902 - A.6. Moving a Value
local a, b = pointer("/qux/thud"):move({
  foo = {
    bar = "baz";
    waldo = "fred";
  };
  qux = {
    corge = "grault";
  };
}, pointer("/foo/waldo"))
assert(a)
assert(pointer(""):test(b, {
  foo = {
    bar = "baz";
  };
  qux = {
    corge = "grault";
    thud = "fred";
  };
}))

-- RFC 6902 - A.7. Moving an Array Element
local a, b = pointer("/foo/3"):move({
  foo = { "all", "grass", "cows", "eat" };
}, pointer("/foo/1"))
assert(a)
assert(pointer(""):test(b, {
  foo = { "all", "cows", "eat", "grass" };
}))

local root = { a = { b = { c = 17 } } }
local a, b = pointer("/a/b/c"):move(root, pointer("/a/b"))
assert(not a)
assert(pointer(""):test(root, { a = { b = { c = 17 } } }))
