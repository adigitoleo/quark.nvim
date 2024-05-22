local failures = {}
local testfiles = {
    "init-lazy.lua",
    "init-pckr.lua",
}
for _, testfile in pairs(testfiles) do
    io.stdout:write(string.format("=> running test: %s\n", testfile))
    vim.fn.jobwait({ vim.fn.jobstart({ "nvim", "--headless", "-u", "test/" .. testfile, "-c", "quit" },
        {
            stderr_buffered = true,
            on_stderr = function(_, data, _)
                local err = string.gsub(table.concat(data), "\r", "\n")
                -- Sometimes we get empty stderr (e.g. just newlines), and that shouldn't count.
                if #string.gsub(err, "%s", "") > 0 then
                    io.stderr:write(string.format("\27[31m%s\27[m\n", err))
                    table.insert(failures, testfile)
                end
            end
        }) })
end
local n_fails = vim.tbl_count(failures)
if n_fails > 0 then
    io.stdout:write(string.format("FAILED: %d/%d\n", n_fails, #testfiles))
    io.stdout:write("\t" .. table.concat(failures, "\t") .. "\n")
else
    io.stdout:write("PASS\n")
end
os.exit(n_fails)
