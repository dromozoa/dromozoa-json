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

local function test(a, b)
  assert(json.encode(a) == b)
  assert(json.encode(json.decode(b)) == b)
end

test(-1, "-1")
test(-1.0, "-1")
test(0, "0")
test(0.0, "0")
test(0.5, "0.5")
test(1, "1")
test(1.0, "1")
test("foo bar baz", [["foo bar baz"]])
test("\"\\/\b\f\n\r\t\0\001\031", [["\"\\\/\b\f\n\r\t\u0000\u0001\u001F"]])
test("", [[""]])
test(" ", [[" "]])
test("\t", [["\t"]])
test("\t ", [["\t "]])
test(" \t", [[" \t"]])
test(" \t ", [[" \t "]])
test(true, "true")
test(false, "false")
test(nil, "null")
test(function () end, "null")
test({}, "[]")
test({ 17, 23, 37, 42, 69 }, "[17,23,37,42,69]")
test({ 17, nil, 23, nil, 37, nil, 42, nil, 69 }, "[17,null,23,null,37,null,42,null,69]")
test({ foo = 42 }, [[{"foo":42}]])
test({ foo = { bar = { baz = 42 } } }, [[{"foo":{"bar":{"baz":42}}}]])

local cycle = {}
cycle.cycle = cycle
local result, message = pcall(json.encode, cycle)
assert(not result)
assert(message:match("too much recursion"))

assert(json.decode([["Z" ]]) == "Z")
assert(json.decode([[ "Z" ]]) == "Z")
assert(json.decode([["\u005A"]]) == "Z")
assert(json.decode([["\u005a"]]) == "Z")
assert(json.decode([["\uD84C\uDFB4"]]) == string.char(0xF0, 0xA3, 0x8E, 0xB4))
assert(json.decode([["\ud84c\udfB4"]]) == string.char(0xF0, 0xA3, 0x8E, 0xB4))

local result, message = pcall(json.decode, "[[[[")
assert(not result)

local result, message = pcall(json.decode, "[] []")
assert(not result)

assert(json.encode(json.decode([[ { "foo" : [ "bar" , 42 ] } ]])) == [[{"foo":["bar",42]}]])
