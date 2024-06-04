local failures = {}
local testspec = { -- Each test consists of both a setup file and the main test file.
    { "init-lazy.lua", "test-lazy.lua" },
    { "init-pckr.lua", "test-pckr.lua" },
}
local tests = require("test.tests")

function runtest(file, cmd)
    local job = vim.system(cmd):wait()
    if job.code ~= 0 then
        if job.stderr == "" then
            io.stderr:write("reached the timeout for this test\n")
        else
            io.stderr:write(string.format("\27[31m%s\27[m\n", job.stderr))
        end
        table.insert(failures, file)
    end
end

for _, spec in pairs(testspec) do
    initfile = spec[1]
    testfile = spec[2]
    io.stdout:write(string.format("\27[1m=> running test: %s\27[m\n", testfile))
    session = tests.create_session()
    if session ~= nil then
        -- Here initfile installs the package manager and plugins, testfile runs the tests.
        runtest(initfile, { "nvim", "--headless", "-n", "-u", "test/" .. initfile, "-c", "quit" })
        runtest(testfile, { "nvim", "--headless", "-n", "-u", "test/" .. testfile})
        tests.destroy_session() -- Destroy session outside the actual test file to ensure cleanup.
    else
        os.exit(1)
    end
end
local n_fails = vim.tbl_count(failures)
if n_fails > 0 then
    io.stdout:write(string.format("FAILED: %d/%d\n", n_fails, #testspec))
    io.stdout:write("\t" .. table.concat(failures, "\t") .. "\n")
else
    io.stdout:write("PASS\n")
end
vim.defer_fn(function()
    os.exit(n_fails)
end, 10000)
