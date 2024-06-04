local failures = {}
local testspec = { -- Each test consists of both a setup file and the main test file.
    { "init-lazy.lua", "test-lazy.lua" },
    { "init-pckr.lua", "test-pckr.lua" },
}
local tests = require("test.tests")

function runtest(file, cmd)
    -- The timeout should be able to accomodate all of the vim.defer_fn() calls in the session.
    -- It should be less than the maximum timeout in test/run.lua.
    local job = vim.system(cmd, { timeout = 3000 }):wait()
    if job.code == tests.TERMCODE or job.signal == tests.TERM then
        tests.crit("reached the timeout for " .. file)
    elseif job.code ~= 0 then
        tests.crit(job.stderr)
        table.insert(failures, file)
    end
end

for _, spec in pairs(testspec) do
    initfile = spec[1]
    testfile = spec[2]
    tests.info("=> running test: " .. testfile)
    session = tests.create_session()
    if session ~= nil then
        -- Here initfile installs the package manager and plugins, testfile runs the tests.
        runtest(initfile, { "nvim", "--headless", "-n", "-u", "test/" .. initfile, "-c", "quit" })
        runtest(testfile, { "nvim", "--headless", "-n", "-u", "test/" .. testfile })
        tests.destroy_session() -- Destroy session outside the actual test file to ensure cleanup.
    else
        os.exit(1)
    end
end
local n_fails = vim.tbl_count(failures)
if n_fails > 0 then
    tests.info(string.format("FAILED: %d/%d\n", n_fails, #testspec))
    tests.info("\t" .. table.concat(failures, "\t"))
else
    tests.info("PASSED")
end
os.exit(n_fails)
