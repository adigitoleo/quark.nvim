local libfzf = require("backends.fzf")
local libfzy = require("backends.fzy")
local api = vim.api
local opt = vim.opt
local fn = vim.fn
local command = api.nvim_create_user_command
local Quark = {
    cmd_actions = { "execute", "cancel", "add-space", "add-self-and-space" }
}

-- TODO: On fzf FileType, set a single-shot autocommand for WinClosed that redraws the statusline.
-- TODO: Implement winblend using a FileType fzf autocommand.
-- TODO: Implement xoffset and yoffset window options?

Quark.config = {
    backend = "fzf",        -- "fzf" or "fzy_lua"
    define_commands = true, -- toggle automatic definition of user-commands
    window = {              -- <https://github.com/junegunn/fzf/blob/master/README-VIM.md>
        width_frac = 0.9,   -- width of floating window as a fraction of total width
        height_frac = 0.6,  -- height of floating window as a fraction of total height
        border = "sharp",   -- border style, see the fzf(1) manual page or :h api-floatwin for fzy_lua
        zindex = 21,        -- floating window 'priority', only used for fzy_lua
    },
    cmd_window = {          -- same as above but for the fuzzy ex-command picker window
        width_frac = 1,
        height_frac = 0.4,  -- FIXME: Somehow this loooks more like 60% height??
        border = "top",
        zindex = 23,
    },
    -- additional actions for the ex-command picker
    -- defaults: enter = 'execute' and 'ctrl-c' = 'cancel'
    cmd_actions = {
        space = 'add-space',
        [';'] = 'cancel',
        ['|'] = 'add-self-and-space',
        ['!'] = 'add-self-and-space', -- 'fzf --expect !' requires fzf ≥ 0.51.0
    },
    fzf = {
        preview = true,         -- show embedded file previews using head(1) on linux
        default_command = true, -- string or true: if true, use $FZF_DEFAULT_COMMAND
        default_opts = true,    -- string or true: if true, use $FZF_DEFAULT_OPTS
        bang_flags = {},        -- flags to append to default_command for :QuarkFind!
        -- additional options passed to the fzf command for everything else
        extra_opts = {},
        -- additional options passed to the fzf command for the ex-command picker
        cmd_extra_opts = {
            '--no-multi',
            '--color',
            'prompt:-1',
        },
    }
    -- fzy_lua = {
    --     winblend = 30, -- transparency setting, see :h 'winblend'
    -- }
}

-- Use error(), which is blocking, instead of nvim_err_writeln(), which is not.
-- This is used in the test suite and could be useful for debugging.
Quark._err_blocking = false
-- Track if user commands have been defined before.
Quark._has_commands = false

local function warn(msg) ---@param msg string
    local erf = api.nvim_err_writeln
    if Quark._err_blocking then erf = error end
    erf("[quark.nvim]: " .. msg)
end

-- Validate custom user config, fall back to Quark.config defaults.
---@param key string
---@param section string|nil
local function validate(key, value, section)
    local schema = Quark.config
    local got_type = type(value)
    local option = key .. " = " .. tostring(value)
    -- TODO: Append libfzy.border_choices when implemented.
    local border_choices = libfzf.border_choices
    local numeric_window_keys = { "width_frac", "height_frac", "winblend", "zindex", "xoffset", "yoffset" }
    if section then
        option = table.concat({ section, key }, ".") .. " = " .. tostring(value)
        if section ~= "cmd_actions" and (schema[section] == nil or schema[section][key] == nil) then
            warn("unrecognized option: " .. option)
            return nil
        elseif section == "window" or section == "cmd_window" then
            if vim.tbl_contains(numeric_window_keys, key) and got_type ~= "number" then
                warn("got '" .. option .. "', which is not a number")
                return schema[section][key]
            elseif key == "border" and not vim.tbl_contains(border_choices, value) then
                warn("got '" .. option .. "', which is not one of: " .. table.concat(border_choices, ", "))
                return schema[section][key]
            elseif key == "highlight" and got_type ~= "string" then
                warn("got '" .. option .. "', which is not a string")
                return schema[section][key]
            end
        elseif section == "cmd_actions" then
            if type(key) ~= "string" or got_type ~= "string" then
                warn("got '" .. option .. "', which is not a string => string mapping")
                return
            elseif not vim.list_contains(Quark.cmd_actions, value) then
                warn("got '" .. option .. "', which is not one of: " .. table.concat(Quark.cmd_actions, ","))
                return
            end
            return value
        elseif section == "fzf" then
            if (key == "default_command" or key == "default_opts") and not (got_type == "string" or value == true) then
                warn("got '" .. option .. "', which is not a string or 'true'")
                return schema[section][key]
            elseif key == "preview" and got_type ~= "boolean" then
                warn("got '" .. option .. "', which is not a boolean")
                return schema[section][key]
            elseif (key == "bang_flags" or key == "cmd_extra_opts" or key == "extra_opts") and got_type ~= "table" then
                warn("got '" .. option .. "', which is not a table ('list')")
                return schema[section][key]
            end
        end
        -- TODO: Validate fzy_lua config options.
    elseif key == "backend" and not (value == "fzf" or value == "fzy_lua") then
        warn("got '" .. option .. "', which is not one of 'fzf' or 'fzy_lua'")
        return schema[key]
    elseif key == "define_commands" and got_type ~= "boolean" then
        warn("got '" .. option .. "', which is not a boolean")
        return schema[key]
    elseif schema[key] == nil then
        warn("unrecognized option: " .. option)
        return nil
    end
    return value
