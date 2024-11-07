local tc = require('test.context')
local child = tc.child
local sleep = vim.uv.sleep

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local eq = expect.equality
local err = expect.error
local ok = expect.no_error

local T = new_set({ hooks = { pre_case = tc.setup, post_once = child.stop } })

local defaults = quark.config -- get default config from parent session

T['default'] = function()
    tc.lua('quark = quark.setup {}')
    eq(tc.lua_get('quark.config'), defaults)
end
T['all-valid'] = function()
    ok(quark.setup, {
        backend = "fzy_lua",
        define_commands = false,
        window = {
            width_frac = 0.7,
            height_frac = 0.7,
            border = "sharp",
            zindex = 12,
        },
        cmd_window = {
            width_frac = 0.8,
            height_frac = 0.33,
            border = "top",
            zindex = 13,
        },
        cmd_actions = {
            space = 'execute',
            enter = 'add-space',
            ['!'] = 'cancel',
            ['>'] = 'add-self-and-space',
            [';'] = 'add-self-and-space',
            ['$'] = 'add-self-and-space',
        },
        fzf = {
            preview = false,
            default_command = 'rg --files --hidden --no-messages',
            default_opts = table.concat {
                '--layout',
                'reverse',
                '--marker',
                '+',
                '--bind',
                'backward-eof:abort,tab:down,shift-tab:up,+:toggle-down,¶:abort,alt-\\;:abort,ctrl-l:clear-selection+first,alt-j:preview-down,alt-k:preview-up',
                '--color',
                'fg:12,bg:-1,hl:1,fg+:-1,bg+:-1,hl+:1,preview-fg:3,prompt:2,gutter:-1,pointer:-1,marker:6,spinner:3,info:3,border:12,header:12',
            },
            extra_opts = { '--no-multi' },
            cmd_extra_opts = { '--layout', 'reverse-list' },
            bang_flags = { '--no-ignore-vcs' },
        }
    })
end

T['unrecognized'] = new_set({
    parametrize = {
        { 'foo = false' },                     -- unrecognized option
        { 'foo = { border = "double" }' },     -- unrecognized section
        { 'window = { foo = "double" }' },     -- valid section but unrecognized option
        { 'cmd_window = { foo = "double" }' }, -- valid section but unrecognized option
        { 'fzf = { foo = "double" }' },        -- valid section but unrecognized option
        -- NOTE: Don't check the cmd_actions section, those options (keys) are valid until fzf tries to read them
    }
})
T['unrecognized']['multi'] = function(s)
    err(function() tc.lua('quark.setup { ' .. s .. ' }') end, "unrecognized option")
end

T['invalid'] = new_set({
    parametrize = {
        { 'define_commands = "foo"',              type(defaults.define_commands) },
        { 'window = { width_frac = "foo" }',      type(defaults.window.width_frac) },
        { 'window = { height_frac = "foo" }',     type(defaults.window.height_frac) },
        { 'window = { zindex = "foo" }',          type(defaults.window.zindex) },
        { 'cmd_window = { width_frac = "foo" }',  type(defaults.cmd_window.width_frac) },
        { 'cmd_window = { height_frac = "foo" }', type(defaults.cmd_window.height_frac) },
        { 'cmd_window = { zindex = "foo" }',      type(defaults.cmd_window.zindex) },
        { 'cmd_actions = { [42] = "execute" }',   "string" },
        { 'fzf = { preview = "foo" }',            type(defaults.fzf.preview) },
        { 'fzf = { cmd_extra_opts = 42 }',        type(defaults.fzf.cmd_extra_opts) },
        { 'fzf = { extra_opts = 42 }',            type(defaults.fzf.extra_opts) },
        { 'fzf = { bang_flags = 42 }',            type(defaults.fzf.bang_flags) },
    }
})
T['invalid']['multi'] = function(s, t)
    err(function() tc.lua('quark.setup { ' .. s .. ' }') end, "which is not a " .. t)
end

T['invalid-backend'] = new_set({ parametrize = { { 42 }, { "foo" } } })
T['invalid-backend']['multi'] = function(x)
    err(
        function() tc.lua('quark.setup { backend = ' .. x .. ' }') end,
        "which is not one of"
    )
end

T['invalid-cmd-action'] = new_set({ parametrize = { { "foo" },  { "bar" } } })
T['invalid-cmd-action']['multi'] = function(x)
    -- FIXME: Broken test and maybe broken validation for this config section.
    -- tc.lua('quark.setup { cmd_actions = { space = ' .. x .. ' } }')
    -- vim.print(tc.lua_get('quark.config'))
    err(
        function() tc.lua('quark.setup { cmd_actions = { space = ' .. x .. ' } }') end,
        "which is not one of"
    )
end

T['invalid-window-border'] = function()
    err(function() tc.lua('quark.setup { window = { border = 42 } }') end, "which is not one of")
end
T['invalid-cmd_window-border'] = function()
    err(function() tc.lua('quark.setup { cmd_window = { border = 42 } }') end, "which is not one of")
end

T['invalid-fzf-default_command'] = function()
    err(function() tc.lua('quark.setup { fzf = { default_command = 42 } }') end, "which is not a string or 'true'")
end
T['invalid-fzf-default_opts'] = function()
    err(function() tc.lua('quark.setup { fzf = { default_opts = 42 } }') end, "which is not a string or 'true'")
end

T['no-commands'] = function()
    tc.lua('quark = quark.setup { define_commands = false }')
    err(function() tc.cmd("QuarkFind") end, "Not an editor command")
    sleep(123)
    err(function() tc.cmd("QuarkRecent") end, "Not an editor command")
    sleep(123)
    err(function() tc.cmd("QuarkSwitch") end, "Not an editor command")
end

return T
