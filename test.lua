#! /usr/bin/env lua

local json = require "dromozoa.json.pure"

local function test(a, b)
  assert(json.encode(a) == b)
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
print(result, message)
assert(not result)
