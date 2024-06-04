local opt = vim.opt
local tests = require("test.tests")
local session = require("_testvar.fixtures")
local lazydir = session.lazydir
local lazypath = lazydir .. "lazy.nvim"

opt.rtp:prepend(lazypath)
local lazy = tests.load("lazy")
if lazy ~= nil then
    vim.cmd.packadd { args = { "fzf" } }
    vim.cmd.packadd { args = { "quark.nvim" } }
    local quark = tests.load("quark")
    tests.runtests(quark)
end
 -- The arg gives the max allowed time (ms) for these tests.
 -- It should be able to accomodate all of the vim.defer_fn() calls in this session.
 -- It should be less than the maximum timeout in test/run.lua.
vim.defer_fn(function() os.exit(vim.g.ok) end, 3000)
