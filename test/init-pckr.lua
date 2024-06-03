local fn = vim.fn
local opt = vim.opt
common = require("test.common")

local function pkgbootstrap()
    local pckr_path = fn.stdpath("data") .. "/site/pack/pckr/start/pckr.nvim"
    if not (vim.uv or vim.loop).fs_stat(pckr_path) then
        -- pckr.nvim is less mature than lazy.nvim so we use git HEAD rather than a stable branch/tag.
        fn.system { "git", "clone", "--depth", "1", "https://github.com/lewis6991/pckr.nvim", pckr_path }
    end
    opt.rtp:prepend(pckr_path)
end

pkgbootstrap()
require("pckr").add {
    {
        "https://git.sr.ht/~adigitoleo/quark.nvim",
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
