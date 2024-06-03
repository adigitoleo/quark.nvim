local Common = {}
local api = vim.api
local bindkey = vim.keymap.set
function Common.warn(msg) api.nvim_err_writeln(msg) end

function Common.load(plugin) -- Load either local or third-party plugin.
    local has_plugin, out = pcall(require, plugin)
    if has_plugin then
        return out
    else
        Common.warn("failed to load plugin '" .. plugin .. "'")
        return nil
    end
end

function Common.create_keybinds()
    bindkey("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
    bindkey("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
    bindkey("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
    bindkey("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
end

return Common