end

-- Setup function to allow and validate user configuration.
---@param config table|nil table
function Quark.setup(config)
    if config ~= nil then
        if config.backend == "fzf" and not libfzf.has_fzf() then
            warn(
                "unable to initialise fzf backend for fzf version ≥ 0.51.0," ..
                " is your fzf executable installed correctly?"
            )
            return nil
            -- elseif config.backend == "fzy_lua" and not libfzy.get_fzy() then
            --     warn(
            --         "unable to download fzy_lua backend from 'https://github.com/swarn/fzy-lua'," ..
            --         " check your network connection"
            --     )
            --     return nil
        end
        for k, v in pairs(config) do
            if type(v) == "table" then
                for _k, _v in pairs(v) do
                    Quark.config[k][_k] = validate(_k, _v, k)
                end
            else
                Quark.config[k] = validate(k, v)
            end
        end
    end
    if Quark.config.define_commands then
        command("QuarkRecent", Quark.fuzzy_recent, { desc = "Open recent files (v:oldfiles) or listed buffers" })
        command("QuarkSwitch", Quark.fuzzy_switch, { desc = "Switch between listed buffers or loaded `:terminal`s" })
        command("QuarkFind", Quark.fuzzy_find,
            { nargs = "?", complete = "file", bang = true, desc = "Open files from <dir> (or :pwd by default)" })
        Quark._has_commands = true
    elseif Quark._has_commands == true then
        for _, cmd in pairs({ "QuarkRecent", "QuarkSwitch", "QuarkFind" }) do
            api.nvim_del_user_command(cmd)
        end
    end

    return Quark
end

-- Generate filtered list of file names from given sources, omitting current file name.
---@param sources table sources, each field is a sub-table of file names
---@param mods string filename filters to use, see :h filename-modifiers and :h fnamemodify()
---@param sep string separator to insert between file names
local function list_files(sources, mods, sep) ---@return string
    local ignore = { vim.env.VIMRUNTIME }            -- Ignore internal (neo)vim files.
    table.insert(ignore, "/nvim/runtime/doc/")       -- Ignore neovim helpfiles.
    for _, pattern in pairs(opt.wildignore:get()) do -- Respect 'wildignore'.
        pattern, _ = string.gsub(pattern, "*", "")   -- Remove glob signs, not used here.
        table.insert(ignore, pattern)
    end
    local thisfilename = fn.expand("%" .. mods) -- Ignore current file name if any.
    if fn.strchars(thisfilename) > 0 then table.insert(ignore, thisfilename) end

    local files = {} -- Deduplicated list of files from given sources.
    for _, source in pairs(sources) do
        for _, file in pairs(source) do
            file = fn.fnamemodify(file, mods)
            if fn.strchars(file) > 0 and fn.filereadable(file) > 0 then
                local match = false
                for _, pattern in pairs(ignore) do
                    if file:match(pattern) then
                        match = true
                        break
                    end
                end
                if not match and fn.count(files, file) == 0 then
                    table.insert(files, file)
                end
            end
        end
    end
    return table.concat(files, sep)
end

-- Generate list of open terminals, omitting focused terminal.
---@param sep string separator to insert between file names
local function list_terminals(sep) ---@return string
    local terminals = {}
    vim.tbl_map(function(v) table.insert(terminals, api.nvim_buf_get_var(v, "term_title")) end,
        vim.tbl_filter(
            function(v)
                if fn.getbufvar(v, "&buftype") == "terminal" and fn.bufnr("%") ~= v then return v end
                return false
            end, api.nvim_list_bufs()
        )
    )
    return table.concat(terminals, sep)
end

-- Generate list of (most?) builtin and user/plugin-defined commands.
---@param sep string separator to insert between file names
local function list_commands(sep) ---@return string
    local cmdlist = {}
    for _, line in pairs(fn.readfile(fn.expand("$VIMRUNTIME/doc/index.txt", 1))) do
        local match = line:match("^|:(%w+)|")
        if match then table.insert(cmdlist, match) end
    end

    -- Get user/plugin defined commands from `:command`.
    local com = vim.split(fn.execute("command"), '\n')
    for i, line in pairs(com) do
        repeat
            if i == 1 then break end -- First element is 'Name' from :command header.
            local match = line:match("^%W%W%W%W(%w+)%s")
            if match then table.insert(cmdlist, match) end
            break
        until true
    end
    return table.concat(cmdlist, sep)
