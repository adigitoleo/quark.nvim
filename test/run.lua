-- Run this file with `nvim -l <file>` to run the test suite.
-- It really just runs test/init.lua, but adds SIGINT (Ctrl-C) handling.
local uv = vim.uv or vim.loop
local tests = require("test.tests")

local signal = uv.new_signal()
local function die()
    tests.destroy_session()
    io.stdout:write("\n")
    os.exit(1)
end
uv.signal_start(signal, "sigint", function(_)
    die()
end)
local ok = os.execute("nvim -l test/collect.lua")
if ok ~= 0 then die() end
