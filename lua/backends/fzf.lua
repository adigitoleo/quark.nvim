local system = (vim.uv or vim.loop).os_uname().sysname
local fn = vim.fn

---@param cmd string
local function is_executable(cmd) if fn.executable(cmd) > 0 then return true else return false end end

local F = {
    -- From the fzf(1) man page.
    border_opts = { "sharp", "rounded", "bold", "double", "block", "thinblock", "horizontal", "vertical", "top", "bottom", "left", "right", "none" }
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
        require_fzf_msg = require_fzf_msg .. "\ncannot read fzf version. Make sure your fzf binary is installed correctly."
        return false
    end
    if not (fn.exists("*fzf#run") and fn.exists("*fzf#wrap")) then
        require_fzf_msg = require_fzf_msg .. "\ncannot find fzf#run and fzf#wrap functions. Make sure your fzf.vim is installed correctly."
    elseif tonumber(fzfver[1], 10) >= 0 and tonumber(fzfver[2], 10) >= 51 then
        return true
    else
        return false
    end
end

return F
