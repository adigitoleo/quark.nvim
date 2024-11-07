local uv = vim.uv
local command = vim.api.nvim_create_user_command
vim.opt.rtp:append(vim.fn.getcwd())

local function handle_signal(signal)
    -- Clean up child instances.
    if signal == "sigterm" then
        io.stdout:write("\nRunning sigterm handler\n")
        os.execute('pkill -TERM -P ' .. tostring(uv.os_getpid()))
    elseif signal == "sigint" then
        io.stdout:write("\nRunning sigint handler\n")
        -- Sending INT is not enough, children don't respond to it (kids these days...)
        os.execute('pkill -TERM -P ' .. tostring(uv.os_getpid()))
    end
    vim.cmd("qa!") -- Exit stage left.
end

local sigterm_handle = uv.new_signal()
uv.signal_start(sigterm_handle, "sigterm", handle_signal)
local sigint_handle = uv.new_signal()
uv.signal_start(sigint_handle, "sigint", handle_signal)

function TestInit()
    vim.opt.rtp:append('dep/mini.nvim')
    local ok, mini_test = pcall(require, 'mini.test')
    if not ok then error("missing test dependency; check that the 'mini.test' submodule is correctly initialised.") end
    mini_test.setup({
        collect = {
            find_files = function()
                return vim.fn.globpath('test', '**/test_*.lua', true, true)
            end,
            -- silent = true,
        },
    })
    quark = require('quark').setup { fzf = {
            -- Default fzf options based on my usual $FZF_DEFAULT_COMMAND and $FZF_DEFAULT_OPTS.
            default_command = "rg --files --hidden --no-messages",
            default_opts = ('--multi --layout=reverse --marker="+" --bind backward-eof:abort,tab:down,shift-tab:up'
            .. '--bind +:toggle-down,¶:abort,alt-\\;:abort,ctrl-l:clear-selection+first,alt-j:preview-down,alt-k:preview-up'
            .. ' --color fg:12,bg:-1,hl:1,fg+:-1,bg+:-1,hl+:1,preview-fg:3'
            .. ' --color prompt:2,gutter:-1,pointer:-1,marker:6,spinner:3,info:3'
            .. ' --color border:12,header:12')
        }
    }
    if quark ~= nil then
        vim.keymap.set("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
        vim.keymap.set("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
        vim.keymap.set("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
        vim.keymap.set("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
        vim.cmd.helptags('ALL')
        quark._err_blocking = true
        vim.api.nvim_echo(
            { { "Test suite setup completed for nvim instance with PID " }, { tostring(uv.os_getpid()) }, { "\n" } },
            #vim.api.nvim_list_uis() ~= 0, -- show in :messages when not headless
            { verbose = true }             -- hide in logging mode
        )
    else
        error("Failed test suite setup for nvim instance with PID " .. tostring(uv.os_getpid()))
    end
end

if #vim.api.nvim_list_uis() == 0 then
    TestInit() -- Load test dependency automatically if headless.
else           -- Otherwise set up convenient user commands.
    command("TestInit", TestInit, { bar = true, desc = "Initialise testing context" })
    command("TestRun", [[=MiniTest.run()]], { desc = "Run test suite" })
end
