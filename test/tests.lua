local Tests = {}
local api = vim.api
local fn = vim.fn
local uv = vim.uv or vim.loop
local bindkey = vim.keymap.set

-- Check :h vim.system() for these.
Tests.INT = 2
Tests.TERM = 15
Tests.TERMCODE = 124

-- Send a message to neovim's error message buffer.
function Tests.err(msg) api.nvim_err_writeln(msg) end

-- Send a message to stderr and color it in red.
function Tests.crit(msg) io.stderr:write(string.format("\27[31m%s\27[m\n", msg)) end

-- Send a message to stdout and use boldface.
function Tests.info(msg) io.stdout:write(string.format("\27[1m%s\27[m\n", msg)) end

function Tests.load(plugin) -- Load either local or third-party plugin.
    local has_plugin, out = pcall(require, plugin)
    if has_plugin then
        return out
    else
        Tests.err(string.format("failed to load plugin '%s'", plugin))
        return nil
    end
end

function Tests.create_keybinds(quark) -- Create default keybinds for this plugin.
    bindkey("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
    bindkey("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
    bindkey("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
    bindkey("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
end

-- Create test session in _testvar/.
function Tests.create_session()
    local ok = uv.fs_mkdir("_testvar", tonumber("755", 8))
    if not ok then
        -- Use io.stderr:write not Test.err, because this will be called in collect.lua!
        io.stderr:write("failed to create temporary directory '_testvar' for test session\n")
        return
    end
    local session = {
        root = "_testvar",
        module = "_testvar/fixtures.lua",
        lazydir = "_testvar/site/pack/lazy/opt/",
        lazylock = "_testvar/lazy-lock.json",
        pckr_path = "_testvar/site/pack/pckr/start/pckr.nvim",
        pckr_root = "_testvar/site/pack/",
    }
    local session_module = io.open(session.module, "w+")
    if session_module ~= nil then
        session_module:write("return {\n")
        for k, v in pairs(session) do
            session_module:write(string.format("%s = '%s',\n", k, v))
        end
        session_module:write("}\n")
    end
    io.close(session_module)
    return session
end

function Tests.destroy_session()
    -- Here 0 == FALSE, see :h Boolean.
    if fn.isdirectory("_testvar") ~= 0 then
        -- Here 0 == TRUE means the delete was successful.
        if fn.delete("_testvar", "rf") ~= 0 then
            -- Use io.stderr:write not Test.err, because this will be called in collect.lua!
            io.stderr:write("failed to remove '_testvar' directory\n")
        end
    end
end

function Tests.runtests(quark)
    vim.g.ok = false
    vim.opt.showmode = false
    vim.g.ok = Tests.find_cmd()
    -- vim.g.ok = Tests.always_fail()
    return vim.g.ok
end

function Tests.check(expected, got)
    if not (got == expected) then
        Tests.err(string.format("Expected: %s\nGot: %s\n", expected, got))
        return false
    end
    return true
end

function Tests.typekeys(keys, special, mode)
    local _mode = mode or "t"
    if special then
        api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), _mode, false)
    else
        api.nvim_feedkeys(keys, _mode, false)
    end
end

function Tests.find_cmd()
    local defer_time = 0
    Tests.typekeys("<Cmd>", true)
    Tests.typekeys("QuarkFind test/\r")
    Tests.typekeys("tests.lua")
    -- Wait for fzf results.
    defer_time = defer_time + 500
    vim.defer_fn(function()
        Tests.typekeys("\r")
    end, defer_time)
    -- Wait until buffer loads.
    defer_time = defer_time + 500
    vim.g.expected = "test/tests.lua"
    vim.defer_fn(function()
        vim.g.got = fn.fnamemodify(api.nvim_buf_get_name(0), ":.")
    end, defer_time)
    -- Wait until globals are set.
    defer_time = defer_time + 500
    vim.defer_fn(function()
        vim.g.ok = Tests.check(vim.g.expected, vim.g.got)
    end, defer_time)
    return vim.g.ok
end

function Tests.always_fail(defer_time)
    local msg = "this test is expected to fail"
    vim.g.expected = msg
    vim.defer_fn(function()
        vim.g.got = vim.text.hexencode(msg)
        vim.g.ok = Tests.check(vim.g.expected, vim.g.got)
    end, defer_time or 500)
end

return Tests
