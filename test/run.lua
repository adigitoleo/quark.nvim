-- run this file with `nvim -l <file>` to run the test suite.
-- it really just runs test/collect.lua, but adds sigint (ctrl-c) and timeout (sigterm) handling.
local uv = vim.uv or vim.loop
local tests = require("test.tests")
local sigint = uv.new_signal()
local sigterm = uv.new_signal()

local function die(signal, code)
    tests.destroy_session()
    io.stdout:write("\n")
    if signal == tests.TERM or code == tests.TERMCODE then -- (sig)term
        tests.err("reached maximum test timeout")
        os.exit(code)
    elseif signal == tests.INT then -- (sig)int
        tests.err("test runner interrupted (SIGINT)")
        os.exit(code)
    else
        os.exit(code)
    end
end
sigint:start("sigint", function(signal) die(signal, 1) end)
sigterm:start("sigint", function(signal) die(signal, 1) end)
local job = vim.system({ "nvim", "-l", "test/collect.lua" },
    {
        timeout = 10000,
        stdout = function(_, data) io.stdout:write(data) end,
        stderr = function(_, data) io.stderr:write(data) end,
        text = true,
    }):wait()
die(job.signal, job.code)