end

function Quark.list_filetypes() -- List all known filetypes.
    local filetypes = {}
    for _, ft in pairs(fn.split(fn.expand("$VIMRUNTIME/ftplugin/*.vim"))) do
        table.insert(filetypes, fn.fnamemodify(ft, ":t:r"))
    end
    return filetypes
end

function Quark.list_syntax() -- List all known syntax files.
    local syntax = {}
    for _, sx in pairs(fn.split(fn.expand("$VIMRUNTIME/syntax/*.vim"))) do
        table.insert(syntax, fn.fnamemodify(sx, ":t:r"))
    end
    return syntax
end

-- Get list of open ("listed", or "loaded" if all is true) buffer IDs.
function Quark.list_bufs(all)
    local bufs = {}
    for i, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) then
            if all then
                bufs[i] = buf
            else
                if vim.bo[buf].buflisted then
                    table.insert(bufs, buf)
                end
            end
        end
    end
    return bufs
end

-- Get list of open ("listed", or "loaded" if all is true) buffer names.
function Quark.list_buf_names(all)
    local buffer_names = {}
    for _, buf in pairs(Quark.list_bufs(all)) do
        table.insert(buffer_names, api.nvim_buf_get_name(buf))
    end
    return buffer_names
end

-- Fuzzy-find files in current or chosen directory.
function Quark.fuzzy_find(opts)
    local dir = '.'
    if (opts and opts.fargs and vim.tbl_count(opts.fargs) > 0) then dir = opts.fargs[1] end
    if Quark.config.backend == "fzf" then
        if not libfzf.has_fzf() then return end
        local cmd = Quark.config.fzf.default_command
        local cmdstr = nil
        if cmd == true then
            cmdstr = os.getenv("FZF_DEFAULT_COMMAND")
            if cmdstr == nil then
                warn("requires either explicit fzf command or FZF_DEFAULT_COMMAND environment variable")
                return
            end
        else
            cmdstr = tostring(cmd)
        end
        if (opts and opts.bang) then cmdstr = cmdstr .. ' ' .. table.concat(Quark.config.fzf.bang_flags, ' ') end
        local fzf = vim.deepcopy(Quark.config.fzf)
        fzf.cmd_actions = Quark.config.cmd_actions
        fn["fzf#run"](libfzf.specgen(fzf, Quark.config.window, cmdstr, false, dir))
    else
        warn("fzy_lua backend not implemented")
    end
end

-- Fuzzy-find recent files or switch to open buffers (excluding terminals).
function Quark.fuzzy_recent()
    if Quark.config.backend == "fzf" then
        if not libfzf.has_fzf() then return end
        local sep, printf = libfzf.get_sep_and_printf()
        local source = table.concat({
            printf, ' "', list_files({ vim.v.oldfiles, Quark.list_buf_names(false) }, ":~:.", sep), '"'
        })
        local fzf = vim.deepcopy(Quark.config.fzf)
        fzf.cmd_actions = Quark.config.cmd_actions
        fn["fzf#run"](libfzf.specgen(fzf, Quark.config.window, source, false, "", "Recent files: "))
    else
        warn("fzy_lua backend not implemented")
    end
end

-- Switch to fuzzy-matched open buffers (including terminals).
function Quark.fuzzy_switch()
    if Quark.config.backend == "fzf" then
        if not libfzf.has_fzf() then return end
        local sep, printf = libfzf.get_sep_and_printf()
        local files = list_files({ Quark.list_buf_names(false) }, ":~:.", sep)
        local terms = list_terminals(sep)
        local source = nil
        if #files > 0 and #terms > 0 then
            source = table.concat({ printf, ' "', files .. sep .. terms, '"' })
        elseif #files > 0 then
            source = table.concat({ printf, ' "', files, '"' })
        elseif #terms > 0 then
            source = table.concat({ printf, ' "', terms, '"' })
        end
        if source ~= nil then
            local fzf = vim.deepcopy(Quark.config.fzf)
            fzf.cmd_actions = Quark.config.cmd_actions
            fn["fzf#run"](libfzf.specgen(fzf, Quark.config.window, source, false, "", "Open buffers: "))
        else
            warn("no buffers available")
        end
    else
        warn("fzy_lua backend not implemented")
    end
end

-- Fuzzy ex-command selection.
function Quark.fuzzy_cmd()
    if Quark.config.backend == "fzf" then
        if not libfzf.has_fzf() then return end
        local sep, printf = libfzf.get_sep_and_printf()
        local fzf = vim.deepcopy(Quark.config.fzf)
        fzf.cmd_actions = Quark.config.cmd_actions
        fn["fzf#run"](
            libfzf.specgen(
                fzf, Quark.config.cmd_window, printf .. ' "' .. list_commands(sep) .. '"', true, "", ":"
            )
        )
    else
        warn("fzy_lua backend not implemented")
    end
end

return Quark
