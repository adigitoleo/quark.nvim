-- Run this file with `nvim -l <file>` to run the test suite.
-- It really just runs test/collect.lua, but adds SIGINT (Ctrl-C) handling.
local uv = vim.uv or vim.loop
local tests = require("test.tests")

local signal = uv.new_signal()
local function die(code)
    tests.destroy_session()
    io.stdout:write("\n")
    os.exit(code)
end
uv.signal_start(signal, "sigint", function(_)
    die(1)
end)
local job = vim.system({ "nvim", "-l", "test/collect.lua" }, { timeout = 10000 }):wait()
if job.code ~= 0 then die(1) else die(0) end
