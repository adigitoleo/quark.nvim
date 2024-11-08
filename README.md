# ∴ quark.nvim

> Sure he hasn't got much of a bark
> And sure any he has it's all beside the mark.

Fuzzy pickers to open files, switch buffers and execute ex-commands.
Minimal configuration; tiny hackable source code.
Ce n'est pas un [télescope](https://github.com/nvim-telescope/telescope.nvim).

This [NeoVim](https://neovim.io) plugin, written in Lua, offers just three commands to
(1) open files from a directory,
(2) switch between open buffers and
(3) open files from recent history (see `:help shada-file`).
There is also an optional function which can be used to find and execute ex-commands.
Pickers don't list the currently open buffer. 
**This plugin is currently tested on latest NeoVim on Arch Linux.**
Check [this link](https://archlinux.org/packages/extra/x86_64/neovim/) to
discover the recommended NeoVim version.

## Setup

Install the plugin using your preferred plugin manager. Alternatively, NeoVim
can load packages if they are added to your [`'packpath'`](https://neovim.io/doc/user/options.html#'packpath').

To load the package without a plugin manager use the lua command `require('haunt').setup()`.
Default options are applied automatically, including floating window appearance,
the default system command used to list files and the default fzf flags.
These will be set to the values of
the `FZF_DEFAULT_COMMAND` and `FZF_DEFAULT_OPTS` environment variables,
unless overridden with explicit configurations as in the example below:

```lua
-- Requires fzf: <https://github.com/junegunn/fzf>
-- See also the 'Backends' section of the README file below.
quark = require("quark").setup {
    fzf = {
        -- Requires ripgrep: <https://github.com/BurntSushi/ripgrep>
        -- Alternatively, you can use find(1) on most Linux systems.
        default_command = "rg --files --hidden --no-messages",
        -- Allow opening multiple files and navigating the file preview.
        default_opts = "--multi --bind alt-j:preview-down,alt-k:preview-up",
    }
}
if quark ~= nil then
    vim.keymap.set("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
    -- Optional mappings for quick fuzzy-picker launching.
    vim.keymap.set("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
    vim.keymap.set("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
    vim.keymap.set("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
end
```

## Backends

Available commands and options are described in `:help quark`.

Supported fuzzy-finder backends:
- [x] [fzf](https://github.com/junegunn/fzf)¹ (default)
- [ ] [fzy-lua](https://github.com/swarn/fzy-lua)

¹Strictly, only the `fzf.vim` file (base fzf vim plugin) is required.
This file may not be installed by the `neovim` or `fzf` package for your Linux
distribution. In that case, there are two options:
1. Make sure to first install the `vim` package and add/copy
   the provided `fzf.vim` file into the neovim [`'runtimepath'`](https://neovim.io/doc/user/options.html#'runtimepath').
2. Install `<https://github.com/junegunn/fzf>` or `'junegunn/fzf'` using your
   NeoVim plugin manager.

## Contributing

New versions are generally developed on the `dev` branch.
Please send patches/queries to my [public inbox](https://lists.sr.ht/~adigitoleo/public-inbox).
Current issues and pending feature requests are listed on [my nvim-plugins tracker](https://todo.sr.ht/~adigitoleo/nvim-plugins?search=%5Bhaunt.nvim%5D).
Developers should download the [just](https://github.com/casey/just) command runner.
The source code includes a test suite which can be run using `just test`.
Running the test suite for the first time requires an internet connection,
because test suite dependencies need to be downloaded.
The test suite can also be run interactively by opening NeoVim with

    nvim -u test/init.lua

And running `:TestInit|TestRun`. The current CI test status is shown below:

[![builds.sr.ht status](https://builds.sr.ht/~adigitoleo/quark.nvim.svg)](https://builds.sr.ht/~adigitoleo/quark.nvim?)
