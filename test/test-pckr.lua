local opt = vim.opt
local tests = require("test.tests")
local session = require("_testvar.fixtures")
local pckr_path = session.pckr_path

opt.rtp:prepend(pckr_path)
opt.pp:prepend(session.root .. "/site")
local pckr = tests.load("pckr")
if pckr ~= nil then
    vim.cmd.packadd { args = { "fzf" } }
    vim.cmd.packadd { args = { "quark.nvim" } }
    local quark = tests.load("quark")
    if quark ~= nil then
        quark.setup {
            fzf = { default_command = "rg --files --hidden --no-messages" }
        }
        tests.create_keybinds(quark)
        tests.runtests(quark)
    end
end
 -- The arg gives the max allowed time (ms) for these tests.
 -- It should be able to accomodate all of the vim.defer_fn() calls in this session.
 -- It should be less than the maximum timeout in test/run.lua.
vim.defer_fn(function() os.exit(vim.g.ok) end, 3000)
