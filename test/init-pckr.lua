local fn = vim.fn
local opt = vim.opt
local tests = require("test.tests")
local session = require("_testvar.fixtures")
local package_root = session.pckr_root
local pckr_path = session.pckr_path

local function pkgbootstrap()
    if not (vim.uv or vim.loop).fs_stat(pckr_path) then
        -- pckr.nvim is less mature than lazy.nvim so we use git HEAD rather than a stable branch/tag.
        fn.system { "git", "clone", "--depth", "1", "https://github.com/lewis6991/pckr.nvim", pckr_path }
    end
    opt.rtp:prepend(pckr_path)
end
pkgbootstrap()

local pckr = tests.load("pckr")
if pckr ~= nil then
    pckr.setup {
        package_root = package_root,
        display = { non_interactive = true },
    }
    pckr.add {
        -- This shouldn't be needed on most Linux systems if the fzf package is installed.
        -- { "https://github.com/junegunn/fzf", run = ":call fzf#install()" },
        {
            "https://git.sr.ht/~adigitoleo/quark.nvim",
            branch = "dev",
            config = function()
                local quark = tests.load("quark")
                if quark then
                    quark.setup {
                        fzf = { default_command = "rg --files --hidden --no-messages" }
                    }
                    tests.create_keybinds(quark)
                end
            end,
        }
    }
end
