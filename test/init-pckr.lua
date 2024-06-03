local fn = vim.fn
local opt = vim.opt
common = require("test.common")

local function pkgbootstrap()
    local pckr_path = fn.stdpath("data") .. "/site/pack/pckr/start/pckr.nvim"
    if not (vim.uv or vim.loop).fs_stat(pckr_path) then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/lewis6991/pckr.nvim", pckr_path })
    end
    opt.rtp:prepend(pckr_path)
end

pkgbootstrap()
require("pckr").add {
    "https://git.sr.ht/~adigitoleo/quark.nvim",
}
vim.cmd { cmd = "Pckr", args = { "update" } }
quark = common.load("quark")
if quark then
    quark.setup {
        -- Requires ripgrep: <https://github.com/BurntSushi/ripgrep>
        fzf = { default_command = "rg --files --hidden --no-messages" }
    }
    common.create_keybinds()
end
