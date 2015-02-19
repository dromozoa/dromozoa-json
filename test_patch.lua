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
local patch = require "dromozoa.json.patch"
local pointer = require "dromozoa.json.pointer"

local data = {
  -- RFC 6902 - A.1. Adding an Object Member
  {
    { foo = "bar" };
    { { op = "add"; path = "/baz"; value = "qux" } };
    { baz = "qux"; foo = "bar" };
  };
  -- RFC 6902 - A.2. Adding an Array Element
  {
    { foo = { "bar", "baz" } };
    { { op = "add"; path = "/foo/1"; value = "qux" } };
    { foo = { "bar", "qux", "baz" } };
  };
  -- RFC 6902 - A.3. Removing an Object Member
  {
    { baz = "qux"; foo = "bar" };
    { { op = "remove"; path = "/baz" } };
    { foo = "bar" };
  };
  -- RFC 6902 - A.4. Removing an Array Element
  {
    { foo = { "bar", "qux", "baz" } };
    { { op = "remove"; path = "/foo/1" } };
    { foo = { "bar", "baz" } };
  };
  -- RFC 6902 - A.5. Replacing a Value
  {
    { baz = "qux"; foo = "bar" };
    { { op = "replace"; path = "/baz"; value = "boo" } };
    { baz = "boo"; foo = "bar" };
  };
  -- RFC 6902 - A.6. Moving a Value
  {
    { foo = { bar = "baz"; waldo = "fred" }; qux = { corge = "grault" } };
    { { op = "move"; from = "/foo/waldo"; path = "/qux/thud" } };
    { foo = { bar = "baz" }; qux = { corge = "grault"; thud = "fred" } };
  };
  -- RFC 6902 - A.7. Moving an Array Element
  {
    { foo = { "all", "grass", "cows", "eat" } };
    { { op = "move"; from = "/foo/1"; path = "/foo/3" } };
    { foo = { "all", "cows", "eat", "grass" } };
  };
  -- RFC 6902 - A.8. Testing a Value: Success
  {
    { baz = "qux"; foo = { "a", 2, "c" } };
    {
      { op = "test"; path = "/baz"; value = "qux" };
      { op = "test"; path = "/foo/1"; value = 2 };
    };
    { baz = "qux"; foo = { "a", 2, "c" } };
  };
  -- RFC 6902 - A.9. Testing a Value: Error
  {
    { baz = "qux" };
    { { op = "test"; path = "/baz"; value = "bar" } };
  };
  -- RFC 6902 - A.10. Adding a Nested Member Object
  {
    { foo = "bar" };
    { { op = "add"; path = "/child"; value = { grandchild = {} } } };
    { foo = "bar"; child = { grandchild = {} } };
  };
  -- RFC 6902 - A.11. Ignoring Unrecognized Elements
  {
    { foo = "bar" };
    { { op = "add"; path = "/baz"; value = "qux"; xyz = 123 } };
    { foo = "bar"; baz = "qux" };
  };
  -- RFC 6902 - A.12. Adding to a Nonexistent Target
  {
    { foo = "bar" };
    { { op = "add"; path = "/baz/bat"; value = "qux" } };
  };
  -- RFC 6902 - A.14. ~ Escape Ordering
  {
    { ["/"] = 9; ["~1"] = 10 };
    { { op = "test"; path = "/~01"; value = 10 } };
    { ["/"] = 9; ["~1"] = 10 };
  };
  -- RFC 6902 - A.15. Comparing Strings and Numbers
  {
    { ["/"] = 9; ["~1"] = 10 };
    { { op = "test"; path = "/~01"; value = "10" } };
  };
  -- RFC 6902 - A.16. Adding an Array Value
  {
    { foo = { "bar" } };
    { { op = "add"; path = "/foo/-"; value = { "abc", "def" } } };
    { foo = { "bar", { "abc", "def" } } };
  };
}

for i = 1, #data do
  local v = data[i]
  local a, b = patch(v[1], v[2])
  if v[3] == nil then
    assert(not a)
  else
    assert(pointer(""):test({ b }, v[3]))
  end
end
