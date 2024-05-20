local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        url = 'https://github.com/adigitoleo/quark.nvim',
        config = function()
            quark = require("quark").setup({
                -- Requires ripgrep: <https://github.com/BurntSushi/ripgrep>
                fzf = { default_command = "rg --files --hidden no-messages" }
            })
            if quark ~= nil then
                vim.keymap.set("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
                -- Optional mappings for quick fuzzy-picker launching.
                vim.keymap.set("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
                vim.keymap.set("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
                vim.keymap.set("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
            end
        end
    }
})
