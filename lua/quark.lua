local api = vim.api
local opt = vim.opt
local fn = vim.fn
local command = api.nvim_create_user_command
local uncommand = api.nvim_del_user_command
local system = vim.loop.os_uname().sysname
local Quark = {}

if system == "Windows_NT" then
    _lsep = [[`n]]
    _printf = "echo"
else
    _lsep = [[\n]]
    _printf = "printf"
end

Quark.config = {
    define_commands = true,        -- toggle to prevent definition of default user commands
    window = {                     -- <https://github.com/junegunn/fzf/blob/master/README-VIM.md>
        width = 0.9,               -- width of floating window as a fraction of total width
        height = 0.6,              -- height of floating window as a fraction of total height
        winblend = 22,             -- transparency setting, not (yet?) supported by fzf?
        border = "sharp",          -- border style, see :h floatwin-api
        highlight = "NormalFloat", -- highlight group to use for the floating window
        zindex = 21,               -- floating window 'priority'
        preview = true,            -- show file previews using head(1) on linux
    },
    cmd_window = {                 -- Same as above but for the fuzzy ex-command picker window
        width = 1,
        height = 0.4,
        xoffset = 0,
        yoffset = 1, -- start one line above the status messages
        border = "top",
        highlight = "StatusLine",
        zindex = 23,
    },
    fzf = {
        default_command = nil, -- string or nil: if nil, use $FZF_DEFAULT_COMMAND
        -- default_opts = nil,    -- string or nil: if nil, use $FZF_DEFAULT_OPTS
        -- additional options passed to the fzf command for the ex-command picker
        cmd_extra_opts = {
            '--no-multi',
            '--print-query',
            '--prompt',
            ':',
            '--color',
            'prompt:-1',
            '--expect',
            ';,space|!', -- expect ! requires fzf ≥ 0.51.0
            '--layout',
            'reverse-list'
        },
        -- additional options passed to the fzf command for everything else
        extra_opts = vim.list_extend({ '--multi' },
            system == "Linux" and
            { '--preview', 'case $(file {}) in *"text"*) head -200 {} ;; *) echo "Preview unavailable" ;; esac',
                '--preview-window', vim.o.columns > 120 and 'right:60%:sharp' or 'down:60%:sharp' } or {})
    }
}

local function warn(msg) api.nvim_err_writeln("[quark.nvim]: " .. msg) end
local function is_executable(cmd) if fn.executable(cmd) > 0 then return true else return false end end

-- Validate custom user config, fall back to defaults defined above.
local function validate(key, value, section)
    local cfg = Quark.config
    local option = key .. " = " .. value
    local border_opts = { "sharp", "rounded", "horizontal", "vertical", "top", "bottom", "left", "right", "no", "none" }
    local numeric_window_keys = { "width_frac", "height_frac", "winblend", "zindex", "xoffset", "yoffset" }
    if section then
        option = table.concat({ section, key }, ".") .. " = " .. value
        if section == "window" or section == "cmd_window" and cfg.window[key] ~= nil then
            if vim.tbl_contains(numeric_window_keys, key) and not type(value) == "number" then
                warn(option .. " must be a number")
                return cfg[section][key]
            elseif key == "preview" and not type(value) == "boolean" then
                warn(option .. " must be a boolean")
                return cfg[section][key]
            elseif key == "border" and not vim.tbl_contains(border_opts, value) then
                warn(option .. " must be one of: " .. table.concat(border_opts, ", "))
            elseif key == "border" or key == "highlight" and not type(key) == "string" then
                warn(option .. " must be a string")
            end
        elseif section == "fzf" and cfg.fzf[key] ~= nil then
            if key == "default_command" and not type(value) == "string" then
                warn(option .. " must be a string")
            elseif (key == "cmd_extra_opts" or key == "extra_opts") and not type(value) == "table" then
                warn(option .. " must be a table ('list')")
            end
        end
    elseif key == "define_commands" and not type(value) == "boolean" then
        warn(option .. " must be a boolean")
    else
        warn("unrecognized config option " .. option)
    end
    return value
end

local function define_commands()
    command("QuarkRecent", Quark.fuzzy_recent, { desc = "Open recent files (v:oldfiles) or listed buffers" })
    command("QuarkFind", Quark.fuzzy_find,
        { nargs = "?", complete = "file", desc = "Open files from <dir> (or :pwd by default)" })
    command("QuarkSwitch", Quark.fuzzy_switch, { desc = "Switch between listed buffers or loaded `:terminal`s" })
end

local function delete_commands()
    uncommand("QuarkRecent")
    uncommand("QuarkFind")
    uncommand("QuarkSwitch")
end

local function has_fzf()
    local require_fzf_msg = "this plugin requires fzf (minimum version 0.51.0): <https://github.com/junegunn/fzf>"
    local tmpfile = os.tmpname() -- The things we do for Windows...
    local has_fzf_bin, _ = os.execute("fzf --version > " .. tmpfile)
    if not has_fzf_bin then
        warn(require_fzf_msg)
        warn("cannot find fzf command. Make sure your fzf binary is installed correctly.")
        os.remove(tmpfile)
        return false
    end
    local fzfver = {}
    for line in io.lines(tmpfile) do
        fzfver = vim.split(line, ".", { plain = true, trimempty = false })
        break
    end
    os.remove(tmpfile)
    if #fzfver < 3 then
        warn(require_fzf_msg)
        warn("cannot read fzf version. Make sure your fzf binary is installed correctly.")
        return false
    end
    if not is_executable("fzf") then
        warn(require_fzf_msg)
        warn("cannot execute fzf command. Make sure your fzf binary is installed correctly.")
        return false
    end
    if (
            tonumber(fzfver[1], 10) >= 0 and tonumber(fzfver[2], 10) >= 51
            and fn.exists("*fzf#run") and fn.exists("*fzf#wrap")
        ) then
        return true
    else
        warn(require_fzf_msg)
        return false
    end
end

-- Setup function to allow and validate user configuration.
function Quark.setup(config)
    if not has_fzf() then
        return
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
    vim.g.fzf_layout = { window = Quark.config.window }
    if Quark.config.define_commands then define_commands() else delete_commands() end
    return Quark
end

-- Generate filtered list of file names from given sources, omitting current file name.
local function list_files(sources, mods, sep)
    -- source: table of sources, each field is a sub-table of file names.
    -- mods: string of filters to use, see :h filename-modifiers and :h fnamemodify().
    -- sep: string, separator to insert between file names.

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
local function list_terminals(sep)
    -- sep: string, separator to insert between file names.
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
local function list_commands(sep)
    -- sep: string, separator to insert between file names.
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

function list_filetypes() -- List all known filetypes.
    local filetypes = {}
    for _, ft in pairs(fn.split(fn.expand("$VIMRUNTIME/ftplugin/*.vim"))) do
        table.insert(filetypes, fn.fnamemodify(ft, ":t:r"))
    end
    return filetypes
end

function list_syntax() -- List all known syntax files.
    local syntax = {}
    for _, sx in pairs(fn.split(fn.expand("$VIMRUNTIME/syntax/*.vim"))) do
        table.insert(syntax, fn.fnamemodify(sx, ":t:r"))
    end
    return syntax
end

-- Get list of open ("listed", or "loaded" if all is true) buffer names.
local function list_buf_names(all)
    local buffer_names = {}
    for _, buf in pairs(list_bufs(all)) do
        table.insert(buffer_names, api.nvim_buf_get_name(buf))
    end
    return buffer_names
end

-- Generate spec for custom fuzzy finders.
local function fzf_specgen(source, dir, prompt)
    local options = vim.deepcopy(Quark.config.fzf.extra_opts)
    if not Quark.config.window.preview then
        table.remove(options, #options) -- Remove --preview flag.
        table.remove(options, #options) -- Remove args.
    end
    table.insert(options, '--prompt')
    if prompt ~= nil then table.insert(options, prompt) else table.insert(options, dir .. ' ') end
    return {
        source = source,
        sink = 'e',
        dir = fn.substitute(fn.fnamemodify(dir, ':~'), '/*$', '/', ''),
        options = options,
    }
end

-- Files in current or chosen directory.
function Quark.fuzzy_find(opts)
    if not has_fzf() then return end
    local cmd = Quark.config.fzf.default_command
    if cmd == nil then
        cmd = os.getenv("FZF_DEFAULT_COMMAND")
        if cmd == nil then warn("requires either explicit fzf command or $FZF_DEFAULT_COMMAND") end
    end
    fn["fzf#run"](fn["fzf#wrap"](fzf_specgen('rg --files --hidden --no-messages', opts.args)))
end

-- Recent files and vim.g.oldfiles.
function Quark.fuzzy_recent()
    if not has_fzf() then return end
    local source = table.concat({
        _printf, ' "', list_files({ vim.v.oldfiles, list_buf_names(false) }, ":~:.", _lsep), '"'
    })
    fn["fzf#run"](fn["fzf#wrap"](fzf_specgen(source, "", "Recent files: ")))
end

-- vim.g.oldfiles and terminal buffers.
function Quark.fuzzy_switch()
    if not has_fzf() then return end
    local files = list_files({ list_buf_names(false) }, ":~:.", _lsep)
    local terms = list_terminals(_lsep)
    local source = nil
    if #files > 0 and #terms > 0 then
        source = table.concat({ _printf, ' "', files .. _lsep .. terms, '"' })
    elseif #files > 0 then
        source = table.concat({ _printf, ' "', files, '"' })
    elseif #terms > 0 then
        source = table.concat({ _printf, ' "', terms, '"' })
    end
    if source ~= nil then
        fn["fzf#run"](fn["fzf#wrap"](fzf_specgen(source, "", "Open buffers: ")))
    else
        warn("no buffers available")
    end
end

-- Fuzzy ex-command selection.
function Quark.fuzzy_cmd()
    if not has_fzf() then return end
    local spec = {
        source = _printf .. ' "' .. list_commands(_lsep) .. '"',
        window = Quark.config.cmd_window,
        options = {
            '--no-multi',
            '--print-query',
            '--prompt', ':',
            '--color', 'prompt:-1',
            '--expect', ';,space,|,!',
            '--layout', 'reverse-list'
        }
    }
    spec["sink*"] = function(fzf_out)
        if #fzf_out < 2 then return end
        local query = fzf_out[1]
        local key = fzf_out[2]
        local completion = fzf_out[3] ~= nil and fzf_out[3] or ''

        if #key == 0 then -- <Cr> pressed => execute completion
            -- NOTE: vim.cmd(completion) doesn't trigger TermOpen and swallows paged output from e.g. ':ls'.
            api.nvim_input(':' .. completion .. '<Cr>')
        elseif key == ';' then     -- ';' pressed => cancel completion
            api.nvim_input(':' .. query)
        elseif key == 'space' then -- '<space>' pressed => append space to completion
            api.nvim_input(':' .. completion .. ' ')
        else                       -- '!' or '|' pressed => append to completion, append trailing space
            api.nvim_input(':' .. completion .. key .. ' ')
        end
    end
    fn["fzf#run"](spec)
end

return Quark.setup {}
