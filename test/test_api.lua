local tc = require('test.context')
local child = tc.child
local fn = child.fn
local input = child.type_keys
local sleep = vim.uv.sleep

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local eq = expect.equality
local err = expect.error
local ok = expect.no_error

local T = new_set({ hooks = { pre_case = tc.setup, post_once = child.stop } })

local function buffile() return vim.fs.basename(fn.bufname()) end

T['find-switch-recent'] = function()
    tc.lua('quark.fuzzy_find()')
    sleep(321) -- Wait for floating window to open
    eq(fn.mode(), 't')
    input("RDM md")
    sleep(321) -- Wait for matches (async)
    input("<Cr>")
    sleep(123)
    eq(buffile(), "README.md")

    tc.lua('quark.fuzzy_find()')
    sleep(321) -- Wait for floating window to open
    eq(fn.mode(), 't')
    input("jfl")
    sleep(321) -- Wait for matches (async)
    input("<Cr>")
    sleep(123)
    eq(buffile(), "justfile")

    tc.lua('quark.fuzzy_switch()')
    sleep(321) -- Wait for floating window to open
    eq(fn.mode(), 't')
    input("<Cr>")
    sleep(123)
    eq(buffile(), "README.md")

    tc.cmd('%bdelete')
    sleep(123)
    eq(buffile(), "")

    -- Simulate effect of shada file, see :h oldfiles-variable.
    child.api.nvim_set_vvar('oldfiles', { 'README.md' })

    tc.lua('quark.fuzzy_recent()')
    sleep(321) -- Wait for floating window to open
    eq(fn.mode(), 't')
    input("RDM md")
    sleep(321) -- Wait for matches (async)
    input("<Cr>")
    sleep(123)
    eq(buffile(), "README.md")
end

return T
