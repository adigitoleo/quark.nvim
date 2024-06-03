local opt = vim.opt
local fn = vim.fn
common = require("test.common")

local function pkgbootstrap()
    local lazypath = fn.stdpath("data") .. "/site/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        fn.system {
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath,
        }
    end
    opt.rtp:prepend(lazypath)
end

pkgbootstrap()
require("lazy").setup {
    {
        url = "https://git.sr.ht/~adigitoleo/quark.nvim",
        branch = "dev",
        config = function()
            quark = common.load("quark")
            if quark then
                quark.setup {
                    fzf = { default_command = "rg --files --hidden --no-messages" }
                }
                common.create_keybinds()
            end
        end
    }
}
