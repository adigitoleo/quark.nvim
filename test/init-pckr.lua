local api = vim.api
local fn = vim.fn
local opt = vim.opt
local bindkey = vim.keymap.set
local function warn(msg) api.nvim_err_writeln("init.lua: " .. msg) end

local function pkgbootstrap()
    local pckr_path = fn.stdpath("data") .. "/site/pack/pckr/start/pckr.nvim"
    if not vim.loop.fs_stat(pckr_path) then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/lewis6991/pckr.nvim", pckr_path })
    end
    opt.rtp:prepend(pckr_path)
end

local function load(plugin) -- Load either local or third-party plugin.
    local has_plugin, out = pcall(require, plugin)
    if has_plugin then
        return out
    else
        warn("failed to load plugin '" .. plugin .. "'")
        return nil
    end
end

pkgbootstrap()
require("pckr").add {
    "https://git.sr.ht/~adigitoleo/quark.nvim",
}
quark = load("quark")
if quark then
    quark.setup {
        -- Requires ripgrep: <https://github.com/BurntSushi/ripgrep>
        fzf = { default_command = "rg --files --hidden --no-messages" }
    }
    bindkey("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
    bindkey("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
    bindkey("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
    bindkey("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
end
