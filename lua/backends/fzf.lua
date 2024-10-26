local api = vim.api
local system = (vim.uv or vim.loop).os_uname().sysname
local fn = vim.fn

---@param cmd string
local function is_executable(cmd) if fn.executable(cmd) > 0 then return true else return false end end

local F = {
    -- From the fzf(1) man page.
    border_choices = { "sharp", "rounded", "bold", "double", "block", "thinblock", "horizontal", "vertical", "top", "bottom", "left", "right", "none" },
    -- File previews using head(1) for text files.
    preview_opts = system == "Linux" and {
        '--preview', "'case $(file {}) in *\"text\"*) head -200 ;; *) echo \"Preview unavailable\" ;; esac'",
        '--preview-window', vim.o.columns > 120 and "'right:60%:sharp'" or "'down:60%:sharp'"
    } or {},
    -- Mapping from generic window options to fzf options.
    window_opts_map = { width_frac = "width", height_frac = "height" }
}

-- Get separator and printf command suitable for constructing fzf 'sources'.
function F.get_sep_and_printf()
    local lsep = [[\n]]
    local printf = "printf"
    if system == "Windows_NT" then
        lsep = [[`n]]
        if vim.o.shell == "pwsh.exe" or vim.o.shell == "pwsh" then
            printf = "pwsh.exe -c echo" -- Extra pwsh.exe nesting ensures laziness?
        else
            printf = "echo"             -- Bare echo might prevent fuzzy_cmd from working.
        end
    end
    return lsep, printf
end

-- Check for a supported version of `fzf` (executable) and `fzf.vim`.
function F.has_fzf()
    local require_fzf_msg = "this plugin requires fzf (minimum version 0.51.0): <https://github.com/junegunn/fzf>"
    local tmpfile = os.tmpname() -- The things we do for Windows...
    local has_fzf_bin, _ = os.execute("fzf --version > " .. tmpfile)
    if not has_fzf_bin or not is_executable("fzf") then
        require_fzf_msg = require_fzf_msg ..
            "\ncannot find fzf command. Make sure your fzf binary is installed correctly."
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
        require_fzf_msg = require_fzf_msg ..
            "\ncannot read fzf version. Make sure your fzf binary is installed correctly."
        return false
    end
    if not (fn.exists("*fzf#run") and fn.exists("*fzf#wrap")) then
        require_fzf_msg = require_fzf_msg ..
            "\ncannot find fzf#run and fzf#wrap functions. Make sure your fzf.vim is installed correctly."
    elseif tonumber(fzfver[1], 10) >= 0 and tonumber(fzfver[2], 10) >= 51 then
        return true
    else
        return false
    end
end

-- Generate spec for custom fzf fuzzy finders.
---@param fzf table fzf configuration table (see Quark.config.fzf)
---@param window table window configuration table (see Quark.config.window or Quark.config.cmd_window)
---@param source string command to run to generate list of entries for the fuzzy search
---@param cmd boolean toggle spec for ex-command picker
---@param dir string directory in which to run the 'source' command
---@param prompt string|nil optional prompt message to display in front of the search query
function F.specgen(fzf, window, source, cmd, dir, prompt) ---@return table
    local options = {}
    if fzf.default_opts then
        options = fn.split(os.getenv("FZF_DEFAULT_OPTS") or '')
    end
    local extra_opts = fzf.extra_opts
    if cmd then
        extra_opts = fzf.cmd_extra_opts
        table.insert(extra_opts, '--print-query')
        if #fzf.cmd_actions > 0 then  -- Add '--expect' flag to fzf command with appropriate argument
            table.insert(extra_opts, '--expect')
            local keys = {}
            for k, _ in pairs(fzf.cmd_actions) do table.insert(keys, k) end
            table.insert(extra_opts, fn.shellescape(table.concat(keys, ',')))
        end
    elseif fzf.preview then
        for _, opt in pairs(F.preview_opts) do table.insert(extra_opts, opt) end
    end
    -- Always add a prompt, by default just the current directory name.
    table.insert(extra_opts, '--prompt')
    if prompt ~= nil then
        table.insert(extra_opts, fn.shellescape(prompt))
    else
        table.insert(extra_opts, fn.shellescape(dir .. ' '))
    end
    -- Transform window options to be compatible with fzf#run.
    local _window = {}
    for k, v in pairs(window) do
        if type(v) == 'string' then v = fn.shellescape(v) end
        if vim.tbl_contains(vim.tbl_keys(F.window_opts_map), k) then
            _window[F.window_opts_map[k]] = v
        else
            _window[k] = v
        end
    end
    -- Use 'e' (equivalent to 'edit') as the default sink.
    local spec = {
        source = source,
        sink = 'e',
        dir = fn.substitute(fn.fnamemodify(dir, ':~'), '/*$', '/', ''),
        options = table.concat(vim.list_extend(options, extra_opts), ' '),
        window = _window,
    }
    if cmd then -- Implement the ex-command picker sink.
        spec.sink = nil
        spec["sink*"] = function(fzf_out)
            if #fzf_out < 2 then return end
            local query = fzf_out[1]
            local key = fzf_out[2]
            local completion = fzf_out[3] ~= nil and fzf_out[3] or ''

            if #key == 0 or (fzf.cmd_actions[key] == 'execute') then
                -- <Cr> pressed => execute completion
                -- NOTE: vim.cmd(completion) doesn't trigger TermOpen and swallows paged output from e.g. ':ls'.
                api.nvim_input(':' .. completion .. '<Cr>')
            elseif fzf.cmd_actions[key] == 'cancel' then
                api.nvim_input(':' .. query)
            elseif fzf.cmd_actions[key] == 'add-space' then
                api.nvim_input(':' .. completion .. ' ')
            elseif fzf.cmd_actions[key] == 'add-self-and-space' then
                api.nvim_input(':' .. completion .. key .. ' ')
            end
        end
    end
    vim.print(spec)
    return fn["fzf#wrap"](spec)
end

return F
